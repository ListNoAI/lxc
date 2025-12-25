#!/bin/bash

# 1. Installazione Docker
apt update && apt install -y curl
curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh

# 2. Setup cartelle
mkdir -p /opt/docker-services

# 3. Creazione Docker Compose
cat <<EOF > /opt/docker-services/docker-compose.yml
services:
  freshrss:
    image: freshrss/freshrss:latest
    container_name: freshrss
    ports:
      - "10020:80"
    environment:
      - TZ=Europe/Rome
    volumes:
      - freshrss_data:/var/www/FreshRSS/data
    restart: unless-stopped

  readeck:
    image: codeberg.org/readeck/readeck:latest
    container_name: readeck
    ports:
      - "10021:8000"
    volumes:
      - readeck_data:/readeck
    restart: unless-stopped

  excalidraw:
    image: excalidraw/excalidraw:latest
    container_name: excalidraw
    ports:
      - "10022:80"
    restart: unless-stopped

  fossflow:
    image: fossflow/fossflow:latest
    container_name: fossflow
    ports:
      - "10023:80"
    restart: unless-stopped

  flame:
    image: pawelmalak/flame:latest
    container_name: flame
    ports:
      - "10024:5005"
    volumes:
      - flame_data:/app/data
    environment:
      - PASSWORD=otrebla80
    restart: unless-stopped

  portainer_agent:
    image: portainer/agent:latest
    container_name: portainer_agent_services
    ports:
      - "9001:9001"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/docker/volumes:/var/lib/docker/volumes
    restart: unless-stopped

volumes:
  freshrss_data:
  readeck_data:
  flame_data:
EOF

# 4. Avvio
cd /opt/docker-services
docker compose up -d

echo "LXC.3 Installato! Flame Dashboard disponibile su porta 10024"
