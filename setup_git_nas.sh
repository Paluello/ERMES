#!/bin/bash
# Script per inizializzare git sul NAS usando il container Docker
# Il NAS non ha git, ma il container Docker sì!

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

COMPOSE_DIR="/volume1/docker/ERMES"
GITHUB_REPO="${GITHUB_REPO:-Paluello/ERMES}"
GITHUB_BRANCH="${GITHUB_BRANCH:-main}"

echo -e "${GREEN}📦 Setup Git sul NAS (usando container Docker)${NC}"
echo "=========================================="

# Verifica che siamo nella directory giusta
if [ ! -d "$COMPOSE_DIR" ]; then
    echo -e "${YELLOW}⚠️ Directory $COMPOSE_DIR non trovata${NC}"
    echo "Suggerimento: esegui questo script dalla directory del progetto"
    exit 1
fi

cd "$COMPOSE_DIR" || exit 1

# Verifica che il container sia in esecuzione
if ! sudo docker ps | grep -q ermes-backend; then
    echo -e "${YELLOW}⚠️ Container ermes-backend non in esecuzione${NC}"
    echo "Avvio il container..."
    sudo docker compose -f docker-compose.github.nas.yml up -d
    sleep 3
fi

echo -e "${GREEN}✓ Container in esecuzione${NC}"

# Usa git dal container per inizializzare la repository
echo -e "\n${YELLOW}📥 Inizializzo repository git usando git dal container...${NC}"

# Inizializza git se non esiste
if [ ! -d ".git" ]; then
    echo "Inizializzo repository..."
    sudo docker exec ermes-backend git -C /volume1/docker/ERMES init || {
        echo "Errore: impossibile inizializzare git"
        exit 1
    }
fi

# Aggiungi remote
echo "Configuro remote GitHub..."
sudo docker exec ermes-backend git -C /volume1/docker/ERMES remote add origin "https://github.com/${GITHUB_REPO}.git" 2>/dev/null || {
    # Se esiste già, aggiornalo
    sudo docker exec ermes-backend git -C /volume1/docker/ERMES remote set-url origin "https://github.com/${GITHUB_REPO}.git" || true
}

# Configura git
sudo docker exec ermes-backend git -C /volume1/docker/ERMES config --global --add safe.directory /volume1/docker/ERMES 2>/dev/null || true

# Fetch
echo "Scarico informazioni da GitHub..."
sudo docker exec ermes-backend git -C /volume1/docker/ERMES fetch origin "$GITHUB_BRANCH" || {
    echo "Errore: impossibile fare fetch"
    exit 1
}

# Checkout solo backend/app
echo "Aggiorno solo backend/app..."
sudo docker exec ermes-backend git -C /volume1/docker/ERMES checkout -f "origin/${GITHUB_BRANCH}" -- backend/app || {
    echo "Errore: impossibile fare checkout"
    exit 1
}

echo -e "\n${GREEN}✅ Setup completato!${NC}"
echo -e "\nOra il webhook può aggiornare automaticamente solo i file modificati."
echo -e "\nPer testare:"
echo -e "  sudo docker exec ermes-backend cat /tmp/ermes_update.log"

