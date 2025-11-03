#!/bin/bash
# Script di deployment per NAS - aggiorna da GitHub

set -e

# Colori per output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 ERMES Deployment Script${NC}"
echo "================================"

# Rileva comando docker-compose (può essere docker-compose o docker compose)
# Verifica anche se serve sudo
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
elif docker compose version &> /dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose"
elif sudo docker compose version &> /dev/null 2>&1; then
    DOCKER_COMPOSE="sudo docker compose"
    echo -e "${YELLOW}⚠ Usando sudo per Docker${NC}"
else
    echo -e "${RED}❌ Errore: docker-compose non trovato!${NC}"
    echo "Assicurati che Docker sia installato sul NAS"
    echo "Prova: docker --version"
    echo ""
    echo "Se ottieni 'permission denied', prova:"
    echo "  sudo usermod -aG docker $USER"
    echo "  (poi fai logout e login di nuovo)"
    exit 1
fi

echo -e "${GREEN}✓ Usando: $DOCKER_COMPOSE${NC}"

# Carica variabili da .env se esiste
if [ -f .env ]; then
    source .env
    echo -e "${YELLOW}✓ File .env caricato${NC}"
else
    echo -e "${YELLOW}⚠ File .env non trovato, uso valori di default${NC}"
fi

# Verifica GITHUB_REPO configurato
if [ -z "$GITHUB_REPO" ] || [ "$GITHUB_REPO" = "your-username/ERMES" ]; then
    echo -e "${RED}❌ Errore: GITHUB_REPO non configurato!${NC}"
    echo "Crea file .env con GITHUB_REPO=tuo-username/tuo-repo"
    exit 1
fi

echo -e "${GREEN}Repository: ${GITHUB_REPO}${NC}"
echo -e "${GREEN}Branch: ${GITHUB_BRANCH:-main}${NC}"

# Determina quale compose file usare
COMPOSE_FILE="docker-compose.github.yml"
if [ "$1" = "nas" ]; then
    COMPOSE_FILE="docker-compose.github.nas.yml"
    echo -e "${YELLOW}Usando configurazione NAS ottimizzata${NC}"
fi

# Ferma container esistenti
echo -e "\n${YELLOW}⏹ Fermo container esistenti...${NC}"
$DOCKER_COMPOSE -f $COMPOSE_FILE down || true

# Rimuovi vecchia immagine backend (forza rebuild)
echo -e "\n${YELLOW}🗑 Rimuovo vecchia immagine backend...${NC}"
docker rmi ermes-backend 2>/dev/null || true

# Rebuild e avvia
echo -e "\n${GREEN}🔨 Rebuild immagini da GitHub...${NC}"
$DOCKER_COMPOSE -f $COMPOSE_FILE build --no-cache --pull

echo -e "\n${GREEN}▶ Avvio container...${NC}"
$DOCKER_COMPOSE -f $COMPOSE_FILE up -d

# Attendi avvio
echo -e "\n${YELLOW}⏳ Attendo avvio servizi...${NC}"
sleep 5

# Verifica stato
echo -e "\n${GREEN}📊 Stato container:${NC}"
$DOCKER_COMPOSE -f $COMPOSE_FILE ps

echo -e "\n${GREEN}✅ Deployment completato!${NC}"
echo -e "\nServizi disponibili:"
IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
echo -e "  Backend API: http://${IP}:8000"
echo -e "  RTMP Server: rtmp://${IP}:1935"
echo -e "\nLog: $DOCKER_COMPOSE -f $COMPOSE_FILE logs -f"

