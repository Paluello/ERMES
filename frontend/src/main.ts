/** Entry point applicazione frontend */
import { MapController } from './map/mapController';
import { APIClient, WebSocketClient, Detection, TelemetryData, Source } from './api/client';

// Inizializza mappa dopo che il DOM è pronto
let mapController: MapController;

function initMap() {
    const mapElement = document.getElementById('map');
    if (!mapElement) {
        console.error('Elemento mappa non trovato!');
        return;
    }
    
    console.log('Inizializzazione mappa...');
    mapController = new MapController('map');
    console.log('Mappa inizializzata');
}

// Inizializza quando il DOM è pronto
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initMap);
} else {
    initMap();
}

// Aggiungi marker di test dopo che la mappa è inizializzata (per debug)
// Questo marker verde dovrebbe apparire su Milano centro per verificare che la visualizzazione funzioni
setTimeout(() => {
    if (mapController) {
        console.log('Aggiungo marker di test verde su Milano centro...');
        // Marker di test su Milano centro
        const testTelemetry: TelemetryData = {
            source_id: 'test_marker',
            source_type: 'test',
            timestamp: new Date().toISOString(),
            latitude: 45.4642,
            longitude: 9.1900,
            altitude: 0
        };
        mapController.updateSourcePosition(testTelemetry);
        console.log('✅ Marker di test verde aggiunto su Milano centro - se lo vedi, la visualizzazione funziona!');
    } else {
        console.warn('Mappa non ancora inizializzata, marker di test non aggiunto');
    }
}, 1000);

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
    console.log('Detection ricevuta:', detection);
    if (mapController) {
        mapController.updateDetection(detection);
        updateTrackedObjectsList();
    }
});

// Handler telemetria
wsClient.onTelemetry((telemetry: TelemetryData) => {
    console.log('Telemetria ricevuta:', telemetry);
    if (mapController) {
        mapController.updateSourcePosition(telemetry);
        updateSourcesList();
    } else {
        console.warn('Mappa non ancora inizializzata, telemetria ignorata');
    }
});

// Aggiorna lista sorgenti e mostra sulla mappa
async function updateSourcesList(): Promise<void> {
    try {
        const sources = await APIClient.getSources();
        console.log('Sorgenti ricevute:', sources);
        
        const sourcesList = document.getElementById('sources-list');
        if (sourcesList) {
            if (sources.length === 0) {
                sourcesList.innerHTML = '<p style="color: #6b7280; font-size: 0.875rem;">Nessuna sorgente registrata</p>';
            } else {
                sourcesList.innerHTML = sources.map((source: Source) => `
                    <div class="source-item ${source.is_available ? 'active' : ''}">
                        <strong>${source.source_id}</strong><br>
                        <small>${source.source_type}</small>
                    </div>
                `).join('');
                
                // Prova a recuperare la telemetria per ogni sorgente e mostrarla sulla mappa
                if (mapController) {
                    for (const source of sources) {
                        try {
                            const telemetry = await APIClient.getTelemetry(source.source_id);
                            console.log(`Telemetria recuperata per ${source.source_id}:`, telemetry);
                            if (telemetry && telemetry.latitude && telemetry.longitude) {
                                mapController.updateSourcePosition(telemetry);
                            }
                        } catch (e) {
                            // La sorgente non ha ancora telemetria, va bene
                            console.log(`Sorgente ${source.source_id} non ha ancora telemetria disponibile`);
                        }
                    }
                }
            }
        }
    } catch (e) {
        console.error('Errore caricamento sorgenti:', e);
        const sourcesList = document.getElementById('sources-list');
        if (sourcesList) {
            sourcesList.innerHTML = '<p style="color: #ef4444; font-size: 0.875rem;">Errore nel caricamento sorgenti</p>';
        }
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

