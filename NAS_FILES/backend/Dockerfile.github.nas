# Dockerfile GitHub ottimizzato per NAS ARM
FROM python:3.11-slim

RUN apt-get update && apt-get install -y \
    git \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ARG GITHUB_REPO=your-username/ERMES
ARG GITHUB_BRANCH=main
ARG GITHUB_TOKEN=

RUN if [ -n "$GITHUB_TOKEN" ]; then \
        git clone https://${GITHUB_TOKEN}@github.com/${GITHUB_REPO}.git . ; \
    else \
        git clone https://github.com/${GITHUB_REPO}.git . ; \
    fi && \
    git checkout ${GITHUB_BRANCH} && \
    cd backend && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install opencv-python-headless

WORKDIR /app/backend

ENV PYTHONUNBUFFERED=1
ENV OMP_NUM_THREADS=2

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]

