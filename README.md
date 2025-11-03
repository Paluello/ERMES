# ERMES - Sistema di Tracking e Geolocalizzazione Multi-Sorgente

Sistema modulare per rilevamento, tracciamento e geolocalizzazione in tempo reale di oggetti (auto, camionette, persone) da feed video multipli: droni, telecamere fisse e telefoni mobile.

## Architettura

Il sistema è composto da:

1. **Data Source Abstraction Layer** - Interfaccia comune per diverse sorgenti video/telemetria
2. **Drone Communication Module** - Implementazione specifica per droni MAVLink
3. **Video Processing Module** - Elaborazione video con YOLO per object detection/tracking
4. **Geolocalization Engine** - Calcolo coordinate geografiche degli oggetti rilevati
5. **Frontend Dashboard** - Visualizzazione su mappa Leaflet in tempo reale

## Requisiti

- Python 3.9+
- Node.js 18+
- pymavlink (per comunicazione drone)
- Ultralytics YOLO (per detection)
- OpenCV (per elaborazione video)

## Installazione

### Backend

```bash
cd backend
pip install -r requirements.txt
```

### Frontend

```bash
cd frontend
npm install
```

## Utilizzo

### Avvio Backend

```bash
cd backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Avvio Frontend

```bash
cd frontend
npm run dev
```

Accesso dashboard: http://localhost:3000

## Configurazione

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

