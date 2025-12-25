#!/bin/bash
# ==========================================
# Bootstrap LXC.1 docker-files
# Debian 12 LXC
# Servizi: Filebrowser, Pigeonpod, Booklore
# Dockwatch + Portainer Agent
# Porte: 10001-10003
# ==========================================

# Aggiornamento base
apt update && apt upgrade -y

# Installazione prerequisiti
apt install -y docker.io docker-compose git curl

# Abilita e avvia Docker
systemctl enable docker
systemctl start docker

# Creazione directory dati persistenti
mkdir -p /mnt/data/filebrowser \
         /mnt/data/pigeonpod \
         /mnt/data/booklore

# Creazione docker-compose.yml
cat <<EOF > /mnt/data/docker-compose.yml
version: "3.8"
services:
  filebrowser:
    image: filebrowser/filebrowser:latest
    container_name: filebrowser
    ports:
      - "10001:80"
    volumes:
      - /mnt/data/filebrowser:/srv
    restart: unless-stopped

  pigeonpod:
    image: jorritfolmer/pigeonpod:latest
    container_name: pigeonpod
    ports:
      - "10002:80"
    volumes:
      - /mnt/data/pigeonpod:/app/data
    restart: unless-stopped

  booklore:
    image: linuxserver/booklore:latest
    container_name: booklore
    ports:
      - "10003:80"
    volumes:
      - /mnt/data/booklore:/config
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

echo "✅ LXC.1 bootstrap completato!"
echo "Filebrowser -> http://<LXC1-IP>:10001"
echo "Pigeonpod  -> http://<LXC1-IP>:10002"
echo "Booklore   -> http://<LXC1-IP>:10003"
echo "Portainer Agent attivo"
echo "Dockwatch attivo per aggiornamenti automatici"
