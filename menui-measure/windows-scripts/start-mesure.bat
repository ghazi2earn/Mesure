@echo off
echo Démarrage de l'application Mesure...

REM Aller dans le répertoire de l'application
cd /d "C:\laragon\www\Mesure\menui-measure\laravel-app"

REM Vérifier que les dépendances sont installées
if not exist "vendor" (
    echo Installation des dépendances Composer...
    composer install
)

REM Vérifier que les assets sont compilés
if not exist "public\build" (
    echo Compilation des assets...
    npm run build
)

REM Générer la clé d'application si nécessaire
if not exist ".env" (
    echo Copie du fichier .env...
    if exist ".env.example" (
        copy .env.example .env
    ) else (
        echo Création d'un fichier .env minimal...
        echo APP_NAME="Menui Mesure" > .env
        echo APP_ENV=local >> .env
        echo APP_KEY= >> .env
        echo APP_DEBUG=true >> .env
        echo APP_URL=http://mesure.test >> .env
        echo. >> .env
        echo DB_CONNECTION=mysql >> .env
        echo DB_HOST=127.0.0.1 >> .env
        echo DB_PORT=3306 >> .env
        echo DB_DATABASE=menui >> .env
        echo DB_USERNAME=root >> .env
        echo DB_PASSWORD= >> .env
        echo. >> .env
        echo CACHE_DRIVER=redis >> .env
        echo QUEUE_CONNECTION=redis >> .env
        echo SESSION_DRIVER=redis >> .env
        echo. >> .env
        echo REDIS_HOST=127.0.0.1 >> .env
        echo REDIS_PASSWORD=null >> .env
        echo REDIS_PORT=6379 >> .env
        echo. >> .env
        echo AI_SERVICE_URL=http://localhost:8000 >> .env
        echo AI_SERVICE_TIMEOUT=60 >> .env
    )
    php artisan key:generate
)

REM Vider les caches
echo Nettoyage des caches...
php artisan config:clear
php artisan route:clear
php artisan view:clear

echo Application prête !
echo Accédez à http://mesure.test
echo.
echo Si Laragon n'est pas démarré, lancez-le et redémarrez Apache.
pause


