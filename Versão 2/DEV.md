# DEV_DOC.md — Developer documentation

## Prerequisites

Run the project inside a Linux virtual machine with:

- Docker Engine
- Docker Compose v2
- `make`
- `git`
- `openssl`

For Debian or Ubuntu, install the locally available Docker and Compose v2 packages. Package names can differ by distribution:

```bash
sudo apt update
sudo apt install -y docker.io docker-compose-v2 make git openssl
```

Allow the current user to run Docker, then start a new login session so the group change takes effect:

```bash
sudo usermod -aG docker "$USER"
```

Add the required domain mapping inside the VM:

```bash
printf '%s\n' '127.0.0.1 ekeller-.42.fr' | sudo tee -a /etc/hosts
```

## Setup from a clean clone

### 1. Clone the repository

```bash
git clone <repository-url> inception
cd inception
```

The `.env` and secret files are intentionally not stored in Git. They must be created locally before running Compose.

### 2. Create the environment file

Create `srcs/.env` with the non-sensitive settings expected by the initialization scripts:

```bash
cat > srcs/.env <<'EOF'
DOMAIN_NAME=ekeller-.42.fr
MYSQL_DATABASE=wordpress_db
MYSQL_USER=wp_user
WP_TITLE=Inception ekeller-
WP_ADMIN_USER=superuser
WP_ADMIN_EMAIL=superuser@42.fr
WP_USER_LOGIN=editor_user
WP_USER_EMAIL=editor@42.fr
EOF
```

The administrator login is `superuser`, which complies with the prohibition on administrator usernames containing `admin`.

### 3. Create local secrets

Create the ignored directory and generate unique passwords:

```bash
mkdir -p secrets

openssl rand -base64 24 > secrets/db_password.txt
openssl rand -base64 24 > secrets/db_root_password.txt

{
  printf 'ADMIN_PASSWORD='
  openssl rand -base64 24
  printf 'USER_PASSWORD='
  openssl rand -base64 24
} > secrets/credentials.txt

chmod 600 secrets/*.txt
```

The expected files are:

| File | Used by |
|---|---|
| `secrets/db_password.txt` | MariaDB and WordPress |
| `secrets/db_root_password.txt` | MariaDB |
| `secrets/credentials.txt` | WordPress |

Never commit these files or copy their values into Markdown files.

### 4. Prepare host storage

The `Makefile` creates the required directories automatically:

- `/home/ekeller-/data/mariadb`
- `/home/ekeller-/data/wordpress`

The equivalent manual command is:

```bash
mkdir -p /home/ekeller-/data/mariadb
mkdir -p /home/ekeller-/data/wordpress
```

If the current VM user cannot create `/home/ekeller-/data`, create it once with appropriate administrative permissions and assign ownership to the user running Docker.

## Build and launch

```bash
make
```

This creates the host directories and runs:

```bash
docker compose -f srcs/docker-compose.yml up -d --build
```

On first boot, MariaDB initializes its data directory. WordPress then:

1. Waits until MariaDB responds.
2. Downloads WordPress core.
3. Creates `wp-config.php`.
4. Installs the site with the configured administrator.
5. Creates the second WordPress user.
6. Starts PHP-FPM in the foreground.

## Makefile usage

| Command | Effect | Persistent data |
|---|---|---|
| `make` or `make all` | Build and start the complete stack | Preserved |
| `make status` | Display Compose service status | Unchanged |
| `make logs` | Follow logs for all services | Unchanged |
| `make down` | Stop and remove project containers/network | Preserved |
| `make clean` | Run `down -v` and delete `/home/ekeller-/data` | Deleted |
| `make fclean` | Run `clean` and prune unused Docker images/build data | Deleted |
| `make re` | Destructively reset and rebuild the project | Deleted |

Use `make down` for a normal stop. The other cleanup targets must only be used when a complete data reset is intended.

## Docker Compose commands

