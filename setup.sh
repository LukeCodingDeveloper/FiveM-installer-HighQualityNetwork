#!/bin/bash

# Variables
GITHUB_REPO="https://github.com/DeinGithubBenutzername/DeinRepositoryName"

# Update and install necessary packages
sudo apt-get update
sudo apt-get install -y wget unzip screen

# Download and extract FiveM server
wget -O fx.tar.xz https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/XXXXX/fx.tar.xz
mkdir -p /opt/fivem
tar xf fx.tar.xz -C /opt/fivem

# Download and install mysql-async (Beispiel)
git clone https://github.com/brouznouf/fivem-mysql-async /opt/fivem/resources/mysql-async

# Download your framework from GitHub
git clone $GITHUB_REPO /opt/fivem/resources/myframework

# Create a basic server.cfg
cat <<EOL > /opt/fivem/server.cfg
endpoint_add_tcp "0.0.0.0:30120"
endpoint_add_udp "0.0.0.0:30120"

set mysql_connection_string "server=localhost;database=fivem;userid=root;password="

start mysql-async
start myframework
EOL

echo "Installation abgeschlossen. Bitte konfiguriere die server.cfg Datei nach deinen Bedürfnissen."
