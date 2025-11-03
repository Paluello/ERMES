#!/bin/bash
# Script per verificare file .env sul NAS

echo "Verifica file .env:"
echo "==================="

if [ -f .env ]; then
    echo "✓ File .env trovato"
    echo ""
    echo "Contenuto:"
    cat .env
    echo ""
    echo "Variabili caricate:"
    source .env
    echo "GITHUB_REPO=$GITHUB_REPO"
    echo "GITHUB_BRANCH=$GITHUB_BRANCH"
    echo "GITHUB_TOKEN=${GITHUB_TOKEN:0:20}..." # Mostra solo primi 20 caratteri
else
    echo "❌ File .env NON trovato!"
    echo "Crea file .env con:"
    echo "GITHUB_REPO=Paluello/ERMES"
    echo "GITHUB_BRANCH=main"
    echo "GITHUB_TOKEN="
fi

