#!/bin/bash

# Script d'installation automatique pour Menui Measure
# Compatible avec Ubuntu 20.04+ et Debian 11+

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERREUR]${NC} $1"
    exit 1
}

warning() {
    echo -e "${YELLOW}[ATTENTION]${NC} $1"
}

# Vérifier que le script est exécuté avec sudo
if [ "$EUID" -ne 0 ]; then 
    error "Ce script doit être exécuté avec sudo"
fi

# Variables de configuration
read -p "Entrez votre nom de domaine (ex: menui.com): " DOMAIN
read -p "Entrez votre email pour Let's Encrypt: " EMAIL
read -sp "Entrez le mot de passe pour la base de données MySQL: " DB_PASSWORD
echo

# Confirmation
echo
echo "Configuration:"
echo "- Domaine: $DOMAIN"
echo "- Email: $EMAIL"
echo
read -p "Continuer l'installation? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

log "Début de l'installation de Menui Measure..."

# 1. Mise à jour du système
log "Mise à jour du système..."
apt update && apt upgrade -y

# 2. Installation des dépendances de base
log "Installation des dépendances de base..."
apt install -y \
    curl \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    supervisor

# 3. Installation de PHP 8.2
log "Installation de PHP 8.2..."
add-apt-repository ppa:ondrej/php -y
apt update
apt install -y \
    php8.2-fpm \
    php8.2-cli \
    php8.2-common \
    php8.2-mysql \
    php8.2-xml \
    php8.2-xmlrpc \
    php8.2-curl \
    php8.2-gd \
    php8.2-imagick \
    php8.2-mbstring \
    php8.2-opcache \
    php8.2-soap \
    php8.2-zip \
    php8.2-redis \
    php8.2-bcmath \
    php8.2-intl

# Configuration PHP
log "Configuration de PHP..."
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 20M/g' /etc/php/8.2/fpm/php.ini
sed -i 's/post_max_size = 8M/post_max_size = 25M/g' /etc/php/8.2/fpm/php.ini
sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php/8.2/fpm/php.ini
sed -i 's/max_execution_time = 30/max_execution_time = 300/g' /etc/php/8.2/fpm/php.ini

systemctl restart php8.2-fpm

# 4. Installation de MySQL 8
log "Installation de MySQL 8..."
apt install -y mysql-server

# Configuration MySQL
mysql -e "CREATE DATABASE IF NOT EXISTS menui CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER IF NOT EXISTS 'menui'@'localhost' IDENTIFIED BY '$DB_PASSWORD';"
mysql -e "GRANT ALL PRIVILEGES ON menui.* TO 'menui'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# 5. Installation de Redis
log "Installation de Redis..."
apt install -y redis-server

# Configuration Redis
cat >> /etc/redis/redis.conf << EOF
maxmemory 256mb
maxmemory-policy allkeys-lru
EOF

systemctl restart redis-server
systemctl enable redis-server

# 6. Installation de Node.js
log "Installation de Node.js 18..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# 7. Installation de Composer
log "Installation de Composer..."
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
chmod +x /usr/local/bin/composer

# 8. Installation de Python 3.11
log "Installation de Python 3.11..."
add-apt-repository ppa:deadsnakes/ppa -y
apt update
apt install -y python3.11 python3.11-venv python3.11-dev python3-pip

# Dépendances pour OpenCV
apt install -y \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libgl1-mesa-glx \
    libgtk-3-0 \
    libgdk-pixbuf2.0-0

# 9. Installation de Nginx
log "Installation de Nginx..."
apt install -y nginx

# 10. Création du répertoire de l'application
log "Création du répertoire de l'application..."
mkdir -p /var/www/menui
chown -R www-data:www-data /var/www/menui

# 11. Clonage du repository (remplacer par votre repo)
log "Clonage du repository..."
cd /var/www/menui
# git clone https://github.com/votre-repo/menui-measure.git .

