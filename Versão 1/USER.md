# Inception — User Documentation

## 1. Overview

Inception is a small web infrastructure built with Docker Compose.

The infrastructure is composed of three services:

- **NGINX** — HTTPS entry point and reverse proxy.
- **WordPress + PHP-FPM** — web application.
- **MariaDB** — database used by WordPress.

The services run in separate Docker containers and communicate through a dedicated Docker network.

The infrastructure is accessible through:

```text
https://<login>.42.fr

where <login> must be replaced by the login used for the 42 project.

2. Services
Service	Purpose	Access
NGINX	HTTPS reverse proxy	Port 443
WordPress + PHP-FPM	Website and PHP processing	Internal
MariaDB	WordPress database	Internal

Only NGINX exposes a port to the host.

WordPress and MariaDB are accessible only through the internal Docker network.

3. Starting the Infrastructure

From the project root:

make

or:

make up

The Makefile will:

Create the required data directories.
Create the local secret files if they do not exist.
Configure the local domain.
Build the Docker images.
Create the Docker network and volumes.
Start the containers.

After the containers have started, access:

https://<login>.42.fr

The browser may display a warning because the project uses a self-signed TLS certificate.

This is expected for the local development environment.

4. WordPress

The WordPress website is available at:

https://<login>.42.fr

The WordPress administration panel can be accessed at:

https://<login>.42.fr/wp-admin

The administrator credentials are defined during the initial project setup.

The administrator username must not contain:

admin
administrator

or variations of these names.

5. Local Domain

The project uses the domain:

<login>.42.fr

For local development, this domain must resolve to the machine running Docker.

The project setup handles the /etc/hosts configuration automatically.

The expected entry is similar to:

127.0.0.1 <login>.42.fr

If the domain cannot be resolved, check:

cat /etc/hosts

and verify that the expected entry exists.

6. HTTPS / TLS

NGINX is the only entry point into the infrastructure.

The project exposes:

443

NGINX accepts only:

TLSv1.2
TLSv1.3

HTTP is not used as an external entry point.

The certificate is self-signed because the infrastructure is intended to run locally.

To inspect the TLS connection:

openssl s_client -connect <login>.42.fr:443 -servername <login>.42.fr
7. Stopping the Infrastructure

To stop the containers:

make down

This removes the containers but keeps the persistent data.

The WordPress website and MariaDB database should therefore remain available after restarting the project.

8. Restarting the Project

To rebuild and restart the complete infrastructure:

make re

This performs a complete cleanup followed by a new build.

Warning: depending on the Makefile configuration, a full cleanup may delete the persistent data.

Do not use make re if you need to preserve an existing WordPress installation or database.

9. Persistent Data

Two persistent data locations are used by the project:

/home/<login>/data/mariadb
/home/<login>/data/wordpress

They contain:

MariaDB
/home/<login>/data/mariadb

Contains the MariaDB database files.

WordPress
/home/<login>/data/wordpress

Contains the WordPress installation, themes, plugins and uploaded files.

These directories are located on the host machine and are mounted into the corresponding containers.

10. Checking the Containers

List running containers:

docker ps

The expected services are:

nginx
wordpress
mariadb

To see all containers, including stopped ones:

docker ps -a

Docker Compose can also be used:

docker compose -f srcs/docker-compose.yml ps
11. Checking Logs

To inspect a service:

docker logs nginx
docker logs wordpress
docker logs mariadb

To follow logs in real time:

docker logs -f nginx
12. Testing the Website

A simple HTTPS request can be performed with:

curl -k -I https://<login>.42.fr

The -k option allows curl to connect to the self-signed certificate.

A successful configuration should return an HTTP response from NGINX.

13. Database Persistence Test

The MariaDB container can be accessed with:

docker exec -it mariadb mariadb -u root -p

After entering the root password:

SHOW DATABASES;

The WordPress database should be present.

To inspect its tables:

USE wordpress;
SHOW TABLES;
14. Docker Network

The three services communicate through a dedicated Docker network.

The expected architecture is:

                    HTTPS :443
                        |
                        v
                  +-----------+
                  |   NGINX   |
                  +-----------+
                        |
                        v
                  +-----------+
                  | WordPress |
                  | PHP-FPM   |
                  +-----------+
                        |
                        v
                  +-----------+
                  | MariaDB   |
                  +-----------+

             Docker internal network

MariaDB does not expose its port to the host.

WordPress does not expose its PHP-FPM port to the host.

Only NGINX is accessible from outside the Docker network.

15. Makefile Commands
Command	Purpose
make	Build and start the infrastructure
make up	Build and start the infrastructure
make down	Stop and remove containers
make clean	Remove containers, volumes and persistent data
make fclean	Complete Docker cleanup
make re	Clean everything and rebuild

For normal use, the recommended commands are:

make

and:

make down
16. Security Notes

Passwords are not stored directly inside Dockerfiles.

Sensitive credentials are stored using Docker Secrets.

The .env file contains configuration values that are not considered secret, such as:

domain name
database name
database username
internal ports

Secret files must never be committed to Git.

The secrets/ directory should therefore be excluded from version control.

17. Troubleshooting
The website cannot be reached

Check that all containers are running:

docker ps

Then check NGINX logs:

docker logs nginx

Also verify the domain:

getent hosts <login>.42.fr
WordPress is not loading

Check the WordPress container:

docker logs wordpress

Then verify that MariaDB is running:

docker logs mariadb

WordPress depends on MariaDB being available through the Docker network.

The database is unavailable

Check:

docker ps

and:

docker logs mariadb

Verify that the MariaDB data directory exists:

ls -la /home/<login>/data/mariadb
Containers keep restarting

Inspect the logs of the affected service:

docker logs <service>

For example:

docker logs mariadb

A container that exits immediately usually indicates a configuration or initialization problem.

18. Expected Final Result

When the project is running correctly:

https://<login>.42.fr

should display the WordPress website.

The infrastructure should contain exactly three mandatory services:

NGINX
WordPress + PHP-FPM
MariaDB

Only port 443 should be exposed to the host.

The WordPress website and MariaDB database must remain persistent across container restarts.
