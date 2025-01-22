#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

# Variables
CONFIG_FILE="/etc/laps-runner.json"
LAPS4LINUX_VENV_DIR="/opt/laps4linux"
LAPS4LINUX_BINARY="$LAPS4LINUX_VENV_DIR/bin/laps-runner"
GROUP_NAME="secLAPSAdmins"

echo "Starting LAPS4LINUX Runner setup with Native LAPS and automatic SID retrieval..."

# Install prerequisites
echo "Installing required dependencies..."
apt update && apt install -y python3-venv python3-pip python3-setuptools python3-gssapi python3-dnspython krb5-user libkrb5-dev ldap-utils

# Retrieve the SID for the specified group
echo "Retrieving the SID for group: $GROUP_NAME..."
GROUP_SID=$(ldapsearch -LLL -Q -Y GSSAPI -b "dc=$(hostname -d | sed 's/\./,dc=/g')" "(cn=$GROUP_NAME)" objectSid | awk '/objectSid:/ {print $2}')

if [ -z "$GROUP_SID" ]; then
  echo "Failed to retrieve the SID for group: $GROUP_NAME. Ensure the group exists in Active Directory and that this machine is joined to the domain."
  exit 1
fi

echo "Retrieved SID for $GROUP_NAME: $GROUP_SID"

# Create a Python virtual environment for LAPS4LINUX
echo "Setting up Python virtual environment..."
mkdir -p "$LAPS4LINUX_VENV_DIR"
python3 -m venv "$LAPS4LINUX_VENV_DIR" --system-site-packages

# Activate the virtual environment and install LAPS4LINUX
echo "Installing LAPS4LINUX Runner..."
"$LAPS4LINUX_VENV_DIR/bin/pip3" install laps4linux

# Check if installation succeeded
if [ ! -f "$LAPS4LINUX_BINARY" ]; then
  echo "LAPS4LINUX installation failed."
  exit 1
fi

echo "Creating LAPS4LINUX configuration file with encryption..."
# Generate configuration file
cat <<EOF > "$CONFIG_FILE"
{
  "server": [],
  "domain": "ad.enchantedexperiences.net",
  "ldap-query": "(&(objectClass=computer)(cn=%1))",
  "use-starttls": false,
  "client-keytab-file": "/etc/krb5.keytab",
  "cred-cache-file": "/tmp/laps.temp",
  "native-laps": true,
  "security-descriptor": "$GROUP_SID",
  "history-size": 10,
  "ldap-attribute-password": "msLAPS-EncryptedPassword",
  "ldap-attribute-password-history": "msLAPS-EncryptedPasswordHistory",
  "ldap-attribute-password-expiry": "msLAPS-PasswordExpirationTime",
  "hostname": null,
  "password-change-user": "exadmin",
  "password-days-valid": 30,
  "password-length": 16,
  "password-alphabet": "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()",
  "pam-grace-period": 0
}
EOF

# Secure the configuration file
chmod 600 "$CONFIG_FILE"

# Create systemd service
echo "Creating systemd service for LAPS4LINUX Runner..."
cat <<EOF > /etc/systemd/system/laps4linux.service
[Unit]
Description=LAPS4LINUX Password Management Service
After=network.target

[Service]
Type=simple
ExecStart=$LAPS4LINUX_BINARY -f
Restart=always
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
systemctl daemon-reload
systemctl enable laps4linux
systemctl start laps4linux

# Optionally add LAPS to PAM
echo "Configuring PAM for automatic password rotation..."
cat <<EOF > /usr/share/pam-configs/laps
Name: LAPS4LINUX configuration
Default: yes
Priority: 0

Session-Type: Additional
Session-Interactive-Only: yes
Session:
        optional pam_exec.so type=close_session seteuid quiet $LAPS4LINUX_BINARY --pam
EOF

pam-auth-update

echo "Setup completed successfully!"
echo "-----------------------------------------------------"
echo "Next Steps:"
echo "1. Verify the configuration file at $CONFIG_FILE."
echo "2. Test the setup with the following command:"
echo "   $LAPS4LINUX_BINARY -f"
echo "3. Check the logs using:"
echo "   journalctl -u laps4linux -f"
echo "-----------------------------------------------------"
