# Guide de déploiement OVH - Menui Measure

Ce guide détaille les étapes pour déployer l'application Menui Measure sur un VPS OVH.

## Prérequis

- VPS OVH avec Ubuntu 22.04 LTS
- Nom de domaine pointant vers le VPS
- Accès SSH root ou sudo
- Compte OVH Object Storage (optionnel)

## Étape 1: Préparation du serveur

### 1.1 Mise à jour du système
```bash
sudo apt update && sudo apt upgrade -y
```

### 1.2 Installation de Docker et Docker Compose
```bash
# Installation de Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Installation de Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Vérification
docker --version
docker-compose --version
```

### 1.3 Installation de Git et autres outils
```bash
sudo apt install -y git nginx certbot python3-certbot-nginx
```

## Étape 2: Déploiement de l'application

### 2.1 Cloner le repository
```bash
cd /opt
sudo git clone https://github.com/votre-username/menui-measure.git
sudo chown -R $USER:$USER menui-measure
cd menui-measure
```

### 2.2 Configuration des variables d'environnement
```bash
# Copier et éditer le fichier d'environnement
cp laravel-app/.env.example laravel-app/.env.prod

# Éditer les variables de production
nano laravel-app/.env.prod
```

Variables importantes à configurer :
```env
APP_NAME=menui
APP_ENV=production
APP_DEBUG=false
APP_URL=https://votre-domaine.com

# Base de données
DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=menui_prod
DB_USERNAME=menui_user
DB_PASSWORD=mot_de_passe_securise

# Redis
REDIS_HOST=redis
CACHE_STORE=redis
QUEUE_CONNECTION=redis

# AI Service
AI_SERVICE_URL=http://ai-service:8000

# OVH Object Storage (optionnel)
AWS_ACCESS_KEY_ID=votre_access_key
AWS_SECRET_ACCESS_KEY=votre_secret_key
AWS_DEFAULT_REGION=gra
AWS_BUCKET=votre-bucket
AWS_ENDPOINT=https://s3.gra.cloud.ovh.net
AWS_USE_PATH_STYLE_ENDPOINT=true
```

### 2.3 Créer le fichier docker-compose.prod.yml
Le fichier est déjà créé, mais vérifiez les variables d'environnement.

## Étape 3: Configuration Nginx

### 3.1 Créer la configuration Nginx
```bash
sudo nano /etc/nginx/sites-available/menui-measure
```

Contenu du fichier :
```nginx
server {
    listen 80;
    server_name votre-domaine.com www.votre-domaine.com;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /ai/ {
        proxy_pass http://localhost:8001/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    client_max_body_size 20M;
}
```

### 3.2 Activer le site
```bash
sudo ln -s /etc/nginx/sites-available/menui-measure /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## Étape 4: Déploiement avec Docker

### 4.1 Construire et lancer les conteneurs
```bash
cd /opt/menui-measure

# Construire les images
docker-compose -f docker-compose.prod.yml build

# Lancer les services
docker-compose -f docker-compose.prod.yml up -d
```

### 4.2 Initialiser la base de données
```bash
# Attendre que les services soient prêts
sleep 30

# Exécuter les migrations
docker-compose -f docker-compose.prod.yml exec laravel php artisan migrate --force

