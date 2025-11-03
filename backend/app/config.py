"""Configurazioni globali del sistema"""
from pydantic_settings import BaseSettings
from typing import Optional
from enum import Enum


class GPSPrecision(str, Enum):
    """Tipi di precisione GPS supportati"""
    STANDARD = "standard"  # 3-5 metri
    RTK = "rtk"  # Precisione centimetrica


class SourceType(str, Enum):
    """Tipi di sorgenti video supportate"""
    DRONE = "drone"
    STATIC_CAMERA = "static_camera"
    MOBILE_PHONE = "mobile_phone"


class Settings(BaseSettings):
    """Configurazioni applicazione"""
    
    # GPS Configuration
    gps_precision: GPSPrecision = GPSPrecision.STANDARD
    gps_standard_accuracy: float = 5.0  # metri
    gps_rtk_accuracy: float = 0.1  # metri
    
    # Video Processing
    video_fps: int = 30
    max_tracked_objects: int = 20
    yolo_model: str = "yolov8n.pt"  # nano per velocità, può essere yolov8s/m/l/x
    yolo_conf_threshold: float = 0.5
    yolo_iou_threshold: float = 0.45
    
    # Camera Calibration (default, override con calibrazione specifica)
    camera_fov_horizontal: float = 84.0  # gradi
    camera_fov_vertical: float = 53.0  # gradi
    camera_resolution_width: int = 1920
    camera_resolution_height: int = 1080
    
    # API Configuration
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    websocket_path: str = "/ws"
    
    # Performance
    target_latency_seconds: float = 2.0
    video_buffer_size: int = 10
    
    # Logging
    log_level: str = "INFO"
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()

