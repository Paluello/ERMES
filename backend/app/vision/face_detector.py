"""Face detector per rilevamento volti nelle immagini"""
import cv2
import numpy as np
from typing import List, Dict, Any, Optional
import os


class FaceDetector:
    """Detector per rilevamento volti usando OpenCV Haar Cascade"""
    
    def __init__(self, model_path: Optional[str] = None, conf_threshold: float = 0.5):
        """
        Args:
            model_path: Path al file cascade XML (default: usa Haar Cascade predefinito)
            conf_threshold: Soglia di confidenza minima per detection (usato come threshold per minNeighbors)
        """
        self.conf_threshold = conf_threshold
        
        # Usa Haar Cascade di OpenCV (sempre disponibile, veloce e affidabile)
        if model_path and os.path.exists(model_path):
            cascade_path = model_path
        else:
            # Usa il cascade predefinito di OpenCV
            cascade_path = cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
        
        if os.path.exists(cascade_path):
            self.face_cascade = cv2.CascadeClassifier(cascade_path)
            if self.face_cascade.empty():
                print("Warning: Haar Cascade caricato ma vuoto. Face detection potrebbe non funzionare.")
                self.face_cascade = None
        else:
            self.face_cascade = None
            print(f"Warning: Cascade file non trovato: {cascade_path}")
    
    def detect(self, frame: np.ndarray) -> List[Dict[str, Any]]:
        """
        Rileva volti in un frame
        
        Args:
            frame: Frame video come numpy array (BGR format)
        
        Returns:
            Lista di detection volti con formato:
            {
                'bbox': [x1, y1, x2, y2],
                'class_id': -1,  # ID speciale per volti
                'class_name': 'face',
                'confidence': float,
                'center': [x, y]
            }
        """
        detections = []
        
        if self.face_cascade is None:
            return detections
        
        # Converti in scala di grigi per Haar Cascade
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        
        # Parametri per detectMultiScale
        # scaleFactor: quanto ridurre l'immagine ad ogni scala (1.1 = piccolo incremento, più preciso ma più lento)
        # minNeighbors: numero minimo di vicini per confermare una detection (più alto = meno falsi positivi)
        # minSize: dimensione minima del volto da rilevare
        min_neighbors = max(3, int(self.conf_threshold * 10))  # Converte threshold in minNeighbors (3-10)
        
        faces = self.face_cascade.detectMultiScale(
            gray,
            scaleFactor=1.1,
            minNeighbors=min_neighbors,
            minSize=(30, 30),
            flags=cv2.CASCADE_SCALE_IMAGE
        )
        
        h, w = frame.shape[:2]
        for (x, y, width, height) in faces:
            # Calcola confidence basata sulla dimensione del volto rilevato
            # Volti più grandi tendono ad essere più affidabili
            face_area = width * height
            frame_area = w * h
            area_ratio = face_area / frame_area
            # Confidence più alta per volti più grandi (normalizzati)
            confidence = min(0.95, 0.6 + (area_ratio * 10))
            
            detections.append({
                'bbox': [float(x), float(y), float(x + width), float(y + height)],
                'class_id': -1,  # ID speciale per volti
                'class_name': 'face',
                'confidence': confidence,
                'center': [
                    float(x + width / 2),
                    float(y + height / 2)
                ]
            })
        
        return detections
    
    def is_available(self) -> bool:
        """Verifica se il detector è disponibile"""
        return self.face_cascade is not None and not self.face_cascade.empty()

