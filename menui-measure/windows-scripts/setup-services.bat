@echo off
echo Configuration des services pour Menui Mesure...

echo.
echo Vérification des services requis dans Laragon...

REM Vérifier si Laragon est en cours d'exécution
tasklist /fi "imagename eq nginx.exe" 2>nul | find /i "nginx.exe" >nul
if %errorlevel% equ 0 (
    echo ✓ Nginx détecté (Laragon en cours)
) else (
    tasklist /fi "imagename eq httpd.exe" 2>nul | find /i "httpd.exe" >nul
    if %errorlevel% equ 0 (
        echo ✓ Apache détecté (Laragon en cours)
    ) else (
        echo ⚠ Laragon ne semble pas démarré
        echo Veuillez démarrer Laragon avant de continuer
        pause
        exit /b 1
    )
)

REM Vérifier MySQL
tasklist /fi "imagename eq mysqld.exe" 2>nul | find /i "mysqld.exe" >nul
if %errorlevel% equ 0 (
    echo ✓ MySQL détecté
) else (
    echo ✗ MySQL non détecté
    echo Démarrez MySQL dans Laragon
)

REM Vérifier Redis
tasklist /fi "imagename eq redis-server.exe" 2>nul | find /i "redis-server.exe" >nul
if %errorlevel% equ 0 (
    echo ✓ Redis détecté
) else (
    echo ⚠ Redis non détecté
    echo Redis est optionnel mais recommandé pour les performances
    echo Vous pouvez l'activer dans Laragon ou utiliser les caches par défaut
)

echo.
echo Configuration de la base de données...
cd /d "C:\laragon\www\Mesure\menui-measure\laravel-app"

REM Vérifier si la base de données existe
mysql -u root -e "CREATE DATABASE IF NOT EXISTS menui CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>nul
if %errorlevel% equ 0 (
    echo ✓ Base de données 'menui' créée/vérifiée
) else (
    echo ✗ Impossible de créer la base de données
    echo Vérifiez que MySQL est démarré et accessible
)

REM Exécuter les migrations
echo Exécution des migrations...
php artisan migrate --force
if %errorlevel% equ 0 (
    echo ✓ Migrations exécutées avec succès
) else (
    echo ⚠ Erreur lors des migrations
    echo Vérifiez la configuration de la base de données dans .env
)

echo.
echo Configuration terminée !
echo.
echo Services recommandés dans Laragon :
echo - Apache ou Nginx : ✓ (requis)
echo - MySQL : ✓ (requis) 
echo - Redis : ⚠ (optionnel mais recommandé)
echo.
echo Prochaines étapes :
echo 1. Configurez le service IA avec setup-ai-service.bat
echo 2. Démarrez le service IA avec start-ai-service.bat
echo 3. Testez l'application avec test-app.bat
echo.
pause