```bash
# Validate and render the resolved configuration
docker compose -f srcs/docker-compose.yml config

# Build images
docker compose -f srcs/docker-compose.yml build

# Start containers
docker compose -f srcs/docker-compose.yml up -d

# Display service state
docker compose -f srcs/docker-compose.yml ps

# Follow logs
docker compose -f srcs/docker-compose.yml logs -f

# Stop while preserving persistent data
docker compose -f srcs/docker-compose.yml down
```

Do not add `-v` to `docker compose down` when the data must be preserved.

## Container and network management

```bash
# Inspect individual logs
docker logs nginx
docker logs wordpress
docker logs mariadb

# Open a shell
docker exec -it wordpress bash
docker exec -it mariadb bash

# Run WP-CLI
docker exec wordpress wp plugin list \
  --path=/var/www/html \
  --allow-root

# Connect to MariaDB; enter the local root secret when prompted
docker exec -it mariadb mariadb -u root -p

# Inspect the Compose bridge network
docker network inspect srcs_inception_net

# List project volumes
docker volume ls
```

Compose-generated resource names include the project-name prefix by default. With this repository layout, examples include `srcs_inception_net`, `srcs_wordpress_db`, and `srcs_wordpress_files`.

## Data persistence

The Compose volumes use the local driver with bind options:

| Data | Logical Compose volume | Host path |
|---|---|---|
| MariaDB database | `wordpress_db` | `/home/ekeller-/data/mariadb` |
| WordPress files | `wordpress_files` | `/home/ekeller-/data/wordpress` |

Inspect them with:

```bash
docker volume inspect srcs_wordpress_db
docker volume inspect srcs_wordpress_files
```

The inspection output must contain paths under `/home/ekeller-/data/`.

Data survives:

- `make down`
- Container recreation
- Docker restart
- VM reboot

Data does not survive `make clean`, `make fclean`, or `make re`.

To test persistence correctly, edit a WordPress page, run `make down`, reboot the VM, run `make`, and confirm that the edit remains.

## Project structure

```text
inception/
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── .gitignore
├── secrets/                         # Local ignored *.txt secret files
│   ├── db_password.txt
│   ├── db_root_password.txt
│   └── credentials.txt
└── srcs/
    ├── .env                         # Local non-sensitive configuration
    ├── docker-compose.yml
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/nginx.conf
        │   └── tools/generate_ssl.sh
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/www.conf
        │   └── tools/wp_setup.sh
        └── mariadb/
            ├── Dockerfile
            ├── conf/my.cnf
            └── tools/db_init.sh
```

## Troubleshooting

| Problem | Check | Resolution |
|---|---|---|
| Domain does not resolve | `getent hosts ekeller-.42.fr` | Add the required `/etc/hosts` entry |
| HTTPS is unreachable | `make status` and `docker logs nginx` | Start the stack or correct the reported NGINX error |
| WordPress reports a database error | `docker logs wordpress` and `docker logs mariadb` | Verify secrets and wait for MariaDB initialization |
| Port 443 is already used | `sudo lsof -i :443` | Stop the conflicting host service |
| Host volume cannot be created | Inspect `/home/ekeller-/data` permissions | Assign the directory to the user running Docker |

## eval
###simple setup
make status
docker port nginx
docker port wordpress
docker port mariadb
curl -kIv https://ekeller-.42.fr/

###nginx
docker port nginx

###wordpres
check users
docker exec wordpress \
  wp user list \
  --fields=ID,user_login,user_email,roles \
  --path=/var/www/html \
  --allow-root
https://ekeller-.42.fr/wp-admin/

###mariadb
docker exec -it mariadb mariadb -u root -p
SHOW DATABASES;
USE wordpress_db;
SHOW TABLES;
SELECT COUNT(*) AS post_count FROM wp_posts;
SELECT COUNT(*) AS user_count FROM wp_users;
docker exec -it wordpress \
  mariadb -h mariadb -u wp_user -p wordpress_db
SELECT DATABASE();
SHOW TABLES;
SELECT ID, post_title, post_status FROM wp_posts;
