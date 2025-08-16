@echo off
echo ========================================
echo      BUILD ET PUSH SERVICE IA
echo ========================================
echo.

REM Configuration
set DOCKER_USERNAME=ghazitounsi
set IMAGE_NAME=menui-ai-service
set VERSION=latest
set VPS_HOST=vps-df0c2336.vps.ovh.net

echo Configuration :
echo - Docker Hub : %DOCKER_USERNAME%/%IMAGE_NAME%:%VERSION%
echo - VPS cible : %VPS_HOST%
echo.

REM Vérification de Docker
echo [1/6] Vérification de Docker...
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Erreur : Docker n'est pas installé ou accessible
    pause
    exit /b 1
)

REM Affichage des informations Docker détaillées
echo ✅ Docker est disponible
echo.
echo === INFORMATIONS DOCKER ===
for /f "tokens=*" %%i in ('docker --version') do echo Version Docker : %%i
echo.
echo État de Docker Desktop :
docker info --format "{{.ServerVersion}}" >nul 2>&1
if errorlevel 1 (
    echo ⚠️  Docker Desktop n'est pas démarré ou accessible
    echo Démarrez Docker Desktop et relancez ce script
    pause
    exit /b 1
) else (
    echo ✅ Docker Desktop est en cours d'exécution
)
echo.
echo Conteneurs en cours d'exécution :
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | findstr /V "CONTAINER" | findstr /C:"" >nul && (
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
) || (
    echo Aucun conteneur en cours d'exécution
)
echo.

REM Changement vers le répertoire AI service
echo.
echo [2/6] Positionnement dans le répertoire AI service...
cd /d "%~dp0ai-service"
if not exist "main.py" (
    echo ❌ Erreur : Fichier main.py introuvable
    echo Vérifiez que vous êtes dans le bon répertoire
    pause
    exit /b 1
)
echo ✅ Répertoire AI service trouvé

REM Build de l'image
echo.
echo [3/6] Construction de l'image Docker...
echo Construction en cours... (cela peut prendre quelques minutes)
docker build -t %DOCKER_USERNAME%/%IMAGE_NAME%:%VERSION% .
if errorlevel 1 (
    echo ❌ Erreur lors de la construction de l'image
    pause
    exit /b 1
)
echo ✅ Image construite avec succès

REM Test local rapide
echo.
echo [4/6] Test local rapide...
echo Démarrage du conteneur de test...
docker run --rm -d --name test-ai-service -p 8002:8000 %DOCKER_USERNAME%/%IMAGE_NAME%:%VERSION%
timeout /t 5 >nul
echo Test de connectivité...
curl -s http://localhost:8002/health >nul
if errorlevel 1 (
    echo ⚠️  Avertissement : Test local échoué, mais on continue...
) else (
    echo ✅ Test local réussi
)
docker stop test-ai-service >nul 2>&1
echo Arrêt du conteneur de test

REM Login Docker Hub
echo.
echo [5/6] Connexion à Docker Hub...
echo Veuillez entrer vos identifiants Docker Hub :
docker login
if errorlevel 1 (
    echo ❌ Erreur lors de la connexion à Docker Hub
    pause
    exit /b 1
)
echo ✅ Connexion réussie

REM Push vers Docker Hub
echo.
echo [6/6] Envoi vers Docker Hub...
docker push %DOCKER_USERNAME%/%IMAGE_NAME%:%VERSION%
if errorlevel 1 (
    echo ❌ Erreur lors de l'envoi vers Docker Hub
    pause
    exit /b 1
)
echo ✅ Image envoyée avec succès

echo.
echo ========================================
echo            BUILD TERMINÉ !
echo ========================================
echo.
echo Image disponible : %DOCKER_USERNAME%/%IMAGE_NAME%:%VERSION%
echo.
echo Prochaines étapes :
echo 1. Modifiez votre nom d'utilisateur Docker dans ce script
echo 2. Utilisez deploy-ai-service.bat pour déployer sur le VPS
echo.
pause
