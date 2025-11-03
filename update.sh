#!/bin/bash
# Script rapido per aggiornare solo il codice (senza rebuild completo)

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🔄 Aggiornamento ERMES da GitHub${NC}"

COMPOSE_FILE="docker-compose.github.yml"
if [ "$1" = "nas" ]; then
    COMPOSE_FILE="docker-compose.github.nas.yml"
fi

# Rebuild solo backend (codice da GitHub)
echo -e "${YELLOW}Rebuild backend con ultimo codice...${NC}"
docker-compose -f $COMPOSE_FILE build --no-cache ermes-backend

# Riavvia solo backend
echo -e "${YELLOW}Riavvio backend...${NC}"
docker-compose -f $COMPOSE_FILE restart ermes-backend

echo -e "${GREEN}✅ Aggiornamento completato!${NC}"

