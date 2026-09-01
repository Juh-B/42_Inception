#!/bin/bash

set -e

# ===================== NGINX CONFIGURATION =====================

echo "Configuring NGINX..."

mkdir -p /etc/ssl/nginx

if [ ! -f /etc/ssl/nginx/nginx.crt ]; then
    echo "[nginx_init] Generating self-signed SSL certificate..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/nginx/nginx.key \
        -out /etc/ssl/nginx/nginx.crt \
        -subj "/C=BR/ST=SP/L=SaoPaulo/O=42/CN=${DOMAIN_NAME}"

    chmod 600 /etc/ssl/nginx/nginx.key
    chmod 644 /etc/ssl/nginx/nginx.crt
    echo "[nginx_init] SSL certificate generated successfully."
fi


# ===================== VALIDATION =====================

nginx -t

echo "NGINX configuration is valid."
echo "Starting NGINX..."

# Command nginx -g "daemon off;"
exec "$@"
