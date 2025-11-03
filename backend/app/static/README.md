# ERMES Static Files

Questa directory contiene tutti i file statici per il frontend di ERMES.

## Struttura

```
static/
├── app/                    # React App unificata (dashboard + docs)
│   ├── src/
│   │   ├── pages/         # Pagine React (Dashboard, Docs)
│   │   ├── components/    # Componenti React riutilizzabili
│   │   ├── api.ts         # Modulo API TypeScript
│   │   └── styles/        # Stili CSS
│   └── dist/              # File compilati (generati da npm run build)
└── swagger-custom.css      # CSS personalizzato per Swagger UI (usato nella React app)
```

## React App

L'applicazione React unificata (`app/`) gestisce:

- **Dashboard** (`/#/`) - Dashboard principale con statistiche, sistema, sorgenti
- **Documentazione API** (`/#/docs`) - Swagger UI React per testare le API

### Setup e Build

```bash
cd backend/app/static/app
npm install
npm run build
```

Dopo il build, i file compilati vengono serviti da FastAPI su `/` e `/docs`.

## Sviluppo

### Modificare la Dashboard

Edita i file in `app/src/pages/Dashboard.tsx` e i componenti in `app/src/components/`.

### Modificare la Documentazione

Edita `app/src/pages/Docs.tsx` e gli stili in `app/src/styles/swagger-custom.css`.

### Aggiungere Nuove Pagine

1. Crea nuovo componente in `app/src/pages/`
2. Aggiungi route in `app/src/App.tsx`
3. Esegui `npm run build`

## Tecnologie

- **React 19** + **TypeScript**
- **React Router** (HashRouter)
- **Tailwind CSS** per styling
- **Swagger UI React** per documentazione API
- **Vite** per build e dev server
