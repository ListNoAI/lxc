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
mkdir -p /data/pigeonpod
mkdir -p /data/filebrowser_config
touch /data/filebrowser_config/database.db # Crea il file per evitare errori di directory

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
    restart: unless-stopped
    container_name: pigeon-pod
    ports:
      - '10002:8080'
    environment:
      - 'PIGEON_BASE_URL=https://pigeonpod.cloud' # set to your domain. NOTE: If you changed this domain during use, your previous subscription links will become invalid.
      - 'PIGEON_AUDIO_FILE_PATH=/data/audio/' # set to your audio file path
      - 'PIGEON_VIDEO_FILE_PATH=/data/video/' # set to your video file path
      - 'PIGEON_COVER_FILE_PATH=/data/cover/' # set to your cover file path
      - 'SPRING_DATASOURCE_URL=jdbc:sqlite:/data/pigeon-pod.db' # set to your database path
    volumes:
      - data:/data

volumes:
  data:

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
    ports:
      - "10004:1609"
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
