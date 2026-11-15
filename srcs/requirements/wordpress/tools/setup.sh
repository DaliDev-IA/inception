#!/bin/bash
set -e

# Nom du serveur MariaDB
DB_HOST="${DB_HOST:-mariadb}"

# Lire les mots de passe depuis les secrets Docker
DB_PASSWORD="$(cat /run/secrets/db_password)"
WP_ADMIN_PASSWORD="$(cat /run/secrets/wp_admin_password)"
WP_USER_PASSWORD="$(cat /run/secrets/wp_user_password)"

# Attendre que MariaDB soit disponible
echo "[setup] attente de MariaDB sur ${DB_HOST}..."
tries=0

until mariadb-admin ping -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" --silent; do
    tries=$((tries + 1))

    if [ "$tries" -ge 30 ]; then
        echo "[setup] MariaDB injoignable apres 30 essais" >&2
        exit 1
    fi

    sleep 2
done

# Installer WordPress uniquement au premier démarrage
if [ ! -f /var/www/html/wp-config.php ]; then
    echo "[setup] premiere installation de WordPress"

    wp core download --allow-root

    wp config create --allow-root \
        --dbname="$DB_NAME" \
        --dbuser="$DB_USER" \
        --dbpass="$DB_PASSWORD" \
        --dbhost="$DB_HOST"

    wp core install --allow-root \
        --url="https://${DOMAIN_NAME}" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email

    wp user create "$WP_USER" "$WP_USER_EMAIL" \
        --allow-root \
        --role=author \
        --user_pass="$WP_USER_PASSWORD"
fi

# Donner les droits à PHP-FPM
chown -R www-data:www-data /var/www/html

# Démarrer PHP-FPM comme processus principal du conteneur
echo "[setup] demarrage de php-fpm (PID 1)"
exec php-fpm8.2 -F