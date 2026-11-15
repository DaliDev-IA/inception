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

All commands below assume the terminal is at the repository root (`~/inception`).

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

The current Compose setup uses two named Docker volumes backed by these host folders:

```text
/home/mohchams/data/mariadb
/home/mohchams/data/wordpress
```

Create the directories if they do not exist:

```bash
mkdir -p /home/mohchams/data/mariadb /home/mohchams/data/wordpress
```

The service processes may need different filesystem ownership/permissions. Inspect errors before changing permissions; do not use `chmod 777` as a quick fix.

Make sure `mohchams.42.fr` resolves to the VM's reachable IP address. For local access **inside the VM**, a suitable entry in `/etc/hosts` can point that name to `127.0.0.1`. On another computer, use the VM's reachable address instead.

## 5. Build and start

From the repository root:

```bash
make
```

This runs the default Makefile target and builds/starts the Compose services.

Equivalent Compose operation:

```bash
docker compose -f srcs/docker-compose.yml up -d --build
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
| `make fclean` | **Destructive:** remove volumes, images and local data directories |
| `make re` | **Destructive:** full cleanup then a new build/start |

The Makefile uses `docker compose -f srcs/docker-compose.yml`. Run it from the project root.

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
curl -kI https://localhost
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
docker volume inspect srcs_mariadb_data srcs_wordpress_data
```

The Compose file defines `mariadb_data` and `wordpress_data`. With the default project name `srcs`, the full Docker names are `srcs_mariadb_data` and `srcs_wordpress_data`.

MariaDB stores database files in `/var/lib/mysql`; WordPress stores site files in `/var/www/html`. The corresponding host data is kept under `/home/mohchams/data/`.

To test persistence safely:

```bash
make down
make up
```

Then check the website and existing WordPress content. The normal `down` command does not delete the named volumes.

**Never use `make fclean`, `make re`, or `docker compose down -v` if you need to preserve the stored data.**

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
