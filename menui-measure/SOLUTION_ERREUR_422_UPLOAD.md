# Solution - Erreur 422 Upload Photos

## Problème identifié

L'erreur **422 Unprocessable Content** sur `https://mesures.calendrize.com/guest/Pa6oRll3llBfm1PiY7Scx8PczVB4Ru4w/photos` indique que la validation des données échoue côté serveur.

## Règles de validation actuelles

D'après le code dans `GuestUploadController.php` :

```php
$request->validate([
    'photos' => 'required|array|min:1|max:10',
    'photos.*' => 'required|image|mimes:jpeg,jpg,png|max:10240', // 10MB max
    'contact_email' => 'nullable|email',
    'contact_phone' => 'nullable|string|max:20',
]);
```

## Causes possibles de l'erreur 422

### 1. **Taille de fichier trop importante**
- Limite : 10MB par photo (`max:10240` = 10240 KB)
- Vérifiez la taille des photos uploadées

### 2. **Format de fichier non supporté**
- Formats acceptés : `jpeg`, `jpg`, `png` uniquement
- Pas de support pour `gif`, `webp`, `bmp`, etc.

### 3. **Problème de configuration PHP/Nginx**
- `upload_max_filesize` et `post_max_size` trop petits
- `client_max_body_size` Nginx insuffisant

### 4. **Token expiré ou invalide**
- Le token guest peut avoir expiré
- Vérification : `$task->isGuestTokenValid()`

### 5. **Problème de stockage**
- Permissions insuffisantes sur le dossier `storage/app/public/`
- Lien symbolique `storage:link` manquant

## Solution de débogage immédiate

### Étape 1: Ajouter des logs détaillés

Modifiez temporairement le contrôleur pour loguer plus d'informations :

```php
// Dans GuestUploadController.php, après la ligne 50, avant la validation :

Log::info('Tentative d\'upload de photos', [
    'token' => $token,
    'task_id' => $task->id,
    'request_files' => $request->hasFile('photos') ? 'YES' : 'NO',
    'files_count' => $request->hasFile('photos') ? count($request->file('photos')) : 0,
    'php_max_upload' => ini_get('upload_max_filesize'),
    'php_post_max' => ini_get('post_max_size'),
]);

if ($request->hasFile('photos')) {
    foreach ($request->file('photos') as $index => $file) {
        Log::info("Photo $index", [
            'original_name' => $file->getClientOriginalName(),
            'mime_type' => $file->getClientMimeType(),
            'size_bytes' => $file->getSize(),
            'size_mb' => round($file->getSize() / 1024 / 1024, 2),
            'extension' => $file->getClientOriginalExtension(),
            'is_valid' => $file->isValid(),
        ]);
    }
}

// Capturer l'erreur de validation
try {
    $request->validate([
        'photos' => 'required|array|min:1|max:10',
        'photos.*' => 'required|image|mimes:jpeg,jpg,png|max:10240',
        'contact_email' => 'nullable|email',
        'contact_phone' => 'nullable|string|max:20',
    ]);
} catch (ValidationException $e) {
    Log::error('Erreur de validation', [
        'errors' => $e->errors(),
        'request_data' => $request->all(),
    ]);
    throw $e;
}
```

### Étape 2: Vérifications serveur

```bash
# 1. Vérifier les logs Laravel
tail -f /var/www/votre-app/laravel-app/storage/logs/laravel.log

# 2. Vérifier la configuration PHP
php -i | grep -E "(upload_max_filesize|post_max_size|max_file_uploads)"

# 3. Vérifier la configuration Nginx
nginx -T | grep client_max_body_size

# 4. Vérifier les permissions storage
ls -la storage/app/public/
ls -la public/storage

# 5. Tester le token
curl -X GET "https://mesures.calendrize.com/guest/Pa6oRll3llBfm1PiY7Scx8PczVB4Ru4w/check-token"
```

### Étape 3: Test avec validation simplifiée

Créez temporairement une version simplifiée pour isoler le problème :

```php
// Version de débogage dans GuestUploadController.php
public function store(Request $request, $token)
{
    $task = Task::where('guest_token', $token)->firstOrFail();

    // Log des informations de base
    Log::info('Debug upload start', [
        'token' => $token,
        'task_found' => $task ? 'YES' : 'NO',
        'task_valid' => $task->isGuestTokenValid() ? 'YES' : 'NO',
        'has_files' => $request->hasFile('photos') ? 'YES' : 'NO',
    ]);

    if (!$task->isGuestTokenValid()) {
        Log::error('Token invalide', ['token' => $token]);
        throw ValidationException::withMessages([
            'token' => ['Le lien a expiré.'],
        ]);
    }

    // Validation simplifiée pour test
    $validated = $request->validate([
        'photos' => 'required|array|min:1',
        'photos.*' => 'required|file', // Validation très basique
    ]);

    Log::info('Validation réussie', ['files_count' => count($validated['photos'])]);

    return response()->json([
        'success' => true,
        'message' => 'Test validation OK',
        'photos_count' => count($validated['photos']),
    ]);
}
```

## Solutions rapides à tester

### Solution 1: Augmenter les limites

```bash
# Dans /etc/php/8.2/fpm/php.ini
upload_max_filesize = 50M
post_max_size = 50M
max_file_uploads = 20

# Dans nginx.conf
client_max_body_size 50M;

# Redémarrer les services
systemctl restart php8.2-fpm nginx
```

### Solution 2: Vérifier le storage

```bash
cd /var/www/votre-app/laravel-app
php artisan storage:link
chown -R www-data:www-data storage/
chmod -R 775 storage/
```

### Solution 3: Tester avec validation réduite

Modifiez temporairement la validation :

```php
'photos.*' => 'required|file|max:5120', // 5MB au lieu de 10MB
```

## Tests recommandés

1. **Test avec une seule petite image** (< 1MB, format JPG)
2. **Vérifier les logs** après chaque tentative
3. **Tester le token** séparément
4. **Utiliser Postman/curl** pour isoler le problème frontend/backend

Le problème est très probablement lié aux **limites de taille de fichier** ou à la **configuration du serveur**. Les logs détaillés vous donneront la cause exacte.
