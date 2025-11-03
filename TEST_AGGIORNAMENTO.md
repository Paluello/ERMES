# Guida Test Aggiornamento ERMES

## 1. Push delle Modifiche su GitHub

Sul Mac, prima di tutto pusha tutte le modifiche:

```bash
cd /Users/palu/Desktop/WEB/ERMES
git add .
git commit -m "Ottimizzato sistema aggiornamento: git clone/pull + restart veloce"
git push
```

## 2. Aggiorna il NAS (Prima Volta)

Sul NAS, aggiorna il container con le nuove modifiche:

```bash
cd /volume1/docker/ERMES
sudo docker compose -f docker-compose.github.nas.yml build --no-cache ermes-backend
sudo docker compose -f docker-compose.github.nas.yml up -d
```

**Nota:** Questa volta farà rebuild completo (è normale). Le prossime volte sarà veloce!

## 3. Verifica che l'API Funzioni

Sul NAS:

```bash
# Test endpoint status
curl http://localhost:8000/api/status

# Dovresti vedere:
# {"status":"running","version":"0.1.0",...}
```

## 4. Test Aggiornamento Manuale da Swagger UI

1. **Apri il browser** e vai su: `http://100.84.46.19:8000/docs`

2. **Cerca l'endpoint** `/api/update/trigger` nella lista

3. **Clicca su "Try it out"**

4. **Clicca su "Execute"**

5. **Dovresti vedere una risposta:**
   ```json
   {
     "success": true,
     "message": "Aggiornamento avviato in background",
     "process_id": 123,
     "note": "Controlla i log con: docker logs ermes-backend | grep update"
   }
   ```

## 5. Verifica i Log dell'Aggiornamento

Sul NAS, controlla i log per vedere cosa sta succedendo:

```bash
# Log dello script di aggiornamento
sudo docker exec ermes-backend cat /tmp/ermes_update.log

# Oppure log del backend (filtra per "update")
sudo docker logs ermes-backend | grep -i update

# Log completi dell'ultimo aggiornamento
sudo docker logs ermes-backend --tail 50
```

**Cosa aspettarsi nei log:**
- ✅ "Codice Python montato come volume - aggiornamento veloce possibile!"
- ✅ "Clone da GitHub..." o "git pull..."
- ✅ "Riavvio backend con nuovo codice (nessun rebuild necessario)..."
- ✅ "Aggiornamento veloce completato (solo restart ~5 secondi, nessun rebuild)"

## 6. Verifica Stato Aggiornamento

Puoi anche usare l'endpoint `/api/update/status`:

```bash
curl http://localhost:8000/api/update/status
```

## 7. Test Completo: Modifica + Aggiornamento

1. **Sul Mac**, fai una piccola modifica (es. commento nel codice):
   ```bash
   # Modifica un file qualsiasi, es. backend/app/api/routes.py
   # Aggiungi un commento: # Test aggiornamento
   ```

2. **Push su GitHub:**
   ```bash
   git add .
   git commit -m "Test aggiornamento veloce"
   git push
   ```

3. **Sul NAS**, usa il pulsante in `/docs` o:
   ```bash
   curl -X POST http://localhost:8000/api/update/trigger
   ```

4. **Controlla i log** - dovrebbe essere veloce (~10-20 secondi invece di 5 minuti)

5. **Verifica che la modifica sia presente:**
   ```bash
   # Entra nel container
   sudo docker exec -it ermes-backend bash
   
   # Verifica il file modificato
   cat /app/backend/app/api/routes.py | grep "Test aggiornamento"
   ```

## Troubleshooting

### Se l'aggiornamento continua a fare rebuild completo:

1. **Verifica che il volume sia montato:**
   ```bash
   sudo docker exec ermes-backend ls -la /app/backend/app
   ```

2. **Verifica che la directory sul NAS esista:**
   ```bash
   ls -la /volume1/docker/ERMES/backend/app
   ```

3. **Controlla i log per vedere perché non funziona:**
   ```bash
   sudo docker exec ermes-backend cat /tmp/ermes_update.log
   ```

### Se git clone fallisce:

1. **Verifica GITHUB_REPO nel .env:**
   ```bash
   cat /volume1/docker/ERMES/.env | grep GITHUB_REPO
   ```

2. **Se necessario, aggiungi nel .env:**
   ```bash
   GITHUB_REPO=Paluello/ERMES
   GITHUB_BRANCH=main
   GITHUB_TOKEN=il-tuo-token-se-necessario
   ```

### Se il container non si riavvia:

```bash
# Controlla lo stato
sudo docker ps | grep ermes-backend

# Riavvia manualmente se necessario
sudo docker compose -f docker-compose.github.nas.yml restart ermes-backend
```

## Tempi Attesi

- **Prima volta (rebuild completo):** ~5 minuti
- **Aggiornamenti successivi (veloce):** ~10-20 secondi
  - Git clone/pull: ~5-10 secondi
  - Restart container: ~5 secondi

## Successo!

Se vedi nei log "Aggiornamento veloce completato (solo restart ~5 secondi, nessun rebuild)", significa che tutto funziona perfettamente! 🎉
