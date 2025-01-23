#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

CLOUDFLARE_EMAIL="hdinternal@enchantedexperiences.net"

echo "Updating system and installing Certbot..."
# Install Certbot and the Cloudflare plugin
apt update && apt install -y certbot python3-certbot-dns-cloudflare

echo "Please enter the subdomain for the certificate request (e.g., sub.example.com):"
read -r SUBDOMAIN

echo "Please enter your Cloudflare API key:"
read -s CLOUDFLARE_API_KEY

# Create Cloudflare credentials file
CLOUDFLARE_CREDS_FILE="/etc/letsencrypt/cloudflare.ini"
echo "Creating Cloudflare credentials file at $CLOUDFLARE_CREDS_FILE..."
cat <<EOF >"$CLOUDFLARE_CREDS_FILE"
dns_cloudflare_api_token = $CLOUDFLARE_API_KEY
EOF

# Secure the credentials file
chmod 600 "$CLOUDFLARE_CREDS_FILE"

# Request the certificate
echo "Requesting the certificate for $SUBDOMAIN using DNS challenge..."
certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials "$CLOUDFLARE_CREDS_FILE" \
  --non-interactive \
  --agree-tos \
  --email "$CLOUDFLARE_EMAIL" \
  -d "$SUBDOMAIN"

if [ $? -ne 0 ]; then
  echo "Certificate request failed. Please check your Cloudflare API token and subdomain."
  exit 1
fi

# Set up auto-renewal
echo "Setting up auto-renewal for the certificate..."
(crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet --dns-cloudflare --dns-cloudflare-credentials $CLOUDFLARE_CREDS_FILE") | crontab -

echo "Certificate setup and auto-renewal configuration complete!"
echo "Your certificate files are located in /etc/letsencrypt/live/$SUBDOMAIN/"