#!/bin/bash
# Script semplificato per aggiornare ERMES via webhook GitHub
# Usa git direttamente nel container per aggiornare solo i file modificati

set -e

LOG_FILE="/tmp/ermes_update.log"
COMPOSE_FILE="docker-compose.github.nas.yml"

# Trova il path corretto - prova diversi possibili path
# Ordine di priorità basato su ciò che è realmente montato
if [ -d "/app" ] && [ -f "/app/backend/app/main.py" ]; then
    # Path standard montato dal docker-compose
    COMPOSE_DIR="/app"
elif [ -d "/volume1/docker/ERMES" ]; then
    COMPOSE_DIR="/volume1/docker/ERMES"
elif [ -d "/workspace" ]; then
    COMPOSE_DIR="/workspace"
else
    # Prova a trovare la directory usando pwd
    COMPOSE_DIR=$(pwd)
fi

BACKEND_DIR="$COMPOSE_DIR/backend/app"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "🚀 Webhook: Inizio aggiornamento..."

# Verifica docker compose
if command -v docker &> /dev/null && docker compose version &> /dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
else
    log "❌ ERRORE: docker compose non trovato"
    exit 1
fi

# Verifica socket Docker
if [ ! -S /var/run/docker.sock ]; then
    log "❌ ERRORE: Socket Docker non montato"
    exit 1
fi

# Log del path trovato
log "📁 Directory progetto: $COMPOSE_DIR"

# Vai nella directory
cd "$COMPOSE_DIR" || {
    log "❌ ERRORE: Directory $COMPOSE_DIR non trovata"
    log "Directory corrente: $(pwd)"
    log "Contenuto root: $(ls -la / | head -20)"
    exit 1
}

# Leggi configurazione GitHub
GITHUB_REPO="${GITHUB_REPO:-Paluello/ERMES}"
GITHUB_BRANCH="${GITHUB_BRANCH:-main}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

log "📥 Aggiorno codice da GitHub: $GITHUB_REPO (branch: $GITHUB_BRANCH)"

# Usa git dal container Docker (git è già installato nel Dockerfile)
# Lo script viene eseguito nel container, quindi git è disponibile

# Se la directory è già un repository git, fai pull
if [ -d "$COMPOSE_DIR/.git" ]; then
    log "📦 Repository git trovata - aggiorno solo i file modificati..."
    cd "$COMPOSE_DIR" || exit 1
    
    # Configura git se necessario
    git config --global --add safe.directory "$COMPOSE_DIR" 2>/dev/null || true
    
    # Fetch e pull solo i file modificati
    git fetch origin "$GITHUB_BRANCH" >> "$LOG_FILE" 2>&1 || {
        log "⚠️ ATTENZIONE: git fetch fallito, continuo comunque..."
    }
    
    git pull origin "$GITHUB_BRANCH" >> "$LOG_FILE" 2>&1 || {
        log "⚠️ ATTENZIONE: git pull fallito, continuo comunque..."
    }
    
    log "✅ Codice aggiornato via git pull (solo file modificati)"
else
    # Non è un repository git - inizializza e clona solo backend/app
    log "📦 Inizializzo repository git (prima volta)..."
    cd "$COMPOSE_DIR" || exit 1
    
    # Inizializza git se non esiste
    if [ ! -d ".git" ]; then
        git init >> "$LOG_FILE" 2>&1
        git remote add origin "https://github.com/${GITHUB_REPO}.git" >> "$LOG_FILE" 2>&1 || {
            # Se il remote esiste già, aggiornalo
            git remote set-url origin "https://github.com/${GITHUB_REPO}.git" >> "$LOG_FILE" 2>&1 || true
        }
        git config --global --add safe.directory "$COMPOSE_DIR" 2>/dev/null || true
    fi
    
    # Fetch solo il branch che ci interessa
    git fetch origin "$GITHUB_BRANCH" >> "$LOG_FILE" 2>&1 || {
        log "❌ ERRORE: git fetch fallito"
        exit 1
    }
    
    # Checkout solo backend/app senza modificare altri file
    git checkout -f "origin/${GITHUB_BRANCH}" -- backend/app >> "$LOG_FILE" 2>&1 || {
        log "❌ ERRORE: git checkout fallito"
        exit 1
    }
    
    log "✅ Codice aggiornato via git checkout (solo backend/app)"
fi

# Riavvia backend
log "🔄 Riavvio backend..."
$DOCKER_COMPOSE_CMD -f "$COMPOSE_FILE" restart ermes-backend >> "$LOG_FILE" 2>&1 || {
    log "❌ ERRORE durante il riavvio"
    exit 1
}

log "✅ Aggiornamento completato! (veloce, ~5 secondi, solo file modificati)"
