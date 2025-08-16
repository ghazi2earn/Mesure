@echo off
echo ========================================
echo    TEST BUILD PROGRESSIF SERVICE IA
echo ========================================
echo.

REM Configuration
set DOCKER_USERNAME=ghazitounsi
set IMAGE_NAME=menui-ai-service
set VERSION=test

echo Configuration de test :
echo - Image : %DOCKER_USERNAME%/%IMAGE_NAME%:%VERSION%
echo.

REM Vérification de Docker
echo [1/5] Vérification de Docker...
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Erreur : Docker n'est pas installé ou accessible
    pause
    exit /b 1
)
echo ✅ Docker disponible

REM Changement vers le répertoire AI service
echo.
echo [2/5] Positionnement dans le répertoire AI service...
cd /d "%~dp0ai-service"
if not exist "main.py" (
    echo ❌ Erreur : Fichier main.py introuvable
    pause
    exit /b 1
)
echo ✅ Répertoire AI service trouvé

echo.
echo [3/5] Test avec approche minimale...
echo === TENTATIVE 1 : Dockerfile minimal ===
if exist "Dockerfile.minimal" (
    docker build -f Dockerfile.minimal -t %DOCKER_USERNAME%/%IMAGE_NAME%:minimal .
    if not errorlevel 1 (
        echo ✅ Build minimal réussi !
        echo Test de démarrage...
        docker run --rm -d --name test-minimal -p 8003:8000 %DOCKER_USERNAME%/%IMAGE_NAME%:minimal
        timeout /t 5 >nul
        curl -s http://localhost:8003/health >nul
        if not errorlevel 1 (
            echo ✅ Test minimal complet réussi !
            docker stop test-minimal >nul 2>&1
            echo.
            echo === SUCCÈS AVEC APPROCHE MINIMALE ===
            echo Vous pouvez utiliser Dockerfile.minimal pour votre build
            goto success
        )
        docker stop test-minimal >nul 2>&1
    )
    echo ⚠️  Approche minimale échouée
) else (
    echo Dockerfile.minimal non trouvé
)

echo.
echo [4/5] Test avec approche robuste...
echo === TENTATIVE 2 : Dockerfile robuste ===
if exist "Dockerfile.robust" (
    docker build -f Dockerfile.robust -t %DOCKER_USERNAME%/%IMAGE_NAME%:robust .
    if not errorlevel 1 (
        echo ✅ Build robuste réussi !
        echo Test de démarrage...
        docker run --rm -d --name test-robust -p 8004:8000 %DOCKER_USERNAME%/%IMAGE_NAME%:robust
        timeout /t 5 >nul
        curl -s http://localhost:8004/health >nul
        if not errorlevel 1 (
            echo ✅ Test robuste complet réussi !
            docker stop test-robust >nul 2>&1
            echo.
            echo === SUCCÈS AVEC APPROCHE ROBUSTE ===
            echo Vous pouvez utiliser Dockerfile.robust pour votre build
            goto success
        )
        docker stop test-robust >nul 2>&1
    )
    echo ⚠️  Approche robuste échouée
) else (
    echo Dockerfile.robust non trouvé
)

echo.
echo [5/5] Test avec Dockerfile standard (corrigé)...
echo === TENTATIVE 3 : Dockerfile standard ===
docker build -t %DOCKER_USERNAME%/%IMAGE_NAME%:standard .
if not errorlevel 1 (
    echo ✅ Build standard réussi !
    echo Test de démarrage...
    docker run --rm -d --name test-standard -p 8005:8000 %DOCKER_USERNAME%/%IMAGE_NAME%:standard
    timeout /t 5 >nul
    curl -s http://localhost:8005/health >nul
    if not errorlevel 1 (
        echo ✅ Test standard complet réussi !
        docker stop test-standard >nul 2>&1
        echo.
        echo === SUCCÈS AVEC DOCKERFILE STANDARD CORRIGÉ ===
        echo Votre Dockerfile original fonctionne maintenant
        goto success
    )
    docker stop test-standard >nul 2>&1
)
echo ❌ Toutes les approches ont échoué

echo.
echo ========================================
echo      TOUS LES TESTS ONT ÉCHOUÉ
echo ========================================
echo.
echo Recommandations :
echo 1. Exécutez diagnose-docker.bat pour identifier les problèmes
echo 2. Vérifiez votre connexion Internet
echo 3. Redémarrez Docker Desktop
echo 4. Supprimez le cache : docker system prune -a
echo.
goto end

:success
echo.
echo ========================================
echo         TEST PROGRESSIF RÉUSSI !
echo ========================================
echo.
echo Une des approches a fonctionné.
echo Vous pouvez maintenant utiliser le build correspondant.
echo.

:end
REM Nettoyage des images de test
docker rmi %DOCKER_USERNAME%/%IMAGE_NAME%:minimal >nul 2>&1
docker rmi %DOCKER_USERNAME%/%IMAGE_NAME%:robust >nul 2>&1
docker rmi %DOCKER_USERNAME%/%IMAGE_NAME%:standard >nul 2>&1

pause
