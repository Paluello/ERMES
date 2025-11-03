# Fix File .env sul NAS

## Problema

Docker Compose non legge le variabili dal file `.env`. L'errore mostra che usa `your-username/ERMES` invece di `Paluello/ERMES`.

## Soluzione

### 1. Verifica File .env sul NAS

Sul NAS, esegui:

```bash
cd /volume1/docker/ERMES
cat .env
```

Dovresti vedere:
```
GITHUB_REPO=Paluello/ERMES
GITHUB_BRANCH=main
GITHUB_TOKEN=github_pat_...
```

### 2. Se il File Non Esiste o è Sbagliato

Crea/modifica il file `.env`:

```bash
cd /volume1/docker/ERMES
nano .env
```

Aggiungi/modifica con:

```bash
GITHUB_REPO=Paluello/ERMES
GITHUB_BRANCH=main
GITHUB_TOKEN=github_pat_IL_TUO_TOKEN_QUI
```

**IMPORTANTE:**
- ✅ **NON** spazi intorno al `=`
- ✅ **NON** virgolette
- ✅ **NON** spazi alla fine delle righe

### 3. Verifica Formato

Il file `.env` deve essere esattamente così (senza spazi extra):

```
GITHUB_REPO=Paluello/ERMES
GITHUB_BRANCH=main
GITHUB_TOKEN=github_pat_...
```

**ERRATO:**
```
GITHUB_REPO = Paluello/ERMES  ❌ (spazi intorno a =)
GITHUB_REPO="Paluello/ERMES"  ❌ (virgolette)
GITHUB_REPO=Paluello/ERMES    ❌ (spazi alla fine)
```

### 4. Test

Dopo aver corretto il file `.env`, verifica:

```bash
cd /volume1/docker/ERMES
source .env
echo "Repo: $GITHUB_REPO"
echo "Branch: $GITHUB_BRANCH"
```

Dovresti vedere:
```
Repo: Paluello/ERMES
Branch: main
```

### 5. Rebuild

Ora prova di nuovo:

```bash
sudo docker compose -f docker-compose.github.nas.yml build --no-cache
sudo docker compose -f docker-compose.github.nas.yml up -d
```

## Troubleshooting

### Docker Compose non legge .env

Se Docker Compose ancora non legge le variabili, puoi esportarle manualmente:

```bash
cd /volume1/docker/ERMES
export GITHUB_REPO=Paluello/ERMES
export GITHUB_BRANCH=main
export GITHUB_TOKEN=github_pat_...
sudo docker compose -f docker-compose.github.nas.yml build --no-cache
```

### Verifica Permessi File

```bash
ls -la .env
# Dovrebbe essere: -rw-r--r-- (644)
```

Se necessario:
```bash
chmod 644 .env
```

