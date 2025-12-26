#!/bin/bash
# Installazione Syncthing su Debian / LXC
set -e

# Verifica root
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Esegui come root"
  exit 1
fi

echo "▶ Aggiornamento sistema"
apt update
apt upgrade -y
apt install -y curl apt-transport-https

echo "▶ Aggiunta chiavi GPG Syncthing"
mkdir -p /etc/apt/keyrings
curl -L -o /etc/apt/keyrings/syncthing-archive-keyring.gpg https://syncthing.net/release-key.gpg

echo "▶ Aggiunta repository Syncthing"
echo "deb [signed-by=/etc/apt/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable" | tee /etc/apt/sources.list.d/syncthing.list

echo "▶ Installazione Syncthing"
apt update
apt install -y syncthing

# Genera config se manca
CONFIG_DIR="/root/.config/syncthing"
CONFIG_FILE="$CONFIG_DIR/config.xml"

echo "▶ Generazione config iniziale"
if [ ! -f "$CONFIG_FILE" ]; then
  mkdir -p "$CONFIG_DIR"
  syncthing --generate="$CONFIG_DIR"
fi

echo "▶ Configurazione porta 10010"
sed -i 's/127.0.0.1:8384/0.0.0.0:10010/g' "$CONFIG_FILE"

echo "▶ Abilitazione servizio Syncthing per root"
systemctl enable syncthing@root
systemctl restart syncthing@root

echo "▶ Ottimizzazione Inotify"
echo "fs.inotify.max_user_watches=204800" | tee -a /etc/sysctl.conf

echo "------------------------------------------------"
echo "Syncthing installato correttamente!"
echo "Accedi alla GUI: http://$(hostname -I | awk '{print \$1}'):10010"
echo "------------------------------------------------"
