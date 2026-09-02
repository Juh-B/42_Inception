*This project has been created as part of the 42 curriculum by jcosta-b.*

# Inception

## Description

Inception is a system administration project from the 42 curriculum. The goal is to build a small web infrastructure using Docker and Docker Compose inside a Virtual Machine.

The mandatory infrastructure is composed of three services:

* **NGINX** — web server and the only entry point to the infrastructure. It uses TLSv1.2/TLSv1.3 and exposes port `443`.
* **WordPress + PHP-FPM** — provides the WordPress website and processes PHP requests.
* **MariaDB** — stores the WordPress database.

The services run in separate Docker containers and communicate through a dedicated Docker network.

The project also uses two persistent volumes:

* One for the MariaDB database.
* One for the WordPress website files.

The domain used by the project is:

`jcosta-b.42.fr`

The infrastructure is built from custom Dockerfiles based on the penultimate stable version of Debian or Alpine. Ready-made application images are not used.

## Project Structure

```text
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/
└── srcs/
    ├── docker-compose.yml
    ├── .env
    └── requirements/
        ├── nginx/
        ├── wordpress/
        └── mariadb/
```

## Main Design Choices

### Docker

Docker is used to isolate each service into its own container. Each container has a specific responsibility and communicates with the others through a Docker network.

NGINX is the only service exposed to the host through port `443`.

### Virtual Machines vs Docker

A Virtual Machine emulates an entire operating system and generally requires more resources because it includes its own kernel and operating system environment.

Docker containers share the host kernel and isolate applications and their dependencies. They are lighter and faster to start, making Docker a good choice for this infrastructure.

### Secrets vs Environment Variables

Environment variables are useful for configuration values such as the domain name and usernames.

Secrets are more appropriate for confidential information such as passwords because they avoid storing sensitive values directly in Dockerfiles or the Git repository.

This project uses a `.env` file for configuration and Docker secrets/local secret files for sensitive credentials. Secret files are excluded from Git.

### Docker Network vs Host Network

A Docker network provides isolated communication between containers. Services can communicate using their container/service names without exposing every service to the host.

The host network would make containers use the host's network directly and would reduce this isolation.

For this project, a dedicated Docker network is used.

### Docker Volumes vs Bind Mounts

Docker volumes are managed by Docker and are useful for persistent application data.

Bind mounts connect a container directory directly to a directory on the host.

This project uses persistent storage under:

```text
/home/jcosta-b/data/
```

This allows the database and WordPress files to survive container recreation.

## Instructions

### Prerequisites

The project must be run inside a Virtual Machine with:

* Docker
* Docker Compose
* Make
* Git

### Configuration

Before starting the project, configure the `.env` file:

```text
srcs/.env
```

Example:

```env
DOMAIN_NAME=jcosta-b.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wordpress
```

Passwords and other confidential information must not be placed in the Git repository.

The local `/etc/hosts` file must point the domain to the Virtual Machine IP:

```text
<VM_IP> jcosta-b.42.fr
```

### Start the project

From the project root:

```bash
make
```

or:

```bash
make setup
make up
```

The Makefile builds the Docker images and starts the infrastructure using Docker Compose.

### Stop the project

```bash
make down
```

### Clean the project

The available Makefile targets can be used to stop, rebuild or clean the infrastructure.

Check the Makefile for the exact commands available in the project.

### Access the website

Open:

```text
https://jcosta-b.42.fr
```

The infrastructure is accessible only through HTTPS on port `443`.

The WordPress administration panel is available at:

```text
https://jcosta-b.42.fr/wp-admin
```

## Resources

The following resources were used to study and implement the project:

* Docker documentation
* Docker Compose documentation
* NGINX documentation
* WordPress documentation
* PHP-FPM documentation
* MariaDB documentation
* OpenSSL documentation
* 42 Inception subject

### AI Usage

AI tools were used as a learning and development assistant during the project.

They were used mainly for:

* Understanding Docker and Docker Compose concepts.
* Understanding containers, networks, volumes and environment variables.
* Studying NGINX, PHP-FPM and MariaDB configuration.
* Troubleshooting configuration and runtime errors.
* Reviewing Dockerfiles, shell scripts and Docker Compose configuration.
* Understanding project requirements and evaluation criteria.
* Improving and reviewing the project documentation.

The final configuration, commands and implementation were reviewed and tested as part of the project development.
