# Dockerfile per Frontend ERMES
FROM node:18-alpine AS builder

WORKDIR /app

# Copia package files
COPY package*.json ./
COPY tsconfig.json ./
COPY vite.config.ts ./

# Installa dipendenze
RUN npm install

# Copia sorgenti e build
COPY src ./src
COPY index.html ./
RUN npm run build

# Stage produzione con nginx
FROM nginx:alpine

# Copia build files
COPY --from=builder /app/dist /usr/share/nginx/html

# Configurazione nginx per SPA
RUN echo 'server { \
    listen 80; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
    location /api { \
        proxy_pass http://ermes-backend:8000; \
    } \
    location /ws { \
        proxy_pass http://ermes-backend:8000; \
        proxy_http_version 1.1; \
        proxy_set_header Upgrade $http_upgrade; \
        proxy_set_header Connection "upgrade"; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

