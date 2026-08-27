#!/bin/bash

set -e

DATA_DIR="/var/lib/mysql"

DB_PASSWORD=$(cat /run/secrets/db_password)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

mkdir -p /run/mysqld

chown -R mysql:mysql /run/mysqld
chown -R mysql:mysql "${DATA_DIR}"

if [ ! -d "${DATA_DIR}/mysql" ]; then

    echo "Initializing MariaDB data directory..."

    mariadb-install-db \
        --user=mysql \
        --datadir="${DATA_DIR}" \
        > /dev/null

    echo "Creating database and users..."

    mariadbd \
        --bootstrap \
        --user=mysql \
        --datadir="${DATA_DIR}" <<EOF

CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';

GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';

ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';

FLUSH PRIVILEGES;

EOF

    echo "MariaDB initialization complete."

else

    echo "MariaDB data directory already initialized."

fi

exec mariadbd \
    --user=mysql \
    --datadir="${DATA_DIR}" \
    --bind-address=0.0.0.0 \
    --port="${MARIADB_INTERNAL_PORT}"
