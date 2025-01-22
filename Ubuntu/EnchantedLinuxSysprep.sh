#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

# Variables
SCRIPTS_DIR="./Scripts" # Update this to the correct path if needed

# Function to ensure a script is executable and run it
run_script() {
    local script_path="$1"

    if [ -f "$script_path" ]; then
        chmod +x "$script_path" # Make the script executable
        "$script_path"          # Execute the script
    else
        echo "Script $script_path not found!"
    fi
    read -p "Press Enter to return to the main menu..."
}

# Define functions for each option
set_static_dns() {
    run_script "$SCRIPTS_DIR/SetStaticDNS.sh"
}

expand_lvm() {
    run_script "$SCRIPTS_DIR/ExpandLVM.sh"
}

domain_join() {
    run_script "$SCRIPTS_DIR/DomainJoin.sh"
}

install_laps4linux_runner() {
    run_script "$SCRIPTS_DIR/InstallLAPS4LINUX.sh"
}

install_certbot_cloudflare() {
    run_script "$SCRIPTS_DIR/InstallCertbotCloudflare.sh"
}

install_pelican_wings() {
    run_script "$SCRIPTS_DIR/InstallPelicanWings.sh"
}

run_ubuntu_updates() {
    echo "Running Ubuntu updates..."
    sudo apt update && sudo apt upgrade -y
    echo "Ubuntu updates completed!"
    read -p "Press Enter to return to the main menu..."
}

# Main menu loop
while true; do
    clear
    echo "Enchanted Linux Sysprep Tool"
    echo "============================"
    echo "1. Set Static DNS"
    echo "3. Expand LVM"
    echo "4. Domain Join"
    echo "5. Install LAPS4LINUX Runner"
    echo "6. Install & Configure Certbot for Cloudflare DNS challenges"
    echo "7. Install Pelican Wings"
    echo "8. Run Ubuntu Updates"
    echo "0. Exit"
    echo "============================"
    read -p "Enter your choice: " choice

    case $choice in
        1)
            set_static_dns
            ;;
        3)
            expand_lvm
            ;;
        4)
            domain_join
            ;;
        5)
            install_laps4linux_runner
            ;;
        6)
            install_certbot_cloudflare
            ;;
        7)
            install_pelican_wings
            ;;
        8)
            run_ubuntu_updates
            ;;
        0)
            echo "Exiting. Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            read -p "Press Enter to continue..."
            ;;
    esac
done
