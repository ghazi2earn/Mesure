@echo off
echo ========================================
echo  BUILD SERVICE IA - IMAGE PYTHON OFFICIELLE
echo ========================================
echo.

REM Configuration
set DOCKER_USERNAME=ghazitounsi
set IMAGE_NAME=menui-ai-service
set VERSION=latest
set VPS_HOST=vps-df0c2336.vps.ovh.net

echo Configuration :
echo - Docker Hub : %DOCKER_USERNAME%/%IMAGE_NAME%:%VERSION%
echo - Base : Image Python 3.11 officielle
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

echo ✅ Docker est disponible
echo.

REM Vérification de Docker Desktop
echo [2/7] Vérification de Docker Desktop...
docker info --format "{{.ServerVersion}}" >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker Desktop n'est pas démarré
    echo Démarrez Docker Desktop et relancez ce script
    pause
    exit /b 1
) else (
    echo ✅ Docker Desktop en cours d'exécution
)
echo.

REM Positionnement dans le répertoire
echo [3/7] Positionnement dans le répertoire AI service...
cd /d "%~dp0ai-service"
if not exist "main.py" (
    echo ❌ Erreur : Fichier main.py introuvable
    pause
    exit /b 1
)
echo ✅ Répertoire AI service trouvé

REM Choix automatique du meilleur Dockerfile
echo.
echo [4/7] Sélection du Dockerfile optimal...
set DOCKERFILE_TO_USE=Dockerfile
set DOCKERFILE_NAME=standard

REM Priorité 1: Dockerfile.python-official (multi-stage)
if exist "Dockerfile.python-official" (
    if exist "requirements-official.txt" (
        set DOCKERFILE_TO_USE=Dockerfile.python-official
        set DOCKERFILE_NAME=python-official ^(multi-stage^)
        echo ✅ Utilisation de Dockerfile.python-official ^(multi-stage^)
        goto build_image
    )
)

REM Priorité 2: Dockerfile.official (progressif)
if exist "Dockerfile.official" (
    set DOCKERFILE_TO_USE=Dockerfile.official
    set DOCKERFILE_NAME=python-official ^(progressif^)
    echo ✅ Utilisation de Dockerfile.official ^(progressif^)
    goto build_image
)

REM Fallback: Dockerfile standard
echo ✅ Utilisation du Dockerfile standard ^(corrigé^)

:build_image
REM Construction de l'image
echo.
echo [5/7] Construction de l'image Docker...
echo Dockerfile utilisé : %DOCKERFILE_NAME%
echo Construction en cours... ^(cela peut prendre quelques minutes^)

if "%DOCKERFILE_TO_USE%"=="Dockerfile" (
    docker build -t %DOCKER_USERNAME%/%IMAGE_NAME%:%VERSION% .
) else (
    docker build -f %DOCKERFILE_TO_USE% -t %DOCKER_USERNAME%/%IMAGE_NAME%:%VERSION% .
)

if errorlevel 1 (
    echo ❌ Erreur lors de la construction avec %DOCKERFILE_NAME%
    echo.
    echo Tentative avec une approche alternative...
    
    REM Fallback vers Dockerfile standard si disponible
    if not "%DOCKERFILE_TO_USE%"=="Dockerfile" (
        echo Essai avec Dockerfile standard...
        docker build -t %DOCKER_USERNAME%/%IMAGE_NAME%:%VERSION% .
        if errorlevel 1 (
            echo ❌ Échec également avec Dockerfile standard
            echo.
            echo === CONSEILS DE DÉPANNAGE ===
            echo 1. Exécutez diagnose-docker.bat
            echo 2. Essayez test-python-official.bat
            echo 3. Vérifiez votre connexion Internet
            pause
            exit /b 1
        ) else (
            echo ✅ Construction réussie avec Dockerfile standard
        )
    ) else (
        echo ❌ Échec de construction
        pause
        exit /b 1
    )
) else (
    echo ✅ Image construite avec succès avec %DOCKERFILE_NAME%
)

REM Test local rapide
echo.
echo [6/7] Test local rapide...
echo Démarrage du conteneur de test...
docker run --rm -d --name test-ai-service -p 8020:8000 %DOCKER_USERNAME%/%IMAGE_NAME%:%VERSION%
if errorlevel 1 (
    echo ❌ Erreur lors du démarrage du conteneur
    goto push_anyway
)

timeout /t 10 >nul
echo Test de connectivité...

REM Test de santé du service
docker exec test-ai-service curl -s http://localhost:8000/health >nul 2>&1
if errorlevel 1 (
    echo Test interne échoué, test externe...
    curl -s http://localhost:8020/health >nul 2>&1
    if errorlevel 1 (
        echo ⚠️  Tests locaux échoués, mais on continue...
    ) else (
        echo ✅ Test externe réussi
    )
) else (
    echo ✅ Tests internes et service opérationnel
)

docker stop test-ai-service >nul 2>&1
echo Arrêt du conteneur de test

:push_anyway
REM Push vers Docker Hub
echo.
echo [7/7] Publication sur Docker Hub...
echo Connexion à Docker Hub...
docker login
if errorlevel 1 (
    echo ❌ Erreur lors de la connexion à Docker Hub
    pause
    exit /b 1
)

echo Publication de l'image...
docker push %DOCKER_USERNAME%/%IMAGE_NAME%:%VERSION%
if errorlevel 1 (
    echo ❌ Erreur lors de la publication
    pause
    exit /b 1
)

echo.
echo ========================================
echo    BUILD PYTHON OFFICIEL TERMINÉ !
echo ========================================
echo.
echo ✅ Image publiée : %DOCKER_USERNAME%/%IMAGE_NAME%:%VERSION%
echo 🐍 Base utilisée : Python 3.11 officielle
echo 📦 Dockerfile : %DOCKERFILE_NAME%
echo.
echo Prochaines étapes :
echo 1. Déployez avec : deploy-ai-service.bat
echo 2. Testez avec : test-ai-service-remote.bat
echo.
echo Avantages de l'image Python officielle :
echo - Stabilité et fiabilité garanties
echo - Mises à jour de sécurité régulières  
echo - Optimisations officielles
echo - Compatibilité maximale
echo.
pause
