# Dockerfile per Backend ERMES
FROM python:3.11-slim

# Installa dipendenze sistema (ffmpeg per RTMP receiver)
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Crea directory lavoro
WORKDIR /app

# Copia requirements e installa dipendenze Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copia codice applicazione
COPY . .

# Esponi porta API
EXPOSE 8000

# Comando avvio
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

