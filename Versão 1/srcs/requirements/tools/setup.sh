#!/bin/bash

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SECRETS_DIR="${PROJECT_ROOT}/secrets"
DOMAIN_NAME="${USER}.42.fr"

GREEN='\033[1;32m'
YELLOW='\033[33m'
RESET='\033[0m'

echo -e "${YELLOW}Starting Inception setup...${RESET}"


# ===================== HOSTS =====================

if ! grep -qE "^[[:space:]]*127\.0\.0\.1[[:space:]]+${DOMAIN_NAME}([[:space:]]|$)" /etc/hosts; then
    echo "Adding ${DOMAIN_NAME} to /etc/hosts..."
    echo "127.0.0.1 ${DOMAIN_NAME}" | sudo tee -a /etc/hosts > /dev/null
else
    echo "${DOMAIN_NAME} already exists in /etc/hosts."
fi


# ===================== SECRETS =====================

mkdir -p "${SECRETS_DIR}"

create_secret()
{
    local file="$1"
    local description="$2"

    if [ ! -s "${SECRETS_DIR}/${file}" ]; then
        echo
        echo "${description}"
        read -r -s -p "Password: " password
        echo

        if [ -z "${password}" ]; then
            echo "Password cannot be empty."
            exit 1
        fi

        printf '%s' "${password}" > "${SECRETS_DIR}/${file}"
        chmod 600 "${SECRETS_DIR}/${file}"

        echo "${file} created."
    else
        echo "${file} already exists."
    fi
}


create_secret \
    "db_password.txt" \
    "MariaDB application user password"

create_secret \
    "db_root_password.txt" \
    "MariaDB root password"

create_secret \
    "wordpress_admin_password.txt" \
    "WordPress administrator password"

create_secret \
    "wordpress_user_password.txt" \
    "WordPress secondary user password"


# ===================== DATA DIRECTORIES =====================

mkdir -p "/home/${USER}/data/mariadb"
mkdir -p "/home/${USER}/data/wordpress"

echo
echo -e "${GREEN}Setup complete!${RESET}"
