#!/bin/bash
# Bootstrap LXC - Docker + servizi
# Debian 12
# ==========================================

set -e

# Controllo root
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Eseguire lo script come root"
  exit 1
fi

echo "▶ Aggiornamento sistema"
apt update && apt upgrade -y
apt install -y curl gnupg lsb-release ca-certificates

# ==========================================
# Installazione Docker
# ==========================================
if ! command -v docker >/dev/null 2>&1; then
  echo "▶ Installazione Docker"
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
fi

# Docker Compose plugin
if ! docker compose version >/dev/null 2>&1; then
  apt install -y docker-compose-plugin
fi

systemctl enable docker
systemctl restart docker

# ==========================================
# Directory persistenti
# ==========================================
mkdir -p /opt/docker-files
mkdir -p /data/pigeonpod/{audio,video,cover}
mkdir -p /data/filebrowser_config
mkdir -p /opt/dockwatch/config

touch /data/filebrowser_config/database.db

# IP locale
IP_ADDR=$(hostname -I | awk '{print $1}')

# ==========================================
# docker-compose.yml
# ==========================================
cat <<EOF > /opt/docker-files/docker-compose.yml
version: "3.8"

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
    image: ghcr.io/aizhimou/pigeon-pod:latest
    container_name: pigeonpod
    ports:
      - "10002:8080"
    environment:
      - PIGEON_BASE_URL=http://${IP_ADDR}:10002
      - PIGEON_AUDIO_FILE_PATH=/data/audio/
      - PIGEON_VIDEO_FILE_PATH=/data/video/
      - PIGEON_COVER_FILE_PATH=/data/cover/
      - SPRING_DATASOURCE_URL=jdbc:sqlite:/data/pigeon-pod.db
    volumes:
      - /data/pigeonpod:/data
    restart: unless-stopped

  dockwatch:
    image: ghcr.io/notifiarr/dockwatch:main
    container_name: dockwatch
    ports:
      - "10003:80"
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Rome
    volumes:
      - /opt/dockwatch/config:/config
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

# ==========================================
# Avvio container
# ==========================================
cd /opt/docker-files
docker compose down || true
docker compose up -d

# ==========================================
# Output finale
# ==========================================
echo "--------------------------------------------"
echo "✅ Installazione completata"
echo "Filebrowser : http://${IP_ADDR}:10001"
echo "Pigeonpod   : http://${IP_ADDR}:10002"
echo "Dockwatch   : http://${IP_ADDR}:10003"
echo "Portainer   : http://${IP_ADDR}:9001"
echo "--------------------------------------------"
