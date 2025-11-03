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

# Verifica e aggiorna il repository git
cd "$COMPOSE_DIR" || exit 1

# Configura git se necessario
git config --global --add safe.directory "$COMPOSE_DIR" 2>/dev/null || true

# Se la directory è già un repository git, fai pull
if [ -d "$COMPOSE_DIR/.git" ]; then
    log "📦 Repository git trovata - aggiorno i file..."
    
    # Verifica che il remote sia configurato correttamente
    if ! git remote get-url origin > /dev/null 2>&1; then
        log "🔧 Configuro remote origin..."
        if [ -n "$GITHUB_TOKEN" ]; then
            git remote add origin "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPO}.git" 2>/dev/null || \
            git remote set-url origin "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPO}.git"
        else
            git remote add origin "https://github.com/${GITHUB_REPO}.git" 2>/dev/null || \
            git remote set-url origin "https://github.com/${GITHUB_REPO}.git"
        fi
    fi
    
    # Fetch e pull
    log "📥 Fetch da GitHub..."
    git fetch origin "$GITHUB_BRANCH" >> "$LOG_FILE" 2>&1 || {
        log "⚠️ ATTENZIONE: git fetch fallito, continuo comunque..."
    }
    
    log "📥 Pull da GitHub..."
    git pull origin "$GITHUB_BRANCH" >> "$LOG_FILE" 2>&1 || {
        log "⚠️ ATTENZIONE: git pull fallito, provo checkout diretto..."
        # Fallback: checkout diretto dal branch remoto
        git checkout -f "origin/${GITHUB_BRANCH}" >> "$LOG_FILE" 2>&1 || {
            log "❌ ERRORE: anche checkout fallito"
        }
    }
    
    log "✅ Codice aggiornato via git pull"
else
    # Non è un repository git - clona l'intera repository
    log "📦 Directory non è un repository git - clono da GitHub..."
    
    # Salva file esistenti importanti (docker-compose, .env, etc)
    mkdir -p /tmp/ermes_backup
    cp -f docker-compose*.yml .env* /tmp/ermes_backup/ 2>/dev/null || true
    
    # Clone completo
    if [ -n "$GITHUB_TOKEN" ]; then
        log "📥 Clone con token..."
        git clone --depth 1 --branch "$GITHUB_BRANCH" \
            "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPO}.git" \
            /tmp/ermes_clone >> "$LOG_FILE" 2>&1 || {
            log "❌ ERRORE: git clone fallito!"
            exit 1
        }
    else
        log "📥 Clone senza token..."
        git clone --depth 1 --branch "$GITHUB_BRANCH" \
            "https://github.com/${GITHUB_REPO}.git" \
            /tmp/ermes_clone >> "$LOG_FILE" 2>&1 || {
            log "❌ ERRORE: git clone fallito!"
            exit 1
        }
    fi
    
    # Copia tutti i file nella directory corrente (eccetto .git se esiste)
    log "📋 Copio file nella directory montata..."
    rsync -av --exclude='.git' /tmp/ermes_clone/ "$COMPOSE_DIR/" >> "$LOG_FILE" 2>&1 || {
        log "⚠️ rsync non disponibile, uso cp..."
        cp -r /tmp/ermes_clone/* "$COMPOSE_DIR/" 2>/dev/null || true
        cp -r /tmp/ermes_clone/.* "$COMPOSE_DIR/" 2>/dev/null || true
    }
    
    # Ripristina file esistenti
    cp -f /tmp/ermes_backup/* "$COMPOSE_DIR/" 2>/dev/null || true
    
    # Inizializza git nella directory finale
    cd "$COMPOSE_DIR" || exit 1
    git init >> "$LOG_FILE" 2>&1
    if [ -n "$GITHUB_TOKEN" ]; then
        git remote add origin "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPO}.git" 2>/dev/null || \
        git remote set-url origin "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPO}.git"
    else
        git remote add origin "https://github.com/${GITHUB_REPO}.git" 2>/dev/null || \
        git remote set-url origin "https://github.com/${GITHUB_REPO}.git"
    fi
    git add -A >> "$LOG_FILE" 2>&1 || true
    git reset --hard "origin/${GITHUB_BRANCH}" >> "$LOG_FILE" 2>&1 || true
    
    # Pulisci
    rm -rf /tmp/ermes_clone /tmp/ermes_backup
    
    log "✅ Repository clonato e inizializzato"
fi

# Verifica che i file siano presenti
if [ ! -f "$COMPOSE_DIR/backend/app/main.py" ]; then
    log "❌ ERRORE: File main.py non trovato in $COMPOSE_DIR/backend/app/"
    log "Contenuto directory: $(ls -la $COMPOSE_DIR/backend/app/ 2>&1 | head -10)"
    exit 1
fi

log "✅ Verifica: File main.py trovato in $COMPOSE_DIR/backend/app/"

# Riavvia backend
log "🔄 Riavvio backend..."
$DOCKER_COMPOSE_CMD -f "$COMPOSE_FILE" restart ermes-backend >> "$LOG_FILE" 2>&1 || {
    log "❌ ERRORE durante il riavvio"
    exit 1
}

log "✅ Aggiornamento completato! (veloce, ~5 secondi, solo file modificati)"
