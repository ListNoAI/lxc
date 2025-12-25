#!/bin/bash
# ==========================================
# Script host-side unico: crea LXC.1 + Docker
# Servizi: Filebrowser, Pigeonpod, Booklore, Portainer Agent, Dockwatch
# ==========================================

# --- CONFIGURAZIONE LXC ---
CTID=201                  # ID del container aggiornato
HOSTNAME=lxc1
TEMPLATE=local:vztmpl/debian-12-standard_12.4-1_amd64.tar.gz
STORAGE=local-lvm
CORES=2
MEMORY=2048                # MB
ROOTFS=8G
NET_BRIDGE=vmbr0
FEATURES="nesting=1,keyctl=1"
PASSWORD="LaTuaPassword"   # cambiare con password sicura

# --- CREA LXC ---
pct create $CTID $TEMPLATE \
  --hostname $HOSTNAME \
  --cores $CORES \
  --memory $MEMORY \
  --net0 name=eth0,bridge=$NET_BRIDGE,ip=dhcp \
  --rootfs $STORAGE:$ROOTFS \
  --features $FEATURES \
  --unprivileged 1 \
  --password $PASSWORD

# --- AVVIA LXC ---
pct start $CTID

# --- INSTALLA DOCKER E CONTAINER DENTRO LXC ---
pct exec $CTID -- bash -c " \
  apt update && apt upgrade -y && \
  apt install -y docker.io docker-compose git curl && \
  systemctl enable docker && systemctl start docker && \
  mkdir -p /mnt/data/filebrowser /mnt/data/pigeonpod /mnt/data/booklore && \
  cat <<EOF > /mnt/data/docker-compose.yml
version: '3.8'
services:
  filebrowser:
    image: filebrowser/filebrowser:latest
    container_name: filebrowser
    ports:
      - '10001:80'
    volumes:
      - /mnt/data/filebrowser:/srv
    restart: unless-stopped

  pigeonpod:
    image: jorritfolmer/pigeonpod:latest
    container_name: pigeonpod
    ports:
      - '10002:80'
    volumes:
      - /mnt/data/pigeonpod:/app/data
    restart: unless-stopped

  booklore:
    image: linuxserver/booklore:latest
    container_name: booklore
    ports:
      - '10003:80'
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
  docker-compose -f /mnt/data/docker-compose.yml up -d
"

echo "✅ LXC.1 creata con CTID=$CTID e container Docker avviati!"
echo "Porte dei servizi:"
echo "Filebrowser -> 10001"
echo "Pigeonpod  -> 10002"
echo "Booklore   -> 10003"
