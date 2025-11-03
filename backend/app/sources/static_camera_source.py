"""Implementazione sorgente telecamera fissa (piazza/strada)"""
from datetime import datetime
from typing import Optional
from app.sources import VideoSource, TelemetryData
from app.config import SourceType


class StaticCameraSource(VideoSource):
    """Sorgente video/telemetria per telecamere fisse"""
    
    def __init__(
        self,
        source_id: str,
        latitude: float,
        longitude: float,
        altitude: float,
        camera_tilt: float = 0.0,  # Angolo tilt camera in gradi
        camera_pan: float = 0.0,  # Angolo pan camera in gradi
        camera_fov_horizontal: float = 84.0,
        camera_fov_vertical: float = 53.0
    ):
        """
        Args:
            source_id: Identificativo univoco della telecamera
            latitude: Latitudine posizione telecamera
            longitude: Longitudine posizione telecamera
            altitude: Altitudine telecamera (metri sopra livello mare)
            camera_tilt: Angolo tilt (negativo = verso il basso)
            camera_pan: Angolo pan (0 = nord, 90 = est)
            camera_fov_horizontal: Campo visivo orizzontale (gradi)
            camera_fov_vertical: Campo visivo verticale (gradi)
        """
        super().__init__(source_id, SourceType.STATIC_CAMERA)
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.camera_tilt = camera_tilt
        self.camera_pan = camera_pan
        self.camera_fov_horizontal = camera_fov_horizontal
        self.camera_fov_vertical = camera_fov_vertical
        self.video_url: Optional[str] = None
    
    def connect(self) -> bool:
        """Connetti alla telecamera"""
        # Per telecamere fisse, la connessione è principalmente verificare
        # che lo stream video sia accessibile
        self.is_connected = True
        return True
    
    def disconnect(self):
        """Disconnetti dalla telecamera"""
        self.is_connected = False
    
    def set_video_url(self, url: str):
        """Imposta URL stream video (RTSP, HTTP, file, ecc.)"""
        self.video_url = url
    
    def get_video_stream(self):
        """Ottieni stream video dalla telecamera"""
        if not self.video_url:
            raise ValueError(f"Video URL non configurato per camera {self.source_id}")
        # TODO: Implementare acquisizione stream basata su URL
        # OpenCV può gestire RTSP, HTTP, file, ecc.
        raise NotImplementedError("Video stream acquisition da implementare")
    
    def get_latest_telemetry(self) -> Optional[TelemetryData]:
        """Ottieni dati telemetria (statici per telecamera fissa)"""
        return TelemetryData(
            source_type=SourceType.STATIC_CAMERA,
            source_id=self.source_id,
            timestamp=datetime.now(),
            latitude=self.latitude,
            longitude=self.longitude,
            altitude=self.altitude,
            heading=self.camera_pan,  # Pan corrisponde a heading
            camera_tilt=self.camera_tilt,
            camera_pan=self.camera_pan,
            metadata={
                'fov_horizontal': self.camera_fov_horizontal,
                'fov_vertical': self.camera_fov_vertical,
                'is_static': True
            }
        )
    
    def is_available(self) -> bool:
        """Verifica disponibilità telecamera"""
        return self.is_connected and self.video_url is not None

