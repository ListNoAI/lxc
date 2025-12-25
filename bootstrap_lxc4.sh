#!/bin/bash
# ==========================================
# Bootstrap LXC.4 docker-services
# Debian 12 LXC
# Servizi: Portainer Server + Diun (notifiche aggiornamenti Docker)
# Porta: 9000 per Portainer
# ==========================================

# Aggiornamento base
apt update && apt upgrade -y

# Installazione prerequisiti
apt install -y docker.io docker-compose git curl

# Abilita e avvia Docker
systemctl enable docker
systemctl start docker

# Creazione directory dati persistenti
mkdir -p /mnt/data/portainer \
         /mnt/data/diun

# Creazione docker-compose.yml
cat <<EOF > /mnt/data/docker-compose.yml
version: "3.8"
services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    ports:
      - "9000:9000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /mnt/data/portainer:/data
    restart: unless-stopped

  diun:
    image: crazymax/diun:latest
    container_name: diun
    environment:
      - TZ=Europe/Rome
      - LOG_LEVEL=info
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /mnt/data/diun:/data
    restart: unless-stopped

EOF

# Avvio dei container
docker-compose -f /mnt/data/docker-compose.yml up -d

echo "✅ LXC.4 bootstrap completato!"
echo "Portainer Server -> http://<LXC4-IP>:9000"
echo "Diun attivo per notifiche aggiornamenti immagini Docker"
