"""Processore video per gestione stream e elaborazione frame"""
import cv2
import numpy as np
from typing import Optional, Callable, Generator
from threading import Thread, Lock
import queue
from app.vision.yolo_detector import YOLODetector
from app.vision.tracker import ObjectTracker
from app.config import settings


class VideoProcessor:
    """Processore video per elaborazione stream in tempo reale"""
    
    def __init__(
        self,
        source_id: str,
        on_detection_callback: Optional[Callable] = None
    ):
        """
        Args:
            source_id: ID sorgente video
            on_detection_callback: Callback chiamato quando ci sono nuove detection
        """
        self.source_id = source_id
        self.on_detection_callback = on_detection_callback
        self.detector = YOLODetector()
        self.tracker = ObjectTracker()
        self.cap: Optional[cv2.VideoCapture] = None
        self.rtmp_receiver = None  # Per RTMPStreamReceiver
        self.is_processing = False
        self.process_thread: Optional[Thread] = None
        self.frame_queue = queue.Queue(maxsize=settings.video_buffer_size)
        self.lock = Lock()
    
    def start_processing(self, video_source):
        """
        Avvia elaborazione video
        
        Args:
            video_source: Stream video (cv2.VideoCapture, RTMPStreamReceiver, URL, o file path)
        """
        # Controlla se è un RTMPStreamReceiver
        if hasattr(video_source, 'read_frame'):
            # È un RTMPStreamReceiver
            self.rtmp_receiver = video_source
            self.cap = None
        elif isinstance(video_source, str):
            # URL o file path
            self.cap = cv2.VideoCapture(video_source)
            self.rtmp_receiver = None
        elif isinstance(video_source, cv2.VideoCapture):
            self.cap = video_source
            self.rtmp_receiver = None
        else:
            raise ValueError("video_source deve essere stringa, cv2.VideoCapture o RTMPStreamReceiver")
        
        if self.cap and not self.cap.isOpened():
            raise RuntimeError(f"Impossibile aprire stream video per sorgente {self.source_id}")
        
        self.is_processing = True
        self.process_thread = Thread(target=self._process_loop, daemon=True)
        self.process_thread.start()
    
    def stop_processing(self):
        """Ferma elaborazione video"""
        self.is_processing = False
        if self.rtmp_receiver:
            self.rtmp_receiver.stop()
        if self.cap:
            self.cap.release()
        if self.process_thread:
            self.process_thread.join(timeout=2.0)
    
    def _process_loop(self):
        """Loop principale elaborazione frame"""
        while self.is_processing:
            frame = None
            
            # Leggi frame da sorgente appropriata
            if self.rtmp_receiver:
                # Usa RTMPStreamReceiver
                frame = self.rtmp_receiver.read_frame()
                if frame is None:
                    import time
                    time.sleep(0.033)  # ~30 fps
                    continue
            elif self.cap:
                # Usa cv2.VideoCapture
                ret, frame = self.cap.read()
                if not ret:
                    break
            else:
                break
            
            if frame is None:
                continue
            
            # Detection con YOLO
            detections = self.detector.detect(frame)
            
            # Tracking
            tracked_detections = self.tracker.update(detections)
            
            # Limita numero oggetti tracciati
            if len(tracked_detections) > settings.max_tracked_objects:
                tracked_detections = sorted(
                    tracked_detections,
                    key=lambda x: x['confidence'],
                    reverse=True
                )[:settings.max_tracked_objects]
            
            # Chiama callback se disponibile
            if self.on_detection_callback and tracked_detections:
                self.on_detection_callback(
                    self.source_id,
                    frame,
                    tracked_detections
                )
    
    def get_frame_dimensions(self) -> Optional[tuple]:
        """Ottieni dimensioni frame (width, height)"""
        if self.cap:
            return (
                int(self.cap.get(cv2.CAP_PROP_FRAME_WIDTH)),
                int(self.cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
            )
        return None

