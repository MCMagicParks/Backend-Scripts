#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

echo "Installing prerequisites for LAPS4LINUX..."
# Update system and install prerequisites
apt update && apt install -y wget curl unzip sssd adcli jq

# Variables
LAPS4LINUX_URL="https://github.com/LAPS4Linux/laps4linux/releases/latest/download/laps4linux"
CONFIG_FILE="/etc/laps/laps.conf"
LAPS4LINUX_INSTALL_DIR="/usr/local/bin"
LAPS_SERVICE_FILE="/etc/systemd/system/laps4linux.service"

# Create LAPS directory
mkdir -p /etc/laps
chmod 700 /etc/laps

echo "Downloading and installing LAPS4LINUX runner..."
# Download the LAPS4LINUX runner binary
wget -qO "${LAPS4LINUX_INSTALL_DIR}/laps4linux" "$LAPS4LINUX_URL"
if [ $? -ne 0 ]; then
  echo "Failed to download LAPS4LINUX binary. Exiting."
  exit 1
fi

# Set permissions for the binary
chmod 755 "${LAPS4LINUX_INSTALL_DIR}/laps4linux"

echo "Creating LAPS4LINUX configuration file..."
# Prompt for domain-related details
read -p "Enter your AD domain name (e.g., ad.example.com): " AD_DOMAIN
read -p "Enter the local admin account to manage (e.g., admin): " ADMIN_ACCOUNT
read -p "Enter the OU where computer accounts are stored (e.g., OU=Computers,DC=ad,DC=example,DC=com): " AD_OU

# Generate LAPS4LINUX configuration file
cat <<EOF >"$CONFIG_FILE"
{
  "domain": "$AD_DOMAIN",
  "admin_account": "$ADMIN_ACCOUNT",
  "ou": "$AD_OU",
  "password_length": 16,
  "password_complexity": "high",
  "password_validity_days": 30,
  "update_interval_seconds": 86400,
  "kerberos_tgt_renewal": true
}
EOF

# Secure the configuration file
chmod 600 "$CONFIG_FILE"

echo "Configuring LAPS4LINUX as a systemd service..."
# Create a systemd service file for LAPS4LINUX
cat <<EOF >"$LAPS_SERVICE_FILE"
[Unit]
Description=LAPS4LINUX Password Management Service
After=network.target

[Service]
Type=simple
ExecStart=${LAPS4LINUX_INSTALL_DIR}/laps4linux --config $CONFIG_FILE
Restart=on-failure
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd daemon and enable service
systemctl daemon-reload
systemctl enable laps4linux
systemctl start laps4linux

echo "LAPS4LINUX installation and configuration completed successfully!"
echo "The service is now running and configured to manage the '$ADMIN_ACCOUNT' account."