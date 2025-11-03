# Quick Start con Docker

## Setup Rapido

### 1. Clona/Copia progetto ERMES

```bash
cd /path/to/nas/storage
# Copia cartella ERMES qui
```

### 2. Avvia con Docker Compose

**Per NAS standard:**
```bash
cd ERMES
docker-compose up -d
```

**Per NAS meno potenti (ARM, risorse limitate):**
```bash
cd ERMES
docker-compose -f docker-compose.nas.yml up -d
```

### 3. Verifica

```bash
# Controlla container
docker ps

# Dovresti vedere:
# - ermes-backend (porta 8000)
# - ermes-rtmp (porta 1935)
```

### 4. Accedi ai Servizi

- Backend: `http://<IP-NAS>:8000`
- API Docs: `http://<IP-NAS>:8000/docs`
- RTMP: `rtmp://<IP-NAS>:1935`

### 5. Configura App iOS

Nell'app EVA:
- URL Backend: `http://<IP-NAS>:8000`
- Streaming partirà automaticamente su RTMP

## Comandi Utili

```bash
# Ferma tutto
docker-compose down

# Riavvia
docker-compose restart

# Log in tempo reale
docker-compose logs -f

# Rimuovi tutto (ATTENZIONE: cancella dati)
docker-compose down -v
```

## Problemi Comuni

**Porta già in uso:**
- Cambia porte in `docker-compose.yml` (es: "8001:8000")

**Out of memory:**
- Usa `docker-compose.nas.yml` che limita risorse

**Container non si avvia:**
- Controlla log: `docker logs ermes-backend`
- Verifica spazio: `df -h`

Per più dettagli, vedi `SETUP_NAS.md`.

