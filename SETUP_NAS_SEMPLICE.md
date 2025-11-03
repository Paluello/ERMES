# Guida Semplice: Setup ERMES sul NAS Ugreen

## Panoramica

Il NAS Ugreen può essere accessibile in diversi modi. Ti spiego i 3 metodi più semplici:

## Metodo 1: Via Interfaccia Web (PIÙ SEMPLICE)

### Passo 1: Trova l'IP del NAS

1. Accedi al NAS Ugreen dalla rete locale
2. Di solito l'IP è qualcosa come `192.168.1.XXX` o `10.0.0.XXX`
3. Puoi trovarlo:
   - Dall'app Ugreen sul telefono
   - Dalle impostazioni router
   - Oppure apri terminale Mac e digita: `ping ugreen.local` (se supportato)

### Passo 2: Accedi al NAS

1. Apri un browser sul Mac
2. Vai su: `http://<IP-DEL-NAS>` (es: `http://192.168.1.100`)
3. Fai login con le credenziali del NAS

### Passo 3: Crea Cartella ERMES

1. Cerca la sezione "File Manager" o "Condivisioni" nell'interfaccia web
2. Crea una nuova cartella chiamata `ERMES`
3. Tipicamente la trovi in: `/share/ERMES` o `/volume1/ERMES`

### Passo 4: Carica File

Dall'interfaccia web del NAS:
1. Vai nella cartella `ERMES` appena creata
2. Clicca "Upload" o "Carica File"
3. Carica questi file (dal tuo Mac):

**File da caricare:**
- `docker-compose.github.nas.yml`
- `backend/Dockerfile.github.nas` (crea cartella `backend` prima)
- `backend/nginx-rtmp.conf` (nella cartella `backend`)
- `deploy.sh`
- `update.sh`
- `.env.example` (poi lo rinominerai in `.env`)

**Struttura finale sul NAS:**
```
/share/ERMES/
├── docker-compose.github.nas.yml
├── backend/
│   ├── Dockerfile.github.nas
│   └── nginx-rtmp.conf
├── deploy.sh
├── update.sh
└── .env
```

### Passo 5: Configura .env

1. Dall'interfaccia web, apri il file `.env.example`
2. Modifica con il tuo repository GitHub:
   ```
   GITHUB_REPO=TUO-USERNAME/ERMES
   GITHUB_BRANCH=main
   GITHUB_TOKEN=
   ```
3. Salva come `.env` (rimuovi `.example`)

## Metodo 2: Via Finder (Mac) - Connessione SMB

### Passo 1: Connetti al NAS

1. Apri **Finder** sul Mac
2. Premi `Cmd+K` (o Vai → Connetti al Server)
3. Digita: `smb://<IP-DEL-NAS>` (es: `smb://192.168.1.100`)
4. Inserisci username e password del NAS
5. Si aprirà una finestra con le condivisioni del NAS

### Passo 2: Trova/Crea Cartella ERMES

1. Naviga nella condivisione principale (di solito chiamata `share` o `public`)
2. Crea cartella `ERMES` se non esiste
3. Apri la cartella `ERMES`

### Passo 3: Copia File

Dal Finder del Mac, trascina questi file nella cartella `ERMES` sul NAS:

**File da copiare:**
- `docker-compose.github.nas.yml`
- `deploy.sh`
- `update.sh`
- `.env.example`

Poi crea cartella `backend` dentro `ERMES` e copia:
- `backend/Dockerfile.github.nas`
- `backend/nginx-rtmp.conf`

### Passo 4: Configura .env

1. Sul NAS, rinomina `.env.example` in `.env`
2. Apri `.env` con TextEdit o altro editor
3. Modifica con il tuo repository GitHub

## Metodo 3: Via Terminale (SSH) - Per Utenti Avanzati

Se il NAS Ugreen supporta SSH:

### Passo 1: Connetti via SSH

```bash
# Sul Mac, apri Terminale
ssh admin@<IP-DEL-NAS>
# Esempio: ssh admin@192.168.1.100
```

### Passo 2: Crea Directory

```bash
mkdir -p /share/ERMES/backend
cd /share/ERMES
```

### Passo 3: Copia File (dal Mac)

Apri un **nuovo terminale** sul Mac e copia i file:

```bash
# Dal Mac, vai nella cartella ERMES
cd /Users/palu/Desktop/WEB/ERMES

# Copia file sul NAS (sostituisci IP)
scp docker-compose.github.nas.yml admin@<IP-NAS>:/share/ERMES/
scp deploy.sh admin@<IP-NAS>:/share/ERMES/
scp update.sh admin@<IP-NAS>:/share/ERMES/
scp .env.example admin@<IP-NAS>:/share/ERMES/.env
scp backend/Dockerfile.github.nas admin@<IP-NAS>:/share/ERMES/backend/
scp backend/nginx-rtmp.conf admin@<IP-NAS>:/share/ERMES/backend/
```

### Passo 4: Configura .env sul NAS

```bash
# Su NAS (via SSH)
cd /share/ERMES
nano .env  # oppure vi .env

# Modifica con:
GITHUB_REPO=TUO-USERNAME/ERMES
GITHUB_BRANCH=main
GITHUB_TOKEN=
```

## Dopo Aver Copiato i File

### Su NAS (via SSH o interfaccia web con terminale):

```bash
cd /share/ERMES  # o percorso dove hai copiato i file

# Rendi eseguibili gli script
chmod +x deploy.sh update.sh

# Prima installazione
./deploy.sh nas
```

Se non hai accesso SSH, dovrai usare l'interfaccia Docker del NAS (se disponibile).

## Come Trovare l'IP del NAS

### Opzione 1: App Ugreen

1. Apri app Ugreen sul telefono
2. Vai alle impostazioni del NAS
3. Trova "Indirizzo IP" o "Network"

### Opzione 2: Router

1. Accedi al router (di solito `192.168.1.1` o `192.168.0.1`)
2. Cerca "Dispositivi connessi" o "DHCP Client List"
3. Cerca dispositivo con nome tipo "Ugreen" o "NAS"

### Opzione 3: Terminale Mac

```bash
# Cerca dispositivi sulla rete
arp -a | grep -i ugreen

# Oppure prova ping
ping ugreen.local
```

## Verifica che Docker sia Installato sul NAS

### Via Interfaccia Web:

1. Cerca sezione "App" o "Container" o "Docker"
2. Se vedi Docker, è installato
3. Se non c'è, cerca "App Store" o "Marketplace" del NAS e installa Docker

### Via SSH:

```bash
docker --version
docker-compose --version
```

Se non è installato, consulta la documentazione NAS Ugreen per installare Docker.

## Troubleshooting

### "Non trovo la cartella share"

Su NAS Ugreen, le condivisioni possono essere in:
- `/share/`
- `/volume1/`
- `/mnt/HD/HD_a2/` (varia per modello)
- Controlla interfaccia web NAS per percorso esatto

### "Non posso accedere via SSH"

Alcuni NAS Ugreen non hanno SSH abilitato di default:
- Abilitalo dalle impostazioni NAS (sezione "SSH" o "Terminal")
- Oppure usa solo Metodo 1 o 2 (interfaccia web/Finder)

### "Docker non è installato"

NAS Ugreen potrebbe avere:
- Docker preinstallato
- Docker disponibile tramite app store
- Docker non supportato (modelli più vecchi)

Verifica documentazione del tuo modello specifico.

## Prossimi Passi

Una volta copiati i file sul NAS, vedi `SETUP_GITHUB.md` per configurare GitHub e avviare tutto.

