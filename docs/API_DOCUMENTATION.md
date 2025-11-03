# Documentazione API ERMES

## Panoramica

ERMES espone una REST API completa per la gestione di sorgenti video, telemetria e sistema di tracking.

## Endpoint Base

- **URL Base**: `http://0.0.0.0:8000`
- **API Prefix**: `/api`
- **Documentazione Interattiva**: `/docs` (Swagger UI)
- **Documentazione Alternativa**: `/redoc`

## Autenticazione

Attualmente l'API non richiede autenticazione. In produzione, si consiglia di implementare:

- Bearer Token Authentication
- API Key Authentication
- OAuth2 (se necessario)

## Endpoint Disponibili

### Sistema

#### `GET /api/status`

Ottiene lo stato generale del sistema.

**Response:**
```json
{
  "status": "running",
  "version": "0.1.0",
  "git_commit": "abc1234",
  "git_branch": "main",
  "gps_precision": "standard",
  "max_tracked_objects": 50
}
```

### Sorgenti

#### `GET /api/sources`

Ottiene la lista di tutte le sorgenti registrate.

**Response:**
```json
{
  "sources": [
    {
      "source_id": "source-123",
      "source_type": "drone",
      "is_available": true
    }
  ]
}
```

#### `GET /api/telemetry/{source_id}`

Ottiene la telemetria più recente per una sorgente specifica.

**Parameters:**
- `source_id` (path): ID della sorgente

**Response:**
```json
{
  "source_id": "source-123",
  "source_type": "drone",
  "timestamp": "2024-01-01T12:00:00Z",
  "latitude": 41.9028,
  "longitude": 12.4964,
  "altitude": 100.5,
  "heading": 45.0,
  "pitch": 0.0,
  "roll": 0.0,
  "yaw": 45.0
}
```

**Errori:**
- `404`: Sorgente non trovata
- `404`: Telemetria non disponibile

### Sorgenti Mobile

#### `POST /api/sources/mobile/register`

Registra un telefono mobile come sorgente video.

**Request Body:**
```json
{
  "source_id": "mobile-123",
  "device_info": {
    "model": "iPhone 14",
    "os": "iOS 17"
  },
  "rtmp_url": "rtmp://server/live/stream"
}
```

**Response:**
```json
{
  "success": true,
  "source_id": "mobile-123",
  "message": "Sorgente registrata con successo"
}
```

**Errori:**
- `400`: Parametri mancanti
- `409`: Sorgente già registrata

#### `POST /api/sources/mobile/{source_id}/telemetry`

Aggiorna la telemetria di una sorgente mobile.

**Request Body:**
```json
{
  "latitude": 41.9028,
  "longitude": 12.4964,
  "altitude": 50.0,
  "heading": 90.0
}
```

**Response:**
```json
{
  "success": true,
  "message": "Telemetria aggiornata"
}
```

#### `POST /api/sources/mobile/{source_id}/disconnect`

Disconnette una sorgente mobile.

**Response:**
```json
{
  "success": true,
  "message": "Sorgente mobile-123 disconnessa"
}
```

### Aggiornamenti

#### `GET /api/update/polling/status`

Ottiene lo stato del polling automatico per aggiornamenti.

**Response:**
```json
{
  "enabled": true,
  "is_running": true,
  "repository": "user/repo",
  "branch": "main",
  "poll_interval_minutes": 15,
  "last_commit_sha": "abc1234"
}
```

#### `POST /api/update/polling/check`

Forza un controllo immediato per nuovi commit.

**Response:**
```json
{
  "success": true,
  "updated": false,
  "message": "Nessun nuovo commit trovato",
  "last_commit_sha": "abc1234"
}
```

#### `POST /api/update/trigger`

Triggera manualmente un aggiornamento del sistema.

**Response:**
```json
{
  "success": true,
  "message": "Aggiornamento avviato in background",
  "process_id": 12345,
  "note": "Controlla i log con: docker logs ermes-backend | grep update"
}
```

#### `GET /api/update/status`

Ottiene lo stato dell'ultimo aggiornamento.

**Response:**
```json
{
  "status": "available",
  "last_logs": "...",
  "total_lines": 100
}
```

### RTMP Callbacks

#### `POST /api/rtmp/on_publish`

Callback chiamato da nginx-rtmp quando uno stream inizia.

**Request (Form Data):**
- `app`: Nome applicazione RTMP
- `name`: Source ID dello stream
- `addr`: Indirizzo IP del client

