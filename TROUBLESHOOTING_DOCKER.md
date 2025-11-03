# Troubleshooting Docker su NAS

## Problema: "docker-compose: command not found"

### Soluzione 1: Usa "docker compose" (senza trattino)

Su NAS moderni, Docker Compose è integrato in Docker e si usa così:

```bash
# Invece di:
docker-compose up -d

# Usa:
docker compose up -d
```

### Soluzione 2: Verifica Docker Installato

```bash
# Controlla Docker
docker --version

# Controlla Docker Compose (nuova sintassi)
docker compose version

# Se funziona, puoi usare direttamente:
docker compose -f docker-compose.github.nas.yml up -d
```

### Soluzione 3: Script Aggiornati

Gli script `deploy.sh` e `update.sh` sono stati aggiornati per gestire automaticamente entrambe le sintassi.

Se ottieni ancora errori, prova manualmente:

```bash
# Prova nuova sintassi
docker compose -f docker-compose.github.nas.yml build
docker compose -f docker-compose.github.nas.yml up -d

# Se non funziona, prova vecchia sintassi
docker-compose -f docker-compose.github.nas.yml build
docker-compose -f docker-compose.github.nas.yml up -d
```

## Comandi Alternativi Manuali

Se gli script non funzionano, puoi eseguire manualmente:

### 1. Build Immagine Backend

```bash
cd /volume1/docker/ERMES

# Con nuova sintassi
docker compose build --build-arg GITHUB_REPO=Paluello/ERMES --build-arg GITHUB_BRANCH=main -f docker-compose.github.nas.yml

# Con vecchia sintassi
docker-compose build --build-arg GITHUB_REPO=Paluello/ERMES --build-arg GITHUB_BRANCH=main -f docker-compose.github.nas.yml
```

### 2. Avvia Container

```bash
# Con nuova sintassi
docker compose -f docker-compose.github.nas.yml up -d

# Con vecchia sintassi
docker-compose -f docker-compose.github.nas.yml up -d
```

### 3. Verifica Stato

```bash
# Controlla container
docker ps

# Log backend
docker logs ermes-backend

# Log RTMP
docker logs ermes-rtmp
```

## Installare Docker Compose (se mancante)

### Su NAS Ugreen con sistema Linux:

```bash
# Scarica docker-compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Rendi eseguibile
chmod +x /usr/local/bin/docker-compose

# Verifica
docker-compose --version
```

**Nota**: Su molti NAS moderni, Docker Compose è integrato e non serve installarlo separatamente.

## Verifica Setup

Esegui questi comandi per verificare che tutto sia OK:

```bash
# 1. Docker installato?
docker --version

# 2. Docker Compose disponibile?
docker compose version || docker-compose --version

# 3. Docker daemon in esecuzione?
docker ps

# 4. Spazio disco disponibile?
df -h

# 5. Memoria disponibile?
free -h
```

## Link Utili

- Documentazione Docker Compose: https://docs.docker.com/compose/
- Docker Compose V2 (nuova sintassi): https://docs.docker.com/compose/compose-v2/

