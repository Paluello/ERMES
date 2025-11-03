# 🚀 Quick Start NAS - Guida Super Semplice

## Primo Passo: Prepara i File

Sul tuo **Mac**, nella cartella ERMES, esegui:

```bash
./prepara_nas.sh
```

Questo crea una cartella `NAS_FILES` con solo i file necessari.

## Secondo Passo: Trova il NAS

### Opzione A: Via App Ugreen (Telefono)

1. Apri app Ugreen sul telefono
2. Guarda l'**IP Address** del NAS (es: `192.168.1.100`)

### Opzione B: Via Router

1. Apri browser, vai su `192.168.1.1` (o IP del router)
2. Cerca "Dispositivi connessi"
3. Trova dispositivo "Ugreen" o "NAS"

## Terzo Passo: Copia File sul NAS

### Metodo 1: Trascina e Rilascia (PIÙ SEMPLICE)

1. Apri **Finder** sul Mac
2. Premi `Cmd+K` (oppure Vai → Connetti al Server)
3. Digita: `smb://192.168.1.XXX` (sostituisci con IP del tuo NAS)
4. Inserisci username/password del NAS
5. Si apre una finestra: trascina la cartella `NAS_FILES` dentro

### Metodo 2: Interfaccia Web NAS

1. Apri browser, vai su `http://192.168.1.XXX` (IP del NAS)
2. Login al NAS
3. Vai a "File Manager" o "Condivisioni"
4. Crea cartella `ERMES`
5. Carica tutti i file dalla cartella `NAS_FILES`

## Quarto Passo: Configura .env

Sul NAS, apri il file `.env` e modifica:

```
GITHUB_REPO=TUO-USERNAME/ERMES
GITHUB_BRANCH=main
GITHUB_TOKEN=
```

Sostituisci `TUO-USERNAME` con il tuo username GitHub.

## Quinto Passo: Avvia ERMES

### Se hai accesso SSH al NAS:

```bash
ssh admin@<IP-NAS>
cd /share/ERMES  # o dove hai copiato i file
chmod +x deploy.sh update.sh
./deploy.sh nas
```

### Se NON hai SSH:

Usa l'interfaccia Docker del NAS (se disponibile):
1. Vai a interfaccia web NAS
2. Cerca sezione "Docker" o "Container"
3. Crea nuovo stack/compose con `docker-compose.github.nas.yml`

## ⚠️ Problemi Comuni

**"Non trovo il NAS"**
- Assicurati che NAS e Mac siano sulla stessa rete WiFi/Ethernet
- Prova a cercare "ugreen.local" nel Finder

**"Non posso accedere via SSH"**
- Alcuni NAS non hanno SSH. Usa interfaccia web Docker se disponibile
- Oppure chiedi supporto Ugreen per abilitare SSH

**"Docker non è installato"**
- Cerca "Docker" nell'app store del NAS
- O installa tramite interfaccia web NAS (sezione App/Marketplace)

## 📞 Serve Aiuto?

Se sei bloccato:
1. Leggi `SETUP_NAS_SEMPLICE.md` per più dettagli
2. Verifica documentazione del tuo modello NAS Ugreen
3. Controlla che Docker sia installato sul NAS

