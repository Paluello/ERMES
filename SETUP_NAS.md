# Setup ERMES su NAS Ugreen con Docker

## Prerequisiti

1. **NAS Ugreen con Docker installato**
   - Verifica che Docker Compose sia disponibile
   - Accedi al NAS via SSH o interfaccia web

2. **Risorse minime consigliate**
   - CPU: 2+ core (ARM o x86)
   - RAM: 2GB+ disponibile
   - Spazio: 5GB+ per immagini Docker e modelli

## Installazione Docker su NAS Ugreen

Se Docker non è già installato:

1. Accedi al NAS via SSH
2. Installa Docker (se supportato):
   ```bash
   # Su alcuni NAS Ugreen:
   opkg install docker docker-compose
   ```

   **Nota**: Alcuni NAS Ugreen hanno Docker preinstallato o disponibile tramite app store.

## Setup ERMES

### 1. Carica File sul NAS

Trasferisci la cartella `ERMES` sul NAS:
- Via SMB/CIFS (condivisione rete)
- Via SFTP/SCP
- Via interfaccia web del NAS

Esempio percorso: `/share/ERMES/` o `/volume1/ERMES/`

### 2. Configurazione per NAS

Il NAS Ugreen può essere ARM o x86. Usa la configurazione appropriata:

**Per NAS ARM (la maggior parte dei NAS):**
```bash
cd /path/to/ERMES
docker-compose -f docker-compose.nas.yml up -d
```

**Per NAS x86:**
```bash
cd /path/to/ERMES
docker-compose up -d
```

### 3. Verifica Installazione

```bash
# Controlla container in esecuzione
docker ps

# Verifica log backend
docker logs ermes-backend

# Verifica log RTMP
docker logs ermes-rtmp
```

### 4. Accesso Servizi

- **Backend API**: `http://<IP-NAS>:8000`
- **Frontend Dashboard**: `http://<IP-NAS>:3000` (se abilitato)
- **RTMP Server**: `rtmp://<IP-NAS>:1935`

Trova IP del NAS:
```bash
ip addr show
# o
hostname -I
```

## Configurazione Ottimizzata per NAS

### Modifiche Consigliate per NAS Meno Potenti

Modifica `backend/app/config.py` o variabili ambiente:

```python
# Usa modello YOLO più leggero
yolo_model = "yolov8n.pt"  # Nano (non small/medium/large)

# Riduci FPS elaborazione
video_fps = 15  # Invece di 30

# Riduci numero oggetti tracciati
max_tracked_objects = 10  # Invece di 20

# Aumenta soglia confidence per meno false positive
yolo_conf_threshold = 0.6  # Invece di 0.5
```

### Limitazioni Risorse nel docker-compose.nas.yml

Già configurato:
- CPU limitata a 1.5 core
- RAM limitata a 1.5GB
- Workers uvicorn = 1 (non multipli)

## Accesso da App iOS

Nell'app EVA, configura:
- **URL Backend**: `http://<IP-NAS>:8000`
- **RTMP URL**: Verrà generato automaticamente come `rtmp://<IP-NAS>:1935/stream/<source_id>`

**Importante**: Sostituisci `<IP-NAS>` con l'IP reale del tuo NAS.

## Firewall/Porte

Assicurati che queste porte siano aperte sul NAS:
- **8000**: Backend API
- **1935**: RTMP streaming
- **3000**: Frontend (opzionale)

Su NAS Ugreen, configurazione firewall solitamente tramite interfaccia web.

## Monitoraggio e Log

### Visualizza Log

```bash
# Log backend
docker logs -f ermes-backend

# Log RTMP
docker logs -f ermes-rtmp

# Log tutti i servizi
docker-compose logs -f
```

### Monitoraggio Risorse

```bash
# Uso CPU/RAM dei container
docker stats

# Spazio disco
df -h
```

## Troubleshooting NAS

### Problema: Container non si avvia

```bash
# Verifica log errore
docker logs ermes-backend

# Verifica spazio disco
df -h

# Verifica memoria disponibile
free -h
```

### Problema: Performance Lente

1. **Riduci risoluzione video** nell'app iOS (720p invece di 1080p)
2. **Riduci FPS** a 15 nel config
3. **Usa solo modello YOLO nano** (yolov8n.pt)
4. **Limita numero sorgenti** simultanee

### Problema: Out of Memory

Se il NAS ha poca RAM:
```yaml
# In docker-compose.nas.yml, riduci ulteriormente:
limits:
  memory: 1G  # Invece di 1.5G
```

### Problema: Architettura ARM vs x86

Se ottieni errori di architettura:
```bash
# Verifica architettura NAS
uname -m
# ARM: armv7l, aarch64
# x86: x86_64

# Se necessario, usa immagini multi-arch o build locale
docker build --platform linux/arm64 -t ermes-backend ./backend
```

## Backup e Persistenza

I dati importanti sono in volumi Docker:
- `ermes-models`: Modelli YOLO scaricati (non critico, si riscaricano)
- `rtmp-recordings`: Recording stream (opzionale)

Per backup:
```bash
# Backup volumi
docker run --rm -v ermes-models:/data -v $(pwd):/backup alpine tar czf /backup/models-backup.tar.gz /data
```

## Aggiornamento

```bash
cd /path/to/ERMES

# Ferma container
docker-compose down

# Pull nuove immagini (se aggiornate)
docker-compose pull

# Riavvia
docker-compose up -d
```

## Considerazioni Performance NAS

### Cosa Funziona Bene su NAS:
- ✅ Server RTMP (nginx-rtmp) - molto leggero
- ✅ Backend API FastAPI - leggero
- ✅ Storage e gestione file

### Cosa può essere Lento:
- ⚠️ Elaborazione YOLO - richiede CPU potente
- ⚠️ Elaborazione video multipli simultanei
- ⚠️ Elaborazione ad alta risoluzione (4K)

### Raccomandazioni:
1. **Inizia con 1 sorgente** per testare performance
2. **Usa risoluzione 720p** invece di 1080p
3. **Monitora uso CPU/RAM** con `docker stats`
4. **Considera NAS più potente** se serve elaborazione multipla

## Alternative per NAS Meno Potenti

Se il NAS è troppo lento per YOLO:
1. **Usa solo telemetria** (GPS/IMU) senza elaborazione video
2. **Elabora video su altro server** più potente
3. **Usa servizio cloud** per elaborazione YOLO (API esterna)

## Supporto

Per problemi specifici NAS Ugreen:
- Consulta documentazione NAS Ugreen
- Verifica compatibilità Docker sul tuo modello
- Considera community NAS Ugreen per supporto