# Créer un utilisateur admin
docker-compose -f docker-compose.prod.yml exec laravel php artisan tinker
# Dans tinker :
# App\Models\User::create(['name' => 'Admin', 'email' => 'admin@example.com', 'password' => bcrypt('password'), 'role' => 'admin']);
```

## Étape 5: SSL avec Certbot

### 5.1 Obtenir le certificat SSL
```bash
sudo certbot --nginx -d votre-domaine.com -d www.votre-domaine.com
```

### 5.2 Configurer le renouvellement automatique
```bash
sudo crontab -e
# Ajouter cette ligne :
0 12 * * * /usr/bin/certbot renew --quiet
```

## Étape 6: Configuration OVH Object Storage (optionnel)

### 6.1 Créer un bucket S3
1. Connectez-vous à l'interface OVH
2. Allez dans "Public Cloud" > "Object Storage"
3. Créez un nouveau conteneur S3
4. Notez les clés d'accès

### 6.2 Configurer Laravel pour S3
Ajoutez dans `.env.prod` :
```env
FILESYSTEM_DISK=s3
AWS_ACCESS_KEY_ID=votre_access_key
AWS_SECRET_ACCESS_KEY=votre_secret_key
AWS_DEFAULT_REGION=gra
AWS_BUCKET=votre-bucket
AWS_ENDPOINT=https://s3.gra.cloud.ovh.net
AWS_USE_PATH_STYLE_ENDPOINT=true
```

## Étape 7: Monitoring et logs

### 7.1 Vérifier les logs
```bash
# Logs de l'application Laravel
docker-compose -f docker-compose.prod.yml logs laravel

# Logs du service AI
docker-compose -f docker-compose.prod.yml logs ai-service

# Logs Nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### 7.2 Monitoring des ressources
```bash
# Vérifier l'utilisation des ressources
docker stats

# Vérifier l'espace disque
df -h
```

## Étape 8: Sauvegarde

### 8.1 Script de sauvegarde automatique
```bash
sudo nano /opt/backup-menui.sh
```

Contenu du script :
```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/opt/backups/menui"

mkdir -p $BACKUP_DIR

# Sauvegarde de la base de données
docker-compose -f /opt/menui-measure/docker-compose.prod.yml exec -T db mysqldump -u root -p$DB_ROOT_PASSWORD menui_prod > $BACKUP_DIR/db_$DATE.sql

# Sauvegarde des fichiers uploadés
tar -czf $BACKUP_DIR/storage_$DATE.tar.gz /opt/menui-measure/storage

# Nettoyer les anciennes sauvegardes (garder 7 jours)
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
```

### 8.2 Programmer la sauvegarde
```bash
sudo chmod +x /opt/backup-menui.sh
sudo crontab -e
# Ajouter : 0 2 * * * /opt/backup-menui.sh
```

## Étape 9: Sécurité

### 9.1 Firewall
```bash
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw enable
```

### 9.2 Mise à jour automatique
```bash
sudo apt install unattended-upgrades
sudo dpkg-reconfigure unattended-upgrades
```

## Étape 10: Tests de validation

### 10.1 Vérifier les services
```bash
# Vérifier que tous les conteneurs fonctionnent
docker-compose -f docker-compose.prod.yml ps

# Tester l'API
curl https://votre-domaine.com/api/health

# Tester le service AI
curl https://votre-domaine.com/ai/
```

### 10.2 Test de bout en bout
1. Créer une tâche via l'interface admin
2. Générer un lien invité
3. Uploader une photo via le lien invité
4. Vérifier que la photo est traitée
5. Effectuer une mesure

## Dépannage

### Problèmes courants

1. **Les conteneurs ne démarrent pas :**
   ```bash
   docker-compose -f docker-compose.prod.yml logs
   ```

2. **Erreur de base de données :**
   ```bash
   docker-compose -f docker-compose.prod.yml exec db mysql -u root -p
   ```

3. **Problème de permissions :**
   ```bash
   sudo chown -R www-data:www-data /opt/menui-measure/storage
   ```

4. **Service AI non accessible :**
   ```bash
   docker-compose -f docker-compose.prod.yml restart ai-service
   ```

## Maintenance

### Mise à jour de l'application
```bash
cd /opt/menui-measure
git pull origin main
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d
docker-compose -f docker-compose.prod.yml exec laravel php artisan migrate --force
```

### Redémarrage des services
```bash
docker-compose -f docker-compose.prod.yml restart
```

### Nettoyage
```bash
# Nettoyer les images Docker inutilisées
docker image prune -f

# Nettoyer les volumes inutilisés
docker volume prune -f
```