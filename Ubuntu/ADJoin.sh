#!/bin/bash

# Ask for input
read -p "Enter the domain: " DOMAIN
read -p "Enter the domain admin username: " ADMIN_USER
read -p "Enter an additional group to add to sudo: " SUDO_GROUP

# Install required packages
echo "Installing required packages..."
sudo apt update
sudo apt install -y krb5-user adcli sssd-ad libnss-sss libpam-sss

# Configure SSSD
echo "Configuring SSSD..."
cat <<EOF | sudo tee /etc/sssd/sssd.conf
[sssd]
config_file_version = 2
services = nss, pam
domains = $DOMAIN

[pam]
offline_credentials_expiration = 365
offline_failed_login_attempts = 5
offline_failed_login_delay = 10

[domain/$DOMAIN]
id_provider = ad
access_provider = simple
ldap_id_mapping = true
cache_credentials = true
fallback_homedir = /home/%u
default_shell = /bin/bash
skel_dir = /etc/skel
EOF
sudo chmod 600 /etc/sssd/sssd.conf

# Configure Kerberos
echo "Configuring Kerberos..."
cat <<EOF | sudo tee /etc/krb5.conf
[libdefaults]
default_realm = $DOMAIN

[realms]
$DOMAIN = {
    kdc = $(echo "$DOMAIN" | awk -F '.' '{print "ad1."$0"\nad2."$0"\nad3."$0}')
    admin_server = ad3.$DOMAIN
}

[domain_realm]
.$DOMAIN = $DOMAIN
$DOMAIN = $DOMAIN
EOF

# Configure PAM for home directories
echo "Configuring PAM..."
cat <<EOF | sudo tee /usr/share/pam-configs/my-ad
Name: AD user home management
Default: yes
Priority: 127
Session-Type: Additional
Session-Interactive-Only: yes
Session:
    required pam_mkhomedir.so skel=/etc/skel umask=0077
EOF
sudo pam-auth-update --package

# Join the domain
echo "Joining the domain..."
sudo adcli join -U "$ADMIN_USER" "$DOMAIN"

# Enable and start SSSD
echo "Enabling and starting SSSD..."
sudo systemctl enable sssd
sudo systemctl start sssd

# Add Domain Admins and additional group to sudoers
echo "Configuring sudoers..."
cat <<EOF | sudo tee /etc/sudoers.d/domainadmins
%Domain\ Admins ALL=(ALL:ALL) ALL
%$SUDO_GROUP ALL=(ALL:ALL) ALL
EOF

echo "Domain join and configuration complete! Please reboot the system."
