#!/bin/bash
# Script per verificare i path montati nel container

echo "Verificando path nel container..."

# Verifica se il container è in esecuzione
if ! sudo docker ps | grep -q ermes-backend; then
    echo "⚠️ Container ermes-backend non in esecuzione"
    exit 1
fi

echo ""
echo "Path montati nel container:"
sudo docker exec ermes-backend ls -la / | grep -E "volume1|app|docker"

echo ""
echo "Verificando se /volume1/docker/ERMES esiste:"
sudo docker exec ermes-backend test -d /volume1/docker/ERMES && echo "✅ /volume1/docker/ERMES esiste" || echo "❌ /volume1/docker/ERMES NON esiste"

echo ""
echo "Verificando se /app esiste:"
sudo docker exec ermes-backend test -d /app && echo "✅ /app esiste" || echo "❌ /app NON esiste"

echo ""
echo "Working directory del container:"
sudo docker exec ermes-backend pwd

echo ""
echo "Contenuto di /app (se esiste):"
sudo docker exec ermes-backend ls -la /app 2>/dev/null || echo "Directory /app non accessibile"

