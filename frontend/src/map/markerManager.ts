/** Gestione marker oggetti tracciati sulla mappa */
import L from 'leaflet';
import { Detection } from '../api/client';

export class MarkerManager {
    private map: L.Map;
    private markers: Map<number, L.Marker> = new Map();
    private markerColors: Map<string, string> = new Map([
        ['person', '#ef4444'],
        ['face', '#ec4899'],  // Rosa per volti rilevati
        ['car', '#fbbf24'],
        ['truck', '#3b82f6'],
        ['bus', '#6366f1'],
        ['motorcycle', '#f59e0b']
    ]);

    constructor(map: L.Map) {
        this.map = map;
    }

    updateMarker(detection: Detection): void {
        const { track_id, latitude, longitude, class_name, confidence } = detection;

        // Icona colorata basata su tipo oggetto
        const color = this.markerColors.get(class_name) || '#6b7280';
        const icon = L.divIcon({
            className: 'custom-marker',
            html: `<div style="
                width: 12px;
                height: 12px;
                background: ${color};
                border: 2px solid white;
                border-radius: 50%;
                box-shadow: 0 2px 4px rgba(0,0,0,0.3);
            "></div>`,
            iconSize: [12, 12],
            iconAnchor: [6, 6]
        });

        // Crea o aggiorna marker
        if (this.markers.has(track_id)) {
            const marker = this.markers.get(track_id)!;
            marker.setLatLng([latitude, longitude]);
            marker.setIcon(icon);
            
            // Aggiorna popup
            marker.bindPopup(`
                <strong>${class_name}</strong><br>
                Track ID: ${track_id}<br>
                Confidence: ${(confidence * 100).toFixed(1)}%<br>
                Accuracy: ${detection.accuracy_meters?.toFixed(1) || 'N/A'}m
            `);
        } else {
            const marker = L.marker([latitude, longitude], { icon })
                .addTo(this.map)
                .bindPopup(`
                    <strong>${class_name}</strong><br>
                    Track ID: ${track_id}<br>
                    Confidence: ${(confidence * 100).toFixed(1)}%<br>
                    Accuracy: ${detection.accuracy_meters?.toFixed(1) || 'N/A'}m
                `);
            
            this.markers.set(track_id, marker);
        }
    }

    removeMarker(trackId: number): void {
        const marker = this.markers.get(trackId);
        if (marker) {
            this.map.removeLayer(marker);
            this.markers.delete(trackId);
        }
    }

    clearAll(): void {
        this.markers.forEach(marker => this.map.removeLayer(marker));
        this.markers.clear();
    }

    getAllMarkers(): Detection[] {
        // Utility per ottenere tutte le detection attuali
        const detections: Detection[] = [];
        this.markers.forEach((marker, trackId) => {
            const latlng = marker.getLatLng();
            // Nota: informazioni complete detection non sono salvate qui
            // Questo è solo per esempio
        });
        return detections;
    }
}

