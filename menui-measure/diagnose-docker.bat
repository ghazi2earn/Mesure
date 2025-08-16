@echo off
echo ========================================
echo      DIAGNOSTIC DOCKER COMPLET
echo ========================================
echo.

echo [1/8] Vérification de l'installation Docker...
docker --version
if errorlevel 1 (
    echo ❌ Docker n'est pas installé ou pas dans le PATH
    goto end
) else (
    echo ✅ Docker est installé
)
echo.

echo [2/8] Informations détaillées Docker...
docker info
if errorlevel 1 (
    echo ❌ Docker daemon non accessible
    goto end
) else (
    echo ✅ Docker daemon accessible
)
echo.

echo [3/8] Espace disque disponible...
docker system df
echo.

echo [4/8] État de la mémoire...
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
echo.

echo [5/8] Images Docker présentes...
docker images
echo.

echo [6/8] Conteneurs en cours...
docker ps -a
echo.

echo [7/8] Test de pull d'une image simple...
echo Test de connectivité avec Docker Hub...
docker pull hello-world:latest
if errorlevel 1 (
    echo ❌ Problème de connectivité ou de permissions Docker Hub
) else (
    echo ✅ Connectivité Docker Hub OK
    docker run --rm hello-world
)
echo.

echo [8/8] Test de build simple...
echo Creation d'un Dockerfile de test...
cd /d "%~dp0"
echo FROM alpine:latest > Dockerfile.test
echo RUN echo "Test build OK" >> Dockerfile.test
echo CMD echo "Test run OK" >> Dockerfile.test

docker build -f Dockerfile.test -t test-diagnostic .
if errorlevel 1 (
    echo ❌ Problème de build Docker
) else (
    echo ✅ Build Docker OK
    docker run --rm test-diagnostic
)

REM Nettoyage
del Dockerfile.test >nul 2>&1
docker rmi test-diagnostic >nul 2>&1
docker rmi hello-world:latest >nul 2>&1

:end
echo.
echo ========================================
echo        DIAGNOSTIC TERMINÉ
echo ========================================
echo.
echo Si vous voyez des erreurs :
echo 1. Redémarrez Docker Desktop
echo 2. Vérifiez les permissions administrateur
echo 3. Libérez de l'espace disque si nécessaire
echo 4. Vérifiez votre connexion Internet
echo.
pause
