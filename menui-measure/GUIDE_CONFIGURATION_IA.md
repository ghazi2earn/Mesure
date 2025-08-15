# Guide de Configuration du Service IA - Menui Mesure

## Vue d'ensemble

Le service IA de Menui Mesure utilise FastAPI avec OpenCV pour détecter automatiquement des marqueurs A4 et suggérer des mesures d'objets dans les photos uploadées.

## Architecture

```
Laravel App (Port 8000)  ←→  Service IA (Port 8001)
       ↕                           ↕
   MySQL/Redis              OpenCV + FastAPI
```

## Modes de fonctionnement

### 1. Mode Simulation (par défaut)
- **Utilisation** : Tests et développement sans traitement réel
- **Configuration** : `AI_SERVICE_URL=http://localhost:8000`
- **Avantages** : Pas de dépendances externes, démarrage rapide

### 2. Mode Développement Local
- **Utilisation** : Développement avec service IA réel
- **Configuration** : `AI_SERVICE_URL=http://127.0.0.1:8001`
- **Prérequis** : Python 3.11+ ou Docker

### 3. Mode Production Docker
- **Utilisation** : Déploiement avec Docker Compose
- **Configuration** : `AI_SERVICE_URL=http://ai-service:8000`
- **Prérequis** : Docker et Docker Compose

## Installation et Configuration

### Étape 1 : Préparation de l'environnement

1. **Démarrer Laragon** avec Apache/Nginx, MySQL et Redis (optionnel)

2. **Configurer l'application**
   ```batch
   cd windows-scripts
   setup-mesure.bat
   ```

3. **Configurer les services**
   ```batch
   setup-services.bat
   ```

### Étape 2 : Configuration du service IA

Exécuter le script de configuration :
```batch
setup-ai-service.bat
```

**Options disponibles :**
- `1` : Mode développement local (recommandé)
- `2` : Mode simulation
- `3` : Mode Docker

### Étape 3 : Démarrage du service IA

```batch
start-ai-service.bat
```

**Options de démarrage :**
- `1` : Docker Compose (tous les services)
- `2` : Python directement
- `3` : Service IA seul avec Docker

### Étape 4 : Test et validation

```batch
test-app.bat          # Test complet de l'application
test-ai-service.bat   # Test spécifique du service IA
```

## Configuration détaillée

### Variables d'environnement (.env)

```env
# Service IA
AI_SERVICE_URL=http://127.0.0.1:8001
AI_SERVICE_TIMEOUT=60

# Base de données
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=menui
DB_USERNAME=root
DB_PASSWORD=

# Cache et queues
CACHE_DRIVER=redis
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
```

### Configuration Laravel (config/services.php)

```php
'ai' => [
    'url' => env('AI_SERVICE_URL', 'http://ai-service:8000'),
    'timeout' => env('AI_SERVICE_TIMEOUT', 60),
],
```

## Dépendances du service IA

### Python (requirements.txt)
- `fastapi==0.104.1` - Framework web
- `uvicorn[standard]==0.24.0` - Serveur ASGI
- `opencv-python==4.8.1.78` - Traitement d'images
- `numpy==1.26.2` - Calculs numériques
- `pydantic==2.5.2` - Validation des données

### Système (Docker)
- Python 3.11-slim
- Dépendances OpenCV : libgl1-mesa-glx, libglib2.0-0, etc.

## API du service IA

### Endpoints principaux

- `GET /` - Informations du service
- `GET /health` - Vérification de l'état
- `POST /analyze` - Analyse d'image (détection A4 + mesures)
- `POST /warp` - Transformation de perspective
- `GET /docs` - Documentation Swagger

### Exemple d'utilisation

```bash
# Test de santé
curl http://127.0.0.1:8001/health

# Analyse d'image
curl -X POST "http://127.0.0.1:8001/analyze" \
     -F "file=@image.jpg" \
     -F "metadata={\"expect_marker\":\"A4\"}"
```

## Intégration Laravel

### Job de traitement (ProcessUploadedPhotoJob)

1. **Vérification** du fichier uploadé
2. **Appel** au service IA via HTTP
3. **Traitement** de la réponse JSON
4. **Sauvegarde** des mesures en base
5. **Notification** de l'utilisateur

### Workflow complet

```
Photo uploadée → Queue → ProcessUploadedPhotoJob → Service IA → Résultats sauvés
```

## Résolution de problèmes

### Service IA non accessible

1. Vérifier que le service est démarré :
   ```bash
   curl http://127.0.0.1:8001/health
   ```

2. Vérifier les ports :
   ```bash
   netstat -an | findstr :8001
   ```

3. Vérifier les logs :
   ```bash
   docker-compose logs ai-service
   ```

### Erreurs de traitement

1. **Marqueur A4 non détecté**
   - Vérifier l'éclairage de la photo
   - S'assurer que la feuille A4 est entièrement visible
   - Contraster le fond

2. **Timeout de connexion**
   - Augmenter `AI_SERVICE_TIMEOUT` dans .env
   - Vérifier les ressources système

3. **Erreurs OpenCV**
   - Redémarrer le service IA
   - Vérifier les dépendances système

### Logs et débogage

```bash
# Logs Laravel
tail -f laravel-app/storage/logs/laravel.log

# Logs Docker
docker-compose logs -f ai-service

# Logs Windows
# Voir les messages dans les fenêtres de commande
```

## Optimisation et performance

### Paramètres recommandés

- **Timeout** : 60-120 secondes pour les grosses images
- **Memory** : 2GB minimum pour le service IA
- **CPU** : 2 cores recommandés

### Cache et queues

- Utiliser Redis pour améliorer les performances
- Configurer plusieurs workers de queue si nécessaire :
  ```bash
  php artisan queue:work --tries=3 --timeout=90
  ```

## Sécurité

### Recommandations

1. **Ne pas exposer** le service IA directement sur Internet
2. **Valider** les fichiers uploadés (taille, type)
3. **Limiter** l'accès aux endpoints sensibles
4. **Surveiller** les ressources système

### Configuration production

```env
# Désactiver le debug
APP_DEBUG=false

# URL sécurisée
AI_SERVICE_URL=http://ai-service:8000

# Logs en production
LOG_LEVEL=warning
```

## Commandes utiles

```batch
# Configuration
setup-mesure.bat           # Configuration de base
setup-services.bat         # Services Laravel
setup-ai-service.bat       # Configuration service IA

# Démarrage
start-mesure.bat          # Application Laravel
start-ai-service.bat      # Service IA
start-queue.bat           # Workers de queue

# Test
test-app.bat              # Test complet
test-ai-service.bat       # Test service IA

# Arrêt
stop-all.bat              # Arrêt de tous les services
```

---

Pour plus d'informations, consultez la documentation technique dans le code source ou contactez l'équipe de développement.
