@echo off
echo ========================================
echo    DÉPLOIEMENT SERVICE IA SUR VPS
echo ========================================
echo.

REM Configuration
set DOCKER_USERNAME=ghazitounsi
set IMAGE_NAME=menui-ai-service
set VERSION=latest
set VPS_HOST=vps-df0c2336.vps.ovh.net
set VPS_USER=ubuntu
set CONTAINER_NAME=menui-ai-service
set HOST_PORT=8001
set CONTAINER_PORT=8000

echo Configuration :
echo - Image : %DOCKER_USERNAME%/%IMAGE_NAME%:%VERSION%
echo - VPS : %VPS_HOST%
echo - Port : %HOST_PORT% -^> %CONTAINER_PORT%
echo.

REM Vérification SSH
echo [1/5] Test de connexion SSH...
ssh -o ConnectTimeout=5 %VPS_USER%@%VPS_HOST% "echo 'Connexion SSH réussie'"
if errorlevel 1 (
    echo ❌ Erreur : Impossible de se connecter au VPS
    echo Vérifiez :
    echo - Que votre clé SSH est configurée
    echo - Que le VPS est accessible
    echo - Que l'utilisateur %VPS_USER% existe
    pause
    exit /b 1
)
echo ✅ Connexion SSH réussie

REM Installation de Docker sur le VPS si nécessaire
echo.
echo [2/5] Vérification/Installation de Docker sur le VPS...
ssh %VPS_USER%@%VPS_HOST% "
    if ! command -v docker >/dev/null 2>&1; then
        echo 'Installation de Docker...'
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        systemctl start docker
        systemctl enable docker
        usermod -aG docker %VPS_USER%
        echo 'Docker installé avec succès'
    else
        echo 'Docker déjà installé'
    fi
"
if errorlevel 1 (
    echo ❌ Erreur lors de l'installation de Docker
    pause
    exit /b 1
)
echo ✅ Docker disponible sur le VPS

REM Arrêt et suppression du conteneur existant
echo.
echo [3/5] Nettoyage des conteneurs existants...
ssh %VPS_USER%@%VPS_HOST% "
    if docker ps -q -f name=%CONTAINER_NAME% | grep -q .; then
        echo 'Arrêt du conteneur existant...'
        docker stop %CONTAINER_NAME%
    fi
    if docker ps -aq -f name=%CONTAINER_NAME% | grep -q .; then
        echo 'Suppression du conteneur existant...'
        docker rm %CONTAINER_NAME%
    fi
    echo 'Nettoyage terminé'
"
echo ✅ Nettoyage effectué

REM Pull de la nouvelle image
echo.
echo [4/5] Téléchargement de la nouvelle image...
ssh %VPS_USER%@%VPS_HOST% "
    echo 'Téléchargement de l image %DOCKER_USERNAME%/%IMAGE_NAME%:%VERSION%...'
    docker pull %DOCKER_USERNAME%/%IMAGE_NAME%:%VERSION%
"
if errorlevel 1 (
    echo ❌ Erreur lors du téléchargement de l'image
    echo Vérifiez que l'image existe sur Docker Hub
    pause
    exit /b 1
)
echo ✅ Image téléchargée

REM Démarrage du nouveau conteneur
echo.
echo [5/5] Démarrage du service IA...
ssh %VPS_USER%@%VPS_HOST% "
    echo 'Création des volumes pour les uploads...'
    mkdir -p /opt/menui-ai/uploads /opt/menui-ai/processed
    
    echo 'Démarrage du conteneur...'
    docker run -d \
        --name %CONTAINER_NAME% \
        --restart unless-stopped \
        -p %HOST_PORT%:%CONTAINER_PORT% \
        -v /opt/menui-ai/uploads:/app/uploads \
        -v /opt/menui-ai/processed:/app/processed \
        -e APP_ENV=production \
        %DOCKER_USERNAME%/%IMAGE_NAME%:%VERSION%
    
    echo 'Vérification du statut...'
    sleep 5
    if docker ps | grep -q %CONTAINER_NAME%; then
        echo 'Service IA démarré avec succès !'
    else
        echo 'Erreur au démarrage, logs :'
        docker logs %CONTAINER_NAME%
        exit 1
    fi
"
if errorlevel 1 (
    echo ❌ Erreur lors du démarrage du service
    pause
    exit /b 1
)

echo.
echo ========================================
echo         DÉPLOIEMENT RÉUSSI !
echo ========================================
echo.
echo Service IA disponible à :
echo - URL : http://%VPS_HOST%:%HOST_PORT%
echo - Health check : http://%VPS_HOST%:%HOST_PORT%/health
echo - Documentation : http://%VPS_HOST%:%HOST_PORT%/docs
echo.
echo Pour vérifier les logs :
echo ssh %VPS_USER%@%VPS_HOST% "docker logs %CONTAINER_NAME%"
echo.
echo Pour redémarrer le service :
echo ssh %VPS_USER%@%VPS_HOST% "docker restart %CONTAINER_NAME%"
echo.

REM Test de connectivité final
echo Test de connectivité final...
timeout /t 3 >nul
curl -s http://%VPS_HOST%:%HOST_PORT%/health
if errorlevel 1 (
    echo ⚠️  Service déployé mais pas encore accessible (normal, peut prendre quelques secondes)
) else (
    echo ✅ Service accessible et opérationnel !
)

echo.
pause


