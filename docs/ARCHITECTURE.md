# Architettura ERMES

## Panoramica

ERMES è un sistema modulare per rilevamento, tracciamento e geolocalizzazione in tempo reale di oggetti (auto, camionette, persone) da feed video multipli. Il sistema supporta tre tipi di sorgenti:

1. **Droni** - Via protocollo MAVLink (ArduPilot/PX4)
2. **Telecamere Fisse** - Stream RTSP/HTTP con posizione statica nota
3. **Telefoni Mobile** - Stream video con metadata GPS/IMU

## Architettura Modulare

### 1. Data Source Abstraction Layer

Il sistema usa un pattern di astrazione per supportare diverse sorgenti video. Tutte le sorgenti implementano l'interfaccia `VideoSource`:

```python
class VideoSource(ABC):
    def connect() -> bool
    def disconnect()
    def get_video_stream()
    def get_latest_telemetry() -> TelemetryData
    def is_available() -> bool
```

**Implementazioni:**
- `DroneSource` - Connessione MAVLink, telemetria GPS/orientamento dinamica
- `StaticCameraSource` - Posizione fissa, telemetria statica
- `MobilePhoneSource` - Telemetria aggiornata dinamicamente via API

**Vantaggi:**
- Facile aggiungere nuove sorgenti (es. satelliti, CCTV)
- Codice di elaborazione video identico per tutte le sorgenti
- Testing semplice con mock sources

### 2. Video Processing Module

**Componenti:**

- **YOLODetector** - Wrapper Ultralytics YOLOv8
  - Detection classi: person, car, truck, bus, motorcycle
  - Output: bounding boxes + confidence scores

- **ObjectTracker** - Tracker basato su IoU (con supporto futuro DeepSORT)
  - Mantiene ID consistenti tra frame
  - Gestisce apparizioni/scomparse oggetti

- **VideoProcessor** - Gestione stream video
  - Acquisizione frame da sorgente
  - Elaborazione asincrona per non bloccare
  - Callback per detection

### 3. Geolocalization Engine

**Componenti:**

- **CameraCalibration** - Parametri camera
  - FOV orizzontale/verticale
  - Risoluzione
  - Lunghezza focale (calcolata o fornita)

- **GeolocationEngine** - Calcolo coordinate geografiche
  - Modello pinhole camera
  - Proiezione pixel → coordinate terreno
  - Considera: posizione sorgente, orientamento, altezza
  - Supporto upgrade futuro RTK

**Formule Chiave:**
```
Angolo relativo camera: θ = atan((pixel - center) / focal_length)
Distanza terreno: d = height / tan(elevation)
Offset lat/lon: Δlat = d * cos(azimuth) / R_earth
```

### 4. API Layer

**REST Endpoints:**
- `GET /api/status` - Stato sistema
- `GET /api/sources` - Lista sorgenti registrate
- `GET /api/telemetry/{source_id}` - Telemetria sorgente

**WebSocket:**
- `/ws` - Stream real-time detection + telemetria
- Messaggi formato JSON:
  ```json
  {
    "type": "detection",
    "payload": {
      "track_id": 1,
      "class_name": "car",
      "latitude": 41.9028,
      "longitude": 12.4964,
      "confidence": 0.95,
      "accuracy_meters": 5.2
    }
  }
  ```

### 5. Frontend Dashboard

**Tecnologie:**
- TypeScript + Vite
- Leaflet per mappe
- WebSocket client per aggiornamenti real-time

**Componenti:**
- `MapController` - Gestione mappa Leaflet
- `MarkerManager` - Marker oggetti tracciati
- `APIClient` - Comunicazione REST
- `WebSocketClient` - Stream real-time

## Flusso di Dati

```
1. Sorgente Video
   ↓
2. VideoProcessor (frame acquisition)
   ↓
3. YOLODetector (object detection)
   ↓
4. ObjectTracker (tracking ID)
   ↓
5. GeolocationEngine (pixel → lat/lon)
   ↓
6. Orchestrator (queue → async processing)
   ↓
7. WebSocket Broadcast
   ↓
8. Frontend (visualizzazione mappa)
```

## Orchestratore

Il `TrackingOrchestrator` coordina tutti i moduli:

- Gestisce multiple sorgenti simultanee
- Coda thread-safe per detection (bridge sync → async)
- Loop asincroni per:
  - Broadcast telemetria (1 Hz)
  - Processamento detection queue
- Lifecycle management (start/stop)

## Estendibilità

### Aggiungere Nuova Sorgente

1. Creare classe che estende `VideoSource`
2. Implementare metodi astratti
3. Registrare via `SourceManager.register_*()`

### Upgrade RTK GPS

1. Modificare `Settings.gps_precision` a `RTK`
2. Aggiornare `MAVLinkClient` per leggere dati RTK
3. `GeolocationEngine` usa automaticamente precisione RTK

### Nuovo Tracker

1. Implementare interfaccia tracker (metodo `update()`)
2. Sostituire in `ObjectTracker.__init__()`

## Configurazione

File: `backend/app/config.py`

- GPS precision (standard/RTK)
- Modello YOLO (nano/small/medium/large)
- Soglie detection (confidence, IoU)
- Parametri camera (FOV, risoluzione)
- Performance (max objects, target latency)

## Limitazioni Attuali

1. **Stream Video**: Placeholder in `get_video_stream()` - da implementare con OpenCV
2. **Calibrazione Camera**: Default generici - calibrazione precisa migliora accuracy
3. **Terreno**: Assumiamo terreno piano - DTM migliorerebbe precisione
4. **Tracker**: IoU-based semplice - DeepSORT migliorerebbe performance

## Prossimi Passi

1. Implementare acquisizione stream video reale (OpenCV)
2. Tool calibrazione camera interattivo
3. Supporto DTM (Digital Terrain Model)
4. Integrazione DeepSORT per tracking avanzato
5. Dashboard admin per gestione sorgenti
6. Database per storico tracking
7. API per registrazione/rimozione sorgenti dinamica

