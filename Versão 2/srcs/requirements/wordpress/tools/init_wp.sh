#!/bin/bash

set -e

WP_DIR="/var/www/html"

DB_PASSWORD=$(cat /run/secrets/db_password | tr -d '\n')
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_credentials | tr -d '\n')
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_credentials | tr -d '\n')


# ===================== WAIT FOR DATABASE =====================

echo "Waiting for MariaDB..."

MAX_RETRIES=5
RETRY=0

until mysqladmin \
    --host=mariadb \
    --port="${MARIADB_INTERNAL_PORT:-3306}" \
    --user="${MYSQL_USER}" \
    --password="${DB_PASSWORD}" \
    ping --silent > /dev/null 2>&1
do
    RETRY=$((RETRY + 1))

    if [ "${RETRY}" -ge "${MAX_RETRIES}" ]; then
        echo "MariaDB did not become available."
        exit 1
    fi

    echo "MariaDB is not ready. Retry ${RETRY}/${MAX_RETRIES}..."
    sleep 2
done

echo "MariaDB is ready."


# ===================== WORDPRESS INSTALLATION =====================

cd "${WP_DIR}"

if [ ! -f "${WP_DIR}/wp-config.php" ]; then

    echo "Downloading WordPress..."

    wp core download \
        --path="${WP_DIR}" \
        --allow-root


    echo "Creating wp-config.php..."

    wp config create \
        --path="${WP_DIR}" \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost="mariadb:${MARIADB_INTERNAL_PORT:-3306}" \
        --allow-root


    echo "Installing WordPress..."

    wp core install \
        --path="${WP_DIR}" \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root


    echo "Creating secondary WordPress user..."

    wp user create \
        --path="${WP_DIR}" \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --role=contributor\
        --user_pass="${WP_USER_PASSWORD}" \
        --allow-root


    chown -R www-data:www-data "${WP_DIR}"

    echo "WordPress installation complete."

else

    echo "WordPress already installed."

fi


unset DB_PASSWORD
unset WP_ADMIN_PASSWORD
unset WP_USER_PASSWORD


# ===================== PHP-FPM =====================

mkdir -p /run/php

echo "Starting PHP-FPM..."

exec /usr/sbin/php-fpm8.2 -F
