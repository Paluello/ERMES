"""Object tracker per mantenere ID consistenti tra frame"""
from typing import List, Dict, Any, Optional
import numpy as np
from collections import defaultdict

try:
    from deep_sort import DeepSort
    DEEPSORT_AVAILABLE = True
except ImportError:
    DEEPSORT_AVAILABLE = False
    # Fallback a tracker semplice basato su IoU
    print("Warning: deep_sort non disponibile. Userò tracker IoU-based semplice")


class SimpleIOUTracker:
    """Tracker semplice basato su IoU (Intersection over Union)"""
    
    def __init__(self, max_age: int = 30, min_hits: int = 3, iou_threshold: float = 0.3):
        """
        Args:
            max_age: Numero massimo di frame senza match prima di rimuovere track
            min_hits: Numero minimo di match prima di considerare track valido
            iou_threshold: Soglia IoU minima per associare detection a track
        """
        self.max_age = max_age
        self.min_hits = min_hits
        self.iou_threshold = iou_threshold
        self.tracks: Dict[int, Dict[str, Any]] = {}
        self.next_id = 1
        self.frame_count = 0
    
    def update(self, detections: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        Aggiorna tracker con nuove detection
        
        Args:
            detections: Lista di detection dal detector YOLO
        
        Returns:
            Lista di detection con track_id aggiunto
        """
        self.frame_count += 1
        
        if not detections:
            # Nessuna detection, incrementa age di tutti i track
            for track_id in list(self.tracks.keys()):
                self.tracks[track_id]['age'] += 1
                if self.tracks[track_id]['age'] > self.max_age:
                    del self.tracks[track_id]
            return []
        
        # Calcola IoU tra detections e tracks esistenti
        matched, unmatched_dets, unmatched_trks = self._associate_detections_to_trackers(
            detections, list(self.tracks.values())
        )
        
        # Aggiorna matched tracks
        for det_idx, trk_idx in matched:
            track = list(self.tracks.values())[trk_idx]
            track_id = track['id']
            self.tracks[track_id].update({
                'bbox': detections[det_idx]['bbox'],
                'center': detections[det_idx]['center'],
                'class_id': detections[det_idx]['class_id'],
                'class_name': detections[det_idx]['class_name'],
                'confidence': detections[det_idx]['confidence'],
                'age': 0,
                'hits': track['hits'] + 1,
                'time_since_update': 0
            })
            detections[det_idx]['track_id'] = track_id
        
        # Crea nuovi tracks per detection non matched
        for det_idx in unmatched_dets:
            track_id = self.next_id
            self.next_id += 1
            self.tracks[track_id] = {
                'id': track_id,
                'bbox': detections[det_idx]['bbox'],
                'center': detections[det_idx]['center'],
                'class_id': detections[det_idx]['class_id'],
                'class_name': detections[det_idx]['class_name'],
                'confidence': detections[det_idx]['confidence'],
                'age': 0,
                'hits': 1,
                'time_since_update': 0
            }
            detections[det_idx]['track_id'] = track_id
        
        # Rimuovi tracks troppo vecchi o non matched
        for trk_idx in unmatched_trks:
            track_id = list(self.tracks.keys())[trk_idx]
            self.tracks[track_id]['age'] += 1
            if self.tracks[track_id]['age'] > self.max_age:
                del self.tracks[track_id]
        
        # Filtra solo tracks con hits sufficienti
        tracked_detections = [
            det for det in detections 
            if 'track_id' in det and self.tracks[det['track_id']]['hits'] >= self.min_hits
        ]
        
        return tracked_detections
    
    def _iou(self, box1: List[float], box2: List[float]) -> float:
        """Calcola IoU tra due bounding box"""
        x1_1, y1_1, x2_1, y2_1 = box1
        x1_2, y1_2, x2_2, y2_2 = box2
        
        # Area di intersezione
        xi1 = max(x1_1, x1_2)
        yi1 = max(y1_1, y1_2)
        xi2 = min(x2_1, x2_2)
        yi2 = min(y2_1, y2_2)
        
        inter_area = max(0, xi2 - xi1) * max(0, yi2 - yi1)
        
        # Area di unione
        box1_area = (x2_1 - x1_1) * (y2_1 - y1_1)
        box2_area = (x2_2 - x1_2) * (y2_2 - y1_2)
        union_area = box1_area + box2_area - inter_area
        
        return inter_area / union_area if union_area > 0 else 0.0
    
    def _associate_detections_to_trackers(
        self,
        detections: List[Dict[str, Any]],
        trackers: List[Dict[str, Any]]
    ) -> tuple:
        """Associa detection a tracker usando IoU"""
        if len(trackers) == 0:
            return [], list(range(len(detections))), []
        
        iou_matrix = np.zeros((len(detections), len(trackers)))
        
        for d, det in enumerate(detections):
            for t, trk in enumerate(trackers):
                iou_matrix[d, t] = self._iou(det['bbox'], trk['bbox'])
        
        matched_indices = []
        unmatched_dets = []
        unmatched_trks = []
        
        # Greedy matching basato su IoU
        if iou_matrix.size > 0:
            for d in range(len(detections)):
                best_t = np.argmax(iou_matrix[d, :])
                if iou_matrix[d, best_t] >= self.iou_threshold:
                    matched_indices.append((d, best_t))
                    iou_matrix[:, best_t] = -1  # Rimuovi colonna
                else:
                    unmatched_dets.append(d)
            
            unmatched_trks = [t for t in range(len(trackers)) 
                            if not any((d, t) in matched_indices for d in range(len(detections)))]
        else:
            unmatched_dets = list(range(len(detections)))
            unmatched_trks = list(range(len(trackers)))
        
        return matched_indices, unmatched_dets, unmatched_trks


class ObjectTracker:
    """Wrapper per tracker oggetti (usa DeepSORT se disponibile, altrimenti IoU tracker)"""
    
    def __init__(self):
        if DEEPSORT_AVAILABLE:
            # TODO: Implementare DeepSORT quando disponibile
            self.tracker = SimpleIOUTracker()
        else:
            self.tracker = SimpleIOUTracker()
    
    def update(self, detections: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Aggiorna tracker con nuove detection"""
        return self.tracker.update(detections)

