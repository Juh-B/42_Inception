*This project has been created as part of the 42 curriculum by jcosta-b.*

# Inception

## Description

Inception is a system-administration project that builds a small web infrastructure with Docker and Docker Compose. Each service runs in a dedicated container built from a `debian:bookworm` base image; no ready-made service images are used.

The stack provides:

- NGINX as the only external entry point, serving HTTPS on port 443 with TLSv1.2 or TLSv1.3.
- WordPress with PHP-FPM, without NGINX.
- MariaDB, without NGINX.
- Persistent storage for the WordPress files and MariaDB database.
- A private bridge network for communication between the containers.

Dockerfiles define how the individual service images are built. Docker Compose describes how those images are built and run together, including their network, volumes, secrets, dependencies, and restart policies. The root `Makefile` provides short commands for the main Compose operations.

The image produced by a Dockerfile is the same kind of image whether it is started manually or through Compose. Without Compose, each `docker build`, `docker run`, network, volume, secret, port, and restart option must be managed separately. Compose records those relationships in one declarative file and starts the complete multi-container application consistently.

### Included sources

The project sources are organized by responsibility:

- `srcs/docker-compose.yml` defines the complete stack.
- `srcs/requirements/nginx/` contains the NGINX Dockerfile, TLS setup script, and server configuration.
- `srcs/requirements/wordpress/` contains the WordPress/PHP-FPM Dockerfile, pool configuration, and installation script.
- `srcs/requirements/mariadb/` contains the MariaDB Dockerfile, database configuration, and initialization script.
- `secrets/` contains local secret files and must never be committed.
- `/home/jcosta-b/data/` contains persistent data on the Docker host.

Keeping each service in its own directory makes its build context explicit and prevents unrelated configuration from being copied into an image. Runtime orchestration remains centralized in the Compose file.

## Main design choices

### Virtual machines vs Docker

| | Virtual machine | Docker container |
|---|---|---|
| Isolation | Runs a complete guest OS and kernel | Isolates processes while sharing the host kernel |
| Startup | Usually slower | Usually faster |
| Overhead | Higher CPU, memory, and disk overhead | Lower overhead |
| Typical use | Full OS isolation or different kernels | Reproducible, lightweight services |

The project itself must run inside a virtual machine, while Docker separates the services inside that VM.

### Secrets vs environment variables

| | Docker secret | Environment variable |
|---|---|---|
| Delivery | Mounted as a file under `/run/secrets/` | Added to the process environment |
| Visibility | Read only by services that receive the secret | Can appear in container inspection output |
| Appropriate data | Passwords and other confidential values | Domain names, usernames, database names, and other non-sensitive settings |

Passwords are kept in ignored files under `secrets/`. Non-sensitive configuration is stored locally in `srcs/.env`.

### Docker bridge network vs host network

| | Docker bridge network | Host network |
|---|---|---|
| Isolation | Uses a private container network | Shares the host network namespace |
| Service discovery | Containers resolve Compose service names | Services must use host addresses and ports |
| Exposure | Only explicitly published ports are reachable externally | Container listeners are directly attached to the host |

This project uses the `inception_net` bridge network. MariaDB and WordPress are not published to the host; only NGINX publishes port 443.

### Docker volumes vs bind mounts

| | Docker-managed volume | Bind mount |
|---|---|---|
| Host location | Selected and managed by Docker | Explicitly selected in the configuration |
| Lifecycle | Managed with Docker volume commands | Managed as normal host files and directories |
| Portability | Does not depend on a fixed host path | Depends on the configured host path |

This project declares named Compose volumes but configures the local driver to bind them to the required host directories:

- MariaDB: `/home/jcosta-b/data/mariadb`
- WordPress: `/home/jcosta-b/data/wordpress`

This preserves Docker volume attachment semantics while making the required host storage paths explicit.

## Instructions

### Prerequisites

- A Linux virtual machine.
- Docker Engine and Docker Compose v2.
- `make` and `openssl`.
- Permission to use Docker without `sudo`, or an equivalent local setup.
- The following local host entry:

```text
127.0.0.1 jcosta-b.42.fr
```

### Configure a clean clone

The real `.env` and secret files are intentionally ignored by Git. Create them locally before the first build.

Create `srcs/.env` with the non-sensitive configuration:

```bash
mkdir -p secrets

cat > srcs/.env <<'EOF'
DOMAIN_NAME=jcosta-b.42.fr
MYSQL_DATABASE=wordpress_db
MYSQL_USER=wp_user
WP_TITLE=Inception jcosta-b
WP_ADMIN_USER=superuser
WP_ADMIN_EMAIL=superuser@42.fr
WP_USER_LOGIN=editor_user
WP_USER_EMAIL=editor@42.fr
EOF
```

Generate local passwords:

```bash
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

Do not commit these files or paste their values into documentation.

### Build and run

```bash
# Build the three images and start the stack
make

# Display container status
make status

# Follow service logs
make logs

# Stop containers while preserving data
make down
```

Open `https://jcosta-b.42.fr` and accept the warning for the self-signed certificate. The administration panel is available at `https://jcosta-b.42.fr/wp-admin`.

The cleanup targets are destructive:

```bash
# Remove project containers, Compose volumes, and persistent host data
make clean

# Perform make clean and prune unused Docker images/build data
make fclean
```

Use `make down`, not `make clean` or `make fclean`, when data must be preserved.

For end-user operations, see `USER_DOC.md`. For development, configuration, persistence, and defense checks, see `DEV_DOC.md`.

## Resources

### Documentation

- [Docker documentation](https://docs.docker.com/)
- [Docker Compose reference](https://docs.docker.com/compose/compose-file/)
- [NGINX documentation](https://nginx.org/en/docs/)
- [WordPress CLI documentation](https://wp-cli.org/)
- [MariaDB documentation](https://mariadb.com/kb/en/)

### AI usage

AI tools (Antigravity / Claude and OpenAI Codex) were used for:

- Generating the initial project structure and Dockerfile boilerplate.
- Drafting NGINX, PHP-FPM, and MariaDB configuration.
- Structuring the MariaDB and WordPress initialization scripts.
- Drafting and reviewing `README.md`, `USER_DOC.md`, and `DEV_DOC.md`.

All generated material was reviewed and adjusted by the project author, who remains responsible for the submitted work.