**Response:**
```json
{
  "status": "accepted",
  "source_id": "source-123"
}
```

#### `POST /api/rtmp/on_publish_done`

Callback chiamato quando uno stream termina.

**Response:**
```json
{
  "status": "processed",
  "source_id": "source-123"
}
```

### Webhook GitHub

#### `POST /api/webhook/github`

Webhook per aggiornamenti automatici da GitHub.

**Headers:**
- `X-GitHub-Event`: Tipo evento (deve essere "push")
- `X-Hub-Signature-256`: Signature HMAC SHA256 (se configurato)

**Request Body:**
GitHub webhook payload (JSON)

**Response:**
```json
{
  "success": true,
  "message": "Aggiornamento avviato",
  "commit": "abc1234"
}
```

**Configurazione:**
1. Vai su GitHub Repository → Settings → Webhooks
2. Aggiungi webhook con URL: `http://tuo-server:8000/api/webhook/github`
3. Content type: `application/json`
4. Secret: Configura `GITHUB_WEBHOOK_SECRET` nel `.env`
5. Events: Seleziona "Just the push event"

## Codici di Stato HTTP

- `200`: Successo
- `400`: Richiesta non valida
- `401`: Non autorizzato
- `403`: Accesso negato
- `404`: Risorsa non trovata
- `409`: Conflitto (es. sorgente già registrata)
- `500`: Errore interno del server

## Formato Errori

Tutti gli errori seguono questo formato:

```json
{
  "detail": "Messaggio di errore descrittivo"
}
```

## Rate Limiting

Attualmente non implementato. Si consiglia di aggiungere:

- Rate limiting per IP
- Rate limiting per endpoint
- Throttling per operazioni pesanti

## Versioning

L'API è attualmente alla versione `0.1.0`. Il versioning futuro può essere implementato tramite:

- URL prefix: `/api/v1/...`
- Header: `Accept: application/vnd.ermes.v1+json`

## Esempi di Utilizzo

### cURL

```bash
# Ottieni stato sistema
curl http://0.0.0.0:8000/api/status

# Registra sorgente mobile
curl -X POST http://0.0.0.0:8000/api/sources/mobile/register \
  -H "Content-Type: application/json" \
  -d '{
    "source_id": "mobile-123",
    "rtmp_url": "rtmp://server/live/stream"
  }'

# Ottieni telemetria
curl http://0.0.0.0:8000/api/telemetry/source-123
```

### Python

```python
import httpx

# Client API
client = httpx.Client(base_url="http://0.0.0.0:8000")

# Status
response = client.get("/api/status")
print(response.json())

# Registra sorgente
response = client.post("/api/sources/mobile/register", json={
    "source_id": "mobile-123",
    "rtmp_url": "rtmp://server/live/stream"
})
print(response.json())
```

### JavaScript

```javascript
// Fetch API
const response = await fetch('http://0.0.0.0:8000/api/status');
const data = await response.json();
console.log(data);

// Registra sorgente
const response = await fetch('http://0.0.0.0:8000/api/sources/mobile/register', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    source_id: 'mobile-123',
    rtmp_url: 'rtmp://server/live/stream'
  })
});
const result = await response.json();
console.log(result);
```

## Testing

### Swagger UI

La documentazione interattiva è disponibile su `/docs` e permette di:

- Visualizzare tutti gli endpoint
- Testare le chiamate direttamente dal browser
- Vedere esempi di request/response
- Provare autenticazione (se configurata)

### Postman

Importa la collection da `/docs/openapi.json`:

1. Vai su `/docs`
2. Scarica il file OpenAPI JSON
3. Importa in Postman

## Sicurezza

### Raccomandazioni

1. **HTTPS**: Usa sempre HTTPS in produzione
2. **CORS**: Configura CORS correttamente per domini specifici
3. **Rate Limiting**: Implementa rate limiting
4. **Input Validation**: Valida sempre gli input
5. **Authentication**: Implementa autenticazione per operazioni sensibili

### Headers di Sicurezza

Si consiglia di aggiungere:

- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `X-XSS-Protection: 1; mode=block`
- `Strict-Transport-Security: max-age=31536000`

## Supporto

Per problemi o domande:

1. Controlla la documentazione su `/docs`
2. Verifica i log: `docker logs ermes-backend`
3. Controlla lo stato: `GET /api/status`

