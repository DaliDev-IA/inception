# Inception — Developer Guide

This guide describes how to build, configure, start and inspect Inception on the Debian VM.

## 1. Requirements

Install and verify:

- Docker Engine
- Docker Compose (`docker compose`)
- GNU Make (`make`)
- Git

Useful checks:

```bash
docker --version
docker compose version
make --version
```

Docker commands must be executed by a user with permission to access the Docker daemon.

All project commands below assume the terminal is at the repository root (for example, `~/projects/inception`).

## 2. Source tree

The root `Makefile` calls `srcs/docker-compose.yml`. Each service has its own Dockerfile, configuration folder (`conf/`) and startup script (`tools/setup.sh`).

- MariaDB configuration: `srcs/requirements/mariadb/conf/50-server.cnf`
- WordPress PHP-FPM configuration: `srcs/requirements/wordpress/conf/www.conf`
- NGINX configuration: `srcs/requirements/nginx/conf/nginx.conf`

The startup scripts initialize their services and run the main process in the foreground.

## 3. Prepare local configuration

Create `srcs/.env` on the VM with the following keys. These are example **non-secret** settings for the current project:

```dotenv
DOMAIN_NAME=mohchams.42.fr
DB_HOST=mariadb
DB_NAME=wordpress
DB_USER=wpuser
WP_TITLE=Inception
WP_ADMIN_USER=mohchams_master
WP_ADMIN_EMAIL=YOUR_ADMIN_EMAIL
WP_USER=mohchams_user
WP_USER_EMAIL=YOUR_SECOND_EMAIL
```

Replace the email placeholders with real **different** email addresses. WordPress cannot create the two accounts with the same email address.

Create the secret directory:

```bash
mkdir -p srcs/secrets
chmod 700 srcs/secrets
```

Create these four local **text files**, each containing its own strong password:

```text
srcs/secrets/db_root_password.txt
srcs/secrets/db_password.txt
srcs/secrets/wp_admin_password.txt
srcs/secrets/wp_user_password.txt
```

Use a local editor to enter the passwords. Do not write passwords in the terminal history or the repository. Keep the files protected:

```bash
chmod 600 srcs/secrets/*.txt
```

Compose mounts these files inside the relevant containers under `/run/secrets/`.

**Git safety:** `srcs/.env`, `srcs/secrets/`, and local data must not be committed. Check the repository's `.gitignore` and review staged files before pushing.

## 4. Prepare local storage and the domain

The current Compose setup uses two genuine Docker-managed named volumes:

```text
inception_mariadb_data
inception_wordpress_data
```

The 42 project stores Docker data beneath `/home/mohchams/data`. On this Debian VM, Docker Engine is configured with:

```json
{"data-root": "/home/mohchams/data"}
```

This setting belongs in `/etc/docker/daemon.json`, **outside the Git repository**. On a fresh VM, configure Docker's data root before starting the project. Preserve any other existing daemon settings rather than overwriting them. Restart Docker after changing the daemon configuration, and verify:

```bash
docker info --format '{{.DockerRootDir}}'
```

The expected result is `/home/mohchams/data`. With this configuration, the two named volumes have these mountpoints:

```text
/home/mohchams/data/volumes/inception_mariadb_data/_data
/home/mohchams/data/volumes/inception_wordpress_data/_data
```

Docker creates and manages these directories. Do not create application-data folders manually and do not replace the named volumes with bind mounts or `driver_opts`. Inspect ownership errors before changing permissions; never use `chmod 777` as a shortcut.

Make sure `mohchams.42.fr` resolves to the VM's reachable IP address. For local access **inside the VM**, a suitable entry in `/etc/hosts` can point that name to `127.0.0.1`. On another computer, use the VM's reachable address instead.

## 5. Build and start

From the repository root:

```bash
make
```

This runs the default Makefile target and builds/starts the Compose services.

Equivalent Compose operation:

```bash
docker compose --parallel 1 -f srcs/docker-compose.yml up -d --build
```

