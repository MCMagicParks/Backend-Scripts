#!/bin/bash

# Variables
DOMAIN="AD.ENCHANTEDEXPERIENCES.NET"
SUDO_GROUP="secLinuxAdmins"

# Install required packages
echo "Installing required packages..."
sudo apt update
sudo apt install -y adcli sssd-ad libnss-sss libpam-sss

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
default_realm = ${DOMAIN^^}

[realms]
${DOMAIN^^} = {
    kdc = ${DOMAIN,,}
    admin_server = ${DOMAIN,,}
}

[domain_realm]
.${DOMAIN,,} = ${DOMAIN^^}
${DOMAIN,,} = ${DOMAIN^^}
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

# Install Kerberos
echo "Installing Kerberos..."
sudo apt install -y krb5-user 

# Join the domain
echo "Joining the domain..."
read -p "Enter your domain credentials: " ADMIN_USER
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

echo "============================"
echo "Domain join has completed sucessfully. Please restart the server to complete configuration."
echo ""
read -r -p "OK to Restart? (Y/N) " RESTART_RESPONSE
if [[ "$RESTART_RESPONSE" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    sudo reboot
fi

