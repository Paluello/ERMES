# Guida Testing End-to-End ERMES + EVA

## Setup Completo

### 1. Backend ERMES

```bash
cd backend
pip install -r requirements.txt

# Installa ffmpeg per RTMP receiver
brew install ffmpeg  # macOS
# o
sudo apt-get install ffmpeg  # Linux

# Avvia backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 2. Server RTMP (nginx-rtmp)

```bash
# Installa nginx-rtmp
brew install nginx-full  # macOS

# Configura nginx
sudo cp backend/nginx-rtmp.conf /opt/homebrew/etc/nginx/nginx.conf  # macOS
# o
sudo cp backend/nginx-rtmp.conf /etc/nginx/nginx.conf  # Linux

# Avvia nginx
brew services start nginx-full  # macOS
# o
sudo systemctl start nginx  # Linux

# Verifica porta 1935
lsof -i :1935
```

### 3. App iOS EVA

1. Apri progetto in Xcode
2. Aggiungi HaishinKit via Swift Package Manager (già fatto)
3. Configura Info.plist con permessi (già fatto)
4. Imposta URL backend nelle impostazioni app:
   - Se backend è su Mac locale: `http://<IP-MAC>:8000`
   - Esempio: `http://192.168.1.100:8000`
5. Build e run su iPhone fisico (camera non funziona su simulatore)

## Test Step-by-Step

### Test 1: Verifica Backend API

```bash
# Test status
curl http://localhost:8000/api/status

# Risposta attesa:
# {"status":"running","version":"0.1.0",...}
```

### Test 2: Verifica Server RTMP

```bash
# Test con ffmpeg (simula app iOS)
ffmpeg -re -i test_video.mp4 -c copy -f flv rtmp://localhost:1935/stream/test123

# Se funziona, vedrai log nginx senza errori
```

### Test 3: Registrazione Sorgente Mobile (via API)

```bash
curl -X POST http://localhost:8000/api/sources/mobile/register \
  -H "Content-Type: application/json" \
  -d '{
    "source_id": "test_phone_001",
    "device_info": {
      "model": "iPhone 15 Pro",
      "os_version": "iOS 17.0"
    },
    "rtmp_url": "rtmp://localhost:1935/stream/test_phone_001"
  }'

# Risposta attesa:
# {"success":true,"source_id":"test_phone_001","message":"Sorgente registrata con successo"}
```

### Test 4: Aggiornamento Telemetria (via API)

```bash
curl -X POST http://localhost:8000/api/sources/mobile/test_phone_001/telemetry \
  -H "Content-Type: application/json" \
  -d '{
    "latitude": 41.9028,
    "longitude": 12.4964,
    "altitude": 50.0,
    "heading": 45.0,
    "pitch": -10.0,
    "roll": 2.0,
    "yaw": 45.0,
    "camera_tilt": -10.0,
    "camera_pan": 45.0
  }'

# Risposta attesa:
# {"success":true,"message":"Telemetria aggiornata"}
```

### Test 5: Verifica Sorgente Registrata

```bash
curl http://localhost:8000/api/sources

# Risposta attesa:
# {"sources":[{"source_id":"test_phone_001","source_type":"mobile_phone","is_available":true}]}
```

### Test 6: Test End-to-End con App iOS

1. **Avvia Backend**: `uvicorn app.main:app --reload --host 0.0.0.0 --port 8000`
2. **Avvia nginx-rtmp**: `brew services start nginx-full`
3. **Configura App EVA**:
   - Apri app su iPhone
   - Vai a Impostazioni
   - Imposta URL backend: `http://<IP-TUO-MAC>:8000`
   - Salva
4. **Avvia Streaming**:
   - Torna alla schermata principale
   - Tocca "Start Streaming"
   - Concedi permessi camera, location, motion
5. **Verifica**:
   - Controlla log backend: dovresti vedere registrazione sorgente
   - Controlla log nginx: dovresti vedere connessione RTMP
   - Verifica telemetria: `curl http://localhost:8000/api/telemetry/<source_id>`
   - Controlla dashboard frontend: oggetti dovrebbero apparire sulla mappa

## Checklist Debugging

### Problema: App non si connette al backend

- [ ] Backend è in esecuzione su porta 8000?
- [ ] URL backend nell'app è corretto?
- [ ] iPhone e Mac sono sulla stessa rete?
- [ ] Firewall blocca porta 8000?
- [ ] Backend è in ascolto su `0.0.0.0` (non solo `localhost`)?

### Problema: Streaming RTMP non funziona

- [ ] nginx-rtmp è in esecuzione?
- [ ] Porta 1935 è aperta?
- [ ] URL RTMP nell'app è corretto?
- [ ] ffmpeg è installato sul backend?
- [ ] Controlla log nginx: `tail -f /var/log/nginx/error.log`

### Problema: Telemetria non viene inviata

- [ ] Permessi location sono concessi?
- [ ] Permessi motion sono concessi?
- [ ] GPS è attivo sul telefono?
- [ ] Controlla log app Xcode per errori API

### Problema: Video non viene processato

- [ ] Stream RTMP è attivo? (verifica con ffmpeg/ffplay)
- [ ] Orchestratore è avviato?
- [ ] YOLO model è scaricato?
- [ ] Controlla log backend per errori processing

## Comandi Utili

### Monitorare Stream RTMP

```bash
# Usa ffplay per vedere stream
ffplay rtmp://localhost:1935/stream/<source_id>

# Verifica con rtmpdump
rtmpdump -r rtmp://localhost:1935/stream/<source_id> -o test.flv
```

### Monitorare Log Backend

```bash
# Log FastAPI
tail -f backend/logs/app.log  # se configurato

# Log Python direttamente
# Vedrai output nella console dove hai avviato uvicorn
```

### Test Locale con Video File

Puoi testare il sistema completo usando un video file invece dello stream live:

```python
# In backend, registra una StaticCameraSource con file video
from app.globals import source_manager

source_manager.register_static_camera(
    source_id="test_camera",
    latitude=41.9028,
    longitude=12.4964,
    altitude=50.0,
    video_url="file:///path/to/test_video.mp4",
    camera_tilt=-30.0
)
```

## Prossimi Passi

Dopo test riusciti:
1. Ottimizza performance (bitrate, risoluzione)
2. Implementa riconnessione automatica
3. Aggiungi background mode iOS
4. Configura produzione (HTTPS, autenticazione)

