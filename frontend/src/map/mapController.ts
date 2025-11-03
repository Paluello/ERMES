/** Controller principale mappa Leaflet */
import L from 'leaflet';
import { MarkerManager } from './markerManager';
import { Detection, TelemetryData } from '../api/client';

export class MapController {
    private map: L.Map;
    private markerManager: MarkerManager;
    private sourceMarkers: Map<string, L.Marker> = new Map();

    constructor(containerId: string) {
        // Inizializza mappa Leaflet
        this.map = L.map(containerId).setView([41.9028, 12.4964], 13); // Default: Roma

        // Aggiungi tile layer OpenStreetMap
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© OpenStreetMap contributors',
            maxZoom: 19
        }).addTo(this.map);

        // Inizializza marker manager
        this.markerManager = new MarkerManager(this.map);
    }

    updateDetection(detection: Detection): void {
        this.markerManager.updateMarker(detection);
    }

    updateSourcePosition(telemetry: TelemetryData): void {
        const { source_id, latitude, longitude, source_type } = telemetry;

        // Icona speciale per sorgente
        const icon = L.divIcon({
            className: 'source-marker',
            html: `<div style="
                width: 16px;
                height: 16px;
                background: #10b981;
                border: 3px solid white;
                border-radius: 50%;
                box-shadow: 0 2px 6px rgba(0,0,0,0.4);
            "></div>`,
            iconSize: [16, 16],
            iconAnchor: [8, 8]
        });

        if (this.sourceMarkers.has(source_id)) {
            const marker = this.sourceMarkers.get(source_id)!;
            marker.setLatLng([latitude, longitude]);
        } else {
            const marker = L.marker([latitude, longitude], { icon })
                .addTo(this.map)
                .bindPopup(`
                    <strong>Sorgente: ${source_id}</strong><br>
                    Tipo: ${source_type}<br>
                    Altitudine: ${telemetry.altitude.toFixed(1)}m
                `);
            this.sourceMarkers.set(source_id, marker);
        }
    }

    removeSource(sourceId: string): void {
        const marker = this.sourceMarkers.get(sourceId);
        if (marker) {
            this.map.removeLayer(marker);
            this.sourceMarkers.delete(sourceId);
        }
    }

    centerOnSource(sourceId: string): void {
        const marker = this.sourceMarkers.get(sourceId);
        if (marker) {
            this.map.setView(marker.getLatLng(), 15);
        }
    }

    getMap(): L.Map {
        return this.map;
    }
}

