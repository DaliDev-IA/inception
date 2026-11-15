#!/bin/bash
set -e

# Créer le dossier destiné au certificat TLS
mkdir -p /etc/nginx/ssl

# Générer un certificat TLS autosigné s'il n'existe pas
if [ ! -f /etc/nginx/ssl/nginx.crt ] || [ ! -f /etc/nginx/ssl/nginx.key ]; then
    echo "[setup] generation du certificat TLS"

    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=FR/ST=Ile-de-France/L=Paris/O=Inception/CN=${DOMAIN_NAME}"
fi

# Protéger la clé privée
chmod 600 /etc/nginx/ssl/nginx.key

# Vérifier la configuration NGINX
nginx -t

# Démarrer NGINX au premier plan
echo "[setup] demarrage de nginx (PID 1)"
exec nginx -g 'daemon off;'
