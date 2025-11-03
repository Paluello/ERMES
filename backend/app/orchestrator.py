"""Orchestratore principale per integrazione moduli"""
import asyncio
import threading
import queue
from typing import Dict, Optional, List, Any
from app.sources.source_manager import SourceManager
from app.sources import VideoSource, TelemetryData
from app.vision.video_processor import VideoProcessor
from app.geolocation.georef_engine import GeolocationEngine
from app.geolocation.camera_calibration import CameraCalibration
from app.api.websocket import connection_manager
from app.config import settings


class TrackingOrchestrator:
    """Orchestratore principale per gestione completa tracking"""
    
    def __init__(self, source_manager: SourceManager, event_loop: Optional[asyncio.AbstractEventLoop] = None):
        """
        Args:
            source_manager: Manager sorgenti video
            event_loop: Event loop asyncio (se None, usa quello corrente)
        """
        self.source_manager = source_manager
        self.video_processors: Dict[str, VideoProcessor] = {}
        self.geolocation_engines: Dict[str, GeolocationEngine] = {}
        self.running = False
        self.processing_threads: Dict[str, threading.Thread] = {}
        self.detection_queue: queue.Queue = queue.Queue()
        self.event_loop = event_loop or asyncio.get_event_loop()
    
    def start_processing_source(self, source_id: str):
        """Avvia elaborazione per una sorgente"""
        source = self.source_manager.get_source(source_id)
        if not source or not source.is_available():
            print(f"Sorgente {source_id} non disponibile")
            return False
        
        # Crea geolocation engine per questa sorgente
        calibration = CameraCalibration()
        geoloc_engine = GeolocationEngine(calibration)
        self.geolocation_engines[source_id] = geoloc_engine
        
        # Crea video processor
        processor = VideoProcessor(
            source_id=source_id,
            on_detection_callback=self._on_detection_callback
        )
        
        try:
            # Ottieni stream video dalla sorgente
            video_stream = source.get_video_stream()
            processor.start_processing(video_stream)
            
            self.video_processors[source_id] = processor
            print(f"Elaborazione avviata per sorgente {source_id}")
            return True
        except Exception as e:
            print(f"Errore avvio elaborazione {source_id}: {e}")
            return False
    
    def stop_processing_source(self, source_id: str):
        """Ferma elaborazione per una sorgente"""
        if source_id in self.video_processors:
            processor = self.video_processors[source_id]
            processor.stop_processing()
            del self.video_processors[source_id]
        
        if source_id in self.geolocation_engines:
            del self.geolocation_engines[source_id]
    
    def _on_detection_callback(
        self,
        source_id: str,
        frame,
        detections: list
    ):
        """Callback chiamato quando ci sono nuove detection (chiamato da thread video)"""
        # Metti detection in coda per processamento asincrono
        try:
            self.detection_queue.put_nowait({
                'source_id': source_id,
                'detections': detections
            })
        except queue.Full:
            print(f"Coda detection piena, detection persa per {source_id}")
    
    async def _broadcast_detections(self, detections: list):
        """Invia detection geolocalizzate via WebSocket"""
        for detection in detections:
            message = {
                "type": "detection",
                "payload": {
                    "track_id": detection.get("track_id"),
                    "class_name": detection.get("class_name"),
                    "latitude": detection.get("latitude"),
                    "longitude": detection.get("longitude"),
                    "confidence": detection.get("confidence"),
                    "source_id": detection.get("source_id"),
                    "source_type": detection.get("source_type"),
                    "accuracy_meters": detection.get("accuracy_meters")
                }
            }
            await connection_manager.broadcast(message)
    
    async def _process_detection_queue(self):
        """Processa coda detection in modo asincrono"""
        while self.running:
            try:
                # Attendi detection dalla coda (con timeout per non bloccare)
                item = await asyncio.get_event_loop().run_in_executor(
                    None,
                    lambda: self.detection_queue.get(timeout=0.1)
                )
                
                source_id = item['source_id']
                detections = item['detections']
                
                if source_id not in self.geolocation_engines:
                    continue
                
                source = self.source_manager.get_source(source_id)
                if not source:
                    continue
                
                # Ottieni telemetria corrente
                telemetry = source.get_latest_telemetry()
                if not telemetry:
                    continue
                
                # Geolocalizza detection
                geoloc_engine = self.geolocation_engines[source_id]
                geolocated = geoloc_engine.geolocate_detections(
                    detections,
                    telemetry,
                    ground_altitude=0.0  # TODO: Calcolare da DTM o configurazione
                )
                
                # Invia via WebSocket
                await self._broadcast_detections(geolocated)
                
            except queue.Empty:
                continue
            except Exception as e:
                print(f"Errore processamento detection: {e}")
    
    async def broadcast_telemetry_loop(self):
        """Loop per broadcast periodico telemetria sorgenti"""
        while self.running:
            sources = self.source_manager.get_active_sources()
            for source in sources:
                telemetry = source.get_latest_telemetry()
                if telemetry:
                    message = {
                        "type": "telemetry",
                        "payload": {
                            "source_id": telemetry.source_id,
                            "source_type": telemetry.source_type.value,
                            "timestamp": telemetry.timestamp.isoformat(),
                            "latitude": telemetry.latitude,
                            "longitude": telemetry.longitude,
                            "altitude": telemetry.altitude,
                            "heading": telemetry.heading,
                            "pitch": telemetry.pitch,
                            "roll": telemetry.roll,
                            "yaw": telemetry.yaw
                        }
                    }
                    await connection_manager.broadcast(message)
            
            await asyncio.sleep(1.0)  # Aggiorna ogni secondo
    
    async def start_async(self):
        """Avvia orchestratore in modo asincrono"""
        self.running = True
        # Avvia loop asincroni in background
        asyncio.create_task(self.broadcast_telemetry_loop())
        asyncio.create_task(self._process_detection_queue())
    
    def start(self):
        """Avvia orchestratore (wrapper sincrono)"""
        self.running = True
        # Le task verranno create nel contesto async di FastAPI
    
    def stop(self):
        """Ferma orchestratore"""
        self.running = False
        # Ferma tutti i processor
        for source_id in list(self.video_processors.keys()):
            self.stop_processing_source(source_id)

