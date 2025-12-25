#!/bin/bash

# 1. Aggiornamento sistema
apt update && apt upgrade -y
apt install -y curl apt-transport-https

# 2. Aggiunta chiavi GPG del repository ufficiale Syncthing
mkdir -p /etc/apt/keyrings
curl -L -o /etc/apt/keyrings/syncthing-archive-keyring.gpg https://syncthing.net/release-key.gpg

# 3. Aggiunta del repository ufficiale a APT
echo "deb [signed-by=/etc/apt/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable" | tee /etc/apt/sources.list.d/syncthing.list

# 4. Installazione di Syncthing
apt update
apt install -y syncthing

# 5. Configurazione iniziale e cambio porta a 10010
# Avviamo syncthing un istante per generare il config.xml se non esiste
syncthing --generate="/root/.config/syncthing"

# Modifichiamo il config per ascoltare su tutte le interfacce (0.0.0.0) e sulla porta 10010
sed -i 's/127.0.0.1:8384/0.0.0.0:10010/g' /root/.config/syncthing/config.xml

# 6. Abilitazione e avvio del servizio per l'utente root
systemctl enable syncthing@root
systemctl start syncthing@root

# 7. Ottimizzazione Inotify (per monitorare molti file)
echo "fs.inotify.max_user_watches=204800" | tee -a /etc/sysctl.conf

echo "------------------------------------------------"
echo "Syncthing installato correttamente!"
echo "Accedi alla GUI qui: http://$(hostname -I | awk '{print $1}'):10010"
echo "------------------------------------------------"
echo "NOTA: Al primo accesso, imposta subito una password nella GUI."
