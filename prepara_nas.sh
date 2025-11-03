#!/bin/bash
# Script per preparare file da copiare sul NAS
# Questo script crea una cartella "NAS_FILES" con solo i file necessari

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}📦 Preparazione file per NAS${NC}"
echo "================================"

# Crea directory temporanea
OUTPUT_DIR="NAS_FILES"
rm -rf $OUTPUT_DIR
mkdir -p $OUTPUT_DIR/backend

echo -e "${YELLOW}Copio file necessari...${NC}"

# Copia file essenziali
cp docker-compose.github.nas.yml $OUTPUT_DIR/
cp deploy.sh $OUTPUT_DIR/
cp update.sh $OUTPUT_DIR/

# Crea file .env con template
cat > $OUTPUT_DIR/.env << 'EOF'
# Configurazione GitHub per Docker Compose
# Modifica GITHUB_REPO con il tuo repository!

# Repository GitHub (formato: username/repo-name)
# ESEMPIO: GITHUB_REPO=mattiapaluello/ERMES
GITHUB_REPO=your-username/ERMES

# Branch da usare (default: main)
GITHUB_BRANCH=main

# Token GitHub (opzionale, solo per repo privati)
# Lascia vuoto se il repo è pubblico
GITHUB_TOKEN=
EOF

# Copia file backend
cp backend/Dockerfile.github.nas $OUTPUT_DIR/backend/
cp backend/nginx-rtmp.conf $OUTPUT_DIR/backend/

# Rendi eseguibili gli script
chmod +x $OUTPUT_DIR/deploy.sh
chmod +x $OUTPUT_DIR/update.sh

echo -e "${GREEN}✅ File preparati in cartella: $OUTPUT_DIR${NC}"
echo ""
echo "Ora puoi:"
echo "1. Trascinare la cartella $OUTPUT_DIR sul NAS (via Finder)"
echo "2. Oppure caricare i file singolarmente via interfaccia web NAS"
echo ""
echo "IMPORTANTE: Prima di avviare, modifica $OUTPUT_DIR/.env con:"
echo "  GITHUB_REPO=TUO-USERNAME/ERMES"
echo "  GITHUB_BRANCH=main"

