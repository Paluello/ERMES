#!/bin/bash
# Script per verificare la configurazione ERMES sul NAS

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}  Verifica Configurazione ERMES${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

# Verifica Docker
echo -e "${YELLOW}1. Verifica Docker...${NC}"
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓ Docker installato${NC}"
    docker --version
else
    echo -e "${RED}✗ Docker non trovato${NC}"
    exit 1
fi

# Verifica Docker Compose
echo ""
echo -e "${YELLOW}2. Verifica Docker Compose...${NC}"
if command -v docker-compose &> /dev/null; then
    echo -e "${GREEN}✓ docker-compose installato${NC}"
    docker-compose --version
elif docker compose version &> /dev/null 2>&1; then
    echo -e "${GREEN}✓ docker compose installato${NC}"
    docker compose version
else
    echo -e "${RED}✗ Docker Compose non trovato${NC}"
    exit 1
fi

# Verifica Container
echo ""
echo -e "${YELLOW}3. Verifica Container ERMES...${NC}"
if docker ps | grep -q ermes-backend; then
    echo -e "${GREEN}✓ Container ermes-backend in esecuzione${NC}"
    docker ps | grep ermes-backend
else
    echo -e "${YELLOW}⚠ Container ermes-backend non in esecuzione${NC}"
fi

if docker ps | grep -q ermes-rtmp; then
    echo -e "${GREEN}✓ Container ermes-rtmp in esecuzione${NC}"
    docker ps | grep ermes-rtmp
else
    echo -e "${YELLOW}⚠ Container ermes-rtmp non in esecuzione${NC}"
fi

# Verifica File .env
echo ""
echo -e "${YELLOW}4. Verifica File .env...${NC}"
if [ -f .env ]; then
    echo -e "${GREEN}✓ File .env trovato${NC}"
    echo ""
    echo -e "${BLUE}Configurazioni GitHub:${NC}"
    grep -E "^GITHUB_" .env | sed 's/=.*/=***/' || echo "  Nessuna configurazione GitHub trovata"
    echo ""
    echo -e "${BLUE}Configurazioni Auto-Update:${NC}"
    grep -E "^GITHUB_AUTO_UPDATE" .env || echo "  Nessuna configurazione auto-update trovata"
else
    echo -e "${YELLOW}⚠ File .env non trovato${NC}"
    echo "  Crea un file .env basato su .env.example"
fi

# Verifica Configurazione Container Backend
echo ""
echo -e "${YELLOW}5. Verifica Configurazione Container Backend...${NC}"
if docker ps | grep -q ermes-backend; then
    echo -e "${BLUE}Variabili d'ambiente GitHub:${NC}"
    docker exec ermes-backend env | grep GITHUB | sort || echo "  Nessuna variabile GitHub trovata"
    echo ""
    echo -e "${BLUE}Socket Docker montato:${NC}"
    if docker exec ermes-backend test -S /var/run/docker.sock 2>/dev/null; then
        echo -e "${GREEN}✓ Socket Docker montato correttamente${NC}"
    else
        echo -e "${RED}✗ Socket Docker non montato${NC}"
        echo "  Aggiungi nel docker-compose.yml:"
        echo "    volumes:"
        echo "      - /var/run/docker.sock:/var/run/docker.sock:ro"
    fi
    echo ""
    echo -e "${BLUE}Script di aggiornamento:${NC}"
    if docker exec ermes-backend test -f /app/update_container.sh 2>/dev/null; then
        echo -e "${GREEN}✓ Script update_container.sh presente${NC}"
    else
        echo -e "${YELLOW}⚠ Script update_container.sh non trovato${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Container non in esecuzione, impossibile verificare${NC}"
fi

# Verifica Auto-Updater
echo ""
echo -e "${YELLOW}6. Verifica Auto-Updater...${NC}"
if docker ps | grep -q ermes-backend; then
    echo -e "${BLUE}Log Auto-Updater:${NC}"
    docker logs ermes-backend 2>&1 | grep -i "auto-updater" | tail -5 || echo "  Nessun log auto-updater trovato"
    echo ""
    echo -e "${BLUE}Ultimi log aggiornamento:${NC}"
    docker exec ermes-backend cat /tmp/ermes_update.log 2>/dev/null | tail -10 || echo "  Nessun log di aggiornamento trovato"
else
    echo -e "${YELLOW}⚠ Container non in esecuzione${NC}"
fi

# Verifica Connessione GitHub
echo ""
echo -e "${YELLOW}7. Verifica Connessione GitHub...${NC}"
GITHUB_REPO=$(grep "^GITHUB_REPO=" .env 2>/dev/null | cut -d '=' -f2 | tr -d '"' | tr -d "'" || echo "Paluello/ERMES")
GITHUB_BRANCH=$(grep "^GITHUB_BRANCH=" .env 2>/dev/null | cut -d '=' -f2 | tr -d '"' | tr -d "'" || echo "main")

echo "Repository: $GITHUB_REPO"
echo "Branch: $GITHUB_BRANCH"
echo ""

if docker ps | grep -q ermes-backend; then
    echo -e "${BLUE}Test connessione da container:${NC}"
    if docker exec ermes-backend curl -s "https://api.github.com/repos/${GITHUB_REPO}/commits/${GITHUB_BRANCH}" | head -5 > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Connessione GitHub OK${NC}"
    else
        echo -e "${RED}✗ Errore connessione GitHub${NC}"
    fi
else
    if curl -s "https://api.github.com/repos/${GITHUB_REPO}/commits/${GITHUB_BRANCH}" | head -5 > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Connessione GitHub OK${NC}"
    else
        echo -e "${RED}✗ Errore connessione GitHub${NC}"
    fi
fi

# Riepilogo
echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}  Riepilogo${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"

ISSUES=0

if ! docker ps | grep -q ermes-backend; then
    echo -e "${RED}✗ Container ermes-backend non in esecuzione${NC}"
    ISSUES=$((ISSUES + 1))
fi

if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠ File .env mancante${NC}"
    ISSUES=$((ISSUES + 1))
fi

if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}✓ Configurazione OK${NC}"
    echo ""
    echo "Per verificare i log in tempo reale:"
    echo "  docker logs -f ermes-backend"
    echo ""
    echo "Per verificare lo stato del polling:"
    echo "  docker logs ermes-backend | grep -i 'polling\|commit'"
else
    echo -e "${YELLOW}⚠ Trovati $ISSUES problema/i da risolvere${NC}"
fi

echo ""

