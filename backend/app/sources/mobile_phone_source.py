"""Implementazione sorgente telefono mobile"""
import json
from datetime import datetime
from typing import Optional, Dict, Any
from app.sources import VideoSource, TelemetryData
from app.config import SourceType


class MobilePhoneSource(VideoSource):
    """Sorgente video/telemetria per telefoni mobile"""
    
    def __init__(self, source_id: str):
        """
        Args:
            source_id: Identificativo univoco del telefono (es. IMEI o UUID)
        """
        super().__init__(source_id, SourceType.MOBILE_PHONE)
        self.latest_telemetry_data: Optional[Dict[str, Any]] = None
        self.video_url: Optional[str] = None
    
    def connect(self) -> bool:
        """Connetti al telefono"""
        # Per telefoni, la connessione può essere via:
        # - HTTP/WebSocket per ricevere metadata
        # - RTMP/WebRTC per stream video
        self.is_connected = True
        return True
    
    def disconnect(self):
        """Disconnetti dal telefono"""
        self.is_connected = False
    
    def set_video_url(self, url: str):
        """Imposta URL stream video dal telefono"""
        self.video_url = url
    
    def update_telemetry(self, data: Dict[str, Any]):
        """
        Aggiorna dati telemetria dal telefono
        
        Args:
            data: Dict con chiavi: latitude, longitude, altitude, heading, 
                  pitch, roll, yaw, velocity_x/y/z, camera_tilt, camera_pan
        """
        self.latest_telemetry_data = data
    
    def get_video_stream(self):
        """Ottieni stream video dal telefono"""
        if not self.video_url:
            raise ValueError(f"Video URL non configurato per telefono {self.source_id}")
        
        # Se è un URL RTMP, usa il receiver RTMP
        if self.video_url.startswith("rtmp://"):
            from app.rtmp.rtmp_receiver import RTMPStreamReceiver
            receiver = RTMPStreamReceiver(self.video_url)
            receiver.start()
            return receiver
        else:
            # Altrimenti usa OpenCV VideoCapture (supporta HTTP, RTSP, file, ecc.)
            import cv2
            return cv2.VideoCapture(self.video_url)
    
    def get_latest_telemetry(self) -> Optional[TelemetryData]:
        """Ottieni ultimi dati telemetria dal telefono"""
        if not self.latest_telemetry_data:
            return None
        
        data = self.latest_telemetry_data
        return TelemetryData(
            source_type=SourceType.MOBILE_PHONE,
            source_id=self.source_id,
            timestamp=datetime.now(),
            latitude=data.get('latitude', 0.0),
            longitude=data.get('longitude', 0.0),
            altitude=data.get('altitude', 0.0),
            heading=data.get('heading'),
            pitch=data.get('pitch'),
            roll=data.get('roll'),
            yaw=data.get('yaw'),
            velocity_x=data.get('velocity_x'),
            velocity_y=data.get('velocity_y'),
            velocity_z=data.get('velocity_z'),
            camera_tilt=data.get('camera_tilt'),
            camera_pan=data.get('camera_pan'),
            metadata=data
        )
    
    def is_available(self) -> bool:
        """Verifica disponibilità telefono"""
        # Una sorgente mobile è disponibile se è connessa e ha un video_url configurato
        # La telemetria può arrivare dopo, quindi non è un requisito obbligatorio
        return (
            self.is_connected and 
            self.video_url is not None
        )

