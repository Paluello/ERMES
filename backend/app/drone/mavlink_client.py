"""Client MAVLink per comunicazione con droni"""
import time
from typing import Optional, Callable, Dict, Any
import threading

try:
    from pymavlink import mavutil
    PYMAVLINK_AVAILABLE = True
except ImportError:
    PYMAVLINK_AVAILABLE = False
    print("Warning: pymavlink non installato. Usa: pip install pymavlink")


class MAVLinkClient:
    """Client per comunicazione MAVLink con droni"""
    
    def __init__(
        self,
        connection_string: str,
        callback: Optional[Callable[[Dict[str, Any]], None]] = None
    ):
        """
        Args:
            connection_string: Stringa connessione (es. "udp:127.0.0.1:14550")
            callback: Funzione chiamata quando arrivano nuovi dati telemetria
        """
        self.connection_string = connection_string
        self.callback = callback
        self.connection: Optional[Any] = None
        self.is_connected = False
        self.latest_data: Dict[str, Any] = {}
    
    def connect(self) -> bool:
        """Connetti al drone"""
        if not PYMAVLINK_AVAILABLE:
            print("Errore: pymavlink non disponibile")
            return False
        
        try:
            self.connection = mavutil.mavlink_connection(self.connection_string)
            # Attendi heartbeat per confermare connessione
            self.connection.wait_heartbeat(timeout=5)
            self.is_connected = True
            print(f"Connesso al drone via {self.connection_string}")
            return True
        except Exception as e:
            print(f"Errore connessione MAVLink: {e}")
            self.is_connected = False
            return False
    
    def disconnect(self):
        """Disconnetti dal drone"""
        self.is_connected = False
        if self.connection:
            try:
                self.connection.close()
            except:
                pass
            self.connection = None
    
    def update(self):
        """Aggiorna e processa messaggi MAVLink"""
        if not self.is_connected or not self.connection:
            return
        
        try:
            msg = self.connection.recv_match(type=['GPS_RAW_INT', 'ATTITUDE', 'GLOBAL_POSITION_INT'], blocking=False, timeout=0.1)
            
            if msg is not None:
                self._process_message(msg)
        except Exception as e:
            print(f"Errore lettura messaggi MAVLink: {e}")
    
    def _process_message(self, msg):
        """Processa messaggio MAVLink e aggiorna dati telemetria"""
        msg_type = msg.get_type()
        
        if msg_type == 'GPS_RAW_INT':
            # GPS dati (lat/lon in gradienti * 1e7)
            self.latest_data['latitude'] = msg.lat / 1e7
            self.latest_data['longitude'] = msg.lon / 1e7
            self.latest_data['altitude'] = msg.alt / 1000.0  # Converti da mm a metri
        
        elif msg_type == 'GLOBAL_POSITION_INT':
            # Posizione globale (più accurata)
            self.latest_data['latitude'] = msg.lat / 1e7
            self.latest_data['longitude'] = msg.lon / 1e7
            self.latest_data['altitude'] = msg.relative_alt / 1000.0  # Altitudine relativa in mm
        
        elif msg_type == 'ATTITUDE':
            # Orientamento (roll, pitch, yaw in radianti)
            import math
            self.latest_data['roll'] = math.degrees(msg.roll)
            self.latest_data['pitch'] = math.degrees(msg.pitch)
            self.latest_data['yaw'] = math.degrees(msg.yaw)
            self.latest_data['heading'] = (math.degrees(msg.yaw) + 360) % 360
        
        # Chiama callback se disponibile
        if self.callback and self.latest_data:
            self.callback(self.latest_data.copy())
    
    def get_latest_telemetry(self) -> Dict[str, Any]:
        """Ottieni ultimi dati telemetria"""
        return self.latest_data.copy()