# Pour l'instant, copier depuis le workspace
cp -r /workspace/menui-measure/* /var/www/menui/

# 12. Installation de l'application Laravel
log "Installation de Laravel..."
cd /var/www/menui/laravel-app

# Créer le fichier .env
cp .env.example .env
sed -i "s|APP_URL=.*|APP_URL=https://$DOMAIN|g" .env
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=$DB_PASSWORD|g" .env
sed -i "s|AI_SERVICE_URL=.*|AI_SERVICE_URL=http://127.0.0.1:8001|g" .env

# Installation des dépendances
sudo -u www-data composer install --optimize-autoloader --no-dev
sudo -u www-data php artisan key:generate

# Installation des dépendances JS et build
sudo -u www-data npm install
sudo -u www-data npm run build

# Migrations et optimisations
sudo -u www-data php artisan migrate --force
sudo -u www-data php artisan storage:link
sudo -u www-data php artisan config:cache
sudo -u www-data php artisan route:cache
sudo -u www-data php artisan view:cache

# Permissions
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache

# 13. Installation du service IA Python
log "Installation du service IA Python..."
cd /var/www/menui/ai-service

# Créer l'environnement virtuel
sudo -u www-data python3.11 -m venv venv
sudo -u www-data venv/bin/pip install -r requirements.txt

# Créer les dossiers
sudo -u www-data mkdir -p uploads processed

# 14. Configuration Nginx
log "Configuration de Nginx..."
cat > /etc/nginx/sites-available/menui << EOF
server {
    listen 80;
    server_name $DOMAIN;
    root /var/www/menui/laravel-app/public;

    index index.php;
    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }

    location /ai-service/ {
        proxy_pass http://127.0.0.1:8001/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    client_max_body_size 20M;
}
EOF

ln -sf /etc/nginx/sites-available/menui /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl restart nginx

# 15. Configuration des services systemd
log "Configuration des services systemd..."

# Service Queue Laravel
cat > /etc/systemd/system/menui-queue.service << EOF
[Unit]
Description=Menui Laravel Queue Worker
After=network.target

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/menui/laravel-app/artisan queue:work --sleep=3 --tries=3 --max-time=3600
StandardOutput=append:/var/www/menui/laravel-app/storage/logs/queue.log
StandardError=append:/var/www/menui/laravel-app/storage/logs/queue.log

[Install]
WantedBy=multi-user.target
EOF

# Service IA Python
cat > /etc/systemd/system/menui-ai.service << EOF
[Unit]
Description=Menui AI Service
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/var/www/menui/ai-service
Environment="PATH=/var/www/menui/ai-service/venv/bin"
ExecStart=/var/www/menui/ai-service/venv/bin/uvicorn main:app --host 127.0.0.1 --port 8001
Restart=always
StandardOutput=append:/var/www/menui/ai-service/service.log
StandardError=append:/var/www/menui/ai-service/service.log

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable menui-queue menui-ai
systemctl start menui-queue menui-ai

# 16. Configuration SSL avec Let's Encrypt
log "Configuration SSL avec Let's Encrypt..."
apt install -y certbot python3-certbot-nginx
certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email $EMAIL

# 17. Configuration du cron Laravel
log "Configuration du cron Laravel..."
(crontab -u www-data -l 2>/dev/null; echo "* * * * * cd /var/www/menui/laravel-app && php artisan schedule:run >> /dev/null 2>&1") | crontab -u www-data -

# 18. Configuration du firewall
log "Configuration du firewall..."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# 19. Optimisations finales
log "Optimisations finales..."

# PHP-FPM
cat >> /etc/php/8.2/fpm/pool.d/www.conf << EOF
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
pm.max_requests = 500
EOF

systemctl restart php8.2-fpm

# 20. Création du script de mise à jour
log "Création du script de mise à jour..."
cat > /usr/local/bin/update-menui << 'EOF'
#!/bin/bash
cd /var/www/menui

# Mode maintenance
cd laravel-app
php artisan down

# Pull les changements
cd ..
git pull origin main

# Mise à jour Laravel
cd laravel-app
composer install --optimize-autoloader --no-dev
npm install
npm run build

# Migrations
php artisan migrate --force

# Caches
php artisan cache:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Redémarrer les services
systemctl restart menui-queue menui-ai php8.2-fpm

# Sortir du mode maintenance
php artisan up

echo "Mise à jour terminée!"
EOF

chmod +x /usr/local/bin/update-menui

# Affichage final
echo
echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}Installation terminée avec succès!${NC}"
echo -e "${GREEN}=================================${NC}"
echo
echo "Informations de connexion:"
echo "- URL: https://$DOMAIN"
echo "- Base de données: menui"
echo "- Utilisateur DB: menui"
echo
echo "Commandes utiles:"
echo "- Voir les logs: journalctl -u menui-queue -f"
echo "- Redémarrer les services: systemctl restart menui-queue menui-ai"
echo "- Mettre à jour l'application: update-menui"
echo
echo "Prochaines étapes:"
echo "1. Créer un utilisateur admin dans l'application"
echo "2. Configurer les clés OVH Object Storage dans .env"
echo "3. Tester l'upload de photos"
echo
log "Installation complète!"