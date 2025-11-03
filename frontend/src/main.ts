/** Entry point applicazione frontend */
import { MapController } from './map/mapController';
import { APIClient, WebSocketClient, Detection, TelemetryData, Source } from './api/client';

// Inizializza mappa
const mapController = new MapController('map');

// Inizializza WebSocket client
const wsClient = new WebSocketClient();

// Gestione stato connessione
const statusDot = document.querySelector('.status-dot') as HTMLElement;
const statusText = document.getElementById('status-text') as HTMLElement;

wsClient.setConnectionChangeCallback((connected: boolean) => {
    if (connected) {
        statusDot.classList.add('connected');
        statusText.textContent = 'Connesso';
    } else {
        statusDot.classList.remove('connected');
        statusText.textContent = 'Disconnesso';
    }
});

// Handler detection
wsClient.onDetection((detection: Detection) => {
    mapController.updateDetection(detection);
    updateTrackedObjectsList();
});

// Handler telemetria
wsClient.onTelemetry((telemetry: TelemetryData) => {
    mapController.updateSourcePosition(telemetry);
    updateSourcesList();
});

// Aggiorna lista sorgenti
async function updateSourcesList(): Promise<void> {
    try {
        const sources = await APIClient.getSources();
        const sourcesList = document.getElementById('sources-list');
        if (sourcesList) {
            sourcesList.innerHTML = sources.map((source: Source) => `
                <div class="source-item ${source.is_available ? 'active' : ''}">
                    <strong>${source.source_id}</strong><br>
                    <small>${source.source_type}</small>
                </div>
            `).join('');
        }
    } catch (e) {
        console.error('Errore caricamento sorgenti:', e);
    }
}

// Aggiorna lista oggetti tracciati (semplificato)
function updateTrackedObjectsList(): void {
    // TODO: Implementare lista completa oggetti tracciati
    // Per ora placeholder
    const objectsList = document.getElementById('tracked-objects');
    if (objectsList) {
        objectsList.innerHTML = '<p style="color: #6b7280; font-size: 0.875rem;">Oggetti visualizzati sulla mappa</p>';
    }
}

// Connessione iniziale
wsClient.connect();

// Carica sorgenti iniziali
updateSourcesList();

// Aggiorna ogni 5 secondi
setInterval(updateSourcesList, 5000);

