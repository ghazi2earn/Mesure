@echo off
echo ========================================
echo   BUILD ET PUSH SERVICE IA (ROBUSTE)
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
echo [1/7] Vérification de Docker...
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

REM Changement vers le répertoire AI service
echo.
echo [2/7] Positionnement dans le répertoire AI service...
cd /d "%~dp0ai-service"
if not exist "main.py" (
    echo ❌ Erreur : Fichier main.py introuvable
    echo Vérifiez que vous êtes dans le bon répertoire
    pause
    exit /b 1
)
echo ✅ Répertoire AI service trouvé

REM Nettoyage des images précédentes (optionnel)
echo.
echo [3/7] Nettoyage des images Docker précédentes...
docker image prune -f >nul 2>&1
echo ✅ Nettoyage effectué

REM Test du Dockerfile robuste d'abord
echo.
echo [4/7] Test avec le Dockerfile robuste...
if exist "Dockerfile.robust" (
    echo Construction avec Dockerfile.robust...
    docker build -f Dockerfile.robust -t %DOCKER_USERNAME%/%IMAGE_NAME%:robust-test .
    if errorlevel 1 (
        echo ⚠️  Échec avec Dockerfile.robust, tentative avec Dockerfile standard...
        goto standard_build
    ) else (
        echo ✅ Construction réussie avec Dockerfile.robust
        echo Utilisation du Dockerfile robuste pour la version finale...
        docker tag %DOCKER_USERNAME%/%IMAGE_NAME%:robust-test %DOCKER_USERNAME%/%IMAGE_NAME%:%VERSION%
        goto test_local
    )
) else (
    echo Dockerfile.robust non trouvé, utilisation du Dockerfile standard...
    goto standard_build
)

:standard_build
echo.
echo [4/7] Construction avec le Dockerfile standard...
docker build -t %DOCKER_USERNAME%/%IMAGE_NAME%:%VERSION% .
if errorlevel 1 (
    echo ❌ Erreur lors de la construction de l'image
    echo.
    echo === CONSEILS DE DÉPANNAGE ===
    echo 1. Vérifiez votre connexion Internet
    echo 2. Redémarrez Docker Desktop
    echo 3. Supprimez le cache Docker : docker system prune -a
    echo 4. Vérifiez l'espace disque disponible
    pause
    exit /b 1
)
echo ✅ Image construite avec succès

:test_local
REM Test local rapide
echo.
echo [5/7] Test local rapide...
echo Démarrage du conteneur de test...
docker run --rm -d --name test-ai-service -p 8002:8000 %DOCKER_USERNAME%/%IMAGE_NAME%:%VERSION%
if errorlevel 1 (
    echo ❌ Erreur lors du démarrage du conteneur de test
    goto cleanup_and_continue
)

timeout /t 10 >nul
echo Test de connectivité...

REM Test simple de ping au conteneur
docker exec test-ai-service curl -s http://localhost:8000/health >nul 2>&1
if errorlevel 1 (
    echo ⚠️  Test via exec échoué, test externe...
    curl -s http://localhost:8002/health >nul 2>&1
    if errorlevel 1 (
        echo ⚠️  Avertissement : Tests locaux échoués, mais on continue...
    ) else (
        echo ✅ Test externe réussi
    )
) else (
    echo ✅ Test local réussi
)

:cleanup_and_continue
docker stop test-ai-service >nul 2>&1
echo Arrêt du conteneur de test

REM Login Docker Hub
echo.
echo [6/7] Connexion à Docker Hub...
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
echo [7/7] Envoi vers Docker Hub...
docker push %DOCKER_USERNAME%/%IMAGE_NAME%:%VERSION%
if errorlevel 1 (
    echo ❌ Erreur lors de l'envoi vers Docker Hub
    pause
    exit /b 1
)
echo ✅ Image envoyée avec succès

echo.
echo ========================================
echo         BUILD ROBUSTE TERMINÉ !
echo ========================================
echo.
echo Image disponible : %DOCKER_USERNAME%/%IMAGE_NAME%:%VERSION%
echo.
echo Prochaines étapes :
echo 1. Utilisez deploy-ai-service.bat pour déployer sur le VPS
echo 2. Testez l'API avec test-ai-service-remote.bat
echo.
pause
