#!/bin/bash

# 1. Aggiornamento sistema e installazione dipendenze
apt update && apt upgrade -y
apt install -y curl gnupg lsb-release

# 2. Installazione Docker (metodo ufficiale)
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
fi

# 3. Creazione struttura cartelle per i dati
mkdir -p /opt/docker-files
mkdir -p /data/booklore
mkdir -p /data/pigeonpod/audio
mkdir -p /data/pigeonpod/video
mkdir -p /data/pigeonpod/cover
mkdir -p /data/filebrowser_config
mkdir -p /home/dockwatch/config
touch /data/filebrowser_config/database.db

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
    image: 'ghcr.io/aizhimou/pigeon-pod:latest'
    container_name: pigeon-pod
    restart: unless-stopped
    ports:
      - '10002:8080'
    environment:
      - 'PIGEON_BASE_URL=http://$(hostname -I | awk "{print \$1}"):10002'
      - 'PIGEON_AUDIO_FILE_PATH=/data/audio/'
      - 'PIGEON_VIDEO_FILE_PATH=/data/video/'
      - 'PIGEON_COVER_FILE_PATH=/data/cover/'
      - 'SPRING_DATASOURCE_URL=jdbc:sqlite:/data/pigeon-pod.db'
    volumes:
      - /data/pigeonpod:/data

  booklore:
    image: booklore/booklore:latest
    container_name: booklore
    ports:
      - "10003:3000"
    volumes:
      - /data/booklore:/app/data
    restart: unless-stopped

  dockwatch:
    image: ghcr.io/notifiarr/dockwatch:main
    container_name: dockwatch
    restart: unless-stopped
    ports:
      - "10004:80"
    environment:
      - PUID=0
      - PGID=0
      - TZ=Europe/Rome
    volumes:
      - /home/dockwatch/config:/config
      - /var/run/docker.sock:/var/run/docker.sock

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
docker compose down # Rimuove eventuali tentativi precedenti falliti
docker compose up -d

# Recupero IP locale
IP_ADDR=$(hostname -I | awk '{print $1}')

echo "------------------------------------------------"
echo "Installazione completata con successo!"
echo "Filebrowser:    http://$IP_ADDR:10001"
echo "Pigeonpod:      http://$IP_ADDR:10002"
echo "Booklore:       http://$IP_ADDR:10003"
echo "Dockwatch:      http://$IP_ADDR:10004"
echo "Portainer Ag.:  Porta 9001"
echo "------------------------------------------------"
