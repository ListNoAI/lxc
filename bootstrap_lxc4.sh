#!/bin/bash

# 1. Installazione Docker
apt update && apt install -y curl
curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh

# 2. Setup cartelle
mkdir -p /opt/docker-mgmt

# 3. Creazione Docker Compose
cat <<EOF > /opt/docker-mgmt/docker-compose.yml
services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    command: -H unix:///var/run/docker.sock
    ports:
      - "10000:9000"
      - "10443:9443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    restart: unless-stopped

  diun:
    image: crazymax/diun:latest
    container_name: diun
    command: serve
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
      - "./diun/data:/data"
    environment:
      - "TZ=Europe/Rome"
      - "DIUN_WATCH_WORKERS=20"
      - "DIUN_WATCH_SCHEDULE=0 0 * * *" # Controlla ogni notte a mezzanotte
      - "DIUN_NOTIF_GOTIFY_ENDPOINT=http://IP_GOTIFY" # Opzionale
    restart: unless-stopped

volumes:
  portainer_data:
EOF

# 4. Avvio
cd /opt/docker-mgmt
docker compose up -d

echo "------------------------------------------------"
echo "LXC.4 Management Pronto!"
echo "Portainer (HTTP):  http://$(hostname -I | awk '{print $1}'):10000"
echo "Portainer (HTTPS): https://$(hostname -I | awk '{print $1}'):10443"
echo "------------------------------------------------"
