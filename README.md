*This project has been created as part of the 42 curriculum by mohchams.*

# Inception

## Description

Inception is a small web infrastructure built with Docker Compose inside a Debian virtual machine (VM).

The project runs three services in three separate containers:

- **NGINX** receives HTTPS requests on port **443**. It uses TLS 1.2 or TLS 1.3 and forwards PHP requests to WordPress.
- **WordPress + PHP-FPM** runs the website and executes PHP code on port **9000** inside the Docker network.
- **MariaDB** stores WordPress data and listens on port **3306** inside the Docker network.

Only NGINX publishes a port on the host. WordPress and MariaDB are not directly exposed to the outside.

```text
Web browser
    |
    | HTTPS :443
    v
  NGINX
    |
    | FastCGI -> wordpress:9000
    v
WordPress + PHP-FPM
    |
    | SQL -> mariadb:3306
    v
  MariaDB
```

The containers use a dedicated Docker bridge network. Two named volumes keep the database and website files after containers are removed or restarted.

## Project structure

```text
inception/
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── .gitignore
└── srcs/
    ├── docker-compose.yml
    ├── .env                 # local file, not committed
    ├── secrets/             # local files, not committed
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/50-server.cnf
        │   └── tools/setup.sh
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/www.conf
        │   └── tools/setup.sh
        └── nginx/
            ├── Dockerfile
            ├── conf/nginx.conf
            └── tools/setup.sh
```

Each image is built from a local Dockerfile using Debian as its base. The services are managed together by Docker Compose.

## Instructions

### Requirements

- A Linux VM with Docker Engine and Docker Compose installed.
- `make` installed on the VM.
- Local configuration file `srcs/.env`.
- Local secret files in `srcs/secrets/`.
- Docker's data root configured as `/home/mohchams/data`, so the named volumes are stored beneath that directory.
- A local DNS or `/etc/hosts` entry that resolves `mohchams.42.fr` to the VM when accessing the website.

The `.env` and secret files are intentionally excluded from Git. Follow **[DEV_DOC.md](DEV_DOC.md)** to prepare them before the first start.

### Run

From the root of the repository:

```bash
make
```

This builds the images, creates Docker-managed named volumes if necessary, and starts the services with Docker Compose.

Open `https://mohchams.42.fr` in your browser. The local TLS certificate is self-signed, so a browser warning may appear.

Useful commands:

```bash
make ps       # show service status
make logs     # read logs
make down     # stop and remove containers, keep volumes
make up       # build and start the stack
```

`make fclean` removes the Compose containers, network and service images, but preserves named volumes. `make re` performs that cleanup and rebuilds the stack. To delete the named volumes intentionally, use `docker compose -f srcs/docker-compose.yml down -v` after backing up the data.

For day-to-day use, see **[USER_DOC.md](USER_DOC.md)**. For developer setup and troubleshooting, see **[DEV_DOC.md](DEV_DOC.md)**.

## Technical choices

### Virtual machines vs Docker

A VM runs a complete guest operating system with its own kernel. Docker containers share the host kernel and isolate processes and their dependencies. Containers are usually lighter and faster to start. In this project, Docker runs **inside a VM**, as required by 42.

### Secrets vs environment variables

Environment variables hold normal configuration such as the domain name, database name and user names. Docker Compose secrets make sensitive values available as files under `/run/secrets/`. The application scripts read the password files when needed. Passwords are not written into Dockerfiles or committed to Git.

### Docker network vs host network

A Docker bridge network lets services communicate by service name, such as `wordpress:9000` and `mariadb:3306`. Host networking would use the host's network directly and reduce isolation. This project uses a dedicated bridge network; it does not use `network: host` or Docker links.

### Docker volumes vs bind mounts

A Docker named volume is managed by Docker and keeps data independently of a container. A bind mount maps a specific host path into a container. In this project, two genuine Docker-managed named volumes are declared without `driver_opts` or bind mounts: `inception_mariadb_data` and `inception_wordpress_data`. The VM configures Docker's `data-root` as `/home/mohchams/data`, so their data resides in `/home/mohchams/data/volumes/<volume-name>/_data`. This Docker daemon configuration is outside the Git repository and must be prepared on a fresh VM.

## Resources

- Docker documentation: https://docs.docker.com/
- Docker Compose documentation: https://docs.docker.com/compose/
- NGINX documentation: https://nginx.org/en/docs/
- WordPress documentation: https://wordpress.org/documentation/
- MariaDB documentation: https://mariadb.com/docs/
- OpenSSL documentation: https://docs.openssl.org/
- Inception subject and evaluation guidelines provided by 42.

### Use of AI

AI was used as a learning assistant to explain Docker, Dockerfiles, Compose, Linux commands, networking, TLS, and Git; to discuss errors during testing; and to help draft documentation. Commands and explanations were reviewed during hands-on work. The student is responsible for understanding, testing, and defending the submitted project.
