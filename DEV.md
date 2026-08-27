---

# `dev.md`

```md
# Inception — Developer Documentation

## 1. Project Structure

The project is organized into a Makefile, Docker Compose configuration, service-specific Dockerfiles and initialization scripts.

The expected structure is:

```text
.
├── Makefile
├── README.md
├── user.md
├── dev.md
├── secrets/
│   ├── db_password.txt
│   ├── db_root_password.txt
│   └── credentials.txt
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   └── tools/
        │       └── init_db.sh
        │
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── www.conf
        │   └── tools/
        │       └── init_wp.sh
        │
        └── nginx/
            ├── Dockerfile
            ├── conf/
            │   └── nginx.conf
            └── tools/
                └── init_nginx.sh

Each mandatory service has its own directory and Dockerfile.

2. Architecture

The infrastructure contains three independent services:

                         Host
                          |
                       Port 443
                          |
                          v
                    +-----------+
                    |   NGINX   |
                    | TLS 1.2/  |
                    | TLS 1.3   |
                    +-----------+
                          |
                    Docker Network
                          |
                          v
                  +---------------+
                  |   WordPress   |
                  |    PHP-FPM    |
                  +---------------+
                          |
                    Docker Network
                          |
                          v
                    +-----------+
                    |  MariaDB  |
                    +-----------+

Each service runs in a dedicated container.

The containers communicate using the Docker Compose service names.

For example:

wordpress -> mariadb

The WordPress container can reach MariaDB using:

mariadb

as the hostname.

No network: host, links or --link mechanisms are used.

3. Docker Base Images

The project uses Debian as the base distribution.

Each service starts from the same supported Debian release family:

FROM debian:bookworm

The Dockerfiles install only the software required by their respective service.

The project does not use pre-built service images from DockerHub.

Debian itself is used as the permitted base image.

4. MariaDB Container

The MariaDB Dockerfile installs:

mariadb-server

The container is responsible only for the database service.

MariaDB data is stored in:

/var/lib/mysql

which is connected to the host through the persistent MariaDB volume.

The initialization script performs the first-time database setup.

It:

Creates the MariaDB runtime directory.
Fixes ownership of the database directories.
Initializes the database system if necessary.
Reads credentials from Docker Secrets.
Creates the WordPress database.
Creates the WordPress database user.
Configures the root password.
Starts MariaDB in the foreground.

The final MariaDB process is executed with exec, allowing it to become PID 1 inside the container.

5. WordPress Container

The WordPress container contains:

WordPress
PHP-FPM
PHP MySQL extension

and the PHP extensions required by WordPress.

NGINX is deliberately not installed in this container.

The WordPress files are stored in:

/var/www/html

and persist on the host through:

/home/<login>/data/wordpress

The initialization script:

Waits for MariaDB to become available.
Downloads WordPress when it is not already installed.
Creates the WordPress configuration.
Configures the database connection.
Installs WordPress.
Creates the administrator account.
Creates the second WordPress user.
Starts PHP-FPM in the foreground.

PHP-FPM listens on the internal Docker network and is not published directly to the host.

6. NGINX Container

NGINX is the only publicly accessible service.

It exposes:

443

The NGINX configuration enables:

TLSv1.2
TLSv1.3

The certificate and private key are generated during image creation for the local development environment.

NGINX acts as a reverse proxy between the client and PHP-FPM.

Requests for PHP files are forwarded to:

wordpress:9000

The WordPress volume is also mounted into NGINX so that NGINX can serve the required WordPress files.

NGINX is started in the foreground:

nginx -g "daemon off;"

This allows NGINX to remain the main process of the container without using artificial infinite loops.

7. Docker Compose

The Docker Compose file defines:

three services
one dedicated network
two persistent volumes
Docker Secrets
service dependencies
restart policies

The mandatory services are:

mariadb
wordpress
nginx

Each service has its own build context and Dockerfile.

Example:

mariadb:
  build:
    context: ./requirements/mariadb
    dockerfile: Dockerfile

The Docker images are therefore built locally.

8. Network

A dedicated bridge network is created:

networks:
  inception:
    driver: bridge

All three services are connected to this network.

The Docker network provides internal DNS resolution based on service names.

For example:

wordpress -> mariadb

resolves mariadb to the MariaDB container.

No service except NGINX needs to expose a port on the host.

9. Volumes

Two persistent storage locations are required.

MariaDB

Host:

/home/<login>/data/mariadb

Container:

/var/lib/mysql
WordPress

Host:

/home/<login>/data/wordpress

Container:

/var/www/html

The Docker Compose file uses local volumes with bind-mount options so that the required host paths are explicitly defined.

