#!/bin/bash
# Script da eseguire DIRETTAMENTE sul NAS per fixare il problema WebSocket

echo "🔧 Fix WebSocket sul NAS..."

# Path della directory sul NAS
NAS_DIR="/volume1/docker/ERMES"
MAIN_PY="$NAS_DIR/backend/app/main.py"

# Verifica che la directory esista
if [ ! -d "$NAS_DIR" ]; then
    echo "❌ Directory $NAS_DIR non trovata!"
    exit 1
fi

# Verifica che il file esista
if [ ! -f "$MAIN_PY" ]; then
    echo "❌ File $MAIN_PY non trovato!"
    exit 1
fi

# Backup del file corrente
cp "$MAIN_PY" "$MAIN_PY.backup.$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup creato"

# Fix 1: Cambia l'import
sed -i 's/from app.api import routes, websocket/from app.api import routes\nfrom app.api import websocket as websocket_module/' "$MAIN_PY"

# Fix 2: Cambia la chiamata
sed -i 's/await websocket\.websocket_endpoint(websocket)/await websocket_module.websocket_endpoint(websocket)/' "$MAIN_PY"

echo "✅ File modificato!"

# Verifica le modifiche
echo ""
echo "Verifica modifiche:"
echo "--- Import ---"
grep -A 1 "from app.api import" "$MAIN_PY" | head -2
echo ""
echo "--- WebSocket call ---"
grep "websocket_module.websocket_endpoint" "$MAIN_PY"

echo ""
echo "🔄 Riavvio backend..."
docker compose -f docker-compose.github.nas.yml restart ermes-backend

echo ""
echo "✅ Completato! Controlla i log con:"
echo "   docker logs ermes-backend | tail -20"

