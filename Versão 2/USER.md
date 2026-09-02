# User Documentation

## Introduction

This document explains how to use the Inception infrastructure.

The project provides a WordPress website running through three Docker services:

* **NGINX** — receives HTTPS requests.
* **WordPress + PHP-FPM** — runs the WordPress application.
* **MariaDB** — stores the WordPress database.

NGINX is the only service accessible from outside the Docker network.

## Starting the Project

From the project root, run:

```bash
make
```

This builds the required Docker images and starts the services.

To check that the containers are running:

```bash
docker ps
```

The expected services are:

```text
nginx
wordpress
mariadb
```

## Stopping the Project

To stop the containers:

```bash
make down
```

Stopping the containers does not remove the persistent project data.

## Accessing the Website

Open the following address in a web browser:

```text
https://jcosta-b.42.fr
```

The website is accessed through HTTPS using port `443`.

HTTP access through other ports is not part of the infrastructure.

## WordPress Administration Panel

The WordPress administration panel can be accessed at:

```text
https://jcosta-b.42.fr/wp-admin
```

Use the WordPress administrator credentials created during the project setup.

The administrator username does not use `admin`, `administrator`, or similar names, as required by the subject.

## Credentials

Sensitive credentials are stored locally and are not committed to the Git repository.

Depending on the project configuration, credentials can be found in:

```text
secrets/
```

or in the local secret configuration used by Docker.

Do not publish password files or other confidential information to Git.

## Checking the Services

### Check running containers

```bash
docker ps
```

### Check all containers

```bash
docker ps -a
```

### Check service logs

For example:

```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

### Check the Docker network

```bash
docker network ls
```

The project network should be present and connected to the project containers.

### Check persistent data

The project data is stored on the host under:

```text
/home/jcosta-b/data/
```

The directories contain persistent WordPress and MariaDB data.

## Restart Behavior

The containers are configured to restart automatically when they stop unexpectedly, according to the Docker Compose configuration.

## Troubleshooting

If the website is not accessible:

1. Check that the containers are running:

```bash
docker ps
```

2. Check the NGINX logs:

```bash
docker logs nginx
```

3. Check the WordPress logs:

```bash
docker logs wordpress
```

4. Check the MariaDB logs:

```bash
docker logs mariadb
```

5. Check that the domain points to the Virtual Machine IP:

```text
jcosta-b.42.fr
```

6. Check that the website is being accessed using:

```text
https://jcosta-b.42.fr
```

and not HTTP.
