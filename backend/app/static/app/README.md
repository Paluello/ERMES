# ERMES React App

Unica applicazione React + TypeScript per dashboard (`/`) e documentazione API (`/docs`).

## Setup

1. Installa le dipendenze:
```bash
cd backend/app/static/app
npm install
```

2. Build per produzione:
```bash
npm run build
```

3. Per sviluppo (con hot reload):
```bash
npm run dev
```

## Struttura

- `src/App.tsx` - Router principale con Routes
- `src/pages/` - Pagine dell'app
  - `Dashboard.tsx` - Dashboard principale (`/`)
  - `Docs.tsx` - Documentazione API con Swagger UI (`/docs`)
- `src/components/` - Componenti React riutilizzabili
  - `Header.tsx` - Header con navigazione
  - `StatCard.tsx` - Card statistiche
  - `InfoCard.tsx` - Card riutilizzabile
  - `SystemInfo.tsx` - Info sistema
  - `VersionInfo.tsx` - Info versione
  - `UpdaterInfo.tsx` - Info auto-updater
  - `SourcesList.tsx` - Lista sorgenti
- `src/api.ts` - Modulo API
- `src/types.ts` - TypeScript types
- `src/styles/swagger-custom.css` - Stili Swagger UI

## Routes

- `/` - Dashboard principale
- `/docs` - Documentazione API interattiva

## Features

- React Router per navigazione SPA
- Tailwind CSS per styling
- TypeScript per type safety
- Auto-refresh ogni 30 secondi nella dashboard
- Swagger UI React per documentazione API

## Deploy

Dopo ogni modifica, esegui `npm run build` per compilare i file nella cartella `dist/`, che vengono poi serviti da FastAPI su tutte le route (SPA).

