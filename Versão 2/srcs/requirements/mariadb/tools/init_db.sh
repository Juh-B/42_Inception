#!/bin/bash

set -e

# ===================== READ SECRETS =====================

DB_PASSWORD=$(cat /run/secrets/db_password | tr -d '\n')
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password | tr -d '\n')

# ===================== EXEC FOLDER =====================

DATA_DIR="/var/lib/mysql"

mkdir -p /run/mysqld /var/log/mysql
chown -R mysql:mysql /run/mysqld "${DATA_DIR}" /var/log/mysql


# ===================== INITIALIZATION =====================

if [ ! -d "${DATA_DIR}/${MYSQL_DATABASE}" ]; then
    echo "[db_init] Database '${MYSQL_DATABASE}' not found. Initializing MariaDB data directory..."

    mariadb-install-db \
        --user=mysql \
        --datadir="${DATA_DIR}" \
        --skip-test-db
        
    # ===================== BOOTSTRAP =====================

    echo "[db_init] Exec users, commands and table by bootstrap..."

    mysqld --user=mysql --bootstrap <<EOF


FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

    echo "[db_init] Successful Configuration."
fi

echo "[db_init] Main process (mysqld)..."
exec "$@"
