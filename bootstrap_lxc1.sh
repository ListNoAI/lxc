#!/bin/bash

# --- CONFIGURAZIONE ---
CT_ID=201 
HOSTNAME="docker-files"
STORAGE="local-lvm"           # <--- Assicurati che si chiami esattamente così in Proxmox
PASSWORD="otrebla80" # <--- Cambiala!
BRIDGE="vmbr1"                # <--- LAN (come richiesto)
DISK_SIZE="40"                # <--- Solo il numero (GB)
RAM="2048"

echo "### 1. Controllo/Download template Debian 13 ###"
pveam update
# Cerchiamo il nome esatto del template nei repository ufficiali
TEMPLATE_NAME=$(pveam available -section system | grep "debian-13" | awk '{print $2}' | head -n1)

if [ -z "$TEMPLATE_NAME" ]; then
    echo "Errore: Impossibile trovare il template Debian 13."
    exit 1
fi

if ! pveam list local | grep -q "$TEMPLATE_NAME"; then
    echo "Download del template $TEMPLATE_NAME..."
    pveam download local "$TEMPLATE_NAME"
fi

echo "### 2. Creazione LXC $CT_ID ($HOSTNAME) ###"
# Correzione fondamentale: --rootfs $STORAGE:$DISK_SIZE
pct create $CT_ID local:vztmpl/$TEMPLATE_NAME \
  --hostname $HOSTNAME \
  --password $PASSWORD \
  --net0 name=eth0,bridge=$BRIDGE,ip=dhcp \
  --rootfs $STORAGE:$DISK_SIZE \
  --memory $RAM \
  --cores 2 \
  --unprivileged 1 \
  --features nesting=1,keyctl=1 \
  --start 1

echo "### 3. Installazione Docker (Attesa rete...) ###"
sleep 20
pct exec $CT_ID -- bash -c "apt update && apt install -y curl && \
curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh"

echo "### 4. Setup Docker Compose e Directory ###"
pct exec $CT_ID -- bash -c "mkdir -p /opt/docker-files /data/booklore /data/pigeonpod /data/filebrowser_config"

# Creazione del file docker-compose.yml con porte 10001+
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

echo "### 5. Avvio Servizi ###"
pct exec $CT_ID -- bash -c "cd /opt/docker-files && docker compose up -d"

echo "### COMPLETATO ###"
echo "LXC ID: $CT_ID"
echo "Porte attive: 10001, 10002, 10003"
