#!/bin/bash
# Script semplificato per inizializzare git sul NAS
# Usa il container Docker che ha git installato

set -e

echo "📦 Setup Git sul NAS (usando container Docker)"
echo "=========================================="

# Verifica che il container sia in esecuzione
if ! sudo docker ps | grep -q ermes-backend; then
    echo "⚠️ Container ermes-backend non in esecuzione"
    echo "Avvio il container..."
    cd /volume1/docker/ERMES
    sudo docker compose -f docker-compose.github.nas.yml up -d
    sleep 5
fi

echo "✓ Container in esecuzione"

# Trova il path corretto nel container
echo ""
echo "Cercando directory progetto nel container..."

# Prova diversi path
COMPOSE_DIR=""
for path in "/volume1/docker/ERMES" "/app" "/workspace"; do
    if sudo docker exec ermes-backend test -d "$path" 2>/dev/null; then
        echo "✓ Trovato: $path"
        COMPOSE_DIR="$path"
        break
    fi
done

if [ -z "$COMPOSE_DIR" ]; then
    echo "❌ Nessun path valido trovato nel container"
    echo ""
    echo "Path disponibili nel container:"
    sudo docker exec ermes-backend ls -la / | head -20
    exit 1
fi

echo ""
echo "Usando directory: $COMPOSE_DIR"

# Inizializza git
echo ""
echo "📥 Inizializzo repository git..."

if sudo docker exec ermes-backend test -d "$COMPOSE_DIR/.git" 2>/dev/null; then
    echo "✓ Repository git già esistente"
else
    echo "Inizializzo nuovo repository..."
    sudo docker exec ermes-backend git -C "$COMPOSE_DIR" init || {
        echo "❌ Errore inizializzazione git"
        exit 1
    }
fi

# Configura remote
echo "Configuro remote GitHub..."
sudo docker exec ermes-backend git -C "$COMPOSE_DIR" remote add origin https://github.com/Paluello/ERMES.git 2>/dev/null || {
    # Se esiste già, aggiornalo
    sudo docker exec ermes-backend git -C "$COMPOSE_DIR" remote set-url origin https://github.com/Paluello/ERMES.git || true
}

# Configura git
sudo docker exec ermes-backend git -C "$COMPOSE_DIR" config --global --add safe.directory "$COMPOSE_DIR" 2>/dev/null || true

# Fetch
echo "Scarico informazioni da GitHub..."
sudo docker exec ermes-backend git -C "$COMPOSE_DIR" fetch origin main || {
    echo "❌ Errore fetch"
    exit 1
}

# Checkout solo backend/app
echo "Aggiorno backend/app..."
sudo docker exec ermes-backend git -C "$COMPOSE_DIR" checkout -f origin/main -- backend/app || {
    echo "❌ Errore checkout"
    exit 1
}

echo ""
echo "✅ Setup completato!"
echo ""
echo "Ora il webhook può aggiornare automaticamente solo i file modificati."

