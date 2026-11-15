FROM debian:bookworm-slim

# Installer PHP-FPM et les dépendances WordPress
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       php8.2-fpm php8.2-mysql php8.2-cli \
       mariadb-client curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Télécharger WP-CLI
RUN curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    -o /usr/local/bin/wp \
    && chmod +x /usr/local/bin/wp

# Préparer les répertoires
RUN mkdir -p /run/php /var/www/html

# Copier nos fichiers de configuration
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/setup.sh /usr/local/bin/setup.sh

# Rendre le script exécutable
RUN chmod +x /usr/local/bin/setup.sh

# Définir le dossier de travail WordPress
WORKDIR /var/www/html

# Documenter le port interne de PHP-FPM
EXPOSE 9000

# Exécuter notre script au démarrage du conteneur
ENTRYPOINT ["/usr/local/bin/setup.sh"]