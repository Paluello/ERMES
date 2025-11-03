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

# Rebuild backend
log "Rebuild backend con ultimo codice da GitHub..."
if command -v docker-compose &> /dev/null; then
    docker-compose -f "$COMPOSE_FILE" build --no-cache ermes-backend >> "$LOG_FILE" 2>&1 || {
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
    docker compose -f "$COMPOSE_FILE" build --no-cache ermes-backend >> "$LOG_FILE" 2>&1 || {
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

log "✅ Aggiornamento completato con successo!"

