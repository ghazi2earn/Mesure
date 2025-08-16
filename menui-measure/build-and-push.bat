
@echo off
REM Script Windows pour construire et publier l'image sur Docker Hub
setlocal enabledelayedexpansion

REM Configuration - MODIFIEZ CETTE VALEUR
set DOCKER_USERNAME=ghazitounsi
set IMAGE_NAME=menui-measure
set VERSION=latest
set FULL_IMAGE_NAME=%DOCKER_USERNAME%/%IMAGE_NAME%:%VERSION%

echo ==============================================
echo 🐳 Construction et publication de l'image Docker
echo ==============================================

REM Vérification de Docker
docker info >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker n'est pas en cours d'exécution
    echo Assurez-vous que Docker Desktop est démarré
    pause
    exit /b 1
)

REM Construction de l'image
echo 🔨 Construction de l'image Docker...
docker build -f Dockerfile.monolith -t %FULL_IMAGE_NAME% .
if errorlevel 1 (
    echo ❌ Erreur lors de la construction
    pause
    exit /b 1
)

REM Test local de l'image
echo 🧪 Test local de l'image...
docker run --rm -d --name menui-test -p 8080:80 %FULL_IMAGE_NAME%
timeout /t 30 /nobreak >nul

REM Test de santé
curl -f http://localhost:8080/health >nul 2>&1
if errorlevel 1 (
    echo ❌ Test local échoué
    docker stop menui-test >nul 2>&1
    pause
    exit /b 1
) else (
    echo ✅ Test local réussi
    docker stop menui-test >nul 2>&1
)

REM Connexion à Docker Hub
echo 🔐 Connexion à Docker Hub...
echo Entrez votre mot de passe Docker Hub:
docker login -u %DOCKER_USERNAME%
if errorlevel 1 (
    echo ❌ Erreur de connexion à Docker Hub
    pause
    exit /b 1
)

REM Publication de l'image
echo 📤 Publication de l'image sur Docker Hub...
docker push %FULL_IMAGE_NAME%
if errorlevel 1 (
    echo ❌ Erreur lors de la publication
    pause
    exit /b 1
)

REM Nettoyage
echo 🧹 Nettoyage...
docker image prune -f >nul 2>&1

echo.
echo ===============================
echo 🎉 Image publiée avec succès !
echo ===============================
echo 📦 Image: %FULL_IMAGE_NAME%
echo 🌐 URL Docker Hub: https://hub.docker.com/r/%DOCKER_USERNAME%/%IMAGE_NAME%
echo.
echo 📋 Pour déployer sur votre serveur:
echo    docker run -d --name menui-measure -p 80:80 -p 8001:8001 %FULL_IMAGE_NAME%
echo.
echo 📋 Avec volumes persistants:
echo    docker run -d --name menui-measure ^
echo      -p 80:80 -p 8001:8001 ^
echo      -v menui_mysql:/var/lib/mysql ^
echo      -v menui_storage:/var/www/menui/laravel-app/storage ^
echo      %FULL_IMAGE_NAME%
echo.
pause



