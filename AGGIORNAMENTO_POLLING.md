# Aggiornamento Automatico con Polling (Senza Webhook)

## ✅ Configurazione Polling Automatico

ERMES supporta aggiornamento automatico **senza webhook** usando polling periodico. Il sistema controlla periodicamente GitHub per nuovi commit e aggiorna automaticamente.

### Vantaggi rispetto al Webhook

- ✅ **Non serve configurare webhook su GitHub**
- ✅ **Funziona anche senza accesso pubblico al NAS**
- ✅ **Più semplice da configurare**
- ⚠️ **Non è istantaneo** (c'è un ritardo fino all'intervallo di polling)

### 1. Configurazione nel `.env`

Nel file `.env` sul NAS:

```env
# Abilita polling automatico
GITHUB_AUTO_UPDATE_ENABLED=true

# Repository GitHub (formato: username/repo)
GITHUB_REPO=Paluello/ERMES

# Branch da monitorare (default: main)
GITHUB_BRANCH=main

# Intervallo di polling in minuti (default: 5)
GITHUB_AUTO_UPDATE_INTERVAL_MINUTES=5

# Token GitHub (opzionale, ma consigliato per rate limit più alti)
GITHUB_TOKEN=ghp_tuo_token_qui
```

### 2. Come Funziona

Il sistema:
1. **Controlla GitHub ogni X minuti** (configurabile)
2. **Confronta l'SHA dell'ultimo commit** con quello locale
3. **Se trova un nuovo commit**, esegue automaticamente `update_container.sh`
4. **Riavvia il backend** con il nuovo codice

### 3. Genera Token GitHub (Opzionale ma Consigliato)

Per evitare rate limit dell'API GitHub:

1. Vai su: `https://github.com/settings/tokens`
2. Clicca **Generate new token (classic)**
3. Seleziona scopo: `public_repo` (se repo pubblico) o `repo` (se privato)
4. Copia il token e aggiungilo al `.env` come `GITHUB_TOKEN`

**Nota**: Senza token, GitHub limita a 60 richieste/ora per IP. Con token puoi fare fino a 5000 richieste/ora.

### 4. Riavvia il Container

Dopo aver configurato il `.env`, riavvia il backend:

```bash
docker compose -f docker-compose.github.nas.yml restart ermes-backend
```

Verifica nei log che il polling sia partito:

```bash
docker logs ermes-backend | grep -i "auto-updater"
```

Dovresti vedere:
```
✅ Auto-updater avviato: polling ogni 5 minuti
```

### 5. Verifica Stato Polling

Puoi controllare lo stato del polling tramite API:

```bash
curl http://localhost:8000/api/update/polling/status
```

Risposta esempio:
```json
{
  "enabled": true,
  "is_running": true,
  "repository": "Paluello/ERMES",
  "branch": "main",
  "poll_interval_minutes": 5,
  "last_commit_sha": "abc1234"
}
```

### 6. Forza Controllo Immediato

Puoi forzare un controllo immediato (utile per test):

```bash
curl -X POST http://localhost:8000/api/update/polling/check
```

### 7. Confronto: Polling vs Webhook

| Caratteristica | Polling | Webhook |
|----------------|---------|---------|
| Configurazione GitHub | ❌ Non necessaria | ✅ Richiesta |
| Aggiornamento istantaneo | ❌ Ritardo fino a intervallo | ✅ Istantaneo |
| Funziona senza IP pubblico | ✅ Sì | ❌ No |
| Rate limit GitHub | ⚠️ 60/h senza token | ✅ Illimitato |
| Complessità setup | ✅ Bassa | ⚠️ Media |

### 8. Intervalli Consigliati

- **Sviluppo attivo**: 2-5 minuti
- **Produzione normale**: 5-10 minuti
- **Produzione stabile**: 15-30 minuti

**Nota**: Intervalli troppo brevi (< 1 minuto) possono saturare le API GitHub.

### 9. Log e Debug

I log degli aggiornamenti sono in:

```bash
docker exec ermes-backend cat /tmp/ermes_update.log
```

Oppure:

```bash
docker logs ermes-backend | grep -i "update\|polling"
```

### 10. Disabilitare Polling

Per disabilitare temporaneamente senza modificare il `.env`:

```bash
# Modifica .env
GITHUB_AUTO_UPDATE_ENABLED=false

# Riavvia
docker compose -f docker-compose.github.nas.yml restart ermes-backend
```

## Troubleshooting

### Polling non parte

1. Verifica `.env`:
   ```bash
   docker exec ermes-backend env | grep GITHUB
   ```

2. Controlla log:
   ```bash
   docker logs ermes-backend | tail -50
   ```

3. Verifica che `GITHUB_REPO` sia nel formato corretto: `username/repo`

### Errori rate limit GitHub

- Aggiungi `GITHUB_TOKEN` al `.env`
- Aumenta `GITHUB_AUTO_UPDATE_INTERVAL_MINUTES` (es. 10-15 minuti)

### Aggiornamento non funziona

Controlla che lo script `update_container.sh` sia presente e eseguibile:

```bash
docker exec ermes-backend ls -la /app/update_container.sh
```

## Note Importanti

- Il polling funziona **solo se il container ha accesso a internet**
- Il primo controllo avviene dopo l'intervallo configurato (non immediatamente)
- Il polling si ferma quando il container viene fermato
- Gli aggiornamenti sono eseguiti in background e non bloccano l'API

