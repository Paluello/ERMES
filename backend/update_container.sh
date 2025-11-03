#!/bin/bash
# Script per aggiornare il container ERMES quando viene chiamato dal webhook GitHub
# Questo script viene eseguito DENTRO il container e comunica con Docker sul host

set -e

LOG_FILE="/tmp/ermes_update.log"
COMPOSE_FILE="docker-compose.github.nas.yml"
COMPOSE_DIR="/volume1/docker/ERMES"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Webhook: Inizio aggiornamento..."

# Verifica che docker sia disponibile
if ! command -v docker &> /dev/null; then
    log "ERRORE: Docker non trovato nel container"
    exit 1
fi

# Verifica che il socket Docker sia montato
if [ ! -S /var/run/docker.sock ]; then
    log "ERRORE: Socket Docker non montato (/var/run/docker.sock)"
    log "Suggerimento: Aggiungi -v /var/run/docker.sock:/var/run/docker.sock nel docker-compose.yml"
    exit 1
fi

# Vai nella directory del progetto
if [ ! -d "$COMPOSE_DIR" ]; then
    log "ERRORE: Directory $COMPOSE_DIR non trovata"
    exit 1
fi

cd "$COMPOSE_DIR" || {
    log "ERRORE: Impossibile entrare in $COMPOSE_DIR"
    exit 1
}

# Il codice Python è montato come volume (./backend/app:/app/backend/app)
# Quindi possiamo fare restart veloce senza rebuild!

