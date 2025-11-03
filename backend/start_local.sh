#!/bin/bash
# Script per avviare il backend ERMES in locale

echo "🚀 Avvio ERMES Backend in locale..."

# Verifica se esiste un venv
if [ -d "venv" ]; then
    echo "📦 Attivazione ambiente virtuale..."
    source venv/bin/activate
elif [ -d ".venv" ]; then
    echo "📦 Attivazione ambiente virtuale..."
    source .venv/bin/activate
else
    echo "⚠️  Nessun ambiente virtuale trovato. Creo uno nuovo..."
    python3 -m venv venv
    source venv/bin/activate
    echo "📦 Installazione dipendenze..."
    pip install --upgrade pip
    pip install -r requirements.txt
fi

# Verifica dipendenze
echo "🔍 Verifica dipendenze..."
if ! python3 -c "import fastapi" 2>/dev/null; then
    echo "📦 Installazione dipendenze..."
    pip install -r requirements.txt
fi

# Avvia server
echo "✅ Avvio server su http://localhost:8000"
echo "📊 Dashboard: http://localhost:8000"
echo "📚 API Docs: http://localhost:8000/docs"
echo ""
echo "Premi CTRL+C per fermare"
echo ""

cd "$(dirname "$0")"
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

