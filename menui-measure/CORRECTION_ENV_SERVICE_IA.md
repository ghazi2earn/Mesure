# Correction urgente du fichier .env

## Problème identifié dans votre .env

Vous avez **deux configurations contradictoires** pour le service IA :

```env
# Ligne ~42 (CORRECTE mais incomplète)
AI_SERVICE_URL=vps-df0c2336.vps.ovh.net:8000

# Ligne ~71 (INCORRECTE - écrase la première)
AI_SERVICE_URL=http://127.0.0.1:8001 
AI_SERVICE_TIMEOUT=60 
```

## Solution immédiate

### 1. Supprimer la configuration en double

Dans votre fichier `.env` sur le serveur, **supprimez ces lignes à la fin** :

```env
# SUPPRIMER CES LIGNES
AI_SERVICE_URL=http://127.0.0.1:8001 
AI_SERVICE_TIMEOUT=60 
```

### 2. Corriger la configuration principale

Modifiez la ligne ~42 pour ajouter le protocole HTTP :

```env
# AVANT (incorrect)
AI_SERVICE_URL=vps-df0c2336.vps.ovh.net:8000

# APRÈS (correct)
AI_SERVICE_URL=http://vps-df0c2336.vps.ovh.net:8000
```

## Configuration finale recommandée

Votre section service IA dans le `.env` devrait ressembler à ceci :

```env
# Service IA
AI_SERVICE_URL=http://vps-df0c2336.vps.ovh.net:8000
AI_SERVICE_TIMEOUT=120

# Configuration invité
GUEST_TOKEN_EXPIRY_DAYS=7
```

## Actions à effectuer immédiatement

### 1. Sur votre serveur de production

```bash
# Se connecter au serveur
ssh votre-user@mesures.calendrize.com

# Éditer le fichier .env
cd /var/www/votre-app/laravel-app
nano .env

# Faire les modifications :
# - Supprimer les lignes en double à la fin
# - Corriger l'URL pour ajouter http://

# Sauvegarder et quitter (Ctrl+X, Y, Enter)
```

### 2. Effacer le cache Laravel

```bash
# Effacer tous les caches
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear

# Recréer le cache de configuration (optionnel en production)
php artisan config:cache
```

### 3. Redémarrer les services

```bash
# Redémarrer la queue Laravel (IMPORTANT !)
sudo systemctl restart menui-queue

# Ou si vous utilisez supervisor
sudo supervisorctl restart all

# Redémarrer le serveur web
sudo systemctl restart nginx
sudo systemctl restart php8.2-fpm
```

## Vérification que ça fonctionne

### 1. Tester la configuration

```bash
# Vérifier la configuration Laravel
php artisan tinker
>>> config('services.ai.url')
// Doit retourner : "http://vps-df0c2336.vps.ovh.net:8000"
>>> exit
```

### 2. Tester la connectivité

```bash
# Tester depuis le serveur
curl -v http://vps-df0c2336.vps.ovh.net:8000/
```

### 3. Tester un upload de photo

Essayez de télécharger une photo via l'interface pour vérifier que le service IA est appelé correctement.

## Fichier .env final (extrait)

```env
APP_NAME=menui
APP_ENV=production
APP_KEY=base64:qpvKHaPq5q3/ZFBrZ4kb8nU+C0E6Dng18T27ATDJmWo=
APP_DEBUG=false
APP_URL=https://mesures.calendrize.com

# Base de données
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=mesure
DB_USERNAME=mesure
DB_PASSWORD=1D98s^6aj

# Queue et cache
QUEUE_CONNECTION=redis
CACHE_DRIVER=redis

# Redis
REDIS_HOST=redis
REDIS_PASSWORD=null
REDIS_PORT=6379

# Service IA (CONFIGURATION CORRECTE)
AI_SERVICE_URL=http://vps-df0c2336.vps.ovh.net:8000
AI_SERVICE_TIMEOUT=120

# Configuration invité
GUEST_TOKEN_EXPIRY_DAYS=7
```

## Points d'attention

1. **Environnement** : Changez `APP_ENV=local` en `APP_ENV=production`
2. **Debug** : Changez `APP_DEBUG=true` en `APP_DEBUG=false` en production
3. **Queue** : Utilisez `QUEUE_CONNECTION=redis` au lieu de `sync` pour de meilleures performances
4. **Cache** : Utilisez `CACHE_DRIVER=redis` au lieu de `file`

Après ces modifications, votre service IA devrait fonctionner correctement et les erreurs de connexion devraient disparaître !
