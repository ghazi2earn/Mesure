@echo off
echo ========================================
echo   TEST IMAGES PYTHON OFFICIELLES
echo ========================================
echo.

REM Configuration
set DOCKER_USERNAME=ghazitounsi
set IMAGE_NAME=menui-ai-service
set VERSION=python-official

echo Test des approches basées sur l'image Python officielle
echo Image de base : %DOCKER_USERNAME%/%IMAGE_NAME%:%VERSION%
echo.

REM Vérification de Docker
echo [1/4] Vérification de Docker...
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker non disponible
    pause
    exit /b 1
)
echo ✅ Docker disponible

REM Positionnement
echo.
echo [2/4] Positionnement dans le répertoire AI service...
cd /d "%~dp0ai-service"
if not exist "main.py" (
    echo ❌ Fichier main.py introuvable
    pause
    exit /b 1
)
echo ✅ Répertoire AI service trouvé

echo.
echo [3/4] Tests des différentes approches Python officielles...

REM Test 1: Dockerfile.official
echo.
echo === TEST 1: Dockerfile.official (approche progressive) ===
if exist "Dockerfile.official" (
    echo Construction de l'image avec Dockerfile.official...
    docker build -f Dockerfile.official -t %DOCKER_USERNAME%/%IMAGE_NAME%:official .
    if not errorlevel 1 (
        echo ✅ Build Dockerfile.official réussi
        echo Test de l'image...
        docker run --rm -d --name test-official -p 8010:8000 %DOCKER_USERNAME%/%IMAGE_NAME%:official
        timeout /t 8 >nul
        echo Vérification de la santé du service...
        curl -s http://localhost:8010/health >nul
        if not errorlevel 1 (
            echo ✅ Service opérationnel avec Dockerfile.official
            set OFFICIAL_SUCCESS=1
        ) else (
            echo ⚠️  Service non accessible avec Dockerfile.official
        )
        docker stop test-official >nul 2>&1
    ) else (
        echo ❌ Échec build Dockerfile.official
    )
) else (
    echo Dockerfile.official non trouvé
)

echo.
echo === TEST 2: Dockerfile.python-official (multi-stage) ===
if exist "Dockerfile.python-official" (
    echo Construction avec multi-stage build...
    docker build -f Dockerfile.python-official -t %DOCKER_USERNAME%/%IMAGE_NAME%:multistage .
    if not errorlevel 1 (
        echo ✅ Build multi-stage réussi
        echo Test de l'image...
        docker run --rm -d --name test-multistage -p 8011:8000 %DOCKER_USERNAME%/%IMAGE_NAME%:multistage
        timeout /t 8 >nul
        echo Vérification de la santé du service...
        curl -s http://localhost:8011/health >nul
        if not errorlevel 1 (
            echo ✅ Service opérationnel avec multi-stage
            set MULTISTAGE_SUCCESS=1
        ) else (
            echo ⚠️  Service non accessible avec multi-stage
        )
        docker stop test-multistage >nul 2>&1
    ) else (
        echo ❌ Échec build multi-stage
    )
) else (
    echo Dockerfile.python-official non trouvé
)

echo.
echo [4/4] Comparaison des tailles d'images...
echo.
echo === TAILLES DES IMAGES ===
docker images %DOCKER_USERNAME%/%IMAGE_NAME% --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

echo.
echo ========================================
echo         RÉSULTATS DES TESTS
echo ========================================
echo.

if "%OFFICIAL_SUCCESS%"=="1" (
    echo ✅ Dockerfile.official : SUCCÈS
) else (
    echo ❌ Dockerfile.official : ÉCHEC
)

if "%MULTISTAGE_SUCCESS%"=="1" (
    echo ✅ Dockerfile.python-official : SUCCÈS
) else (
    echo ❌ Dockerfile.python-official : ÉCHEC
)

echo.
if "%OFFICIAL_SUCCESS%"=="1" (
    echo 🎯 RECOMMANDATION : Utilisez Dockerfile.official
    echo    - Plus simple à maintenir
    echo    - Installation progressive
    echo    - Gestion d'erreurs robuste
) else if "%MULTISTAGE_SUCCESS%"=="1" (
    echo 🎯 RECOMMANDATION : Utilisez Dockerfile.python-official
    echo    - Multi-stage pour optimiser la taille
    echo    - Sécurité renforcée
    echo    - Image de production optimisée
) else (
    echo ⚠️  Aucune approche Python officielle n'a fonctionné
    echo    Utilisez test-build-progressive.bat pour d'autres options
)

echo.
echo Pour utiliser l'approche recommandée :
if "%OFFICIAL_SUCCESS%"=="1" (
    echo docker build -f Dockerfile.official -t %DOCKER_USERNAME%/%IMAGE_NAME%:latest .
) else if "%MULTISTAGE_SUCCESS%"=="1" (
    echo docker build -f Dockerfile.python-official -t %DOCKER_USERNAME%/%IMAGE_NAME%:latest .
)

echo.
echo Nettoyage des images de test...
docker rmi %DOCKER_USERNAME%/%IMAGE_NAME%:official >nul 2>&1
docker rmi %DOCKER_USERNAME%/%IMAGE_NAME%:multistage >nul 2>&1

pause
