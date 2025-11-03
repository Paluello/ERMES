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

# Verifica che docker-compose sia disponibile (può essere docker-compose o docker compose)
DOCKER_COMPOSE_CMD=""
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
elif command -v docker &> /dev/null && docker compose version &> /dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
else
    log "ERRORE: docker-compose non trovato nel container"
    log "Verifica che docker-compose sia installato nel Dockerfile"
    exit 1
fi

log "Usando: $DOCKER_COMPOSE_CMD"

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
    
    # Aggiorna il codice nella directory montata sul NAS
    # La directory montata è /volume1/docker/ERMES/backend/app -> /app/backend/app
    
    log "📥 Aggiorno codice da GitHub..."
    
    # Leggi configurazione GitHub
    GITHUB_REPO="${GITHUB_REPO:-Paluello/ERMES}"
    GITHUB_BRANCH="${GITHUB_BRANCH:-main}"
    GITHUB_TOKEN="${GITHUB_TOKEN:-}"
    
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
            git checkout -f "origin/${GITHUB_BRANCH}" >> "$LOG_FILE" 2>&1 || {
                log "❌ ERRORE: anche checkout fallito"
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
        
        # Copia tutti i file nella directory corrente
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
    
    # Riavvia solo il backend (il codice è già montato come volume, quindi basta restart)
    log "Riavvio backend con nuovo codice (nessun rebuild necessario)..."
    $DOCKER_COMPOSE_CMD -f "$COMPOSE_FILE" restart ermes-backend >> "$LOG_FILE" 2>&1 || {
        log "ERRORE durante il riavvio!"
        exit 1
    }
    
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
    $DOCKER_COMPOSE_CMD -f "$COMPOSE_FILE" restart ermes-backend >> "$LOG_FILE" 2>&1 || {
        log "ERRORE durante il riavvio!"
        exit 1
    }
    
    log "✅ Aggiornamento veloce completato (solo restart ~5 secondi, nessun rebuild)"
else
    log "Repository git non montato - rebuild completo necessario..."
    
    # Rebuild backend (usa cache quando possibile, evita --no-cache)
    log "Rebuild backend con ultimo codice da GitHub..."
    $DOCKER_COMPOSE_CMD -f "$COMPOSE_FILE" build ermes-backend >> "$LOG_FILE" 2>&1 || {
        log "ERRORE durante il build!"
        exit 1
    }
    
    # Riavvio backend
    log "Riavvio backend..."
    $DOCKER_COMPOSE_CMD -f "$COMPOSE_FILE" restart ermes-backend >> "$LOG_FILE" 2>&1 || {
        log "ERRORE durante il riavvio!"
        exit 1
    }
    
    log "✅ Aggiornamento completato (rebuild completo)"
fi


