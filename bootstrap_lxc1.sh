#!/bin/bash

# --- CONFIGURAZIONE ---
CT_ID=201 
HOSTNAME="docker-files"
STORAGE="local-lvm" 
PASSWORD="otrebla80" # <--- Cambiala qui
BRIDGE="vmbr1"
DISK_SIZE="40G" 
RAM="2048"

echo "### 1. Download template Debian 13 ###"
pveam update
TEMPLATE=$(pveam available -section system | grep "debian-13" | awk '{print $2}' | head -n1)
pveam download local "$TEMPLATE"

echo "### 2. Creazione LXC $CT_ID ($HOSTNAME) ###"
pct create $CT_ID local:vztmpl/$TEMPLATE \
  --hostname $HOSTNAME \
  --password $PASSWORD \
  --net0 name=eth0,bridge=$BRIDGE,ip=dhcp \
  --storage $STORAGE \
  --rootfs $STORAGE:$DISK_SIZE \
  --memory $RAM \
  --cores 2 \
  --unprivileged 1 \
  --features nesting=1,keyctl=1 \
  --start 1

echo "### 3. Installazione Docker ###"
sleep 15
pct exec $CT_ID -- bash -c "apt update && apt install -y curl && \
curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh"

echo "### 4. Setup Docker Compose e Volumi ###"
pct exec $CT_ID -- bash -c "mkdir -p /opt/docker-files /data/booklore /data/pigeonpod /data/filebrowser_config"

# Creazione del file docker-compose.yml con porte dalla 10001
cat <<EOF | pct exec $CT_ID -- bash -c "cat > /opt/docker-files/docker-compose.yml"
services:
  filebrowser:
    image: filebrowser/filebrowser:latest
    container_name: filebrowser
    ports:
      - "10001:80"
    volumes:
      - /data:/srv
      - /data/filebrowser_config/database.db:/database.db
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

echo "### 5. Avvio Stack ###"
pct exec $CT_ID -- bash -c "cd /opt/docker-files && docker compose up -d"

echo "### LXC.1 PRONTO! ###"
echo "Filebrowser: http://IP:10001"
echo "Pigeonpod:   http://IP:10002"
echo "Booklore:    http://IP:10003"
