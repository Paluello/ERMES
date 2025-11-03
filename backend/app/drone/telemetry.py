"""Parser e utilities per dati telemetria drone"""
from typing import Dict, Any, Optional
from datetime import datetime


class TelemetryParser:
    """Parser per dati telemetria MAVLink"""
    
    @staticmethod
    def parse_mavlink_message(msg) -> Optional[Dict[str, Any]]:
        """Parse messaggio MAVLink in formato standardizzato"""
        msg_type = msg.get_type()
        result = {}
        
        if msg_type == 'GPS_RAW_INT':
            result = {
                'latitude': msg.lat / 1e7,
                'longitude': msg.lon / 1e7,
                'altitude': msg.alt / 1000.0,
                'timestamp': datetime.now()
            }
        
        elif msg_type == 'GLOBAL_POSITION_INT':
            result = {
                'latitude': msg.lat / 1e7,
                'longitude': msg.lon / 1e7,
                'altitude': msg.relative_alt / 1000.0,
                'velocity_x': msg.vx / 100.0,  # cm/s -> m/s
                'velocity_y': msg.vy / 100.0,
                'velocity_z': msg.vz / 100.0,
                'timestamp': datetime.now()
            }
        
        elif msg_type == 'ATTITUDE':
            import math
            yaw_deg = (math.degrees(msg.yaw) + 360) % 360
            result = {
                'roll': math.degrees(msg.roll),
                'pitch': math.degrees(msg.pitch),
                'yaw': math.degrees(msg.yaw),
                'heading': yaw_deg,
                'timestamp': datetime.now()
            }
        
        return result if result else None

