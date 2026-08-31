#!/bin/bash

set -e

DATA_DIR="/var/lib/mysql"

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld "${DATA_DIR}"


# ===================== INITIALIZATION =====================

if [ ! -d "${DATA_DIR}/mysql" ]; then
    echo "Initializing MariaDB data directory..."

    mariadb-install-db \
        --user=mysql \
        --datadir="${DATA_DIR}" \
        --skip-test-db > /dev/null
fi


# ===================== READ SECRETS =====================

DB_PASSWORD="$(cat /run/secrets/db_password)"
DB_ROOT_PASSWORD="$(cat /run/secrets/db_root_password)"


# ===================== INITIAL DATABASE SETUP =====================

if [ ! -f "${DATA_DIR}/.inception_initialized" ]; then

    echo "Configuring MariaDB..."

    mariadbd \
        --user=mysql \
        --datadir="${DATA_DIR}" \
        --bootstrap <<EOF
USE mysql;

CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';

GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';

FLUSH PRIVILEGES;
EOF

    touch "${DATA_DIR}/.inception_initialized"
    chown mysql:mysql "${DATA_DIR}/.inception_initialized"

    echo "MariaDB initialization complete."

else

    echo "MariaDB already initialized."

fi


unset DB_PASSWORD
unset DB_ROOT_PASSWORD


# ===================== START SERVER =====================

echo "Starting MariaDB..."

exec mariadbd \
    --user=mysql \
    --datadir="${DATA_DIR}" \
    --bind-address=0.0.0.0 \
    --port="${MARIADB_INTERNAL_PORT}"
