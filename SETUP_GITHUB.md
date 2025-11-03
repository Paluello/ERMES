# Setup ERMES da GitHub su NAS

## Prerequisiti

1. **Repository GitHub** con codice ERMES
2. **NAS con Docker** installato
3. **Accesso SSH** al NAS (o terminale)

## Setup Iniziale

### 1. Crea Repository GitHub

Se non hai ancora un repository:

```bash
# Sul tuo Mac/PC locale
cd /Users/palu/Desktop/WEB/ERMES
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/TUO-USERNAME/ERMES.git
git push -u origin main
```

### 2. Configurazione sul NAS

Crea una directory sul NAS e configura:

```bash
# Su NAS (via SSH)
mkdir -p /share/ERMES
cd /share/ERMES

# Crea file .env
cat > .env << EOF
GITHUB_REPO=TUO-USERNAME/ERMES
GITHUB_BRANCH=main
GITHUB_TOKEN=
EOF

# Modifica TUO-USERNAME con il tuo username GitHub
nano .env  # o usa editor preferito
```

**Per repository privati**, crea un token GitHub:
1. Vai su https://github.com/settings/tokens
2. Genera nuovo token (classic) con permessi `repo`
3. Aggiungi al `.env`: `GITHUB_TOKEN=ghp_tuo_token_qui`

### 3. Copia File Necessari sul NAS

Sul NAS, hai bisogno solo di questi file:
- `docker-compose.github.yml` (o `docker-compose.github.nas.yml`)
- `backend/Dockerfile.github` (o `backend/Dockerfile.github.nas`)
- `backend/nginx-rtmp.conf`
- `.env` (configurato)
- `deploy.sh` e `update.sh` (script)

Puoi copiarli manualmente o clonare solo questi file:

```bash
# Sul NAS
cd /share/ERMES

# Crea struttura directory
mkdir -p backend

# Scarica file necessari da GitHub (sostituisci URL)
curl -o docker-compose.github.nas.yml https://raw.githubusercontent.com/TUO-USERNAME/ERMES/main/docker-compose.github.nas.yml
curl -o backend/Dockerfile.github.nas https://raw.githubusercontent.com/TUO-USERNAME/ERMES/main/backend/Dockerfile.github.nas
curl -o backend/nginx-rtmp.conf https://raw.githubusercontent.com/TUO-USERNAME/ERMES/main/backend/nginx-rtmp.conf
curl -o deploy.sh https://raw.githubusercontent.com/TUO-USERNAME/ERMES/main/deploy.sh
curl -o update.sh https://raw.githubusercontent.com/TUO-USERNAME/ERMES/main/update.sh

# Rendi eseguibili gli script
chmod +x deploy.sh update.sh
```

### 4. Prima Installazione

```bash
cd /share/ERMES

# Per NAS standard
./deploy.sh

# Per NAS ARM/ottimizzato
./deploy.sh nas
```

Lo script:
1. Clona il repository da GitHub
2. Builda le immagini Docker
3. Avvia i container

## Aggiornamenti

### Aggiornamento Completo (Rebuild)

Quando vuoi aggiornare tutto da GitHub:

```bash
cd /share/ERMES
./deploy.sh nas  # o ./deploy.sh per versione standard
```

### Aggiornamento Rapido (Solo Codice)

Per aggiornare solo il codice senza rebuild completo:

```bash
cd /share/ERMES
./update.sh nas  # o ./update.sh
```

### Aggiornamento Manuale

```bash
cd /share/ERMES

# Rebuild backend (scarica nuovo codice)
docker-compose -f docker-compose.github.nas.yml build --no-cache ermes-backend

# Riavvia
docker-compose -f docker-compose.github.nas.yml restart ermes-backend
```

## Workflow Consigliato

### Sviluppo Locale → GitHub → NAS

1. **Sviluppa sul Mac/PC:**
   ```bash
   cd /Users/palu/Desktop/WEB/ERMES
   # Fai modifiche...
   git add .
   git commit -m "Descrizione modifiche"
   git push
   ```

2. **Sul NAS, aggiorna:**
   ```bash
   ssh nas-ugreen
   cd /share/ERMES
   ./update.sh nas
   ```

### Branch Diversi

Per testare branch diversi:

```bash
# Modifica .env
GITHUB_BRANCH=develop

# Rebuild
./deploy.sh nas
```

## Verifica Stato

```bash
# Container in esecuzione
docker ps

# Log backend
docker logs -f ermes-backend

# Stato servizi
docker-compose -f docker-compose.github.nas.yml ps
```

## Vantaggi Setup GitHub

✅ **Codice sempre aggiornato** - Pull diretto da GitHub  
✅ **Versionamento** - Traccia tutte le modifiche  
✅ **Rollback facile** - Cambia branch/tag per tornare indietro  
✅ **Collaborazione** - Più persone possono contribuire  
✅ **Backup automatico** - Codice salvato su GitHub  

## Troubleshooting

### Errore: Repository non trovato

- Verifica `GITHUB_REPO` nel `.env`
- Formato corretto: `username/repo-name` (senza `https://github.com/`)

### Errore: Permission denied (repo privato)

- Crea token GitHub con permessi `repo`
- Aggiungi `GITHUB_TOKEN` al `.env`

### Errore: Branch non trovato

- Verifica che il branch esista su GitHub
- Controlla `GITHUB_BRANCH` nel `.env`

### Cache Docker vecchia

```bash
# Pulisci cache e rebuild
docker system prune -a
./deploy.sh nas
```

## Automazione (Opzionale)

Puoi automatizzare aggiornamenti con cron:

```bash
# Aggiungi a crontab (aggiorna ogni giorno alle 3 AM)
crontab -e

# Aggiungi:
0 3 * * * cd /share/ERMES && ./update.sh nas >> /var/log/ermes-update.log 2>&1
```

## Note Importanti

- **Il codice viene clonato durante il build**, non viene montato come volume
- **Modifiche locali sul NAS** vengono perse al rebuild (usa GitHub!)
- **Volume `ermes-models`** persiste tra rebuild (cache modelli YOLO)
- **Config nginx** può essere modificato localmente (montato come volume)

