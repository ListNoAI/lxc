#!/bin/bash
# ==========================================
# Bootstrap LXC.3 docker-services
# Debian 12 LXC
# Servizi: FreshRSS, Readeck, Excalidraw, Fossflow, Flame (startpage/dashboard)
# Dockwatch + Portainer Agent
# Porte: 10011-10015
# ==========================================

# Aggiornamento base
apt update && apt upgrade -y

# Installazione prerequisiti
apt install -y docker.io docker-compose git curl

# Abilita e avvia Docker
systemctl enable docker
systemctl start docker

# Creazione directory dati persistenti
mkdir -p /mnt/data/freshrss \
         /mnt/data/readeck \
         /mnt/data/excalidraw \
         /mnt/data/fossflow \
         /mnt/data/flame

# Creazione docker-compose.yml
cat <<EOF > /mnt/data/docker-compose.yml
version: "3.8"
services:
  freshrss:
    image: freshrss/freshrss
    container_name: freshrss
    ports:
      - "10011:80"
    volumes:
      - /mnt/data/freshrss:/var/www/FreshRSS/data
    restart: unless-stopped

  readeck:
    image: readeck/readeck
    container_name: readeck
    ports:
      - "10012:80"
    volumes:
      - /mnt/data/readeck:/app/data
    restart: unless-stopped

  excalidraw:
    image: excalidraw/excalidraw
    container_name: excalidraw
    ports:
      - "10013:80"
    restart: unless-stopped

  fossflow:
    image: fossflow/fossflow
    container_name: fossflow
    ports:
      - "10014:80"
    restart: unless-stopped

  flame:
    image: pawelmalak/flame
    container_name: flame
    ports:
      - "10015:5005"
    volumes:
      - /mnt/data/flame:/app/data
    restart: unless-stopped

  portainer-agent:
    image: portainer/agent:latest
    container_name: portainer-agent
    environment:
      - AGENT_CLUSTER_ADDR=tasks.agent
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/docker/volumes:/var/lib/docker/volumes
    restart: unless-stopped

  dockwatch:
    image: containrrr/watchtower:latest
    container_name: dockwatch
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    command: --cleanup --interval 3600
    restart: unless-stopped

EOF

# Avvio dei container
docker-compose -f /mnt/data/docker-compose.yml up -d

echo "✅ LXC.3 bootstrap completato!"
echo "FreshRSS   -> http://<LXC3-IP>:10011"
echo "Readeck    -> http://<LXC3-IP>:10012"
echo "Excalidraw -> http://<LXC3-IP>:10013"
echo "Fossflow   -> http://<LXC3-IP>:10014"
echo "Flame      -> http://<LXC3-IP>:10015"
echo "Portainer Agent attivo"
echo "Dockwatch attivo per aggiornamenti automatici"
