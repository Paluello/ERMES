"""Calibrazione camera e gestione parametri"""
from typing import Dict, Any, Optional
import json
import numpy as np
from app.config import settings


class CameraCalibration:
    """Gestisce parametri di calibrazione camera"""
    
    def __init__(
        self,
        fov_horizontal: Optional[float] = None,
        fov_vertical: Optional[float] = None,
        resolution_width: Optional[int] = None,
        resolution_height: Optional[int] = None,
        focal_length: Optional[float] = None,
        sensor_width: Optional[float] = None,
        sensor_height: Optional[float] = None
    ):
        """
        Args:
            fov_horizontal: Campo visivo orizzontale (gradi)
            fov_vertical: Campo visivo verticale (gradi)
            resolution_width: Larghezza risoluzione pixel
            resolution_height: Altezza risoluzione pixel
            focal_length: Lunghezza focale (mm) - calcolata se non fornita
            sensor_width: Larghezza sensore (mm) - calcolata se non fornita
            sensor_height: Altezza sensore (mm) - calcolata se non fornita
        """
        self.fov_horizontal = fov_horizontal or settings.camera_fov_horizontal
        self.fov_vertical = fov_vertical or settings.camera_fov_vertical
        self.resolution_width = resolution_width or settings.camera_resolution_width
        self.resolution_height = resolution_height or settings.camera_resolution_height
        
        # Calcola parametri derivati se non forniti
        if focal_length is None:
            # Stima focale da FOV e risoluzione
            self.focal_length = self._estimate_focal_length()
        else:
            self.focal_length = focal_length
        
        if sensor_width is None or sensor_height is None:
            # Stima dimensioni sensore (assumendo rapporto standard)
            self.sensor_width = 36.0  # mm (full frame equivalente)
            self.sensor_height = 24.0  # mm
        else:
            self.sensor_width = sensor_width
            self.sensor_height = sensor_height
    
    def _estimate_focal_length(self) -> float:
        """Stima lunghezza focale da FOV e risoluzione"""
        # Usa FOV orizzontale per calcolo
        fov_rad = np.radians(self.fov_horizontal)
        focal_length_pixels = self.resolution_width / (2 * np.tan(fov_rad / 2))
        # Converti a mm (assumendo sensore 36mm)
        focal_length_mm = (focal_length_pixels / self.resolution_width) * self.sensor_width
        return focal_length_mm
    
    def get_intrinsic_matrix(self) -> np.ndarray:
        """Ottieni matrice intrinseca camera (K)"""
        fx = (self.focal_length / self.sensor_width) * self.resolution_width
        fy = (self.focal_length / self.sensor_height) * self.resolution_height
        cx = self.resolution_width / 2.0
        cy = self.resolution_height / 2.0
        
        return np.array([
            [fx, 0, cx],
            [0, fy, cy],
            [0, 0, 1]
        ], dtype=np.float32)
    
    def to_dict(self) -> Dict[str, Any]:
        """Converte calibrazione a dict per serializzazione"""
        return {
            'fov_horizontal': self.fov_horizontal,
            'fov_vertical': self.fov_vertical,
            'resolution_width': self.resolution_width,
            'resolution_height': self.resolution_height,
            'focal_length': self.focal_length,
            'sensor_width': self.sensor_width,
            'sensor_height': self.sensor_height
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'CameraCalibration':
        """Crea calibrazione da dict"""
        return cls(**data)
    
    @classmethod
    def from_json_file(cls, filepath: str) -> 'CameraCalibration':
        """Carica calibrazione da file JSON"""
        with open(filepath, 'r') as f:
            data = json.load(f)
        return cls.from_dict(data)
    
    def save_to_json(self, filepath: str):
        """Salva calibrazione su file JSON"""
        with open(filepath, 'w') as f:
            json.dump(self.to_dict(), f, indent=2)

