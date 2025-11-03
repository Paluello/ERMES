# Fix Permessi Docker su NAS

## Problema: "permission denied while trying to connect to the Docker daemon socket"

Questo errore significa che il tuo utente non ha i permessi per usare Docker.

## Soluzione 1: Aggiungi Utente al Gruppo Docker (Raccomandato)

```bash
# Aggiungi il tuo utente al gruppo docker
sudo usermod -aG docker $USER

# Verifica che sia stato aggiunto
groups $USER

# IMPORTANTE: Fai logout e login di nuovo per applicare i cambiamenti
# Oppure esegui:
newgrp docker
```

Dopo logout/login, prova di nuovo:
```bash
./deploy.sh nas
```

## Soluzione 2: Usa Sudo (Temporaneo)

Se non puoi modificare i gruppi, puoi usare sudo:

```bash
# Modifica manualmente deploy.sh per aggiungere sudo
# Oppure esegui direttamente:

sudo docker compose -f docker-compose.github.nas.yml build
sudo docker compose -f docker-compose.github.nas.yml up -d
```

**Nota**: Con sudo, i file creati potrebbero avere permessi root. Dopo potresti dover fare:
```bash
sudo chown -R $USER:$USER /volume1/docker/ERMES
```

## Soluzione 3: Verifica Gruppo Docker

```bash
# Controlla se gruppo docker esiste
getent group docker

# Controlla se sei nel gruppo
groups | grep docker

# Se non sei nel gruppo, aggiungiti (richiede sudo)
sudo usermod -aG docker $USER
```

## Soluzione 4: Permessi Socket Docker (Alternativa)

Se non puoi aggiungere al gruppo, puoi cambiare permessi socket (meno sicuro):

```bash
# NON RACCOMANDATO, ma funziona
sudo chmod 666 /var/run/docker.sock
```

## Verifica Setup

Dopo aver applicato una soluzione:

```bash
# Test senza sudo
docker ps

# Se funziona, procedi con:
./deploy.sh nas
```

## Troubleshooting NAS Ugreen Specifico

Su alcuni NAS Ugreen:
- L'utente potrebbe essere già nel gruppo docker ma serve logout/login
- Potrebbe servire riavviare il servizio Docker
- Controlla interfaccia web NAS per permessi utente

## Comandi Utili

```bash
# Chi è proprietario del socket Docker?
ls -l /var/run/docker.sock

# Chi può usare Docker?
getent group docker

# Riavvia servizio Docker (se possibile)
sudo systemctl restart docker
# oppure
sudo service docker restart
```

## Dopo Fix Permessi

Una volta risolto, lo script `deploy.sh` dovrebbe funzionare senza problemi!

