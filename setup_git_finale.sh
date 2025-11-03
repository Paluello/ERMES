#!/bin/bash
# Script per configurare git nel container (path corretto: /app)

set -e

echo "📦 Setup Git sul NAS"
echo "===================="

# Verifica che il container sia in esecuzione
if ! sudo docker ps | grep -q ermes-backend; then
    echo "⚠️ Container ermes-backend non in esecuzione"
    exit 1
fi

COMPOSE_DIR="/app"
GITHUB_REPO="Paluello/ERMES"
GITHUB_BRANCH="main"

echo "✓ Container in esecuzione"
echo "✓ Usando directory: $COMPOSE_DIR"

# Verifica che il repository git esista già
if sudo docker exec ermes-backend test -d "$COMPOSE_DIR/.git" 2>/dev/null; then
    echo "✓ Repository git già esistente"
else
    echo "📥 Inizializzo nuovo repository git..."
    sudo docker exec ermes-backend git -C "$COMPOSE_DIR" init || {
        echo "❌ Errore inizializzazione git"
        exit 1
    }
fi

# Configura remote
echo "🔗 Configuro remote GitHub..."
sudo docker exec ermes-backend git -C "$COMPOSE_DIR" remote add origin "https://github.com/${GITHUB_REPO}.git" 2>/dev/null || {
    # Se esiste già, aggiornalo
    sudo docker exec ermes-backend git -C "$COMPOSE_DIR" remote set-url origin "https://github.com/${GITHUB_REPO}.git" || true
    echo "✓ Remote già configurato, aggiornato"
}

# Configura git
sudo docker exec ermes-backend git -C "$COMPOSE_DIR" config --global --add safe.directory "$COMPOSE_DIR" 2>/dev/null || true

# Fetch
echo "📥 Scarico informazioni da GitHub..."
sudo docker exec ermes-backend git -C "$COMPOSE_DIR" fetch origin "$GITHUB_BRANCH" || {
    echo "❌ Errore fetch"
    exit 1
}

# Checkout solo backend/app (per non sovrascrivere altri file)
echo "📋 Aggiorno backend/app..."
sudo docker exec ermes-backend git -C "$COMPOSE_DIR" checkout -f "origin/${GITHUB_BRANCH}" -- backend/app || {
    echo "❌ Errore checkout"
    exit 1
}

echo ""
echo "✅ Setup completato!"
echo ""
echo "Ora il webhook può aggiornare automaticamente solo i file modificati."
echo ""
echo "Per testare l'aggiornamento:"
echo "  sudo docker exec ermes-backend cat /tmp/ermes_update.log"

