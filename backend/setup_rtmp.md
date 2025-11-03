# Setup Server RTMP per ERMES

## Opzione 1: nginx-rtmp (Raccomandato)

### Installazione

**macOS:**
```bash
brew install nginx-full
# oppure
brew tap denji/nginx
brew install nginx-full
```

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install nginx libnginx-mod-rtmp
```

**CentOS/RHEL:**
```bash
sudo yum install epel-release
sudo yum install nginx
# RTMP module richiede compilazione custom
```

### Configurazione

1. Copia `nginx-rtmp.conf` nella directory configurazione nginx:
   ```bash
   # macOS
   sudo cp nginx-rtmp.conf /opt/homebrew/etc/nginx/nginx.conf
   
   # Linux
   sudo cp nginx-rtmp.conf /etc/nginx/nginx.conf
   ```

2. Avvia nginx:
   ```bash
   # macOS
   brew services start nginx-full
   
   # Linux
   sudo systemctl start nginx
   ```

3. Verifica che nginx sia in ascolto sulla porta 1935:
   ```bash
   netstat -an | grep 1935
   # o
   lsof -i :1935
   ```

### Test

Testa con ffmpeg:
```bash
ffmpeg -re -i test_video.mp4 -c copy -f flv rtmp://localhost:1935/stream/test123
```

## Opzione 2: SRS (Simple Realtime Server)

### Installazione

```bash
# Compila da sorgente
git clone https://github.com/ossrs/srs.git
cd srs/trunk
./configure
make
sudo make install
```

### Configurazione

Crea `/usr/local/srs/conf/ermes.conf`:
```
listen              1935;
max_connections     1000;
srs_log_tank        file;
srs_log_file        ./objs/srs.log;

http_api {
    enabled         on;
    listen          1985;
}

rtc_server {
    enabled on;
    listen 8000;
}

vhost __defaultVhost__ {
    rtmp {
        enabled     on;
    }
}
```

### Avvio

```bash
/usr/local/srs/objs/srs -c /usr/local/srs/conf/ermes.conf
```

## Opzione 3: Integrazione Python con aiortc/pyav

### Installazione

```bash
pip install aiortc av
```

### Utilizzo

Il modulo `app/rtmp/rtmp_receiver.py` usa ffmpeg per ricevere stream RTMP.
Assicurati che ffmpeg sia installato:

```bash
# macOS
brew install ffmpeg

# Ubuntu/Debian
sudo apt-get install ffmpeg

# CentOS/RHEL
sudo yum install ffmpeg
```

## Integrazione con Backend ERMES

Il backend ERMES usa automaticamente `RTMPStreamReceiver` quando una sorgente mobile
registra un URL RTMP. Lo stream viene convertito in frame OpenCV per l'elaborazione.

### Esempio Utilizzo

```python
from app.sources.source_manager import SourceManager

source_manager = SourceManager()

# Registra telefono mobile con URL RTMP
source_manager.register_mobile_phone(
    source_id="phone_001",
    video_url="rtmp://localhost:1935/stream/phone_001"
)

# Il video stream è ora disponibile per l'orchestratore
```

## Troubleshooting

### Porta 1935 già in uso
```bash
# Trova processo che usa la porta
lsof -i :1935
# Kill processo
kill -9 <PID>
```

### Firewall blocca RTMP
Apri porta 1935:
```bash
# macOS
sudo pfctl -f /etc/pf.conf

# Linux (ufw)
sudo ufw allow 1935/tcp

# Linux (iptables)
sudo iptables -A INPUT -p tcp --dport 1935 -j ACCEPT
```

### Test connessione RTMP
```bash
# Usa rtmpdump o ffmpeg per testare
ffmpeg -re -i test.mp4 -c copy -f flv rtmp://your-server:1935/stream/test
```

