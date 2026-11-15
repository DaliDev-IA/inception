# Inception — User Guide

This guide explains how to use the Inception website without changing its source code.

## 1. What does this project provide?

Inception provides a WordPress website through three Docker services:

- **NGINX**: secure HTTPS access to the website.
- **WordPress + PHP-FPM**: website pages and administration.
- **MariaDB**: storage for articles, pages, users and settings.

The website is available at **https://mohchams.42.fr** when the domain points to the VM.

## 2. Start and stop the website

Open a terminal in the root folder of the repository (`inception/`).

Start the stack:

```bash
make up
```

Check the running services:

```bash
make ps
```

Stop the containers without deleting saved data:

```bash
make down
```

Start them again:

```bash
make up
```

`make down` removes the containers and their network, but keeps the named volumes. Posts, users and pages should still be available after the next start.

**Do not use `make fclean` or `make re` to stop the site.** These targets can delete all persistent data.

## 3. Open WordPress

Website: **https://mohchams.42.fr**

Administration: **https://mohchams.42.fr/wp-admin/**

Use your WordPress administrator account to log in. The administrator username is configured with `WP_ADMIN_USER` in the local `.env` file.

The TLS certificate is self-signed for this local learning project. A browser may display a warning. This does not mean that HTTPS is disabled; it means that the certificate is not signed by a trusted certificate authority.

## 4. Manage credentials

Configuration file:

```text
srcs/.env
```

Local password files:

```text
srcs/secrets/db_root_password.txt
srcs/secrets/db_password.txt
srcs/secrets/wp_admin_password.txt
srcs/secrets/wp_user_password.txt
```

The `.env` file contains non-password settings such as the domain, database name and WordPress user names. Passwords are stored in separate local files and provided to the containers through Docker Compose secrets.

**Never copy passwords into Git, screenshots, issue reports, or chat messages.** Keep secret files readable only by authorized users.

If you change a secret after the services have already been initialized, the stored database or WordPress password may **not** change automatically. A password change must also be applied inside the corresponding service.

## 5. Basic checks

See the three services:

```bash
make ps
```

Read service messages:

```bash
make logs
```

Check the website from the VM:

```bash
curl -kI https://localhost
```

A response such as `HTTP/1.1 200 OK` shows that the web server is responding.

For help with building, volumes or troubleshooting, see **[DEV_DOC.md](DEV_DOC.md)**.
