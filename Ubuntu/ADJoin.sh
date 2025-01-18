#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

# Variables
DOMAIN="ad.enchantedexperiences.net"
ADMIN_GROUP="secLinuxAdmins@AD.ENCHANTEDEXPERIENCES.NET"

echo "Updating system and installing prerequisites..."
# Install prerequisites
apt update && apt install -y sssd-ad sssd-tools realmd adcli samba-common-bin libnss-sss libpam-sss

echo "Verifying domain discoverability..."
# Verify the domain is discoverable via DNS
realm -v discover $DOMAIN
if [ $? -ne 0 ]; then
  echo "Domain discovery failed. Ensure the domain is properly configured in DNS."
  exit 1
fi

echo "Please provide your domain credentials for joining the domain."
read -p "Domain Username: " DOMAIN_USERNAME
read -s -p "Domain Password: " DOMAIN_PASSWORD
echo ""

echo "Joining the domain..."
# Join the domain using provided credentials
echo $DOMAIN_PASSWORD | realm join -U $DOMAIN_USERNAME --install=/ $DOMAIN
if [ $? -ne 0 ]; then
  echo "Failed to join the domain. Check your credentials and try again."
  exit 1
fi

echo "Enabling automatic home directory creation..."
# Enable automatic home directory creation
pam-auth-update --enable mkhomedir

echo "Installing Kerberos tools..."
# Install Kerberos tickets tools after enabling pam-auth-update
apt install -y krb5-user

echo "Configuring sudoers file for admin group..."
# Add secLinuxAdmins group to sudoers
VISUDO_FILE="/etc/sudoers.d/secLinuxAdmins"
if [ ! -f "$VISUDO_FILE" ]; then
  echo "%$ADMIN_GROUP ALL=(ALL:ALL) ALL" > $VISUDO_FILE
  chmod 0440 $VISUDO_FILE
  echo "Sudoers file configured successfully."
else
  echo "Sudoers configuration already exists."
fi

echo "Rebooting the system..."
# Reboot the system
reboot