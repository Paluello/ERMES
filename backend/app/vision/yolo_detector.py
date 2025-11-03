"""Wrapper YOLO per object detection"""
from typing import List, Tuple, Dict, Any
import numpy as np
from app.config import settings

try:
    from ultralytics import YOLO
    ULTRALYTICS_AVAILABLE = True
except ImportError:
    ULTRALYTICS_AVAILABLE = False
    print("Warning: ultralytics non installato. Usa: pip install ultralytics")


class YOLODetector:
    """Detector YOLO per rilevamento oggetti"""
    
    # Classi di interesse per il nostro caso d'uso
    TARGET_CLASSES = {
        0: 'person',
        2: 'car',
        3: 'motorcycle',
        5: 'bus',
        7: 'truck'
    }
    
    def __init__(self, model_path: str = None):
        """
        Args:
            model_path: Path al modello YOLO (default: usa modello pre-addestrato)
        """
        if not ULTRALYTICS_AVAILABLE:
            raise ImportError("ultralytics non disponibile. Installa con: pip install ultralytics")
        
        model_path = model_path or settings.yolo_model
        self.model = YOLO(model_path)
        self.conf_threshold = settings.yolo_conf_threshold
        self.iou_threshold = settings.yolo_iou_threshold
    
    def detect(self, frame: np.ndarray) -> List[Dict[str, Any]]:
        """
        Rileva oggetti in un frame
        
        Args:
            frame: Frame video come numpy array (BGR format)
        
        Returns:
            Lista di detection con formato:
            {
                'bbox': [x1, y1, x2, y2],
                'class_id': int,
                'class_name': str,
                'confidence': float
            }
        """
        results = self.model.predict(
            frame,
            conf=self.conf_threshold,
            iou=self.iou_threshold,
            verbose=False
        )
        
        detections = []
        if results and len(results) > 0:
            result = results[0]
            
            # Filtra solo classi di interesse
            for box in result.boxes:
                class_id = int(box.cls[0])
                
                if class_id in self.TARGET_CLASSES:
                    x1, y1, x2, y2 = box.xyxy[0].cpu().numpy()
                    confidence = float(box.conf[0])
                    
                    detections.append({
                        'bbox': [float(x1), float(y1), float(x2), float(y2)],
                        'class_id': class_id,
                        'class_name': self.TARGET_CLASSES[class_id],
                        'confidence': confidence,
                        'center': [
                            float((x1 + x2) / 2),
                            float((y1 + y2) / 2)
                        ]
                    })
        
        return detections
    
    def is_available(self) -> bool:
        """Verifica se il detector è disponibile"""
        return ULTRALYTICS_AVAILABLE and self.model is not None

