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

# Controlla se il codice è montato come volume (può essere aggiornato senza rebuild)
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
    
    # Il codice Python è montato come volume, quindi è già aggiornato
    # Basta riavviare il container (non serve rebuild)
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


