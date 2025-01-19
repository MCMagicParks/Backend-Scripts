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

# Enable swap in GRUB
GRUB_CONFIG="/etc/default/grub"
SWAP_OPTION="swapaccount=1"

echo "Enabling swap for Docker by updating GRUB configuration..."

# Check if the GRUB_CMDLINE_LINUX_DEFAULT line already contains swapaccount=1
if grep -q "GRUB_CMDLINE_LINUX_DEFAULT" "$GRUB_CONFIG" | grep -q "$SWAP_OPTION"; then
  echo "Swap option ($SWAP_OPTION) is already enabled in GRUB."
else
  echo "Updating GRUB configuration to include $SWAP_OPTION..."
  
  # Update GRUB_CMDLINE_LINUX_DEFAULT to include swapaccount=1
  sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=\"\(.*\)\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\1 $SWAP_OPTION\"/" "$GRUB_CONFIG"
  
  echo "GRUB configuration updated successfully."
fi

# Update GRUB
echo "Updating GRUB..."
update-grub

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
echo "2. Log in to Pelican Panel."
echo "3. Add a new node in the panel and copy the configuration command."
echo "4. Paste and execute the configuration command on this server."
echo "5. Reboot system to enable updated GRUP configuration.
echo "----------------------------------------------------------"
