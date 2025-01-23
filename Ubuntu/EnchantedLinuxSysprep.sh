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
    echo "Enchanted Experiences Linux Sysprep Tool"
    echo "By chums122"
    echo "============================"
    echo "1. Set Static DNS to DCs"
    echo "2. Expand LVM"
    echo "3. Domain Join"
    echo "4. Install LAPS4LINUX Runner (Make sure computer object in proper OU First!)"
    echo "============================"
    echo "5. Install & Configure Certbot for Cloudflare DNS challenges"
    echo "6. Install Pelican Wings"
    echo "7. Run Ubuntu Updates"
    echo "0. Exit"
    echo "============================"
    read -p "Enter your choice: " choice

    case $choice in
        1)
            set_static_dns
            ;;
        2)
            expand_lvm
            ;;
        3)
            domain_join
            ;;
        4)
            install_laps4linux_runner
            ;;
        5)
            install_certbot_cloudflare
            ;;
        6)
            install_pelican_wings
            ;;
        7)
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
