
FROM debian:bookworm-slim

# Installer NGINX et OpenSSL
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    openssl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Créer les dossiers nécessaires
RUN mkdir -p /etc/nginx/ssl /run/nginx

# Copier notre configuration NGINX
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Copier notre script de démarrage
COPY tools/setup.sh /usr/local/bin/setup.sh

# Rendre le script exécutable
RUN chmod +x /usr/local/bin/setup.sh

# Documenter le port HTTPS utilisé
EXPOSE 443

# Démarrer NGINX via notre script
ENTRYPOINT ["/usr/local/bin/setup.sh"]
