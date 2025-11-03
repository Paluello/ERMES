"""Data Source Abstraction Layer - Supporto per diverse sorgenti video/telemetria"""

from abc import ABC, abstractmethod
from typing import Optional, Dict, Any
from datetime import datetime
from app.config import SourceType


class TelemetryData:
    """Dati di telemetria standardizzati da qualsiasi sorgente"""
    
    def __init__(
        self,
        source_type: SourceType,
        source_id: str,
        timestamp: datetime,
        latitude: float,
        longitude: float,
        altitude: float,  # metri sopra livello mare
        heading: Optional[float] = None,  # gradi (0-360)
        pitch: Optional[float] = None,  # gradi
        roll: Optional[float] = None,  # gradi
        yaw: Optional[float] = None,  # gradi
        velocity_x: Optional[float] = None,  # m/s
        velocity_y: Optional[float] = None,  # m/s
        velocity_z: Optional[float] = None,  # m/s
        camera_tilt: Optional[float] = None,  # gradi per gimbal
        camera_pan: Optional[float] = None,  # gradi per gimbal
        metadata: Optional[Dict[str, Any]] = None
    ):
        self.source_type = source_type
        self.source_id = source_id
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.heading = heading
        self.pitch = pitch
        self.roll = roll
        self.yaw = yaw
        self.velocity_x = velocity_x
        self.velocity_y = velocity_y
        self.velocity_z = velocity_z
        self.camera_tilt = camera_tilt
        self.camera_pan = camera_pan
        self.metadata = metadata or {}


class VideoSource(ABC):
    """Interfaccia base per tutte le sorgenti video"""
    
    def __init__(self, source_id: str, source_type: SourceType):
        self.source_id = source_id
        self.source_type = source_type
        self.is_connected = False
    
    @abstractmethod
    def connect(self) -> bool:
        """Connetti alla sorgente video"""
        pass
    
    @abstractmethod
    def disconnect(self):
        """Disconnetti dalla sorgente"""
        pass
    
    @abstractmethod
    def get_video_stream(self):
        """Ottieni stream video (generator o callback)"""
        pass
    
    @abstractmethod
    def get_latest_telemetry(self) -> Optional[TelemetryData]:
        """Ottieni ultimi dati di telemetria disponibili"""
        pass
    
    @abstractmethod
    def is_available(self) -> bool:
        """Verifica se la sorgente è disponibile"""
        pass

