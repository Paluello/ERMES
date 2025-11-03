"""Implementazione sorgente drone MAVLink"""
import threading
import time
from datetime import datetime
from typing import Optional
from app.sources import VideoSource, TelemetryData
from app.config import SourceType


class DroneSource(VideoSource):
    """Sorgente video/telemetria per droni MAVLink"""
    
    def __init__(self, source_id: str, connection_string: str):
        """
        Args:
            source_id: Identificativo univoco del drone
            connection_string: Stringa connessione MAVLink (es. "udp:127.0.0.1:14550" per SITL)
        """
        super().__init__(source_id, SourceType.DRONE)
        self.connection_string = connection_string
        self.telemetry_lock = threading.Lock()
        self.latest_telemetry: Optional[TelemetryData] = None
        self.telemetry_thread: Optional[threading.Thread] = None
        self._mavlink_connection = None
    
    def connect(self) -> bool:
        """Connetti al drone via MAVLink"""
        try:
            # Import qui per evitare dipendenze circolari
            from app.drone.mavlink_client import MAVLinkClient
            
            self._mavlink_connection = MAVLinkClient(
                connection_string=self.connection_string,
                callback=self._on_telemetry_received
            )
            
            if self._mavlink_connection.connect():
                self.is_connected = True
                # Avvia thread per acquisizione telemetria continua
                self.telemetry_thread = threading.Thread(
                    target=self._telemetry_loop,
                    daemon=True
                )
                self.telemetry_thread.start()
                return True
            return False
        except Exception as e:
            print(f"Errore connessione drone {self.source_id}: {e}")
            return False
    
    def disconnect(self):
        """Disconnetti dal drone"""
        self.is_connected = False
        if self._mavlink_connection:
            self._mavlink_connection.disconnect()
        if self.telemetry_thread:
            self.telemetry_thread.join(timeout=2.0)
    
    def get_video_stream(self):
        """Ottieni stream video dal drone"""
        # TODO: Implementare acquisizione stream video (UDP/RTMP)
        # Per ora placeholder
        raise NotImplementedError("Video stream acquisition da implementare")
    
    def get_latest_telemetry(self) -> Optional[TelemetryData]:
        """Ottieni ultimi dati telemetria"""
        with self.telemetry_lock:
            return self.latest_telemetry
    
    def is_available(self) -> bool:
        """Verifica disponibilità drone"""
        return self.is_connected and self._mavlink_connection is not None
    
    def _on_telemetry_received(self, data: dict):
        """Callback chiamato quando arrivano nuovi dati telemetria"""
        with self.telemetry_lock:
            self.latest_telemetry = TelemetryData(
                source_type=SourceType.DRONE,
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
    
    def _telemetry_loop(self):
        """Loop principale acquisizione telemetria"""
        while self.is_connected:
            if self._mavlink_connection:
                self._mavlink_connection.update()
            time.sleep(0.1)  # 10 Hz

