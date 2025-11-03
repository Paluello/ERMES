# Dockerfile ottimizzato per NAS (ARM architecture)
FROM python:3.11-slim

# Installa dipendenze sistema minime
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Installa dipendenze Python (usa cache se possibile)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Installa OpenCV precompilato (più veloce su ARM)
RUN pip install opencv-python-headless

# Copia codice
COPY . .

# Variabili ambiente per ottimizzazione
ENV PYTHONUNBUFFERED=1
ENV OMP_NUM_THREADS=2  # Limita thread OpenMP per non sovraccaricare NAS

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]