To check Compose configuration before starting:

```bash
docker compose -f srcs/docker-compose.yml config --quiet
```

## 6. Useful Makefile commands

| Command | Purpose |
| --- | --- |
| `make up` | Build and start the services |
| `make ps` | Show container status |
| `make logs` | Show service logs |
| `make stop` | Stop the containers, keep them |
| `make start` | Start stopped containers |
| `make restart` | Restart the containers |
| `make down` | Remove containers and the Compose network, keep volumes |
| `make build` | Rebuild service images |
| `make clean` | Remove the Compose containers and network |
| `make fclean` | Remove the Compose containers, network and service images; preserve volumes |
| `make re` | Run `fclean`, rebuild images and start services; preserve volumes |

The Makefile uses `docker compose --parallel 1 -f srcs/docker-compose.yml`. Run it from the project root.

## 7. Manage containers and logs

Show running services:

```bash
docker compose -f srcs/docker-compose.yml ps
```

Read one service's logs:

```bash
docker compose -f srcs/docker-compose.yml logs wordpress
```

The same works with `nginx` or `mariadb`.

Inspect the website response:

```bash
curl -kI --resolve mohchams.42.fr:443:127.0.0.1 https://mohchams.42.fr
```

The `-k` flag is needed for a self-signed local certificate. It disables certificate trust checking for this test only.

## 8. Networks and ports

All three services join the Docker bridge network named `inception` in the Compose file. Docker Compose gives the real network a project prefix, for example `srcs_inception`.

- NGINX publishes **443:443** (HTTPS) to the host.
- WordPress listens on **9000** only within the Docker network.
- MariaDB listens on **3306** only within the Docker network.

NGINX sends PHP requests to `wordpress:9000`. WordPress connects to MariaDB using the service hostname `mariadb`.

## 9. Volumes and persistence

Show named Docker volumes:

```bash
docker volume ls
```

Inspect the current project's volumes:

```bash
docker volume inspect inception_mariadb_data inception_wordpress_data
```

The Compose file defines the logical volumes `mariadb_data` and `wordpress_data`, with explicit Docker names `inception_mariadb_data` and `inception_wordpress_data`. These names do not receive a Compose project prefix.

MariaDB stores database files in `/var/lib/mysql`; WordPress stores site files in `/var/www/html`. Their named-volume data is kept under `/home/mohchams/data/volumes/` when Docker's configured data root is `/home/mohchams/data`.

To test persistence safely:

```bash
make down
make up
```

Then check the website and existing WordPress content. The normal `down` command does not delete the named volumes.

**`make fclean` and `make re` preserve named volumes.** Do not use `docker compose -f srcs/docker-compose.yml down -v` if you need to preserve stored data: `-v` deletes the project's named volumes.

## 10. Troubleshooting

- **Container stops:** read its logs with `docker compose -f srcs/docker-compose.yml logs SERVICE_NAME`.
- **WordPress cannot reach MariaDB:** check that both containers are running, use the expected database variables, and inspect the MariaDB logs.
- **Port 443 is busy:** check whether another service is already using it.
- **A script was modified:** rebuild the image, then recreate the container; `docker restart` alone does not copy a new script into an old image.
- **Make is missing:** on Debian, install it with `sudo apt update && sudo apt install make`.
- **HTTP works on port 80:** this is not expected for the mandatory Inception setup; only port 443 should be published.

## 11. Prepare for evaluation

Before the defense, verify that the Git repository contains the Makefile, Dockerfiles, Compose file, configuration files, startup scripts, and these three documentation files. The local `.env`, secret files and data must not appear in the Git submission.

The evaluator should be able to clone the repository, create the local configuration and secrets, run `make`, and test the WordPress site.

The 42 evaluation also checks: image naming, network isolation, TLS version, two WordPress users, persistence after VM reboot, and a live configuration change followed by a rebuild. Review each item against the current subject and evaluation sheet.
