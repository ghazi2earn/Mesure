#!/bin/sh

# Script de démarrage pour le container Laravel

# Attendre que la base de données soit prête
echo "Attente de la base de données..."
while ! mysqladmin ping -h db -u root -p${DB_ROOT_PASSWORD} --silent; do
    sleep 1
done

echo "Base de données prête !"

# Créer les répertoires nécessaires
mkdir -p /var/www/html/storage/logs
mkdir -p /var/www/html/storage/framework/{cache,sessions,views}
mkdir -p /var/www/html/storage/app/{public,photos}

# Permissions
chown -R www-data:www-data /var/www/html/storage
chown -R www-data:www-data /var/www/html/bootstrap/cache
chmod -R 775 /var/www/html/storage
chmod -R 775 /var/www/html/bootstrap/cache

# Migration de la base de données
echo "Migration de la base de données..."
php artisan migrate --force

# Création du lien symbolique storage
php artisan storage:link

# Optimisations Laravel
echo "Optimisations Laravel..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Démarrage de Supervisor (qui gère PHP-FPM et Nginx)
echo "Démarrage des services..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
