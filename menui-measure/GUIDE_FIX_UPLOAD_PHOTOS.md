# Guide de résolution - Erreur d'upload de photos sur serveur

## Problème identifié

L'erreur `"The photos.0 failed to upload."` sur le serveur indique un problème avec l'upload de fichiers. Après analyse du code, voici les causes les plus probables :

## 1. Lien symbolique storage manquant ⚠️

**Cause principale identifiée** : Le lien symbolique entre `public/storage` et `storage/app/public` n'existe probablement pas sur le serveur.

### Vérification sur le serveur

```bash
# Se connecter au serveur et vérifier
cd /var/www/votre-app/laravel-app/public
ls -la storage

# Si le lien n'existe pas, vous verrez :
# ls: cannot access 'storage': No such file or directory
```

### Solution

```bash
# Se placer dans le répertoire Laravel
cd /var/www/votre-app/laravel-app

# Créer le lien symbolique
php artisan storage:link

# Vérifier que le lien a été créé
ls -la public/storage
# Doit afficher : storage -> ../storage/app/public
```

## 2. Permissions de dossiers incorrectes

### Vérification des permissions

```bash
# Vérifier les permissions des dossiers storage
ls -la storage/
ls -la storage/app/
ls -la storage/app/public/
```

### Correction des permissions

```bash
# Définir les bonnes permissions
sudo chown -R www-data:www-data storage/ bootstrap/cache/
sudo chmod -R 775 storage/ bootstrap/cache/

# Pour les photos spécifiquement
sudo mkdir -p storage/app/public/photos
sudo chown -R www-data:www-data storage/app/public/photos
sudo chmod -R 775 storage/app/public/photos
```

## 3. Configuration PHP - Limites d'upload

Selon votre configuration `docker/php/php.ini`, vous avez :
- `upload_max_filesize = 50M`
- `post_max_size = 50M`
- `max_execution_time = 300`

### Vérification sur le serveur

```bash
# Vérifier la configuration PHP active
php -i | grep -E "(upload_max_filesize|post_max_size|max_execution_time)"
```

Si les valeurs sont trop petites, mettez à jour la configuration PHP et redémarrez le serveur web.

## 4. Configuration Nginx - Taille maximale

Dans votre `docker/nginx/nginx.conf`, vous avez `client_max_body_size 50M;` mais vérifiez la configuration active :

```bash
# Vérifier la configuration Nginx
nginx -t
grep -r "client_max_body_size" /etc/nginx/
```

## 5. Espace disque insuffisant

```bash
# Vérifier l'espace disque disponible
df -h
```

## 6. Validation Laravel côté serveur

Le code dans `GuestUploadController.php` montre ces validations :
- `photos.*' => 'required|image|mimes:jpeg,jpg,png|max:10240'` (10MB max)
- Maximum 10 photos par upload

### Test de débogage

Ajoutez temporairement des logs dans le contrôleur pour identifier le problème :

```php
// Dans GuestUploadController.php, ligne 60 après validation
Log::info('Validation réussie', [
    'photos_count' => count($request->file('photos')),
    'storage_disk' => config('filesystems.default'),
    'storage_path' => storage_path('app/public'),
]);
```

## Script de diagnostic complet

Créez ce script pour diagnostiquer le problème :

```bash
#!/bin/bash
echo "=== DIAGNOSTIC UPLOAD PHOTOS ==="
echo ""

echo "1. Vérification du lien symbolique storage :"
cd /var/www/votre-app/laravel-app
ls -la public/storage 2>/dev/null && echo "✓ Lien storage existe" || echo "✗ Lien storage manquant"
echo ""

echo "2. Vérification des permissions :"
ls -ld storage/ storage/app/ storage/app/public/ 2>/dev/null
echo ""

echo "3. Vérification de l'espace disque :"
df -h /var/www/
echo ""

echo "4. Configuration PHP :"
php -i | grep -E "(upload_max_filesize|post_max_size|max_execution_time|memory_limit)"
echo ""

echo "5. Configuration Nginx :"
nginx -T 2>/dev/null | grep client_max_body_size || echo "Non trouvé"
echo ""

echo "6. Test d'écriture dans storage :"
touch storage/app/public/test_write.txt 2>/dev/null && echo "✓ Écriture OK" || echo "✗ Écriture impossible"
rm -f storage/app/public/test_write.txt 2>/dev/null
```

## Solution rapide recommandée

```bash
# 1. Créer le lien symbolique
cd /var/www/votre-app/laravel-app
php artisan storage:link

# 2. Corriger les permissions
sudo chown -R www-data:www-data storage/ bootstrap/cache/
sudo chmod -R 775 storage/ bootstrap/cache/

# 3. Créer le dossier photos si nécessaire
sudo mkdir -p storage/app/public/photos
sudo chown -R www-data:www-data storage/app/public/photos

# 4. Redémarrer les services
sudo systemctl restart nginx
sudo systemctl restart php8.2-fpm  # ou votre version PHP

# 5. Tester l'upload
```

## Vérification finale

Après avoir appliqué ces corrections :

1. Testez l'upload d'une petite image (< 1MB)
2. Vérifiez les logs Laravel : `tail -f storage/logs/laravel.log`
3. Vérifiez les logs Nginx : `tail -f /var/log/nginx/error.log`
4. Vérifiez que le fichier apparaît dans `storage/app/public/photos/`

Le problème est très probablement le **lien symbolique storage manquant**. C'est l'erreur la plus commune lors du déploiement d'applications Laravel.
