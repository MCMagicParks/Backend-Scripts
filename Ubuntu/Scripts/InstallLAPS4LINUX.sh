#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

# Constants
DEB_PACKAGE="./Scripts/lib/laps4linux-runner.deb"
CONFIG_FILE="/etc/laps-runner.json"
CRON_FILE="/etc/cron.hourly/laps-runner"
PAM_FILE="/etc/pam.d/common-session"
GROUP_SID="S-1-5-21-3286359242-2993552358-4013004210-1168" # secLAPSAdmins group SID
DC1="us-sac1dc-p01.ad.enchantedexperiences.net"
DC2="us-rcd1dc-p01.ad.enchantedexperiences.net"
DOMAIN="ad.enchantedexperiences.net"
PASSWORD_CHANGE_USER="exadmin"

# Functions
install_dependencies() {
    echo "Installing required dependencies..."
    apt update && apt install -y krb5-user python3-venv python3-pip python3-setuptools python3-gssapi python3-dnspython libkrb5-dev
}

install_package() {
    echo "Installing LAPS4LINUX Runner package..."
    if [[ -f "$DEB_PACKAGE" ]]; then
        dpkg -i "$DEB_PACKAGE"
        apt-get install -f -y  # Fix missing dependencies if any
        echo "Package installed successfully."
    else
        echo "Error: DEB package not found at $DEB_PACKAGE"
        exit 1
    fi
}

setup_config() {
    echo "Setting up configuration file..."
    cat <<EOF >"$CONFIG_FILE"
{
    "server": [
        {
            "address": "$DC1",
            "port": 389,
            "ssl": false
        },
        {
            "address": "$DC2",
            "port": 389,
            "ssl": false
        }
    ],
    "use-starttls": true,
    "domain": "$DOMAIN",
    "ldap-query": "(&(objectClass=computer)(cn=%1))",
    "cred-cache-file": "/tmp/laps.temp",
    "client-keytab-file": "/etc/krb5.keytab",
    "native-laps": true,
    "security-descriptor": "$GROUP_SID",
    "history-size": 10,
    "ldap-attribute-password": "msLAPS-EncryptedPassword",
    "ldap-attribute-password-history": "msLAPS-EncryptedPasswordHistory",
    "ldap-attribute-password-expiry": "msLAPS-PasswordExpirationTime",
    "hostname": null,
    "password-change-user": "$PASSWORD_CHANGE_USER",
    "password-days-valid": 30,
    "password-length": 15,
    "password-alphabet": "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()",
    "pam-services": ["login"],
    "pam-grace-period": 300
}
EOF
    if [[ -f "$CONFIG_FILE" ]]; then
        echo "Configuration file overwritten at $CONFIG_FILE."
    else
        echo "Configuration file created at $CONFIG_FILE."
    fi
}

setup_cron() {
    echo "Setting up cron job..."
    if [[ ! -f "$CRON_FILE" ]]; then
        cat <<EOF >"$CRON_FILE"
#!/bin/sh

SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

OUT=\$(/usr/sbin/laps-runner --config $CONFIG_FILE 2>&1)

if [ -f /usr/bin/logger ]; then
    echo \$OUT | /usr/bin/logger -t laps-runner
fi
EOF
        chmod +x "$CRON_FILE"
        echo "Cron job created at $CRON_FILE."
    else
        echo "Cron job already exists at $CRON_FILE. Skipping creation."
    fi
}

setup_pam() {
    echo "Setting up PAM configuration..."
    if ! grep -q "laps-runner" "$PAM_FILE"; then
        echo "Adding PAM configuration to $PAM_FILE..."
        echo "session optional pam_exec.so type=close_session seteuid quiet /usr/sbin/laps-runner --pam" >>"$PAM_FILE"
        echo "PAM configuration updated."
    else
        echo "PAM configuration already exists in $PAM_FILE. Skipping modification."
    fi
}

final_steps() {
    echo "Installation completed."
    echo "Next steps:"
    echo "1. Review the configuration file: $CONFIG_FILE"
    echo "2. Verify the installation by running: /usr/sbin/laps-runner -f"
    echo "3. Ensure the cron job is running correctly: $CRON_FILE"
    echo "4. If applicable, test the PAM integration."
}

# Main Script Execution
install_dependencies
install_package
setup_config
setup_cron
setup_pam
final_steps
