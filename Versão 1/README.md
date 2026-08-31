This project has been created as part of the 42 curriculum by jcosta-b

# Inception

> 42 School — System Administration / Docker

## About

Inception is a Docker-based infrastructure project from the 42 curriculum.

The goal is to build a small web infrastructure from scratch using Docker Compose, without relying on pre-built application images.

The infrastructure contains three independent services:

- NGINX
- WordPress + PHP-FPM
- MariaDB

Each service runs in its own container and communicates with the others through a dedicated Docker bridge network.

The project is designed to expose only HTTPS through NGINX on port 443.

---

## Architecture

```text
                         HOST
                          |
                       HTTPS :443
                          |
                          v
                  +---------------+
                  |     NGINX     |
                  |   TLS 1.2/1.3 |
                  +-------+-------+
                          |
                       FastCGI
                          |
                          v
                  +---------------+
                  |   WORDPRESS   |
                  |    PHP-FPM    |
                  +-------+-------+
                          |
                        MySQL
                          |
                          v
                  +---------------+
                  |    MARIADB    |
                  +---------------+

                    Docker network
                       inception


Services
NGINX

NGINX is the only service directly accessible from the host.

Responsibilities:

HTTPS termination
TLS 1.2 / TLS 1.3
Reverse proxy to PHP-FPM
Serving WordPress files
Port 443
WordPress

WordPress runs with PHP-FPM.

Responsibilities:

WordPress application
PHP execution
Communication with MariaDB

NGINX communicates with PHP-FPM through the Docker network.

MariaDB

MariaDB stores the WordPress database.

It is not exposed to the host.

Technologies
Docker
Docker Compose
Debian Bookworm
NGINX
PHP-FPM
WordPress
MariaDB
Docker Secrets
Make

The application images are built locally from custom Dockerfiles.

No pre-built NGINX, WordPress or MariaDB Docker image is used.

Project Structure

.
├── Makefile
├── README.md
├── USER.md
├── DEV.md
├── .gitignore
│
├── secrets/
│   └── .gitkeep
│
└── srcs/
    ├── .env
    ├── docker-compose.yml
    │
    └── requirements/
        ├── tools/
        │   └── setup.sh
        │
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


Getting Started

The project must be executed inside a Linux virtual machine.

Before starting, make sure Docker, Docker Compose and Make are available.

Run:

make

or:

make up

The setup script will:

Configure the local domain.
Create the required data directories.
Create Docker Secrets when they do not already exist.
Build the three Docker images.
Create the Docker network.
Create the persistent volumes.
Start the containers.
Domain

The project uses the following domain format:

<login>.42.fr

For example:

jdoe.42.fr

The domain is configured to resolve locally to:

127.0.0.1
Persistent Data

The project requires two persistent storage locations:

/home/<login>/data/mariadb
/home/<login>/data/wordpress

MariaDB stores its database files in:

/home/<login>/data/mariadb

WordPress stores its website files in:

/home/<login>/data/wordpress

The data survives container restarts and normal make down operations.

Commands
Start
make

or:

make up
Stop
make down
Clean project data
make clean

This removes:

containers
project images
Docker volumes
WordPress data
MariaDB data
Full Docker cleanup
make fclean
Rebuild
make re
Logs
make logs
Status
make status
Security

Passwords are not stored in:

Dockerfiles
docker-compose.yml
.env
source code

Docker Secrets are used for:

MariaDB application password
MariaDB root password
WordPress administrator password

The secrets/ directory is ignored by Git.

Network

The three services communicate through the Docker network:

inception

Docker's internal DNS allows services to communicate using their service names.

For example:

wordpress -> mariadb
nginx     -> wordpress

No host networking or legacy Docker links are used.

NGINX and TLS

NGINX is the only service exposed to the host.

The public endpoint is:

https://<login>.42.fr

Only port 443 is published.

NGINX accepts:

TLSv1.2
TLSv1.3

Older TLS protocols are disabled.

The project uses a locally generated self-signed certificate.

Therefore, browsers may display a certificate warning.

Container Design

Each container has one main responsibility:

nginx     -> web server / HTTPS
wordpress -> PHP-FPM / WordPress
mariadb   -> database

The main service process runs in the foreground and is executed as PID 1 through exec.

The containers do not use infinite loops such as:

tail -f
sleep infinity
while true

The WordPress initialization script uses a finite retry mechanism to wait for MariaDB during startup.

Persistence Test

To verify persistence:

Start the project.
Open WordPress.
Create or modify some content.
Run:
make down
Start again:
make

The WordPress installation and database should still exist.

Complete Reset

To recreate the infrastructure from scratch:

make fclean
make

This removes the project's persistent data and rebuilds the infrastructure.

Mandatory Scope

This repository intentionally implements only the mandatory part of Inception.

No bonus services are included.

The infrastructure is therefore limited to:

NGINX
WordPress + PHP-FPM
MariaDB
Docker network
WordPress volume
MariaDB volume
TLS
Docker Secrets
