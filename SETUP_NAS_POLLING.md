# Setup ERMES su NAS con Aggiornamento Automatico via Polling

Questa guida spiega come configurare ERMES su un NAS con aggiornamento automatico da GitHub usando polling (consigliato per VPN Tailscale).

## Panoramica

ERMES usa **polling automatico** per controllare GitHub ogni X minuti e aggiornare automaticamente il codice quando rileva nuovi commit. Questa soluzione è ideale quando:

- ✅ Usi VPN Tailscale (webhook non accessibili da internet)
- ✅ Vuoi aggiornamenti automatici senza intervento manuale
- ✅ Il NAS non è esposto pubblicamente

## Architettura Container

ERMES usa 2 container Docker:

1. **ermes-backend**: Backend FastAPI con YOLO e auto-updater
2. **ermes-rtmp**: Server RTMP per ricevere stream video

## Prerequisiti

- NAS con Docker installato
- Accesso SSH o terminale al NAS
- Repository GitHub con codice ERMES

## Setup Passo-Passo

### 1. Clona Repository sul NAS

```bash
# Connettiti al NAS via SSH o terminale
cd /volume1/docker  # o la tua directory Docker preferita
git clone https://github.com/Paluello/ERMES.git
cd ERMES
```

### 2. Configura File .env

Crea un file `.env` nella directory del progetto:

```bash
cp .env.example .env
nano .env  # o usa il tuo editor preferito
```

Configura almeno queste variabili:

```env
# Repository GitHub
GITHUB_REPO=Paluello/ERMES
GITHUB_BRANCH=main

# Abilita polling automatico
GITHUB_AUTO_UPDATE_ENABLED=true
GITHUB_AUTO_UPDATE_INTERVAL_MINUTES=5

# Se il repo è privato, aggiungi token
# GITHUB_TOKEN=ghp_tuo_token_qui
```

**Nota**: Se il tuo repository è privato, devi creare un token GitHub:
1. Vai su https://github.com/settings/tokens
2. Crea un nuovo token con permessi `repo`
3. Inseriscilo nel `.env` come `GITHUB_TOKEN`

### 3. Configura Path Directory (se necessario)

Se la directory del progetto sul NAS è diversa da quella di default, configura:

```env
# Esempio per Synology
PROJECT_DIR=/volume1/docker/ERMES
PROJECT_DIR_MOUNT=/workspace
```

Altrimenti, lascia vuoto per auto-detect.

### 4. Avvia Container

```bash
# Usa docker-compose o docker compose a seconda della versione
docker compose -f docker-compose.github.nas.yml up -d

# Oppure
docker-compose -f docker-compose.github.nas.yml up -d
```

### 5. Verifica Container

```bash
# Controlla che i container siano in esecuzione
docker ps | grep ermes

# Dovresti vedere:
# - ermes-backend
# - ermes-rtmp
```

### 6. Verifica Log Auto-Updater

```bash
# Controlla i log del backend
docker logs ermes-backend | grep -i "auto-updater"

# Dovresti vedere:
# ✅ Auto-updater avviato: polling ogni 5 minuti
```

## Come Funziona il Polling

1. **Avvio**: Quando il backend si avvia, controlla se `GITHUB_AUTO_UPDATE_ENABLED=true`
2. **Polling**: Ogni X minuti (configurato in `GITHUB_AUTO_UPDATE_INTERVAL_MINUTES`), controlla GitHub per nuovi commit
3. **Rilevamento**: Confronta l'SHA dell'ultimo commit locale con quello remoto
4. **Aggiornamento**: Se rileva un nuovo commit:
   - Esegue `git pull` nella directory montata
   - Riavvia il backend (veloce, ~5 secondi, nessun rebuild necessario)

## Log e Debugging

### Log Auto-Updater

I log dell'auto-updater sono nel backend:

