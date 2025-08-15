# Guide de déploiement manuel (sans Docker)

Ce guide explique comment déployer l'application Menui Measure directement sur un serveur sans utiliser Docker.

## Prérequis système

- Ubuntu 20.04 LTS ou supérieur (ou Debian 11+)
- 4GB RAM minimum
- 20GB d'espace disque
- Accès root ou sudo
- Nom de domaine configuré

## 1. Installation des dépendances système

### Mettre à jour le système
```bash
sudo apt update && sudo apt upgrade -y
```

### Installer les paquets essentiels
```bash
sudo apt install -y \
    curl \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release
```

## 2. Installation de PHP 8.2

```bash
# Ajouter le repository PHP
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update

# Installer PHP et les extensions nécessaires
sudo apt install -y \
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

# Configurer PHP-FPM
sudo nano /etc/php/8.2/fpm/php.ini
```

Modifier les paramètres suivants :
```ini
upload_max_filesize = 20M
post_max_size = 25M
memory_limit = 512M
max_execution_time = 300
```

Redémarrer PHP-FPM :
```bash
sudo systemctl restart php8.2-fpm
```

## 3. Installation de MySQL 8

```bash
# Installer MySQL
sudo apt install -y mysql-server

# Sécuriser l'installation
sudo mysql_secure_installation

# Se connecter à MySQL
sudo mysql

# Créer la base de données et l'utilisateur
CREATE DATABASE menui CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'menui'@'localhost' IDENTIFIED BY 'votre_mot_de_passe_fort';
GRANT ALL PRIVILEGES ON menui.* TO 'menui'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

## 4. Installation de Redis

```bash
# Installer Redis
sudo apt install -y redis-server

# Configurer Redis
sudo nano /etc/redis/redis.conf
```

Modifier :
```conf
supervised systemd
maxmemory 256mb
maxmemory-policy allkeys-lru
```

Redémarrer Redis :
```bash
sudo systemctl restart redis-server
sudo systemctl enable redis-server
```

## 5. Installation de Node.js et npm

```bash
# Installer Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Vérifier les versions
node --version
npm --version
```

## 6. Installation de Composer

```bash
# Télécharger et installer Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
sudo chmod +x /usr/local/bin/composer

# Vérifier l'installation
composer --version
```

## 7. Installation de Python 3.11 et dépendances

```bash
# Installer Python 3.11
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt update
sudo apt install -y python3.11 python3.11-venv python3.11-dev

# Installer pip
sudo apt install -y python3-pip

# Installer les dépendances système pour OpenCV
sudo apt install -y \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libgtk-3-0 \
    libgdk-pixbuf2.0-0
```

## 8. Installation de Nginx

```bash
# Installer Nginx
sudo apt install -y nginx

# Créer la configuration pour Menui
sudo nano /etc/nginx/sites-available/menui
```

Configuration Nginx :
```nginx
server {
    listen 80;
    server_name votre-domaine.com;
    root /var/www/menui/laravel-app/public;

    index index.php;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }

    # Proxy pour le service IA Python
    location /ai-service/ {
        proxy_pass http://127.0.0.1:8001/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    client_max_body_size 20M;
}
```

Activer le site :
```bash
sudo ln -s /etc/nginx/sites-available/menui /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

## 9. Déploiement de l'application Laravel

```bash
# Créer le répertoire
sudo mkdir -p /var/www/menui
sudo chown -R $USER:$USER /var/www/menui

# Cloner le repository
cd /var/www/menui
git clone https://github.com/votre-repo/menui-measure.git .

# Aller dans le dossier Laravel
cd laravel-app

# Installer les dépendances PHP
composer install --optimize-autoloader --no-dev

# Copier et configurer le fichier .env
cp .env.example .env
nano .env
```

Configuration .env minimale :
```env
APP_NAME=Menui
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=https://votre-domaine.com

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=menui
DB_USERNAME=menui
DB_PASSWORD=votre_mot_de_passe

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

CACHE_DRIVER=redis
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis

AI_SERVICE_URL=http://127.0.0.1:8001
```

Finaliser l'installation Laravel :
```bash
# Générer la clé d'application
php artisan key:generate

# Exécuter les migrations
php artisan migrate --force

# Créer le lien symbolique pour le storage
php artisan storage:link

# Installer les dépendances JavaScript
npm install

# Compiler les assets
npm run build

# Optimiser pour la production
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Définir les permissions
sudo chown -R www-data:www-data storage bootstrap/cache
sudo chmod -R 775 storage bootstrap/cache
```