# Verifica se il codice Python è montato come volume
if [ -d "/app/backend/app" ]; then
    log "Codice Python montato come volume - aggiornamento veloce possibile!"
    
    # Prova ad aggiornare il codice nella directory montata sul NAS
    # La directory montata è /volume1/docker/ERMES/backend/app -> /app/backend/app
    BACKEND_DIR="/volume1/docker/ERMES/backend"
    
    # Prova ad aggiornare il codice: prima controlla se è un repository git
    if [ -d "$COMPOSE_DIR/.git" ]; then
        log "Trovato repository git - eseguo git pull per aggiornare il codice..."
        cd "$COMPOSE_DIR" || exit 1
        
        # Configura git se necessario
        git config --global --add safe.directory "$COMPOSE_DIR" 2>/dev/null || true
        
        # Pull ultimo codice
        git pull origin main >> "$LOG_FILE" 2>&1 || git pull origin master >> "$LOG_FILE" 2>&1 || {
            log "ATTENZIONE: git pull fallito, continuo comunque con restart..."
        }
        
        log "Codice aggiornato via git pull"
    else
        # Non è un repository git - prova a fare git clone direttamente da GitHub
        log "Directory non è un repository git - provo a fare git clone da GitHub..."
        
        # Leggi GITHUB_REPO e GITHUB_TOKEN dalle variabili d'ambiente o dal .env
        GITHUB_REPO="${GITHUB_REPO:-Paluello/ERMES}"
        GITHUB_BRANCH="${GITHUB_BRANCH:-main}"
        GITHUB_TOKEN="${GITHUB_TOKEN:-}"
        
        cd "$COMPOSE_DIR" || exit 1
        
        # Salva i file esistenti (docker-compose, .env, etc)
        log "Salvo file esistenti..."
        mkdir -p /tmp/ermes_backup
        cp -f docker-compose*.yml .env* /tmp/ermes_backup/ 2>/dev/null || true
        
        # Clone da GitHub
        if [ -n "$GITHUB_TOKEN" ]; then
            log "Clone da GitHub con token..."
            git clone --depth 1 --branch "$GITHUB_BRANCH" \
                "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPO}.git" \
                /tmp/ermes_temp >> "$LOG_FILE" 2>&1 || {
                log "ERRORE: git clone fallito!"
                exit 1
            }
        else
            log "Clone da GitHub senza token..."
            git clone --depth 1 --branch "$GITHUB_BRANCH" \
                "https://github.com/${GITHUB_REPO}.git" \
                /tmp/ermes_temp >> "$LOG_FILE" 2>&1 || {
                log "ERRORE: git clone fallito!"
                exit 1
            }
        fi
        
        # Copia solo il codice backend/app nella directory montata
        log "Copio nuovo codice nella directory montata..."
        cp -r /tmp/ermes_temp/backend/app/* "$BACKEND_DIR/app/" 2>/dev/null || {
            log "ERRORE: copia codice fallita!"
            rm -rf /tmp/ermes_temp
            exit 1
        }
        
        # Ripristina file esistenti
        cp -f /tmp/ermes_backup/* "$COMPOSE_DIR/" 2>/dev/null || true
        
        # Pulisci
        rm -rf /tmp/ermes_temp /tmp/ermes_backup
        
        log "Codice aggiornato via git clone"
    fi
    
    # Riavvia solo il backend (il codice è già montato come volume, quindi basta restart)
    log "Riavvio backend con nuovo codice (nessun rebuild necessario)..."
    if command -v docker-compose &> /dev/null; then
        docker-compose -f "$COMPOSE_FILE" restart ermes-backend >> "$LOG_FILE" 2>&1 || {
            log "ERRORE durante il riavvio!"
            exit 1
        }
    elif command -v docker &> /dev/null && docker compose version &> /dev/null 2>&1; then
        docker compose -f "$COMPOSE_FILE" restart ermes-backend >> "$LOG_FILE" 2>&1 || {
            log "ERRORE durante il riavvio!"
            exit 1
        }
    else
        log "ERRORE: docker-compose non trovato!"
        exit 1
    fi
    
    log "✅ Aggiornamento veloce completato (solo restart ~5 secondi, nessun rebuild)"
    exit 0
fi

# Fallback: rebuild completo se il volume non è montato correttamente
if [ -d "$COMPOSE_DIR/.git" ]; then
    log "Trovato repository git montato - aggiornamento veloce senza rebuild..."
    
    # Pull ultimo codice dalla directory montata
    cd "$COMPOSE_DIR" || exit 1
    
    # Configura git se necessario (per evitare errori)
    git config --global --add safe.directory "$COMPOSE_DIR" 2>/dev/null || true
    
    # Pull ultimo codice
    log "Eseguo git pull..."
    git pull origin main >> "$LOG_FILE" 2>&1 || git pull origin master >> "$LOG_FILE" 2>&1 || {
        log "ATTENZIONE: git pull fallito, continuo comunque..."
    }
    
    # Riavvia solo il backend (il codice è già aggiornato via volume)
    log "Riavvio backend con nuovo codice (nessun rebuild necessario)..."
    if command -v docker-compose &> /dev/null; then
        docker-compose -f "$COMPOSE_FILE" restart ermes-backend >> "$LOG_FILE" 2>&1 || {
            log "ERRORE durante il riavvio!"
            exit 1
        }
    elif command -v docker &> /dev/null && docker compose version &> /dev/null 2>&1; then
        docker compose -f "$COMPOSE_FILE" restart ermes-backend >> "$LOG_FILE" 2>&1 || {
            log "ERRORE durante il riavvio!"
            exit 1
        }
    else
        log "ERRORE: docker-compose non trovato!"
        exit 1
    fi
    
    log "✅ Aggiornamento veloce completato (solo restart ~5 secondi, nessun rebuild)"
else
    log "Repository git non montato - rebuild completo necessario..."
    
    # Rebuild backend (usa cache quando possibile, evita --no-cache)
    log "Rebuild backend con ultimo codice da GitHub..."
    if command -v docker-compose &> /dev/null; then
        docker-compose -f "$COMPOSE_FILE" build ermes-backend >> "$LOG_FILE" 2>&1 || {
            log "ERRORE durante il build!"
            exit 1
        }
        
        # Riavvio backend
        log "Riavvio backend..."
        docker-compose -f "$COMPOSE_FILE" restart ermes-backend >> "$LOG_FILE" 2>&1 || {
            log "ERRORE durante il riavvio!"
            exit 1
        }
    elif command -v docker &> /dev/null && docker compose version &> /dev/null 2>&1; then
        docker compose -f "$COMPOSE_FILE" build ermes-backend >> "$LOG_FILE" 2>&1 || {
            log "ERRORE durante il build!"
            exit 1
        }
        
        # Riavvio backend
        log "Riavvio backend..."
        docker compose -f "$COMPOSE_FILE" restart ermes-backend >> "$LOG_FILE" 2>&1 || {
            log "ERRORE durante il riavvio!"
            exit 1
        }
    else
        log "ERRORE: docker-compose non trovato!"
        exit 1
    fi
    
    log "✅ Aggiornamento completato (rebuild completo)"
fi


