# Developer Documentation

## Introduction

This document explains how to set up, build, run and manage the Inception project.

The infrastructure is built with Docker Compose and contains separate containers for:

* NGINX
* WordPress + PHP-FPM
* MariaDB

The services communicate through a dedicated Docker network.

## Prerequisites

The project must be run inside a Virtual Machine.

Required software:

* Docker
* Docker Compose
* Make
* Git

Check the installed versions with:

```bash
docker --version
docker-compose --version
make --version
git --version
```

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
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        └── mariadb/
            ├── Dockerfile
            ├── conf/
            └── tools/
        
```

All configuration files required by the project are located inside `srcs/`.

## Configuration

### Environment Variables

The main non-sensitive configuration values are stored in:

```text
srcs/.env
```

Example:

```env
DOMAIN_NAME=jcosta-b.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wordpress
```

Passwords must not be stored in Dockerfiles or committed to Git.

### Secrets

Sensitive information is stored locally in the `secrets/` directory or through the Docker secrets configuration used by the project.

Example files may include:

```text
secrets/
├── credentials.txt
├── db_password.txt
└── db_root_password.txt
```

These files must be ignored by Git.

## Domain Configuration

The project domain must point to the Virtual Machine IP.

Add the following entry to the VM's `/etc/hosts`:

```text
<VM_IP> jcosta-b.42.fr
```

This allows the browser to resolve the project domain locally.

## Building and Starting

From the root of the repository:

```bash
make
```

The Makefile is responsible for preparing the required directories and starting Docker Compose with the project configuration.

The Docker Compose file is:

```text
srcs/docker-compose.yml
```

To build and start the services directly:

```bash
docker-compose -f srcs/docker-compose.yml up --build -d
```

## Stopping

Stop the services with:

```bash
make down
```

or:

```bash
docker-compose -f srcs/docker-compose.yml down
```

## Container Management

List running containers:

```bash
docker ps
```

List all containers:

```bash
docker ps -a
```

View logs:

```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

Follow logs:

```bash
docker logs -f nginx
```

Open a shell inside a running container when necessary for debugging:

```bash
docker exec -it nginx sh
```

The exact shell command may depend on the base distribution used by the container.

## Docker Images

List project images:

```bash
docker images
```

Each image follows the name of its corresponding service.

The project does not use ready-made application images from DockerHub. The application images are built locally using the project's Dockerfiles.

The Dockerfiles use Alpine or Debian as their base distribution, according to the project requirements.

## Docker Network

The services communicate through a dedicated Docker network defined in:

```text
srcs/docker-compose.yml
```

List Docker networks:

```bash
docker network ls
```

Inspect the project network:

```bash
docker network inspect <network_name>
```

The containers use the Docker network to communicate with each other without using host networking or deprecated container links.

## Persistent Data

The project uses two persistent storage locations:

```text
/home/jcosta-b/data/mariadb
/home/jcosta-b/data/wordpress
```

MariaDB data is stored in the first location.

WordPress website files are stored in the second location.

This data remains available when containers are stopped or recreated.

## Volumes

List Docker volumes:

```bash
docker volume ls
```

Inspect a volume:

```bash
docker volume inspect <volume_name>
```

Persistent data should not be removed during normal container shutdown.

## Restart Policy

The Docker Compose configuration uses a restart policy so that containers can restart automatically after an unexpected failure.

The restart configuration can be checked with:

```bash
docker inspect <container_name>
```

## Rebuilding the Project

After changing a Dockerfile or configuration, rebuild the images:

```bash
docker-compose -f srcs/docker-compose.yml up --build -d
```

To stop and remove the containers and network:

```bash
docker-compose -f srcs/docker-compose.yml down
```

Persistent data should remain in the host data directories unless it is explicitly removed.

## Cleaning

Be careful when removing volumes because they contain persistent application data.

To inspect resources before removing anything:

```bash
docker ps -a
docker images
docker volume ls
docker network ls
```

## Security

The following rules must always be respected:

* Never commit passwords to Git.
* Never put passwords directly inside Dockerfiles.
* Keep secret files outside version control.
* Do not use the `latest` tag.
* NGINX must be the only public entry point.
* Only port `443` should be exposed for the infrastructure.
* TLSv1.2 or TLSv1.3 must be used.
* Services must run in separate containers.
* Containers must communicate through the Docker network.
* Do not use `network: host`.
* Do not use `links`.
* Do not use infinite loops such as `tail -f`, `sleep infinity` or `while true` to keep containers alive.
