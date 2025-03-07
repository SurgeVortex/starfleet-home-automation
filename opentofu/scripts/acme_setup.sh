#!/bin/bash

# Configuration Variables (Passed as arguments)
DOMAIN="$1"
WILDCARD_DOMAIN="*.$1"
CF_API_TOKEN="$2"  # Replace with your actual API Token
CERT_DIR="/etc/haproxy/certs"
HAPROXY_RELOAD_CMD="systemctl reload haproxy"

# Ensure dependencies are installed
apt update && apt install -y curl socat cron

# Install acme.sh if not already installed
if ! command -v acme.sh &> /dev/null; then
    echo "Installing acme.sh..."
    curl https://get.acme.sh | sh
    export PATH="$HOME/.acme.sh:$PATH"
fi

# Export Cloudflare API token for DNS-01 validation
export CF_Token="$CF_API_TOKEN"

# Set default CA to Let's Encrypt
acme.sh --set-default-ca --server letsencrypt

# Register account with Let's Encrypt
acme.sh --register-account -m admin@$DOMAIN

# Issue certificate using Cloudflare DNS-01 challenge
echo "Issuing certificate for $DOMAIN and $WILDCARD_DOMAIN..."
acme.sh --issue --dns dns_cf -d "$DOMAIN" -d "$WILDCARD_DOMAIN"

# Ensure certificate directory exists
mkdir -p "$CERT_DIR"

# Install certificate for HAProxy
acme.sh --install-cert -d "$DOMAIN" \
  --key-file "$CERT_DIR/$DOMAIN.key"  \
  --fullchain-file "$CERT_DIR/$DOMAIN.pem"  \
  --reloadcmd "$HAPROXY_RELOAD_CMD"

# Set up auto-renewal in cron (if not already set)
if ! crontab -l | grep -q 'acme.sh --cron'; then
    echo "Setting up auto-renewal cron job..."
    (crontab -l ; echo "0 0 * * * ~/.acme.sh/acme.sh --cron --home ~/.acme.sh > /dev/null") | crontab -
fi

echo "SSL setup complete! HAProxy will now use Let's Encrypt certificates with auto-renewal."
