#!/bin/bash

set -e

# Préparer les dossiers de MariaDB
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql

# Initialisation de MariaDB uniquement au premier démarrage
if [ ! -d /var/lib/mysql/mysql ]; then
    echo "Initialisation de MariaDB..."
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql
fi

# Lire les mots de passe dans les Docker Secrets
DB_PASSWORD="$(cat /run/secrets/db_password)"
DB_ROOT_PASSWORD="$(cat /run/secrets/db_root_password)"

# Préparer les instructions SQL
cat > /run/mysqld/init.sql <<EOF
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

# Protéger le fichier SQL temporaire
chown mysql:mysql /run/mysqld/init.sql
chmod 600 /run/mysqld/init.sql

# Démarrer MariaDB comme processus principal
exec mariadbd --user=mysql --datadir=/var/lib/mysql --init-file=/run/mysqld/init.sql
