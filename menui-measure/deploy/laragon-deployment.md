# Guide de déploiement local avec Laragon (Windows)

Ce guide explique comment installer et configurer Menui Measure sur Windows en utilisant Laragon.

## Prérequis

- Windows 10/11
- [Laragon Full](https://laragon.org/download/) (dernière version)
- Au moins 4GB de RAM disponible
- 10GB d'espace disque libre

## 1. Installation et configuration de Laragon

### Télécharger et installer Laragon

1. Téléchargez Laragon Full depuis https://laragon.org/download/
2. Installez Laragon (installation par défaut recommandée)
3. Lancez Laragon en tant qu'administrateur

### Configurer les versions requises

Dans Laragon, nous devons nous assurer d'avoir :
- PHP 8.2+
- MySQL 8.0+
- Redis
- Node.js 18+

#### Installer PHP 8.2

1. Menu → PHP → Version → Add another...
2. Téléchargez PHP 8.2 depuis https://windows.php.net/download/
3. Extrayez dans `C:\laragon\bin\php\php-8.2-Win32-vs16-x64`
4. Redémarrez Laragon et sélectionnez PHP 8.2

#### Activer les extensions PHP nécessaires

Éditez `C:\laragon\bin\php\php-8.2-Win32-vs16-x64\php.ini` :

```ini
; Décommenter ces lignes
extension=curl
extension=fileinfo
extension=gd
extension=intl
extension=mbstring
extension=exif
extension=openssl
extension=pdo_mysql
extension=sodium
extension=zip

; Ajouter si pas présent
extension=redis

; Configuration
upload_max_filesize = 20M
post_max_size = 25M
memory_limit = 512M
max_execution_time = 300
```

## 2. Installation de Python et du service IA

### Installer Python 3.11

1. Téléchargez Python 3.11 depuis https://www.python.org/downloads/
2. Lors de l'installation, cochez "Add Python to PATH"
3. Installez dans `C:\Python311`

### Installer les dépendances Python

Ouvrez PowerShell en tant qu'administrateur :

```powershell
# Installer pip si nécessaire
python -m ensurepip --upgrade

# Installer virtualenv
pip install virtualenv
```

## 3. Cloner et configurer le projet

### Cloner le repository

Dans le terminal Laragon :

```bash
cd C:\laragon\www
git clone https://github.com/votre-repo/menui-measure.git
cd menui-measure
```

Si vous n'avez pas Git, copiez simplement le dossier du projet dans `C:\laragon\www\menui-measure`

## 4. Configuration de la base de données

1. Ouvrez HeidiSQL depuis Laragon
2. Créez une nouvelle base de données :

```sql
CREATE DATABASE menui CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

## 5. Configuration de Laravel

### Installer les dépendances PHP

Dans le terminal Laragon :

```bash
cd C:\laragon\www\menui-measure\laravel-app
composer install
```

### Configurer l'environnement

```bash
# Copier le fichier .env
copy .env.example .env
```

Éditez `.env` avec ces valeurs :

```env
APP_NAME=Menui
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://menui.test

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=menui
DB_USERNAME=root
DB_PASSWORD=

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

CACHE_DRIVER=redis
QUEUE_CONNECTION=redis
SESSION_DRIVER=file

AI_SERVICE_URL=http://localhost:8001

# Pour le développement local
FILESYSTEM_DISK=public
```

### Finaliser l'installation Laravel

```bash
# Générer la clé d'application
php artisan key:generate

# Exécuter les migrations
php artisan migrate

# Créer le lien symbolique pour le storage
php artisan storage:link

# Installer les dépendances JavaScript
npm install

# Pour le développement (avec hot reload)
npm run dev

# Ou pour la production
npm run build
```

## 6. Configuration du Virtual Host

Laragon peut créer automatiquement un virtual host :

1. Clic droit sur Laragon → Apache → sites-enabled
2. Créez un fichier `menui.test.conf` :

```apache
<VirtualHost *:80>
    DocumentRoot "C:/laragon/www/menui-measure/laravel-app/public"
    ServerName menui.test
    ServerAlias *.menui.test
    <Directory "C:/laragon/www/menui-measure/laravel-app/public">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

3. Redémarrez Apache
4. Ajoutez dans `C:\Windows\System32\drivers\etc\hosts` :
```
127.0.0.1 menui.test
```

## 7. Installation du service IA Python

### Créer l'environnement virtuel

Ouvrez PowerShell dans le dossier du projet :

```powershell
cd C:\laragon\www\menui-measure\ai-service

# Créer l'environnement virtuel
python -m venv venv

# Activer l'environnement
.\venv\Scripts\activate

# Installer les dépendances
pip install -r requirements.txt
```

### Créer un script de démarrage

Créez `C:\laragon\www\menui-measure\ai-service\start-ai-service.bat` :

```batch
@echo off
cd /d C:\laragon\www\menui-measure\ai-service
call venv\Scripts\activate
python -m uvicorn main:app --host 127.0.0.1 --port 8001 --reload
pause
```

## 8. Configuration de Redis

### Installer Redis pour Windows

1. Téléchargez Redis pour Windows : https://github.com/microsoftarchive/redis/releases
2. Installez dans `C:\Redis`
3. Ajoutez `C:\Redis` au PATH système

### Démarrer Redis

Créez `C:\laragon\www\menui-measure\start-redis.bat` :

```batch
@echo off
cd /d C:\Redis
redis-server.exe
```

## 9. Démarrer l'application

### Script de démarrage complet

Créez `C:\laragon\www\menui-measure\start-all.bat` :

```batch
@echo off
echo Démarrage de Menui Measure...

:: Démarrer Laragon s'il n'est pas déjà lancé
echo Vérifiez que Laragon est démarré (Apache + MySQL)
pause

:: Démarrer Redis
echo Démarrage de Redis...
start "Redis" cmd /c "C:\Redis\redis-server.exe"

:: Démarrer le service IA
echo Démarrage du service IA...
start "AI Service" cmd /c "cd /d C:\laragon\www\menui-measure\ai-service && venv\Scripts\activate && python -m uvicorn main:app --host 127.0.0.1 --port 8001 --reload"

:: Démarrer la queue Laravel
echo Démarrage de la queue Laravel...
start "Laravel Queue" cmd /c "cd /d C:\laragon\www\menui-measure\laravel-app && php artisan queue:work --tries=3"

:: Démarrer Vite pour le développement
echo Démarrage de Vite (développement)...
start "Vite Dev" cmd /c "cd /d C:\laragon\www\menui-measure\laravel-app && npm run dev"

echo.
echo Tous les services sont démarrés !
echo.
echo Application disponible sur : http://menui.test
echo Service IA disponible sur : http://localhost:8001/docs
echo.
pause
```

### Arrêter tous les services

Créez `C:\laragon\www\menui-measure\stop-all.bat` :

```batch
@echo off
echo Arrêt des services...
taskkill /F /IM redis-server.exe 2>nul
taskkill /F /FI "WindowTitle eq AI Service*" 2>nul
taskkill /F /FI "WindowTitle eq Laravel Queue*" 2>nul
taskkill /F /FI "WindowTitle eq Vite Dev*" 2>nul
echo Services arrêtés.
pause
```

## 10. Configuration additionnelle pour le développement

### Activer le mode debug

Dans `.env` :
```env
APP_DEBUG=true
APP_ENV=local
```

### Configuration de l'IDE

Pour VS Code, installez ces extensions :
- PHP Intelephense
- Laravel Extension Pack
- ESLint
- Prettier
- Python

### Alias de commandes utiles

Créez `C:\laragon\www\menui-measure\dev-commands.bat` :

```batch
@echo off
if "%1"=="migrate" (
    cd laravel-app && php artisan migrate
) else if "%1"=="fresh" (
    cd laravel-app && php artisan migrate:fresh --seed
) else if "%1"=="cache" (
    cd laravel-app && php artisan cache:clear && php artisan config:clear
) else if "%1"=="queue" (
    cd laravel-app && php artisan queue:work --tries=3
) else if "%1"=="test" (
    cd laravel-app && php artisan test
) else if "%1"=="npm-dev" (
    cd laravel-app && npm run dev
) else if "%1"=="npm-build" (
    cd laravel-app && npm run build
) else (
    echo Commandes disponibles:
    echo   dev-commands migrate     - Exécuter les migrations
    echo   dev-commands fresh       - Réinitialiser la base de données
    echo   dev-commands cache       - Vider les caches
    echo   dev-commands queue       - Démarrer le worker de queue
    echo   dev-commands test        - Exécuter les tests
    echo   dev-commands npm-dev     - Démarrer Vite en mode dev
    echo   dev-commands npm-build   - Compiler les assets
)
```

## 11. Tester l'installation

1. Démarrez tous les services avec `start-all.bat`
2. Accédez à http://menui.test
3. Vérifiez que le service IA fonctionne : http://localhost:8001/docs

### Créer un utilisateur admin

```bash
cd C:\laragon\www\menui-measure\laravel-app
php artisan tinker
```

Dans tinker :
```php
$user = new App\Models\User;
$user->name = 'Admin';
$user->email = 'admin@menui.test';
$user->password = bcrypt('password');
$user->role = 'admin';
$user->save();
exit
```

## 12. Dépannage

### Problème : "Class not found"
```bash
cd laravel-app
composer dump-autoload
```

### Problème : Redis ne démarre pas
- Vérifiez que le port 6379 n'est pas utilisé
- Essayez de lancer Redis manuellement depuis `C:\Redis`

### Problème : Service IA ne démarre pas
```bash
# Réinstaller les dépendances
cd ai-service
venv\Scripts\activate
pip install --upgrade -r requirements.txt
```

### Problème : Erreur CORS
Ajoutez dans `laravel-app\config\cors.php` :
```php
'paths' => ['api/*', 'sanctum/csrf-cookie', 'guest/*'],
'allowed_origins' => ['http://menui.test', 'http://localhost:8001'],
```

## 13. Optimisations pour le développement

### Utiliser Laravel Telescope (optionnel)

```bash
cd laravel-app
composer require laravel/telescope --dev
php artisan telescope:install
php artisan migrate
```

### Configurer Xdebug

1. Téléchargez Xdebug pour votre version de PHP
2. Copiez dans `C:\laragon\bin\php\php-8.2-Win32-vs16-x64\ext`
3. Ajoutez dans `php.ini` :

```ini
[xdebug]
zend_extension=xdebug
xdebug.mode=debug
xdebug.start_with_request=yes
xdebug.client_port=9003
```

## 14. Backup et restauration

### Script de backup

Créez `backup.bat` :

```batch
@echo off
set BACKUP_DIR=C:\laragon\backups\menui
set DATE=%date:~-4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%

mkdir "%BACKUP_DIR%\%DATE%" 2>nul

:: Backup base de données
"C:\laragon\bin\mysql\mysql-8.0.30-winx64\bin\mysqldump.exe" -u root menui > "%BACKUP_DIR%\%DATE%\menui.sql"

:: Backup fichiers uploadés
xcopy "C:\laragon\www\menui-measure\laravel-app\storage\app\public" "%BACKUP_DIR%\%DATE%\storage" /E /I /Y

echo Backup terminé dans %BACKUP_DIR%\%DATE%
pause
```

## Raccourcis utiles

- **Application** : http://menui.test
- **API Documentation** : http://localhost:8001/docs
- **PHPMyAdmin** : http://localhost/phpmyadmin
- **Logs Laravel** : `C:\laragon\www\menui-measure\laravel-app\storage\logs`

## Support

Pour toute question ou problème :
1. Vérifiez les logs dans `storage/logs`
2. Consultez la console du navigateur (F12)
3. Vérifiez que tous les services sont démarrés