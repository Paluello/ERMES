#!/bin/bash
# Script per aggiornare ERMES da GitHub (usato da auto-updater con polling)
# Usa git direttamente nel container per aggiornare solo i file modificati

set -e

LOG_FILE="/tmp/ermes_update.log"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.github.nas.yml}"

# Determina directory progetto (variabile d'ambiente o auto-detect)
PROJECT_DIR="${PROJECT_DIR:-}"
if [ -z "$PROJECT_DIR" ]; then
    # Auto-detect: prova diversi path comuni
    if [ -d "/app" ] && [ -f "/app/backend/app/main.py" ]; then
        PROJECT_DIR="/app"
    elif [ -d "/volume1/docker/ERMES" ]; then
        PROJECT_DIR="/volume1/docker/ERMES"
    elif [ -d "/workspace" ]; then
        PROJECT_DIR="/workspace"
    else
        PROJECT_DIR=$(pwd)
    fi
fi

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "🔄 Aggiornamento ERMES da GitHub..."

# Verifica docker compose
if command -v docker &> /dev/null && docker compose version &> /dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
else
    log "❌ ERRORE: docker compose non trovato"
    exit 1
fi

# Verifica socket Docker
if [ ! -S /var/run/docker.sock ]; then
    log "❌ ERRORE: Socket Docker non montato"
    exit 1
fi

log "📁 Directory progetto: $PROJECT_DIR"

# Vai nella directory
cd "$PROJECT_DIR" || {
    log "❌ ERRORE: Directory $PROJECT_DIR non trovata"
    exit 1
}

# Leggi configurazione GitHub
GITHUB_REPO="${GITHUB_REPO:-Paluello/ERMES}"
GITHUB_BRANCH="${GITHUB_BRANCH:-main}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

log "📥 Repository: $GITHUB_REPO (branch: $GITHUB_BRANCH)"

# Configura git
git config --global --add safe.directory "$PROJECT_DIR" 2>/dev/null || true

# Se la directory è già un repository git, fai pull
if [ -d "$PROJECT_DIR/.git" ]; then
    log "📦 Repository git trovata - aggiorno i file..."
    
    # Configura remote se necessario
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
        git checkout -f "origin/${GITHUB_BRANCH}" >> "$LOG_FILE" 2>&1 || {
            log "❌ ERRORE: checkout fallito"
            exit 1
        }
    }
    
    log "✅ Codice aggiornato via git pull"
else
    # Non è un repository git - clona l'intera repository
    log "📦 Directory non è un repository git - clono da GitHub..."
    
    # Salva file esistenti importanti
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
    
    # Copia file nella directory corrente
    log "📋 Copio file nella directory montata..."
    rsync -av --exclude='.git' /tmp/ermes_clone/ "$PROJECT_DIR/" >> "$LOG_FILE" 2>&1 || {
        log "⚠️ rsync non disponibile, uso cp..."
        cp -r /tmp/ermes_clone/* "$PROJECT_DIR/" 2>/dev/null || true
        cp -r /tmp/ermes_clone/.* "$PROJECT_DIR/" 2>/dev/null || true
    }
    
    # Ripristina file esistenti
    cp -f /tmp/ermes_backup/* "$PROJECT_DIR/" 2>/dev/null || true
    
    # Inizializza git nella directory finale
    cd "$PROJECT_DIR" || exit 1
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
if [ ! -f "$PROJECT_DIR/backend/app/main.py" ]; then
    log "❌ ERRORE: File main.py non trovato in $PROJECT_DIR/backend/app/"
    exit 1
fi

log "✅ Verifica: File main.py trovato"

# Riavvia backend
log "🔄 Riavvio backend..."
$DOCKER_COMPOSE_CMD -f "$COMPOSE_FILE" restart ermes-backend >> "$LOG_FILE" 2>&1 || {
    log "❌ ERRORE durante il riavvio"
    exit 1
}

log "✅ Aggiornamento completato! (~5 secondi)"
