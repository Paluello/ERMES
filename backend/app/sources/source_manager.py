"""Manager centrale per gestione multiple sorgenti video"""
from typing import Dict, Optional, List
from app.sources import VideoSource
from app.sources.drone_source import DroneSource
from app.sources.static_camera_source import StaticCameraSource
from app.sources.mobile_phone_source import MobilePhoneSource
from app.config import SourceType


class SourceManager:
    """Gestisce tutte le sorgenti video attive"""
    
    def __init__(self):
        self.sources: Dict[str, VideoSource] = {}
    
    def register_drone(
        self,
        source_id: str,
        connection_string: str
    ) -> bool:
        """Registra una nuova sorgente drone"""
        if source_id in self.sources:
            return False
        
        source = DroneSource(source_id, connection_string)
        if source.connect():
            self.sources[source_id] = source
            return True
        return False
    
    def register_static_camera(
        self,
        source_id: str,
        latitude: float,
        longitude: float,
        altitude: float,
        video_url: str,
        camera_tilt: float = 0.0,
        camera_pan: float = 0.0,
        camera_fov_horizontal: float = 84.0,
        camera_fov_vertical: float = 53.0
    ) -> bool:
        """Registra una nuova telecamera fissa"""
        if source_id in self.sources:
            return False
        
        source = StaticCameraSource(
            source_id=source_id,
            latitude=latitude,
            longitude=longitude,
            altitude=altitude,
            camera_tilt=camera_tilt,
            camera_pan=camera_pan,
            camera_fov_horizontal=camera_fov_horizontal,
            camera_fov_vertical=camera_fov_vertical
        )
        source.set_video_url(video_url)
        
        if source.connect():
            self.sources[source_id] = source
            return True
        return False
    
    def register_mobile_phone(
        self,
        source_id: str,
        video_url: str
    ) -> bool:
        """Registra un nuovo telefono mobile"""
        if source_id in self.sources:
            return False
        
        source = MobilePhoneSource(source_id)
        source.set_video_url(video_url)
        
        if source.connect():
            self.sources[source_id] = source
            return True
        return False
    
    def get_source(self, source_id: str) -> Optional[VideoSource]:
        """Ottieni sorgente per ID"""
        return self.sources.get(source_id)
    
    def get_all_sources(self) -> List[VideoSource]:
        """Ottieni tutte le sorgenti registrate"""
        return list(self.sources.values())
    
    def remove_source(self, source_id: str) -> bool:
        """Rimuovi sorgente"""
        if source_id in self.sources:
            source = self.sources[source_id]
            source.disconnect()
            del self.sources[source_id]
            return True
        return False
    
    def get_active_sources(self) -> List[VideoSource]:
        """Ottieni solo sorgenti attive"""
        return [s for s in self.sources.values() if s.is_available()]