This satisfies the project requirement that the volumes are located under:

/home/<login>/data
10. Environment Variables

Non-sensitive configuration is stored in:

srcs/.env

Examples include:

DOMAIN_NAME
MYSQL_DATABASE
MYSQL_USER
NGINX_INTERNAL_PORT
WORDPRESS_INTERNAL_PORT
MARIADB_INTERNAL_PORT

Sensitive information must not be stored in .env.

Passwords are provided through Docker Secrets.

11. Docker Secrets

The project uses three secret files:

secrets/
├── db_password.txt
├── db_root_password.txt
└── credentials.txt

They are mounted inside containers under:

/run/secrets/

For example:

/run/secrets/db_password

The initialization scripts read these files when configuring the services.

Secret files must not be committed to the Git repository.

The secrets/ directory must therefore be included in .gitignore.

12. Makefile

The Makefile is the main entry point for building and managing the infrastructure.

The main targets are:

make
make up
make down
make clean
make fclean
make re
make

Builds and starts the infrastructure.

Equivalent to:

make up
make up

Creates the required directories and starts Docker Compose with image rebuilding enabled.

make down

Stops and removes the containers while preserving persistent data.

make clean

Stops the infrastructure and removes Docker resources associated with the project.

The persistent data directories may also be removed depending on the implementation.

make fclean

Performs a more complete Docker cleanup.

make re

Rebuilds the project from a clean state.

Because a full clean may remove persistent data, this target should not be used when database or WordPress data needs to be preserved.

13. Container Process Management

A Docker container should run a real service process rather than an artificial infinite loop.

The project therefore does not use:

tail -f
sleep infinity
while true

as a mechanism to keep containers alive.

The final service process becomes PID 1 using exec.

Examples:

exec mariadbd ...
exec php-fpm8.2 -F
exec nginx -g "daemon off;"

This allows Docker to correctly monitor the main process and restart the container when necessary.

14. Container Restart Policy

The services use a Docker restart policy:

restart: unless-stopped

This allows a container to restart automatically if its main process exits unexpectedly.

The container will remain stopped when explicitly stopped by the user.

15. Building the Project

To build and start the complete infrastructure:

make

To inspect the generated images:

docker images

To inspect running containers:

docker ps

To inspect the Compose configuration before starting:

docker compose -f srcs/docker-compose.yml config
16. Testing Individual Services

During development, each service can be tested independently.

MariaDB

Build:

docker compose -f srcs/docker-compose.yml build mariadb

Start:

docker compose -f srcs/docker-compose.yml up mariadb

Inspect:

docker logs mariadb
WordPress

Build:

docker compose -f srcs/docker-compose.yml build wordpress

Inspect:

docker logs wordpress

Verify PHP-FPM:

docker exec wordpress ps aux
NGINX

Build:

docker compose -f srcs/docker-compose.yml build nginx

Inspect:

docker logs nginx

Check the NGINX configuration:

docker exec nginx nginx -t
17. Testing the Network

List Docker networks:

docker network ls

Inspect the project network:

docker network inspect inception

The three mandatory containers should be connected to the same network.

From the WordPress container, MariaDB should be resolvable by its service name:

mariadb

The important point is that containers communicate through Docker's internal network rather than through host networking.

18. Testing Persistence

Start the project:

make

Create or modify data in WordPress.

Then stop the infrastructure:

make down

Start it again:

make

The WordPress installation and database contents should still be present.

The host directories can be inspected with:

ls -la /home/<login>/data/wordpress

and:

ls -la /home/<login>/data/mariadb
19. TLS Verification

The supported TLS protocols can be inspected with:

openssl s_client -connect <login>.42.fr:443 -tls1_2

and:

openssl s_client -connect <login>.42.fr:443 -tls1_3

The NGINX configuration should contain:

ssl_protocols TLSv1.2 TLSv1.3;

Older TLS versions must not be enabled.

20. Git and Sensitive Files

Before committing the project, verify that no credentials are tracked.

The repository must not contain:

database passwords
root passwords
WordPress administrator passwords
private keys
other confidential credentials

The following directory should remain local:

secrets/

A suitable .gitignore should include:

secrets/

The .env file should contain only non-sensitive configuration.

21. Development Workflow

A recommended development workflow is:

1. Modify a Dockerfile or configuration
             |
             v
2. Build the affected service
             |
             v
3. Start the service
             |
             v
4. Inspect logs
             |
             v
5. Test the service
             |
             v
6. Test communication with the other services
             |
             v
7. Test persistence
             |
             v
8. Run the complete infrastructure

For the final validation, the complete stack should be tested from a clean state.
