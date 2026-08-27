#!/bin/bash

set -e

DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wordpress_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wordpress_user_password)

echo "Waiting for MariaDB..."

until mysqladmin \
    -h mariadb \
    -u "${MYSQL_USER}" \
    -p"${DB_PASSWORD}" \
    ping \
    --silent
do
    sleep 2
done

echo "MariaDB is ready."

cd /var/www/html

if [ ! -f wp-config.php ]; then

    echo "Downloading WordPress..."

    wp core download \
        --allow-root

    echo "Creating WordPress configuration..."

    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost="mariadb" \
        --allow-root

    echo "Installing WordPress..."

    wp core install \
        --url="${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --allow-root

    echo "Creating secondary user..."

    wp user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --role=editor \
        --user_pass="${WP_USER_PASSWORD}" \
        --allow-root

    echo "WordPress installation complete."

else

    echo "WordPress already installed."

fi

mkdir -p /run/php

echo "Starting PHP-FPM..."

exec php-fpm8.2 -F