## 10. Installation du service IA Python

```bash
# Aller dans le dossier du service IA
cd /var/www/menui/ai-service

# Créer un environnement virtuel
python3.11 -m venv venv

# Activer l'environnement virtuel
source venv/bin/activate

# Installer les dépendances
pip install -r requirements.txt

# Créer les dossiers nécessaires
mkdir -p uploads processed
```

## 11. Configuration des services systemd

### Service pour la Queue Laravel

Créer `/etc/systemd/system/menui-queue.service` :
```ini
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
```

### Service pour l'API Python

Créer `/etc/systemd/system/menui-ai.service` :
```ini
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
```

Activer et démarrer les services :
```bash
sudo systemctl daemon-reload
sudo systemctl enable menui-queue menui-ai
sudo systemctl start menui-queue menui-ai

# Vérifier le statut
sudo systemctl status menui-queue
sudo systemctl status menui-ai
```

## 12. Configuration SSL avec Let's Encrypt

```bash
# Installer Certbot
sudo apt install -y certbot python3-certbot-nginx

# Obtenir le certificat SSL
sudo certbot --nginx -d votre-domaine.com

# Renouvellement automatique
sudo systemctl enable certbot.timer
```

## 13. Configuration du cron pour Laravel

```bash
# Éditer le crontab pour www-data
sudo crontab -u www-data -e

# Ajouter la ligne suivante
* * * * * cd /var/www/menui/laravel-app && php artisan schedule:run >> /dev/null 2>&1
```

## 14. Optimisation et sécurité

### Configuration du firewall
```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### Installation de Fail2ban
```bash
sudo apt install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### Optimisation PHP-FPM
Éditer `/etc/php/8.2/fpm/pool.d/www.conf` :
```ini
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
pm.max_requests = 500
```

### Optimisation MySQL
Éditer `/etc/mysql/mysql.conf.d/mysqld.cnf` :
```ini
[mysqld]
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT
max_connections = 200
```

Redémarrer les services :
```bash
sudo systemctl restart php8.2-fpm
sudo systemctl restart mysql
```

## 15. Monitoring

### Logs importants
- Laravel : `/var/www/menui/laravel-app/storage/logs/laravel.log`
- Queue : `/var/www/menui/laravel-app/storage/logs/queue.log`  
- Service IA : `/var/www/menui/ai-service/service.log`
- Nginx : `/var/log/nginx/error.log`
- PHP : `/var/log/php8.2-fpm.log`

### Commandes utiles
```bash
# Vérifier l'état des services
sudo systemctl status nginx php8.2-fpm mysql redis-server menui-queue menui-ai

# Voir les logs en temps réel
sudo journalctl -u menui-queue -f
sudo journalctl -u menui-ai -f

# Redémarrer un service
sudo systemctl restart menui-queue
sudo systemctl restart menui-ai
```

## 16. Mise à jour de l'application

Script de mise à jour `/home/user/update-menui.sh` :
```bash
#!/bin/bash
cd /var/www/menui

# Mettre en mode maintenance
cd laravel-app
php artisan down

# Pull les changements
cd ..
git pull origin main

# Mettre à jour Laravel
cd laravel-app
composer install --optimize-autoloader --no-dev
npm install
npm run build

# Migrations
php artisan migrate --force

# Vider les caches
php artisan cache:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Redémarrer les services
sudo systemctl restart menui-queue
sudo systemctl restart menui-ai
sudo systemctl restart php8.2-fpm

# Sortir du mode maintenance
php artisan up

echo "Mise à jour terminée!"
```

Rendre le script exécutable :
```bash
chmod +x /home/user/update-menui.sh
```

## Dépannage

### Problème de permission
```bash
sudo chown -R www-data:www-data /var/www/menui/laravel-app/storage
sudo chown -R www-data:www-data /var/www/menui/laravel-app/bootstrap/cache
sudo chmod -R 775 /var/www/menui/laravel-app/storage
```

### Service IA ne démarre pas
```bash
# Vérifier les dépendances Python
cd /var/www/menui/ai-service
source venv/bin/activate
python -c "import cv2; print('OpenCV OK')"
```

### Queue ne traite pas les jobs
```bash
# Vérifier Redis
redis-cli ping

# Redémarrer la queue
sudo systemctl restart menui-queue
```