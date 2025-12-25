#!/bin/bash
# ==========================================
# Bootstrap LXC.2 syncthing
# Debian 12 LXC
# Servizio: Syncthing nativo
# ==========================================

# Aggiornamento base
apt update && apt upgrade -y

# Installazione prerequisiti
apt install -y curl gnupg lsb-release

# Aggiunta repository Syncthing ufficiale
curl -s https://syncthing.net/release-key.txt | apt-key add -
echo "deb https://apt.syncthing.net/ syncthing stable" | tee /etc/apt/sources.list.d/syncthing.list

# Aggiornamento lista pacchetti
apt update

# Installazione Syncthing
apt install -y syncthing

# Creazione directory dati
mkdir -p /mnt/data/syncthing

# Creazione servizio systemd per avvio automatico
cat <<EOF > /etc/systemd/system/syncthing.service
[Unit]
Description=Syncthing - Open Source Continuous File Synchronization
After=network.target

[Service]
User=root
ExecStart=/usr/bin/syncthing -home=/mnt/data/syncthing
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Ricarica systemd e abilita il servizio
systemctl daemon-reload
systemctl enable syncthing
systemctl start syncthing

echo "✅ LXC.2 bootstrap completato!"
echo "Syncthing in esecuzione e avviato automaticamente"
echo "Web GUI -> http://<LXC2-IP>:8384"
