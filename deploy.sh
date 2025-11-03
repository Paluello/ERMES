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
docker-compose -f $COMPOSE_FILE down || true

# Rimuovi vecchia immagine backend (forza rebuild)
echo -e "\n${YELLOW}🗑 Rimuovo vecchia immagine backend...${NC}"
docker rmi ermes-backend 2>/dev/null || true

# Rebuild e avvia
echo -e "\n${GREEN}🔨 Rebuild immagini da GitHub...${NC}"
docker-compose -f $COMPOSE_FILE build --no-cache --pull

echo -e "\n${GREEN}▶ Avvio container...${NC}"
docker-compose -f $COMPOSE_FILE up -d

# Attendi avvio
echo -e "\n${YELLOW}⏳ Attendo avvio servizi...${NC}"
sleep 5

# Verifica stato
echo -e "\n${GREEN}📊 Stato container:${NC}"
docker-compose -f $COMPOSE_FILE ps

echo -e "\n${GREEN}✅ Deployment completato!${NC}"
echo -e "\nServizi disponibili:"
echo -e "  Backend API: http://$(hostname -I | awk '{print $1}'):8000"
echo -e "  RTMP Server: rtmp://$(hostname -I | awk '{print $1}'):1935"
echo -e "\nLog: docker-compose -f $COMPOSE_FILE logs -f"

