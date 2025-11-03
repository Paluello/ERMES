# Configurazione Webhook GitHub per Auto-Deploy

Questo documento spiega come configurare il webhook GitHub per aggiornare automaticamente ERMES sul NAS quando fai un push su GitHub.

## Come Funziona

1. **Push su GitHub** → GitHub invia una notifica HTTP al tuo NAS
2. **Endpoint webhook** → Il backend ERMES riceve la notifica
3. **Auto-aggiornamento** → Il container si ricostruisce e si riavvia automaticamente con il nuovo codice

## Prerequisiti

- ✅ ERMES già installato e funzionante sul NAS
- ✅ Backend API accessibile da internet (porta 8000)
- ✅ Docker socket montato nel container (già configurato nel docker-compose)

## Configurazione

### 1. Abilita il Webhook nel Backend

Sul NAS, modifica il file `.env` nella directory del progetto:

```bash
cd /volume1/docker/ERMES
nano .env
```

Aggiungi queste righe:

```env
# Webhook GitHub (opzionale ma consigliato per sicurezza)
GITHUB_WEBHOOK_ENABLED=true
GITHUB_WEBHOOK_SECRET=il-tuo-secret-super-segredo-qui
```

**Genera un secret sicuro:**
```bash
openssl rand -hex 32
```

**⚠️ IMPORTANTE:** Salva questo secret, lo userai anche su GitHub!

### 2. Configura il Webhook su GitHub

1. Vai sul tuo repository GitHub: `https://github.com/TUO-USERNAME/ERMES`

2. Vai su **Settings** → **Webhooks** → **Add webhook**

3. Compila il form:
   - **Payload URL**: `http://TUO-NAS-IP:8000/api/webhook/github`
     - Esempio: `http://100.84.46.19:8000/api/webhook/github`
     - Se il NAS è dietro un router, usa l'IP pubblico o configura port forwarding
   
   - **Content type**: `application/json`
   
   - **Secret**: Incolla lo stesso secret che hai messo nel `.env` del NAS
   
   - **Which events**: Seleziona **"Just the push event"**
   
   - **Active**: ✅ Spuntato

4. Clicca **Add webhook**

### 3. Test del Webhook

Dopo aver configurato il webhook, GitHub invierà immediatamente un test. Puoi verificare:

- Su GitHub: Vai su **Settings** → **Webhooks** → Clicca sul webhook → Vedi **Recent Deliveries**
- Sul NAS: Controlla i log del backend:
  ```bash
  sudo docker logs ermes-backend
  ```

### 4. Verifica che il Socket Docker sia Montato

Il webhook funziona solo se il socket Docker è montato nel container. Verifica nel `docker-compose.github.nas.yml`:

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock:ro
```

Se non c'è, aggiungilo e riavvia il container.

## Test Manuale

Puoi testare il webhook manualmente:

```bash
# Simula un push event da GitHub
curl -X POST http://localhost:8000/api/webhook/github \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: push" \
  -H "X-Hub-Signature-256: sha256=$(echo -n '{"ref":"refs/heads/main"}' | openssl dgst -sha256 -hmac 'il-tuo-secret' | cut -d' ' -f2)" \
  -d '{"ref":"refs/heads/main","head_commit":{"id":"abc123"}}'
```

## Come Funziona l'Aggiornamento

Quando GitHub invia il webhook:

1. ✅ Il backend verifica la signature (se configurata)
2. ✅ Verifica che sia un evento `push` sul branch `main` o `master`
3. ✅ Esegue lo script `/app/update_container.sh` in background
4. ✅ Lo script esegue `docker compose build --no-cache ermes-backend`
5. ✅ Lo script esegue `docker compose restart ermes-backend`
6. ✅ Il nuovo container viene avviato con il codice più recente da GitHub

## Log degli Aggiornamenti

Gli aggiornamenti vengono loggati in:
- `/tmp/ermes_update.log` (dentro il container)
- Log del backend: `sudo docker logs ermes-backend`

## Troubleshooting

### Webhook non funziona

1. **Verifica che il webhook sia abilitato:**
   ```bash
   # Nel .env del NAS
   GITHUB_WEBHOOK_ENABLED=true
   ```

2. **Verifica che il backend sia accessibile:**
   ```bash
   curl http://TUO-NAS-IP:8000/api/status
   ```

3. **Controlla i log:**
   ```bash
   sudo docker logs ermes-backend | grep webhook
   ```

4. **Verifica che Docker socket sia montato:**
   ```bash
   sudo docker exec ermes-backend ls -la /var/run/docker.sock
   ```

### Errore: "Docker non disponibile nel container"

Il socket Docker non è montato. Aggiungi nel `docker-compose.github.nas.yml`:

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock:ro
```

Poi riavvia:
```bash
sudo docker compose -f docker-compose.github.nas.yml down
sudo docker compose -f docker-compose.github.nas.yml up -d
```

### Errore: "Signature non valida"

- Verifica che il secret nel `.env` del NAS corrisponda a quello su GitHub
- Il secret deve essere identico!

### Webhook ricevuto ma nessun aggiornamento

Controlla i log dello script:
```bash
sudo docker exec ermes-backend cat /tmp/ermes_update.log
```

## Sicurezza

⚠️ **IMPORTANTE:**

1. **Usa sempre un secret** per proteggere il webhook
2. **Non esporre la porta 8000 pubblicamente** senza autenticazione
3. Considera di usare HTTPS invece di HTTP (richiede certificato SSL)
4. Il webhook accetta solo push su `main` o `master` per sicurezza

## Disabilitare il Webhook

Per disabilitare temporaneamente:

Nel `.env` del NAS:
```env
GITHUB_WEBHOOK_ENABLED=false
```

Poi riavvia il backend:
```bash
sudo docker compose -f docker-compose.github.nas.yml restart ermes-backend
```

