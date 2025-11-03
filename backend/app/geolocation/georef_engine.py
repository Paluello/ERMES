"""Engine per calcolo coordinate geografiche da pixel"""
import numpy as np
from typing import List, Dict, Any, Tuple, Optional
import math
from app.geolocation.camera_calibration import CameraCalibration
from app.sources import TelemetryData
from app.config import GPSPrecision, settings


class GeolocationEngine:
    """Engine per geolocalizzazione oggetti rilevati"""
    
    def __init__(self, camera_calibration: Optional[CameraCalibration] = None):
        """
        Args:
            camera_calibration: Calibrazione camera (usa default se None)
        """
        self.calibration = camera_calibration or CameraCalibration()
        self.earth_radius = 6371000  # Raggio Terra in metri
    
    def pixel_to_ground_coordinates(
        self,
        pixel_x: float,
        pixel_y: float,
        telemetry: TelemetryData,
        ground_altitude: float = 0.0
    ) -> Tuple[float, float]:
        """
        Converte coordinate pixel a coordinate geografiche terreno
        
        Args:
            pixel_x: Coordinata X pixel (0 = sinistra)
            pixel_y: Coordinata Y pixel (0 = alto)
            telemetry: Dati telemetria sorgente
            ground_altitude: Altitudine terreno (metri sopra livello mare)
        
        Returns:
            Tuple (latitude, longitude) coordinate oggetto
        """
        # Altezza sorgente sopra terreno
        source_height = telemetry.altitude - ground_altitude
        
        # Angoli camera (tilt/pan)
        camera_tilt = telemetry.camera_tilt or 0.0
        camera_pan = telemetry.camera_pan or 0.0
        
        # Converti pixel a angoli relativi camera
        K = self.calibration.get_intrinsic_matrix()
        fx, fy = K[0, 0], K[1, 1]
        cx, cy = K[0, 2], K[1, 2]
        
        # Angoli relativi al centro camera
        theta_x = math.atan((pixel_x - cx) / fx)  # Azimuth relativo
        theta_y = math.atan((pixel_y - cy) / fy)  # Elevazione relativa
        
        # Converti a angoli assoluti
        # Considera tilt camera (negativo = verso basso)
        elevation = math.radians(camera_tilt) - theta_y
        azimuth = math.radians(camera_pan) + theta_x
        
        # Calcola distanza al terreno usando altezza e angolo elevazione
        if elevation > 0:
            distance = source_height / math.tan(elevation)
        else:
            # Angolo negativo o zero = fuori campo visivo verso l'alto
            distance = source_height  # Fallback
        
        # Converti distanza + azimuth a offset lat/lon
        # Usa approssimazione locale (per distanze < 1km)
        lat_offset = distance * math.cos(azimuth) / self.earth_radius
        lon_offset = distance * math.sin(azimuth) / (self.earth_radius * math.cos(math.radians(telemetry.latitude)))
        
        # Calcola coordinate finali
        latitude = telemetry.latitude + math.degrees(lat_offset)
        longitude = telemetry.longitude + math.degrees(lon_offset)
        
        return latitude, longitude
    
    def geolocate_detections(
        self,
        detections: List[Dict[str, Any]],
        telemetry: TelemetryData,
        ground_altitude: float = 0.0
    ) -> List[Dict[str, Any]]:
        """
        Geolocalizza lista di detection
        
        Args:
            detections: Lista detection con 'center' o 'bbox'
            telemetry: Dati telemetria sorgente
            ground_altitude: Altitudine terreno
        
        Returns:
            Lista detection con coordinate geografiche aggiunte
        """
        geolocated = []
        
        for det in detections:
            # Usa centro bounding box
            if 'center' in det:
                pixel_x, pixel_y = det['center']
            elif 'bbox' in det:
                x1, y1, x2, y2 = det['bbox']
                pixel_x = (x1 + x2) / 2
                pixel_y = (y1 + y2) / 2
            else:
                continue
            
            try:
                latitude, longitude = self.pixel_to_ground_coordinates(
                    pixel_x, pixel_y, telemetry, ground_altitude
                )
                
                # Aggiungi coordinate a detection
                det_copy = det.copy()
                det_copy['latitude'] = latitude
                det_copy['longitude'] = longitude
                det_copy['source_id'] = telemetry.source_id
                det_copy['source_type'] = telemetry.source_type.value
                
                # Aggiungi precisione stimata
                det_copy['accuracy_meters'] = self._estimate_accuracy(
                    telemetry, source_height=telemetry.altitude - ground_altitude
                )
                
                geolocated.append(det_copy)
            except Exception as e:
                print(f"Errore geolocalizzazione detection: {e}")
                continue
        
        return geolocated
    
    def _estimate_accuracy(
        self,
        telemetry: TelemetryData,
        source_height: float
    ) -> float:
        """
        Stima precisione geolocalizzazione in metri
        
        Considera:
        - Precisione GPS sorgente
        - Altezza sorgente (più alta = meno preciso)
        - Risoluzione camera
        """
        # Precisione GPS base
        if settings.gps_precision == GPSPrecision.RTK:
            gps_accuracy = settings.gps_rtk_accuracy
        else:
            gps_accuracy = settings.gps_standard_accuracy
        
        # Errore dovuto all'altezza (angolo piccolo = errore maggiore)
        # Approssimazione: errore ~ height * pixel_error_radians
        pixel_error = 2.0  # pixel (errore tipico detection)
        angular_error = pixel_error / self.calibration.focal_length
        height_error = source_height * angular_error
        
        # Errore totale (RMS)
        total_error = math.sqrt(gps_accuracy**2 + height_error**2)
        
        return total_error

