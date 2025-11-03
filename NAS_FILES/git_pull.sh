#!/bin/bash
# Script per fare git pull sul NAS usando Docker (se git non è installato)

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_DIR="/volume1/docker/ERMES"
COMPOSE_FILE="docker-compose.github.nas.yml"

echo -e "${GREEN}🔄 Git pull tramite Docker${NC}"

# Verifica che la directory esista
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}❌ Directory $PROJECT_DIR non trovata!${NC}"
    exit 1
fi

cd "$PROJECT_DIR" || exit 1

# Leggi token e repo dal .env se esiste
if [ -f "$PROJECT_DIR/.env" ]; then
    GITHUB_TOKEN=$(grep "^GITHUB_TOKEN=" "$PROJECT_DIR/.env" | cut -d '=' -f2 | tr -d '"' | tr -d "'" | tr -d ' ')
    GITHUB_REPO=$(grep "^GITHUB_REPO=" "$PROJECT_DIR/.env" | cut -d '=' -f2 | tr -d '"' | tr -d "'" | tr -d ' ')
    GITHUB_BRANCH=$(grep "^GITHUB_BRANCH=" "$PROJECT_DIR/.env" | cut -d '=' -f2 | tr -d '"' | tr -d "'" | tr -d ' ')
fi

# Default se non trovato
GITHUB_REPO="${GITHUB_REPO:-Paluello/ERMES}"
GITHUB_BRANCH="${GITHUB_BRANCH:-main}"

# Usa un container Docker con git per fare il pull
# Monta la directory del progetto e fa git pull
echo -e "${YELLOW}Eseguo git pull tramite container Docker...${NC}"

# Esegui git pull con entrypoint corretto
if [ -n "$GITHUB_TOKEN" ]; then
    sudo docker run --rm \
        --entrypoint sh \
        -v "$PROJECT_DIR:/workspace" \
        -w /workspace \
        -e GITHUB_TOKEN="$GITHUB_TOKEN" \
        -e GITHUB_REPO="$GITHUB_REPO" \
        alpine/git:latest \
        -c "git config --global --add safe.directory /workspace && git remote set-url origin https://x-access-token:\${GITHUB_TOKEN}@github.com/\${GITHUB_REPO}.git && git fetch origin && git reset --hard origin/${GITHUB_BRANCH}"
else
    sudo docker run --rm \
        --entrypoint sh \
        -v "$PROJECT_DIR:/workspace" \
        -w /workspace \
        alpine/git:latest \
        -c "git config --global --add safe.directory /workspace && git fetch origin && git reset --hard origin/${GITHUB_BRANCH}"
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Git pull completato con successo!${NC}"
    
    # Riavvia il backend per applicare le modifiche
    echo -e "${YELLOW}Riavvio backend...${NC}"
    if command -v docker-compose &> /dev/null; then
        sudo docker-compose -f "$COMPOSE_FILE" restart ermes-backend
    elif docker compose version &> /dev/null 2>&1; then
        sudo docker compose -f "$COMPOSE_FILE" restart ermes-backend
    else
        echo -e "${RED}❌ docker-compose non trovato!${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Backend riavviato!${NC}"
else
    echo -e "${RED}❌ Errore durante git pull!${NC}"
    exit 1
fi

