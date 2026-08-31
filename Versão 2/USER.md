# USER_DOC.md — User documentation

## Services provided

| Service | URL | Purpose |
|---|---|---|
| WordPress website | `https://jcosta-b.42.fr` | Public website |
| WordPress administration | `https://jcosta-b.42.fr/wp-admin` | Dashboard for managing the site |

NGINX is the only public entry point. MariaDB and PHP-FPM are available only to other containers on the private Docker network.

Because the TLS certificate is self-signed, a browser warning is expected during local use.

## Starting and stopping the project

Run these commands from the repository root:

```bash
# Build images when necessary and start all services
make

# Check container status
make status

# Follow logs from all services
make logs

# Stop the containers without deleting WordPress or database data
make down
```

The initial WordPress installation can take a short time while MariaDB starts and WordPress is downloaded and configured.

## Accessing the website

Ensure that the machine opening the website resolves the project domain to the Docker host. For local access from the VM, `/etc/hosts` should contain:

```text
127.0.0.1 jcosta-b.42.fr
```

Then open:

- Website: `https://jcosta-b.42.fr`
- Administration panel: `https:/jcosta-b.42.fr/wp-admin`

The configured WordPress users are:

| Role | Login | Password location |
|---|---|---|
| Administrator | `superuser` | `ADMIN_PASSWORD` in `secrets/credentials.txt` |
| Author | `editor_user` | `USER_PASSWORD` in `secrets/credentials.txt` |

Neither password should be copied into Git, documentation, screenshots, or evaluation notes.

## Credentials

Local credentials are stored in ignored files at the repository root:

| File | Contents |
|---|---|
| `secrets/db_password.txt` | Password for the MariaDB `wp_user` account |
| `secrets/db_root_password.txt` | Password for the MariaDB `root` account |
| `secrets/credentials.txt` | WordPress administrator and author passwords |

Restrict access to these files:

```bash
chmod 600 secrets/*.txt
```

These secrets are used during the first database and WordPress initialization. Editing a secret file later does not automatically change an account that already exists.

For an existing installation:

- Change WordPress passwords from the WordPress profile/account screens, or with an appropriate WP-CLI command.
- A MariaDB password change must be applied to the database account and then synchronized with the matching secret. If the `wp_user` password changes, the WordPress database configuration must also be updated.
- Back up the data before changing database credentials.

Do not use `make clean` merely to change a password: it deletes the existing WordPress and MariaDB data.

## Basic checks

```bash
# Containers should be running
make status

# Review service logs
docker logs nginx
docker logs wordpress
docker logs mariadb

# The HTTPS endpoint should respond
curl -kI https://jcosta-b.42.fr

# HTTP must not be available
curl -I --max-time 5 http://jcosta-b.42.fr

# MariaDB should respond; enter the root password when prompted
docker exec -it mariadb mariadb-admin ping -u root -p

# List the configured WordPress users
docker exec wordpress wp user list \
  --path=/var/www/html \
  --allow-root
```

If a service is not running, inspect its logs before restarting the stack.

## Persistence and cleanup

WordPress files and MariaDB data survive `make down`, container recreation, and a VM reboot because they are stored under `/home/jcosta-b/data` on the host.

```bash
# Safe stop: persistent data remains
make down

# Destructive reset: deletes project containers, volumes, and host data
make clean

# Destructive reset plus pruning unused Docker images/build data
make fclean
```

After `make clean` or `make fclean`, the next `make` creates a new WordPress installation. Back up any required content first.
