#!/bin/bash

# Script de démarrage principal pour le conteneur monolithique

echo "🚀 Démarrage de Menui Mesure - Conteneur Monolithique"
echo "====================================================="

# Fonction pour attendre qu'un service soit prêt
wait_for_service() {
    local service_name=$1
    local check_command=$2
    local max_attempts=30
    local attempt=1
    
    echo "⏳ Attente du démarrage de $service_name..."
    while [ $attempt -le $max_attempts ]; do
        if eval $check_command; then
            echo "✅ $service_name est prêt"
            return 0
        fi
        echo "   Tentative $attempt/$max_attempts..."
        sleep 2
        ((attempt++))
    done
    
    echo "❌ Impossible de démarrer $service_name"
    return 1
}

# Initialisation de MySQL
echo "📊 Initialisation de MySQL..."
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "   Première installation de MySQL..."
    mysqld --initialize-insecure --user=mysql --datadir=/var/lib/mysql
fi

# Démarrage de MySQL
echo "🔗 Démarrage de MySQL..."
service mysql start
wait_for_service "MySQL" "mysqladmin ping -h localhost --silent"

# Configuration de la base de données
echo "⚙️  Configuration de la base de données..."
mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS menui_prod CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'menui_user'@'localhost' IDENTIFIED BY 'menui_password_2024!';
GRANT ALL PRIVILEGES ON menui_prod.* TO 'menui_user'@'localhost';
FLUSH PRIVILEGES;
EOF

# Démarrage de Redis
echo "🔄 Démarrage de Redis..."
service redis-server start
wait_for_service "Redis" "redis-cli ping | grep -q PONG"

# Démarrage de PHP-FPM
echo "🐘 Démarrage de PHP-FPM..."
service php8.2-fpm start

# Configuration Laravel
echo "⚙️  Configuration de Laravel..."
cd /var/www/menui/laravel-app

# Génération de la clé si nécessaire
if ! grep -q "APP_KEY=base64:" .env; then
    echo "   Génération de la clé d'application..."
    php artisan key:generate --force
fi

# Migration de la base de données
echo "   Migration de la base de données..."
php artisan migrate --force

# Création du lien symbolique storage
echo "   Création du lien symbolique storage..."
php artisan storage:link

# Optimisations Laravel
echo "   Optimisations Laravel..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Démarrage du worker de queue Laravel
echo "🔄 Démarrage du worker de queue..."
nohup php artisan queue:work --sleep=3 --tries=3 --max-time=3600 > /var/log/menui/queue.log 2>&1 &

# Démarrage du service IA Python
echo "🤖 Démarrage du service IA..."
cd /var/www/menui/ai-service
nohup ./venv/bin/python -m uvicorn main:app --host 0.0.0.0 --port 8001 > /var/log/menui/ai-service.log 2>&1 &
wait_for_service "Service IA" "curl -f http://localhost:8001/health"

# Démarrage de Nginx
echo "🌐 Démarrage de Nginx..."
nginx -t && service nginx start

# Configuration des logs
echo "📝 Configuration des logs..."
mkdir -p /var/log/menui
touch /var/log/menui/access.log /var/log/menui/error.log
chown www-data:www-data /var/log/menui/*.log

# Affichage des informations de démarrage
echo ""
echo "🎉 Tous les services sont démarrés !"
echo "=================================="
echo "📱 Application web: http://localhost"
echo "🤖 Service IA: http://localhost:8001"
echo "📊 Base de données: localhost:3306"
echo "🔄 Redis: localhost:6379"
echo ""
echo "📋 Services actifs:"
echo "   • MySQL: $(service mysql status | grep -o 'running\\|stopped')"
echo "   • Redis: $(service redis-server status | grep -o 'running\\|stopped')"
echo "   • PHP-FPM: $(service php8.2-fpm status | grep -o 'running\\|stopped')"
echo "   • Nginx: $(service nginx status | grep -o 'running\\|stopped')"
echo ""

# Surveillance continue des services
echo "🔍 Surveillance des services..."
tail -f /var/log/nginx/access.log /var/log/menui/*.log
