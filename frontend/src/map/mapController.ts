/** Controller principale mappa Leaflet */
import L from 'leaflet';
import { MarkerManager } from './markerManager';
import { Detection, TelemetryData } from '../api/client';

export class MapController {
    private map: L.Map;
    private markerManager: MarkerManager;
    private sourceMarkers: Map<string, L.Marker> = new Map();

    constructor(containerId: string) {
        const container = document.getElementById(containerId);
        if (!container) {
            throw new Error(`Container con id "${containerId}" non trovato`);
        }

        // Assicurati che il container abbia altezza visibile
        if (!container.style.height || container.style.height === '0px') {
            container.style.height = '100%';
        }

        // Inizializza mappa Leaflet - Centrata su Milano con zoom più ampio
        this.map = L.map(containerId).setView([45.4642, 9.1900], 11); // Milano centro

        // Aggiungi tile layer OpenStreetMap
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© OpenStreetMap contributors',
            maxZoom: 19
        }).addTo(this.map);

        // Invalidate size dopo un breve delay per assicurarsi che il container sia visibile
        setTimeout(() => {
            this.map.invalidateSize();
        }, 100);

        // Inizializza marker manager
        this.markerManager = new MarkerManager(this.map);
        
        console.log('MapController inizializzato correttamente');
    }

    updateDetection(detection: Detection): void {
        this.markerManager.updateMarker(detection);
    }

    updateSourcePosition(telemetry: TelemetryData): void {
        const { source_id, latitude, longitude, source_type } = telemetry;

        // Validazione coordinate
        if (!latitude || !longitude || isNaN(latitude) || isNaN(longitude)) {
            console.warn(`Coordinate non valide per sorgente ${source_id}:`, { latitude, longitude });
            return;
        }

        console.log(`Aggiornamento posizione sorgente ${source_id}:`, { latitude, longitude });

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
            console.log(`Marker esistente aggiornato per ${source_id}`);
        } else {
            const marker = L.marker([latitude, longitude], { icon })
                .addTo(this.map)
                .bindPopup(`
                    <strong>Sorgente: ${source_id}</strong><br>
                    Tipo: ${source_type}<br>
                    Altitudine: ${telemetry.altitude?.toFixed(1) || 'N/A'}m
                `);
            this.sourceMarkers.set(source_id, marker);
            console.log(`Nuovo marker creato per sorgente ${source_id}`);
            
            // Centra la mappa sulla prima sorgente aggiunta con zoom appropriato
            if (this.sourceMarkers.size === 1) {
                this.map.setView([latitude, longitude], 13);
            }
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
            this.map.setView(marker.getLatLng(), 13);
        }
    }

    getMap(): L.Map {
        return this.map;
    }
}

