"""Ricevitore RTMP stream e conversione a OpenCV VideoCapture"""
import subprocess
import threading
import queue
import cv2
import numpy as np
from typing import Optional, Callable
import logging

logger = logging.getLogger(__name__)


class RTMPStreamReceiver:
    """
    Riceve stream RTMP e li converte in frame OpenCV
    
    Usa ffmpeg per ricevere stream RTMP e convertirli in frame
    """
    
    def __init__(self, rtmp_url: str, on_frame_callback: Optional[Callable] = None):
        """
        Args:
            rtmp_url: URL stream RTMP (es. rtmp://localhost:1935/stream/source_id)
            on_frame_callback: Callback chiamato per ogni frame ricevuto
        """
        self.rtmp_url = rtmp_url
        self.on_frame_callback = on_frame_callback
        self.ffmpeg_process: Optional[subprocess.Popen] = None
        self.is_running = False
        self.frame_queue = queue.Queue(maxsize=10)
        self.thread: Optional[threading.Thread] = None
    
    def start(self):
        """Avvia ricezione stream RTMP"""
        if self.is_running:
            return
        
        self.is_running = True
        
        # Comando ffmpeg per ricevere RTMP e convertire in raw video
        cmd = [
            'ffmpeg',
            '-i', self.rtmp_url,
            '-f', 'rawvideo',
            '-pix_fmt', 'bgr24',
            '-vcodec', 'rawvideo',
            '-'  # Output su stdout
        ]
        
        try:
            self.ffmpeg_process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                bufsize=10**8
            )
            
            # Avvia thread per leggere frame
            self.thread = threading.Thread(target=self._read_frames, daemon=True)
            self.thread.start()
            
            logger.info(f"RTMP stream receiver avviato per {self.rtmp_url}")
        except Exception as e:
            logger.error(f"Errore avvio RTMP receiver: {e}")
            self.is_running = False
    
    def stop(self):
        """Ferma ricezione stream"""
        self.is_running = False
        
        if self.ffmpeg_process:
            self.ffmpeg_process.terminate()
            try:
                self.ffmpeg_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.ffmpeg_process.kill()
            self.ffmpeg_process = None
        
        if self.thread:
            self.thread.join(timeout=2.0)
    
    def _read_frames(self):
        """Legge frame da ffmpeg stdout"""
        # Assumiamo risoluzione 1920x1080 (modificare se necessario)
        width, height = 1920, 1080
        frame_size = width * height * 3  # BGR24 = 3 bytes per pixel
        
        while self.is_running and self.ffmpeg_process:
            try:
                raw_frame = self.ffmpeg_process.stdout.read(frame_size)
                
                if len(raw_frame) != frame_size:
                    break  # Stream terminato
                
                # Converti bytes a numpy array
                frame = np.frombuffer(raw_frame, dtype=np.uint8)
                frame = frame.reshape((height, width, 3))
                
                # Aggiungi a coda o chiama callback
                if self.on_frame_callback:
                    self.on_frame_callback(frame)
                else:
                    try:
                        self.frame_queue.put_nowait(frame)
                    except queue.Full:
                        # Rimuovi frame più vecchio
                        try:
                            self.frame_queue.get_nowait()
                            self.frame_queue.put_nowait(frame)
                        except queue.Empty:
                            pass
            except Exception as e:
                logger.error(f"Errore lettura frame: {e}")
                break
        
        self.is_running = False
    
    def read_frame(self) -> Optional[np.ndarray]:
        """
        Legge un frame dalla coda
        
        Returns:
            Frame come numpy array (BGR) o None se non disponibile
        """
        try:
            return self.frame_queue.get(timeout=1.0)
        except queue.Empty:
            return None


def create_video_capture_from_rtmp(rtmp_url: str):
    """
    Crea un oggetto simile a cv2.VideoCapture da URL RTMP
    
    Args:
        rtmp_url: URL stream RTMP
    
    Returns:
        RTMPStreamReceiver configurato come VideoCapture-like object
    """
    receiver = RTMPStreamReceiver(rtmp_url)
    receiver.start()
    return receiver

