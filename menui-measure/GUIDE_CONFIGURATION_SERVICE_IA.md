# Guide de Configuration du Service IA

## Problème identifié

L'erreur **"Failed to connect to 127.0.0.1 port 8001: Connection refused"** provient du fait que votre application Laravel tente de se connecter au service IA en local, alors que votre service IA est hébergé sur un serveur OVH.

## Service IA disponible

✅ **Votre service IA fonctionne correctement sur :** `http://vps-df0c2336.vps.ovh.net:8000/`

Réponse du service :
```json
{
  "service": "Service IA de Mesure Menui",
  "version": "1.0.0", 
  "endpoints": ["/analyze", "/warp", "/health"]
}
```

## Configuration actuelle

Dans `laravel-app/config/services.php` (ligne 33) :
```php
'ai' => [
    'url' => env('AI_SERVICE_URL', 'http://ai-service:8000'),
    'timeout' => env('AI_SERVICE_TIMEOUT', 60),
],
```

L'application utilise la variable d'environnement `AI_SERVICE_URL` avec une valeur par défaut pour Docker.

## Solution : Mettre à jour la configuration

### 1. Configuration sur le serveur de production

Connectez-vous à votre serveur et modifiez le fichier `.env` de Laravel :

```bash
# Se connecter au serveur
ssh votre-utilisateur@mesures.calendrize.com

# Aller dans le répertoire Laravel
cd /var/www/votre-app/laravel-app

# Modifier le fichier .env
nano .env
```

### 2. Ajouter/modifier la variable AI_SERVICE_URL

Dans le fichier `.env`, ajoutez ou modifiez cette ligne :

```env
# Configuration du service IA
AI_SERVICE_URL=http://vps-df0c2336.vps.ovh.net:8000
AI_SERVICE_TIMEOUT=120
```

### 3. Effacer le cache de configuration

```bash
# Effacer le cache pour que les nouveaux paramètres soient pris en compte
php artisan config:clear
php artisan cache:clear

# Optionnel : recréer le cache en production
php artisan config:cache
```

### 4. Redémarrer les services

```bash
# Redémarrer la queue Laravel (important !)
sudo systemctl restart menui-queue

# Ou si vous utilisez supervisor
sudo supervisorctl restart laravel-queue:*

# Redémarrer le serveur web si nécessaire
sudo systemctl restart nginx
sudo systemctl restart php8.2-fpm
```

## Vérification de la configuration

### 1. Tester depuis le serveur

```bash
# Tester la connexion au service IA
curl -v http://vps-df0c2336.vps.ovh.net:8000/health

# Vérifier la configuration Laravel
cd /var/www/votre-app/laravel-app
php artisan tinker
>>> config('services.ai.url')
// Doit retourner: "http://vps-df0c2336.vps.ovh.net:8000"
```

### 2. Tester un upload de photo

Après la configuration, testez un upload de photo pour vérifier que le service IA est appelé correctement.

### 3. Vérifier les logs

```bash
# Logs Laravel
tail -f storage/logs/laravel.log

# Logs de la queue
tail -f storage/logs/queue.log
```

## Configuration pour développement local

Si vous voulez tester en local avec le service IA distant, créez un fichier `.env.local` :

```env
APP_NAME=Menui
APP_ENV=local
APP_DEBUG=true
APP_URL=http://menui.test

# Base de données locale
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=menui
DB_USERNAME=root
DB_PASSWORD=

# Service IA distant
AI_SERVICE_URL=http://vps-df0c2336.vps.ovh.net:8000
AI_SERVICE_TIMEOUT=120

# Redis local
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

CACHE_DRIVER=redis
QUEUE_CONNECTION=redis
SESSION_DRIVER=file
```

## Scripts de test

### Test de connectivité au service IA

```bash
#!/bin/bash
echo "Test de connectivité au service IA..."

# Test basique
curl -s http://vps-df0c2336.vps.ovh.net:8000/ | jq .

# Test endpoint health
curl -s http://vps-df0c2336.vps.ovh.net:8000/health | jq .

echo "Service IA accessible !"
```

### Test depuis Laravel

```php
// Dans Laravel Tinker ou un contrôleur de test
use Illuminate\Support\Facades\Http;

$aiUrl = config('services.ai.url');
echo "URL configurée: " . $aiUrl . "\n";

$response = Http::timeout(10)->get($aiUrl . '/health');
if ($response->successful()) {
    echo "✅ Service IA accessible\n";
    echo "Réponse: " . $response->body() . "\n";
} else {
    echo "❌ Erreur: " . $response->status() . "\n";
}
```

## Résolution de problèmes

### Si l'erreur persiste

1. **Vérifiez que le cache est bien effacé**
   ```bash
   php artisan config:clear
   php artisan cache:clear
   ```

2. **Redémarrez TOUS les workers de queue**
   ```bash
   sudo systemctl restart menui-queue
   ```

3. **Vérifiez les logs pour les détails**
   ```bash
   tail -f storage/logs/laravel.log | grep -i "ai\|service\|connection"
   ```

4. **Testez la configuration en mode debug**
   ```bash
   php artisan tinker
   >>> config('services.ai')
   ```

### Erreurs courantes

- **Cache non effacé** : Les anciens paramètres restent en mémoire
- **Queue non redémarrée** : Les workers utilisent encore l'ancienne configuration
- **Firewall** : Le serveur ne peut pas accéder au service IA externe
- **DNS** : Problème de résolution du nom de domaine

## Sécurité

⚠️ **Important** : Le service IA est actuellement accessible publiquement. Considérez :

1. **Restriction d'accès par IP** sur le serveur OVH
2. **Authentification** via API key
3. **HTTPS** au lieu de HTTP pour la production
4. **Firewall** pour limiter l'accès

Après cette configuration, vos uploads de photos devraient fonctionner correctement avec le service IA distant !