```bash
# Log in tempo reale
docker logs -f ermes-backend | grep -i "polling\|commit\|aggiornamento"

# Log dello script di aggiornamento
docker exec ermes-backend cat /tmp/ermes_update.log
```

### Verifica Configurazione

```bash
# Entra nel container
docker exec -it ermes-backend bash

# Verifica variabili d'ambiente
env | grep GITHUB

# Verifica che il polling sia attivo
# Dovresti vedere un messaggio ogni X minuti nei log
```

## Configurazione Avanzata

### Cambiare Intervallo Polling

Nel file `.env`:

```env
# Controlla ogni 10 minuti invece di 5
GITHUB_AUTO_UPDATE_INTERVAL_MINUTES=10
```

Poi riavvia il backend:

```bash
docker compose -f docker-compose.github.nas.yml restart ermes-backend
```

### Disabilitare Auto-Update Temporaneamente

Nel file `.env`:

```env
GITHUB_AUTO_UPDATE_ENABLED=false
```

Poi riavvia il backend.

### Forzare Controllo Immediato

```bash
# Entra nel container
docker exec -it ermes-backend python

# Poi nel Python REPL:
from app.globals import get_auto_updater
updater = get_auto_updater()
if updater:
    import asyncio
    asyncio.run(updater.force_check())
```

## Troubleshooting

### Auto-Updater Non Si Avvia

1. **Verifica configurazione**:
   ```bash
   docker exec ermes-backend env | grep GITHUB_AUTO_UPDATE
   ```

2. **Verifica che GITHUB_REPO sia configurato**:
   ```bash
   docker exec ermes-backend env | grep GITHUB_REPO
   ```

3. **Controlla log**:
   ```bash
   docker logs ermes-backend | tail -50
   ```

### Aggiornamenti Non Funzionano

1. **Verifica connessione GitHub**:
   ```bash
   docker exec ermes-backend curl -s https://api.github.com/repos/Paluello/ERMES/commits/main | head -20
   ```

2. **Verifica permessi directory**:
   ```bash
   docker exec ermes-backend ls -la /workspace/.git
   ```

3. **Controlla log script**:
   ```bash
   docker exec ermes-backend cat /tmp/ermes_update.log
   ```

### Container Non Si Riavvia Dopo Aggiornamento

1. **Verifica socket Docker**:
   ```bash
   docker exec ermes-backend ls -la /var/run/docker.sock
   ```

2. **Verifica docker-compose nel container**:
   ```bash
   docker exec ermes-backend docker compose version
   ```

## Differenza tra Polling e Webhook

| Caratteristica | Polling (Usato) | Webhook (Non Usato) |
|----------------|-----------------|---------------------|
| **Accesso Internet** | Non necessario | Richiesto endpoint pubblico |
| **VPN Tailscale** | ✅ Funziona perfettamente | ❌ Non accessibile |
| **Frequenza** | Controlla ogni X minuti | Istantaneo al push |
| **Configurazione** | Semplicissima | Richiede setup webhook GitHub |
| **Sicurezza** | Solo lettura GitHub | Richiede endpoint pubblico |

## File Chiave

- `docker-compose.github.nas.yml`: Configurazione Docker Compose principale
- `.env`: Configurazione variabili d'ambiente
- `backend/update_container.sh`: Script di aggiornamento eseguito dal polling
- `backend/app/auto_updater.py`: Logica polling automatico
- `backend/app/main.py`: Avvia auto-updater all'avvio

## Prossimi Passi

Dopo il setup iniziale:

1. ✅ Fai un push su GitHub per testare l'aggiornamento automatico
2. ✅ Monitora i log per verificare che il polling funzioni
3. ✅ Configura altre variabili nel `.env` secondo le tue esigenze

## Supporto

Per problemi o domande:
- Controlla i log: `docker logs ermes-backend`
- Verifica configurazione: `docker exec ermes-backend env | grep GITHUB`
- Consulta troubleshooting sopra

