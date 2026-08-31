#!/bin/bash

set -e

SSL_DIR="/etc/nginx/ssl"


# ===================== SSL CERTIFICATE =====================

if [ ! -f "${SSL_DIR}/nginx.crt" ] || [ ! -f "${SSL_DIR}/nginx.key" ]; then

    echo "Generating self-signed SSL certificate..."

    openssl req \
        -x509 \
        -nodes \
        -days 365 \
        -newkey rsa:2048 \
        -keyout "${SSL_DIR}/nginx.key" \
        -out "${SSL_DIR}/nginx.crt" \
        -subj "/C=BR/ST=SP/L=SaoPaulo/O=42/OU=Inception/CN=${DOMAIN_NAME}"

fi


# ===================== NGINX CONFIGURATION =====================

echo "Configuring NGINX..."

envsubst \
    '${DOMAIN_NAME} ${NGINX_INTERNAL_PORT} ${WORDPRESS_INTERNAL_PORT}' \
    < /etc/nginx/nginx.conf \
    > /tmp/nginx.conf

mv /tmp/nginx.conf /etc/nginx/nginx.conf


# ===================== VALIDATION =====================

nginx -t

echo "NGINX configuration is valid."
echo "Starting NGINX..."

exec nginx -g "daemon off;"
