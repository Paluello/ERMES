# Aggiornamento Automatico via Webhook GitHub

## ✅ Configurazione Semplice

ERMES supporta aggiornamento automatico quando fai push su GitHub. **Non serve git sul NAS!**

### 1. Abilita il Webhook

Nel file `.env` sul NAS:
```env
GITHUB_WEBHOOK_ENABLED=true
GITHUB_WEBHOOK_SECRET=il-tuo-secret-qui
```

Genera un secret sicuro:
```bash
openssl rand -hex 32
```

### 2. Configura GitHub

1. Vai su: `https://github.com/TUO-USERNAME/ERMES/settings/hooks`
2. Clicca **Add webhook**
3. Compila:
   - **Payload URL**: `http://TUO-NAS-IP:8000/api/webhook/github`
   - **Content type**: `application/json`
   - **Secret**: (lo stesso del `.env`)
   - **Events**: Solo `push`
4. Salva

### 3. Funziona!

Ora ogni volta che fai `git push` su GitHub, il NAS si aggiorna automaticamente:
- ✅ Scarica codice da GitHub (ZIP, senza git)
- ✅ Copia file nella directory montata
- ✅ Riavvia backend (~10 secondi)

## Come Funziona

Lo script `update_container.sh`:
1. Scarica ZIP da GitHub usando `curl` o `wget`
2. Estrae archivio con `unzip` o `7z`
3. Copia solo `backend/app/` nella directory montata
4. Riavvia il container backend

**Nessun rebuild necessario** perché il codice è montato come volume!

## Fallback Automatico

Se `curl`/`wget` o `unzip` non sono disponibili, lo script fa automaticamente:
- Rebuild completo del container (che scarica da GitHub durante il build)

## Verifica

Dopo un push, controlla i log:
```bash
sudo docker exec ermes-backend cat /tmp/ermes_update.log
```

Dovresti vedere:
```
✅ Aggiornamento completato! (veloce, ~10 secondi)
```

## Test Manuale

Puoi testare il webhook manualmente:
```bash
curl -X POST http://localhost:8000/api/webhook/github \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: push" \
  -d '{"ref":"refs/heads/main","head_commit":{"id":"abc123"}}'
```

