#!/bin/bash

# 1. Aggiornamento sistema e installazione dipendenze
apt update && apt upgrade -y
apt install -y curl gnupg lsb-release

# 2. Installazione Docker (metodo ufficiale)
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# 3. Creazione struttura cartelle per i dati
# Usiamo /data come base per tutti i tuoi file media
mkdir -p /opt/docker-files
mkdir -p /data/booklore
mkdir -p /data/pigeonpod
mkdir -p /data/filebrowser_config

# 4. Creazione del file Docker Compose
cat <<EOF > /opt/docker-files/docker-compose.yml
services:
  filebrowser:
    image: filebrowser/filebrowser:latest
    container_name: filebrowser
    ports:
      - "10001:80"
    volumes:
      - /data:/srv
      - /data/filebrowser_config/database.db:/database.db
    environment:
      - PUID=0
      - PGID=0
    restart: unless-stopped

  pigeonpod:
    image: pigeonpod/pigeonpod:latest
    container_name: pigeonpod
    ports:
      - "10002:8000"
    volumes:
      - /data/pigeonpod:/app/data
    restart: unless-stopped

  booklore:
    image: booklore/booklore:latest
    container_name: booklore
    ports:
      - "10003:3000"
    volumes:
      - /data/booklore:/app/data
    restart: unless-stopped

  dockwatch:
    image: not522/dockwatch:latest
    container_name: dockwatch
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    restart: unless-stopped

  portainer_agent:
    image: portainer/agent:latest
    container_name: portainer_agent
    ports:
      - "9001:9001"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/docker/volumes:/var/lib/docker/volumes
    restart: unless-stopped
EOF

# 5. Avvio dei servizi
cd /opt/docker-files
docker compose up -d

echo "------------------------------------------------"
echo "Installazione completata con successo!"
echo "Filebrowser: http://$(hostname -I | awk '{print $1}'):10001"
echo "Pigeonpod:   http://$(hostname -I | awk '{print $1}'):10002"
echo "Booklore:    http://$(hostname -I | awk '{print $1}'):10003"
echo "Portainer Agent attivo sulla porta 9001"
echo "------------------------------------------------"
