# Guide de déploiement OVH - Menui Measure

## Prérequis

- VPS OVH avec Ubuntu 22.04 LTS minimum
- Nom de domaine pointant vers l'IP du VPS
- Accès SSH au serveur
- Compte OVH Object Storage pour le stockage S3

## 1. Configuration initiale du serveur

### Se connecter au serveur
```bash
ssh root@votre-ip-vps
```

### Mettre à jour le système
```bash
apt update && apt upgrade -y
apt install -y git curl wget software-properties-common
```

### Créer un utilisateur non-root
```bash
adduser menui
usermod -aG sudo menui
su - menui
```

## 2. Installation de Docker et Docker Compose

```bash
# Installer Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Installer Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Vérifier les installations
docker --version
docker-compose --version
```

## 3. Configuration Nginx et SSL

### Installer Nginx
```bash
sudo apt install -y nginx certbot python3-certbot-nginx
```

### Configurer Nginx
```bash
sudo nano /etc/nginx/sites-available/menui
```

Contenu du fichier :
```nginx
server {
    listen 80;
    server_name votre-domaine.com;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /ai-service/ {
        proxy_pass http://localhost:8001/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    client_max_body_size 20M;
}
```

### Activer le site et obtenir le certificat SSL
```bash
sudo ln -s /etc/nginx/sites-available/menui /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# Obtenir le certificat SSL
sudo certbot --nginx -d votre-domaine.com
```

## 4. Déploiement de l'application

### Cloner le repository
```bash
cd ~
git clone https://github.com/votre-repo/menui-measure.git
cd menui-measure
```

### Créer le fichier docker-compose.prod.yml
```bash
nano docker-compose.prod.yml
```

Contenu :
```yaml
version: '3.8'

services:
  db:
    image: mysql:8
    container_name: menui-db
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
      MYSQL_DATABASE: menui
      MYSQL_USER: menui
      MYSQL_PASSWORD: ${DB_PASSWORD}
    volumes:
      - db_data:/var/lib/mysql
    networks:
      - menui-network

  redis:
    image: redis:6-alpine
    container_name: menui-redis
    restart: always
    networks:
      - menui-network

  laravel:
    build:
      context: ./laravel-app
      dockerfile: Dockerfile.prod
    container_name: menui-laravel
    restart: always
    environment:
      - APP_ENV=production
      - APP_DEBUG=false
      - APP_URL=https://votre-domaine.com
      - DB_HOST=db
      - REDIS_HOST=redis
      - AI_SERVICE_URL=http://ai-service:8000
    volumes:
      - ./laravel-app/storage:/var/www/html/storage
      - ./laravel-app/public/uploads:/var/www/html/public/uploads
    ports:
      - "8000:80"
    depends_on:
      - db
      - redis
    networks:
      - menui-network

  ai-service:
    build:
      context: ./ai-service
      dockerfile: Dockerfile
    container_name: menui-ai-service
    restart: always
    volumes:
      - ./ai-service/uploads:/app/uploads
      - ./ai-service/processed:/app/processed
    ports:
      - "8001:8000"
    networks:
      - menui-network

  queue-worker:
    build:
      context: ./laravel-app
      dockerfile: Dockerfile.prod
    container_name: menui-queue
    restart: always
    command: php artisan queue:work --sleep=3 --tries=3
    environment:
      - APP_ENV=production
      - DB_HOST=db
      - REDIS_HOST=redis
      - AI_SERVICE_URL=http://ai-service:8000
    depends_on:
      - db
      - redis
      - laravel
    networks:
      - menui-network

networks:
  menui-network:
    driver: bridge

volumes:
  db_data:
    driver: local
```

### Créer le fichier .env de production
```bash
cp laravel-app/.env.example laravel-app/.env
nano laravel-app/.env
```

Configurer les variables suivantes :
```env
APP_ENV=production
APP_DEBUG=false
APP_URL=https://votre-domaine.com

DB_PASSWORD=mot_de_passe_fort
REDIS_PASSWORD=autre_mot_de_passe

# OVH Object Storage
OVH_ACCESS_KEY_ID=votre_access_key
OVH_SECRET_ACCESS_KEY=votre_secret_key
OVH_DEFAULT_REGION=BHS
OVH_BUCKET=menui-storage
OVH_ENDPOINT=https://s3.bhs.io.cloud.ovh.net

# Génerer une clé d'application
APP_KEY=base64:generer_avec_artisan_key_generate
```

