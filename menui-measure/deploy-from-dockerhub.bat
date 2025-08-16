@echo off
REM Script Windows de déploiement depuis Docker Hub
setlocal enabledelayedexpansion

REM Configuration - MODIFIEZ CES VALEURS
set DOCKER_USERNAME=ghazitounsi
set IMAGE_NAME=menui-measure
set VERSION=latest
set CONTAINER_NAME=menui-measure
set HTTP_PORT=80
set AI_PORT=8001
set MYSQL_PORT=3306

set FULL_IMAGE_NAME=%DOCKER_USERNAME%/%IMAGE_NAME%:%VERSION%

echo ================================================
echo 🚀 Déploiement de Menui Mesure depuis Docker Hub
echo ================================================

REM Vérification de Docker
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker n'est pas installé
    echo Installez Docker Desktop depuis: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

REM Arrêt et suppression de l'ancien conteneur si existant
echo 🛑 Arrêt de l'ancien conteneur...
docker stop %CONTAINER_NAME% >nul 2>&1
docker rm %CONTAINER_NAME% >nul 2>&1

REM Téléchargement de la dernière image
echo 📥 Téléchargement de l'image depuis Docker Hub...
docker pull %FULL_IMAGE_NAME%
if errorlevel 1 (
    echo ❌ Erreur lors du téléchargement
    pause
    exit /b 1
)

REM Création des volumes persistants
echo 💾 Création des volumes persistants...
docker volume create menui_mysql_data >nul 2>&1
docker volume create menui_storage_data >nul 2>&1
docker volume create menui_redis_data >nul 2>&1

REM Obtention de l'IP publique (optionnel)
for /f %%i in ('curl -s ifconfig.me 2^>nul') do set SERVER_IP=%%i
if "%SERVER_IP%"=="" set SERVER_IP=localhost

REM Démarrage du conteneur
echo 🚀 Démarrage du conteneur...
docker run -d ^
    --name %CONTAINER_NAME% ^
    --restart unless-stopped ^
    -p %HTTP_PORT%:80 ^
    -p %AI_PORT%:8001 ^
    -p 127.0.0.1:%MYSQL_PORT%:3306 ^
    -v menui_mysql_data:/var/lib/mysql ^
    -v menui_storage_data:/var/www/menui/laravel-app/storage ^
    -v menui_redis_data:/var/lib/redis ^
    -e APP_URL=http://%SERVER_IP% ^
    %FULL_IMAGE_NAME%

if errorlevel 1 (
    echo ❌ Erreur lors du démarrage du conteneur
    pause
    exit /b 1
)

REM Attente du démarrage
echo ⏳ Attente du démarrage complet...
timeout /t 60 /nobreak >nul

REM Vérification du statut
echo 🔍 Vérification du statut...
docker ps | findstr %CONTAINER_NAME% >nul
if errorlevel 1 (
    echo ❌ Problème de démarrage du conteneur
    echo 📋 Logs du conteneur:
    docker logs %CONTAINER_NAME%
    pause
    exit /b 1
) else (
    echo ✅ Conteneur en cours d'exécution
)

REM Test de connectivité
echo 🌐 Test de connectivité...

REM Test application web
curl -f http://localhost:%HTTP_PORT%/health >nul 2>&1
if errorlevel 1 (
    echo ⚠️  Application web non accessible localement
) else (
    echo ✅ Application web accessible
)

REM Test service IA
curl -f http://localhost:%AI_PORT%/health >nul 2>&1
if errorlevel 1 (
    echo ⚠️  Service IA non accessible
) else (
    echo ✅ Service IA accessible
)

REM Informations finales
echo.
echo ====================================
echo 🎉 Déploiement terminé avec succès !
echo ====================================
echo.
echo 📱 Application web:
echo    • Local: http://localhost:%HTTP_PORT%
if not "%SERVER_IP%"=="localhost" (
    echo    • Public: http://%SERVER_IP%:%HTTP_PORT%
)
echo.
echo 🤖 Service IA:
echo    • Local: http://localhost:%AI_PORT%
if not "%SERVER_IP%"=="localhost" (
    echo    • Public: http://%SERVER_IP%:%AI_PORT%
    echo    • Documentation: http://%SERVER_IP%:%HTTP_PORT%/ai-docs
)
echo.
echo 💾 Base de données MySQL:
echo    • Host: localhost:%MYSQL_PORT%
echo    • Database: menui_prod
echo    • Username: menui_user
echo    • Password: menui_password_2024!
echo.
echo 🔧 Commandes utiles:
echo    • Voir les logs: docker logs -f %CONTAINER_NAME%
echo    • Redémarrer: docker restart %CONTAINER_NAME%
echo    • Arrêter: docker stop %CONTAINER_NAME%
echo    • Shell dans le conteneur: docker exec -it %CONTAINER_NAME% bash
echo.
echo 📋 Sauvegarde base de données:
echo    docker exec %CONTAINER_NAME% mysqldump -u menui_user -pmenui_password_2024! menui_prod ^> backup.sql
echo.
echo 🔄 Mise à jour:
echo    deploy-from-dockerhub.bat
echo.
pause



