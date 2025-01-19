#!/bin/bash

echo "Starting installation of Pelican Wings..."

# Update system and install required dependencies
echo "Updating system and installing dependencies..."
apt update && apt upgrade -y
apt install -y curl wget unzip tar jq

# Install Docker
echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
systemctl enable --now docker
rm -f get-docker.sh

# Install Wings
echo "Installing Wings..."
mkdir -p /etc/pelican /var/run/wings
curl -L -o /usr/local/bin/wings "https://github.com/pelican-dev/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
chmod u+x /usr/local/bin/wings

# Configure Wings service
echo "Setting up Wings as a systemd service..."
cat <<EOF > /etc/systemd/system/wings.service
[Unit]
Description=Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pelican
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable the Wings service
systemctl daemon-reload
systemctl enable wings

echo "Wings has been installed but still needs to be configured."

echo "----------------------------------------------------------"
echo "Next steps:"
echo "1. Log in to Pelican Panel."
echo "2. Add a new node in the panel and copy the configuration command."
echo "3. Paste and execute the configuration command on this server."
echo "4. Start the wings service by running systemctl start wings.
echo "----------------------------------------------------------"