## 5. Configuration OVH Object Storage

1. Se connecter à l'espace client OVH
2. Créer un conteneur Object Storage dans la région souhaitée
3. Créer un utilisateur S3 avec les permissions nécessaires
4. Noter les clés d'accès pour la configuration

## 6. Lancement de l'application

```bash
# Construire et lancer les conteneurs
docker-compose -f docker-compose.prod.yml up -d --build

# Exécuter les migrations
docker-compose -f docker-compose.prod.yml exec laravel php artisan migrate --force

# Créer un lien symbolique pour le storage
docker-compose -f docker-compose.prod.yml exec laravel php artisan storage:link

# Optimiser Laravel pour la production
docker-compose -f docker-compose.prod.yml exec laravel php artisan config:cache
docker-compose -f docker-compose.prod.yml exec laravel php artisan route:cache
docker-compose -f docker-compose.prod.yml exec laravel php artisan view:cache

# Définir les permissions
docker-compose -f docker-compose.prod.yml exec laravel chown -R www-data:www-data storage bootstrap/cache
```

## 7. Monitoring et maintenance

### Vérifier les logs
```bash
# Logs Laravel
docker-compose -f docker-compose.prod.yml logs -f laravel

# Logs du service IA
docker-compose -f docker-compose.prod.yml logs -f ai-service

# Logs de la queue
docker-compose -f docker-compose.prod.yml logs -f queue-worker
```

### Sauvegardes automatiques
Créer un script de sauvegarde :
```bash
nano ~/backup-menui.sh
```

```bash
#!/bin/bash
BACKUP_DIR="/home/menui/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Créer le répertoire de sauvegarde
mkdir -p $BACKUP_DIR

# Sauvegarder la base de données
docker-compose -f ~/menui-measure/docker-compose.prod.yml exec -T db mysqldump -u root -p$DB_ROOT_PASSWORD menui > $BACKUP_DIR/menui_db_$DATE.sql

# Sauvegarder les fichiers uploadés
tar -czf $BACKUP_DIR/uploads_$DATE.tar.gz ~/menui-measure/laravel-app/storage/app/public/

# Nettoyer les sauvegardes de plus de 30 jours
find $BACKUP_DIR -type f -mtime +30 -delete

# Synchroniser avec OVH Object Storage (optionnel)
# rclone sync $BACKUP_DIR ovh:menui-backups/
```

### Ajouter la tâche cron
```bash
chmod +x ~/backup-menui.sh
crontab -e
```

Ajouter :
```
0 2 * * * /home/menui/backup-menui.sh
```

## 8. Mise à jour de l'application

```bash
cd ~/menui-measure
git pull origin main

# Reconstruire les images si nécessaire
docker-compose -f docker-compose.prod.yml build

# Relancer avec les nouvelles images
docker-compose -f docker-compose.prod.yml up -d

# Exécuter les migrations si nécessaires
docker-compose -f docker-compose.prod.yml exec laravel php artisan migrate --force

# Vider les caches
docker-compose -f docker-compose.prod.yml exec laravel php artisan cache:clear
docker-compose -f docker-compose.prod.yml exec laravel php artisan config:cache
docker-compose -f docker-compose.prod.yml exec laravel php artisan route:cache
```

## 9. Sécurité

### Firewall
```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### Fail2ban
```bash
sudo apt install fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

## 10. Performance

### Optimisation MySQL
Ajouter dans docker-compose.prod.yml pour le service db :
```yaml
    command: >
      --max_connections=200
      --innodb_buffer_pool_size=1G
      --innodb_log_file_size=256M
      --innodb_flush_log_at_trx_commit=2
      --innodb_flush_method=O_DIRECT
```

### Redis pour les sessions
Dans le .env Laravel :
```env
SESSION_DRIVER=redis
CACHE_DRIVER=redis
```

## Support et dépannage

### Problèmes courants

1. **Erreur 502 Bad Gateway**
   - Vérifier que les conteneurs sont en cours d'exécution
   - Vérifier les logs Nginx et Laravel

2. **Erreur de permission**
   - Réexécuter les commandes de permission
   - Vérifier l'utilisateur www-data

3. **Problème de mémoire**
   - Augmenter la swap si nécessaire
   - Optimiser les paramètres PHP

### Contacts
- Support technique : support@menui.com
- Documentation : https://docs.menui.com