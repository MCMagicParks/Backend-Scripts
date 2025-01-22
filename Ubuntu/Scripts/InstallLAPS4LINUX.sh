#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

# Variables
CONFIG_FILE="/etc/laps-runner.json"
LAPS4LINUX_DIR="/opt/laps4linux"
RUNNER_DIR="$LAPS4LINUX_DIR/laps-runner"
VENV_DIR="$RUNNER_DIR/venv"
LAPS4LINUX_BINARY="$VENV_DIR/bin/laps-runner"
GROUP_SID="S-1-5-21-3286359242-2993552358-4013004210-1168" # secLAPSAdmins group SID
DOMAIN="ad.enchantedexperiences.net"
PASSWORD_CHANGE_USER="exadmin"

echo "Starting LAPS4LINUX Runner setup with Native LAPS and encryption..."

# Install prerequisites
echo "Installing required dependencies..."
apt update && apt install -y python3-venv python3-pip python3-setuptools python3-gssapi python3-dnspython krb5-user libkrb5-dev ldap-utils adcli git

# Clone the LAPS4LINUX repository and extract only the /runner directory
echo "Cloning the LAPS4LINUX repository..."
if [ ! -d "$RUNNER_DIR" ]; then
  mkdir -p "$LAPS4LINUX_DIR"
  git clone --depth 1 https://github.com/schorschii/LAPS4LINUX.git "$LAPS4LINUX_DIR"
else
  echo "LAPS4LINUX directory already exists. Skipping clone."
fi

# Ensure /runner exists
if [ ! -d "$RUNNER_DIR" ]; then
  echo "The /runner directory is missing in the repository. Please check the LAPS4LINUX repository structure."
  exit 1
fi

# Set up the virtual environment inside the /runner directory
echo "Setting up Python virtual environment in $RUNNER_DIR..."
cd "$RUNNER_DIR" || exit 1
python3 -m venv "$VENV_DIR" --system-site-packages

# Install LAPS4LINUX in the virtual environment
echo "Installing LAPS4LINUX in the virtual environment..."
"$VENV_DIR/bin/pip3" install "$RUNNER_DIR"

# Check if installation succeeded
if [ ! -f "$LAPS4LINUX_BINARY" ]; then
  echo "LAPS4LINUX installation failed."
  exit 1
fi

# Generate configuration file
echo "Creating LAPS4LINUX configuration file with encryption..."
cat <<EOF > "$CONFIG_FILE"
{
  "server": [],
  "domain": "$DOMAIN",
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
  "password-change-user": "$PASSWORD_CHANGE_USER",
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
WorkingDirectory=$RUNNER_DIR
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
