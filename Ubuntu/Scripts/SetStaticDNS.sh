#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

# Variables
DNS1="192.168.10.10"
DNS2="192.168.11.10"
NETPLAN_CONFIG="/etc/netplan/01-netcfg.yaml"
RESOLV_CONF="/etc/resolv.conf"

# Get the current network configuration
echo "Fetching the current network configuration..."
INTERFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -n 1)

if [ -z "$INTERFACE" ]; then
  echo "Failed to detect the network interface. Please check your network connection."
  exit 1
fi

echo "Detected network interface: $INTERFACE"

# Create a backup of the current Netplan configuration
if [ -f "$NETPLAN_CONFIG" ]; then
  echo "Backing up the existing Netplan configuration..."
  cp "$NETPLAN_CONFIG" "$NETPLAN_CONFIG.bak"
fi

# Generate a new Netplan configuration with DHCP and custom DNS servers
echo "Generating a new Netplan configuration..."
cat <<EOF > "$NETPLAN_CONFIG"
network:
  version: 2
  ethernets:
    $INTERFACE:
      dhcp4: true
      nameservers:
        addresses:
          - $DNS1
          - $DNS2
EOF

# Apply the new configuration
echo "Applying the new Netplan configuration..."
netplan apply

# Ensure /etc/resolv.conf is symlinked to the appropriate systemd-resolved configuration
if [ -L "$RESOLV_CONF" ]; then
  echo "Ensuring /etc/resolv.conf links to systemd-resolved..."
  ln -sf /run/systemd/resolve/stub-resolv.conf "$RESOLV_CONF"
else
  echo "Creating symlink for /etc/resolv.conf to systemd-resolved..."
  rm -f "$RESOLV_CONF"
  ln -s /run/systemd/resolve/stub-resolv.conf "$RESOLV_CONF"
fi

# Restart systemd-resolved to apply changes
echo "Restarting systemd-resolved..."
systemctl restart systemd-resolved

# Verify the configuration
echo "Verifying the updated configuration..."
cat "$NETPLAN_CONFIG"
echo "DNS servers have been updated while keeping DHCP enabled."

# Test DNS resolution
echo "Testing DNS resolution..."
nslookup google.com

echo "Configuration complete!"
