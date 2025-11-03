# ERMES - Sistema di Tracking e Geolocalizzazione Multi-Sorgente

Sistema modulare per rilevamento, tracciamento e geolocalizzazione in tempo reale di oggetti (auto, camionette, persone) da feed video multipli: droni, telecamere fisse e telefoni mobile.

## Architettura

Il sistema è composto da:

1. **Data Source Abstraction Layer** - Interfaccia comune per diverse sorgenti video/telemetria
2. **Drone Communication Module** - Implementazione specifica per droni MAVLink
3. **Video Processing Module** - Elaborazione video con YOLO per object detection/tracking
4. **Geolocalization Engine** - Calcolo coordinate geografiche degli oggetti rilevati
5. **Frontend Dashboard** - Visualizzazione su mappa Leaflet in tempo reale

### Architettura Container Docker

ERMES può essere eseguito su NAS o server locale usando Docker Compose:

- **ermes-backend**: Container principale con FastAPI, YOLO e auto-updater
- **ermes-rtmp**: Server RTMP per ricevere stream video

Per setup NAS con aggiornamento automatico via polling, vedi: [SETUP_NAS_POLLING.md](SETUP_NAS_POLLING.md)

## Requisiti

- Python 3.9+
- Node.js 18+
- pymavlink (per comunicazione drone)
- Ultralytics YOLO (per detection)
- OpenCV (per elaborazione video)

## Installazione

### Opzione 1: Docker Compose (Consigliato per NAS)

```bash
# Clona repository
git clone https://github.com/Paluello/ERMES.git
cd ERMES

# Configura .env
cp .env.example .env
# Modifica .env con le tue configurazioni

# Avvia container
docker compose -f docker-compose.github.nas.yml up -d
```

Per setup completo su NAS, vedi: [SETUP_NAS_POLLING.md](SETUP_NAS_POLLING.md)

### Opzione 2: Installazione Locale

#### Backend

```bash
cd backend
pip install -r requirements.txt
```

#### Frontend

```bash
cd frontend
npm install
```

## Utilizzo

### Con Docker Compose

```bash
# Avvia tutti i servizi
docker compose -f docker-compose.github.nas.yml up -d

# Visualizza log
docker compose -f docker-compose.github.nas.yml logs -f

# Ferma servizi
docker compose -f docker-compose.github.nas.yml down
```

Accesso:
- Backend API: http://localhost:8000
- API Docs: http://localhost:8000/docs
- RTMP Server: rtmp://localhost:1935

### Installazione Locale

#### Avvio Backend

```bash
cd backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

#### Avvio Frontend

```bash
cd frontend
npm run dev
```

Accesso dashboard: http://localhost:3000

## Configurazione

### Con Docker Compose

Configura le variabili nel file `.env` (vedi `.env.example`):

```env
# GitHub (per aggiornamento automatico)
GITHUB_REPO=Paluello/ERMES
GITHUB_AUTO_UPDATE_ENABLED=true
GITHUB_AUTO_UPDATE_INTERVAL_MINUTES=5

# Configurazione applicazione
GPS_PRECISION=standard
YOLO_MODEL=yolov8n.pt
YOLO_CONF_THRESHOLD=0.6
```

### Installazione Locale

Modifica `backend/app/config.py` per configurare:
- Precisione GPS (standard o RTK)
- Modello YOLO
- Soglie detection
- Parametri camera

## Sorgenti Supportate

- **Droni**: Connessione MAVLink (ArduPilot/PX4)
- **Telecamere Fisse**: Stream RTSP/HTTP con posizione statica nota
- **Telefoni Mobile**: Stream video con metadata GPS/IMU

## Documentazione API

API docs disponibili su: http://localhost:8000/docs

## Licenza

Open Source

