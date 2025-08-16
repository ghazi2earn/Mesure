@echo off
echo ========================================
echo   INSTALLATION SERVICE AI AUTOMATIQUE
echo ========================================
echo.

REM Vérification des droits administrateur
net session >nul 2>&1
if %errorLevel% == 0 (
    echo ✅ Droits administrateur détectés
) else (
    echo ❌ Ce script nécessite des droits administrateur
    echo Faites un clic droit et "Exécuter en tant qu'administrateur"
    pause
    exit /b 1
)

REM Configuration
set SERVICE_NAME=MenuiAIService
set IMAGE_NAME=ghazitounsi/menui-ai-service:latest
set CONTAINER_NAME=menui-ai-service
set PORT=8000

echo Configuration du service :
echo - Nom du service : %SERVICE_NAME%
echo - Image Docker : %IMAGE_NAME%
echo - Port : %PORT%
echo.

REM Vérification de Docker
echo [1/6] Vérification de Docker...
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker n'est pas installé
    pause
    exit /b 1
)
echo ✅ Docker disponible

REM Pull de la dernière image
echo.
echo [2/6] Téléchargement de la dernière image...
docker pull %IMAGE_NAME%
if errorlevel 1 (
    echo ❌ Échec du téléchargement de l'image
    pause
    exit /b 1
)
echo ✅ Image téléchargée

REM Arrêt du service existant s'il existe
echo.
echo [3/6] Arrêt du service existant...
sc query %SERVICE_NAME% >nul 2>&1
if %errorlevel% == 0 (
    echo Service existant détecté, arrêt en cours...
    sc stop %SERVICE_NAME% >nul 2>&1
    timeout /t 5 >nul
    sc delete %SERVICE_NAME% >nul 2>&1
    echo ✅ Ancien service supprimé
) else (
    echo ✅ Aucun service existant
)

REM Arrêt du conteneur existant
docker stop %CONTAINER_NAME% >nul 2>&1
docker rm %CONTAINER_NAME% >nul 2>&1

REM Création du script de démarrage
echo.
echo [4/6] Création du script de service...
set SCRIPT_PATH=%~dp0start-ai-service.bat

echo @echo off > "%SCRIPT_PATH%"
echo echo Démarrage du service Menui AI... >> "%SCRIPT_PATH%"
echo docker stop %CONTAINER_NAME% ^>nul 2^>^&1 >> "%SCRIPT_PATH%"
echo docker rm %CONTAINER_NAME% ^>nul 2^>^&1 >> "%SCRIPT_PATH%"
echo docker run -d ^\ >> "%SCRIPT_PATH%"
echo     --name %CONTAINER_NAME% ^\ >> "%SCRIPT_PATH%"
echo     --restart=unless-stopped ^\ >> "%SCRIPT_PATH%"
echo     -p %PORT%:8000 ^\ >> "%SCRIPT_PATH%"
echo     -v menui-ai-uploads:/app/uploads ^\ >> "%SCRIPT_PATH%"
echo     -v menui-ai-processed:/app/processed ^\ >> "%SCRIPT_PATH%"
echo     %IMAGE_NAME% >> "%SCRIPT_PATH%"
echo if errorlevel 1 exit /b 1 >> "%SCRIPT_PATH%"
echo echo Service Menui AI démarré avec succès >> "%SCRIPT_PATH%"

echo ✅ Script de service créé

REM Création du service Windows
echo.
echo [5/6] Installation du service Windows...
sc create %SERVICE_NAME% ^
    binPath= "cmd /c \"%SCRIPT_PATH%\"" ^
    start= auto ^
    DisplayName= "Menui AI Service - Service IA de mesure d'images"

if errorlevel 1 (
    echo ❌ Échec de création du service
    pause
    exit /b 1
)

REM Configuration du service
sc description %SERVICE_NAME% "Service automatique pour l'API IA de mesure d'images Menui. Démarre automatiquement le conteneur Docker au boot système."
sc config %SERVICE_NAME% start= auto

echo ✅ Service Windows installé

REM Démarrage du service
echo.
echo [6/6] Démarrage du service...
sc start %SERVICE_NAME%
if errorlevel 1 (
    echo ⚠️  Échec du démarrage automatique, démarrage manuel...
    call "%SCRIPT_PATH%"
    if errorlevel 1 (
        echo ❌ Échec du démarrage manuel
        pause
        exit /b 1
    )
)

REM Test du service
echo.
echo Test du service...
timeout /t 10 >nul
curl -s http://localhost:%PORT%/health >nul
if errorlevel 1 (
    echo ⚠️  Service non accessible immédiatement (normal au premier démarrage)
    echo Attendez quelques minutes puis testez : http://localhost:%PORT%/health
) else (
    echo ✅ Service accessible et fonctionnel !
)

echo.
echo ========================================
echo     SERVICE AI INSTALLÉ AVEC SUCCÈS !
echo ========================================
echo.
echo 🎯 Service installé : %SERVICE_NAME%
echo 🌐 URL du service : http://localhost:%PORT%
echo 🔧 Gestion du service :
echo    - Démarrer : sc start %SERVICE_NAME%
echo    - Arrêter  : sc stop %SERVICE_NAME%
echo    - Statut   : sc query %SERVICE_NAME%
echo.
echo ✅ Le service démarrera automatiquement au boot du système
echo.
echo Pour désinstaller :
echo    sc stop %SERVICE_NAME% ^&^& sc delete %SERVICE_NAME%
echo.
pause
