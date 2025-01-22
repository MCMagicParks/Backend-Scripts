#!/bin/bash

# Variables
SCRIPTS_DIR="./Scripts"

# Define functions for each option
set_static_dns() {
    if [ -f "$SCRIPTS_DIR/SetStaticDNS.sh" ]; then
        "$SCRIPTS_DIR/SetStaticDNS.sh"
    else
        echo "SetStaticDNS.sh script not found!"
    fi
    read -p "Press Enter to return to the main menu..."
}

expand_lvm() {
    if [ -f "$SCRIPTS_DIR/ExpandLVM.sh" ]; then
        "$SCRIPTS_DIR/ExpandLVM.sh"
    else
        echo "ExpandLVM.sh script not found!"
    fi
    read -p "Press Enter to return to the main menu..."
}

domain_join() {
    if [ -f "$SCRIPTS_DIR/ADJoin.sh" ]; then
        "$SCRIPTS_DIR/InstallLAPS4LINUX.sh"
    else
        echo "InstallLAPS4LINUX.sh script not found!"
    fi
    read -p "Press Enter to return to the main menu..."
}

install_laps4linux_runner() {
    if [ -f "$SCRIPTS_DIR/InstallLAPS4LINUX.sh" ]; then
        $SCRIPTS_DIR/InstallLAPS4LINUX.sh
    else
        echo "InstallLAPS4LINUX.sh script not found!"
    fi
    read -p "Press Enter to return to the main menu..."
}

install_certbot_cloudflare() {
    if [ -f "$SCRIPTS_DIR/InstallCertbotCloudflare.sh" ]; then
        $SCRIPTS_DIR/InstallCertbotCloudflare.sh
    else
        echo "InstallCertbotCloudflare.sh script not found!"
    fi
    read -p "Press Enter to return to the main menu..."
}

install_pelican_wings() {
    if [ -f "$SCRIPTS_DIR/InstallPelicanWings.sh" ]; then
        $SCRIPTS_DIR/InstallPelicanWings.sh
    else
        echo "InstallPelicanWings.sh script not found!"
    fi
    read -p "Press Enter to return to the main menu..."
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
    echo "1. Expand LVM"
    echo "2. Domain Join"
    echo "3. Install LAPS4LINUX Runner"
    echo "============================"
    echo "4. Install Certbot & Configure for Cloudflare DNS Challenge"
    echo "5. Install Pelican Wings"
    echo "6. Run Ubuntu Updates"
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
