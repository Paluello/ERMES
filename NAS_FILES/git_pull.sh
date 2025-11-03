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

# Usa un container Docker con git per fare il pull
# Monta la directory del progetto e fa git pull
echo -e "${YELLOW}Eseguo git pull tramite container Docker...${NC}"

docker run --rm \
    -v "$PROJECT_DIR:/workspace" \
    -w /workspace \
    alpine/git:latest \
    sh -c "git config --global --add safe.directory /workspace && git pull origin main || git pull origin master"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Git pull completato con successo!${NC}"
    
    # Riavvia il backend per applicare le modifiche
    echo -e "${YELLOW}Riavvio backend...${NC}"
    if command -v docker-compose &> /dev/null; then
        docker-compose -f "$COMPOSE_FILE" restart ermes-backend
    elif docker compose version &> /dev/null 2>&1; then
        docker compose -f "$COMPOSE_FILE" restart ermes-backend
    else
        echo -e "${RED}❌ docker-compose non trovato!${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Backend riavviato!${NC}"
else
    echo -e "${RED}❌ Errore durante git pull!${NC}"
    exit 1
fi

