#!/bin/bash

set -e

echo "Generating SSL certificate..."

openssl req \
    -x509 \
    -nodes \
    -days 365 \
    -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=BR/ST=SP/L=SaoPaulo/O=42/OU=42/CN=${DOMAIN_NAME}"

echo "Generating NGINX configuration..."

envsubst \
    '${DOMAIN_NAME} ${NGINX_INTERNAL_PORT} ${WORDPRESS_INTERNAL_PORT}' \
    < /etc/nginx/nginx.conf \
    > /tmp/nginx.conf

mv /tmp/nginx.conf /etc/nginx/nginx.conf

echo "Testing NGINX configuration..."

nginx -t

echo "Starting NGINX..."

exec nginx -g "daemon off;"
