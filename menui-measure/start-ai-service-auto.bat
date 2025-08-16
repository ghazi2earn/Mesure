@echo off
echo ========================================
echo    DÉMARRAGE SERVICE AI AUTOMATIQUE
echo ========================================
echo.

REM Configuration
set COMPOSE_FILE=docker-compose-ai-service.yml
set SERVICE_URL=http://localhost:8000

echo Configuration :
echo - Fichier compose : %COMPOSE_FILE%
echo - URL du service : %SERVICE_URL%
echo.

REM Vérification des prérequis
echo [1/4] Vérification des prérequis...
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker n'est pas installé
    pause
    exit /b 1
)

docker-compose --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker Compose n'est pas installé
    pause
    exit /b 1
)

if not exist "%COMPOSE_FILE%" (
    echo ❌ Fichier %COMPOSE_FILE% introuvable
    pause
    exit /b 1
)

echo ✅ Prérequis vérifiés

REM Arrêt des services existants
echo.
echo [2/4] Arrêt des services existants...
docker-compose -f %COMPOSE_FILE% down >nul 2>&1
docker stop menui-ai-service >nul 2>&1
docker rm menui-ai-service >nul 2>&1
echo ✅ Services nettoyés

REM Pull de la dernière image
echo.
echo [3/4] Mise à jour de l'image...
docker pull ghazitounsi/menui-ai-service:latest
if errorlevel 1 (
    echo ⚠️  Échec du pull, utilisation de l'image locale
)
echo ✅ Image à jour

REM Démarrage avec Docker Compose
echo.
echo [4/4] Démarrage du service...
docker-compose -f %COMPOSE_FILE% up -d
if errorlevel 1 (
    echo ❌ Échec du démarrage
    pause
    exit /b 1
)

echo ✅ Service démarré en arrière-plan

REM Attente et test
echo.
echo Attente du démarrage complet...
timeout /t 15 >nul

echo Test de santé du service...
for /L %%i in (1,1,5) do (
    curl -s %SERVICE_URL%/health >nul 2>&1
    if not errorlevel 1 (
        echo ✅ Service opérationnel !
        goto service_ok
    )
    echo Tentative %%i/5 - Attente...
    timeout /t 10 >nul
)

echo ⚠️  Service non accessible après 5 tentatives
echo Vérification des logs...
docker-compose -f %COMPOSE_FILE% logs --tail=20 menui-ai-service
goto end

:service_ok
echo.
echo ========================================
echo      SERVICE AI DÉMARRÉ AVEC SUCCÈS !
echo ========================================
echo.
echo 🎯 Service Menui AI opérationnel
echo 🌐 URL : %SERVICE_URL%
echo 📊 Santé : %SERVICE_URL%/health
echo 📖 API : %SERVICE_URL%/
echo.
echo 🔧 Commandes utiles :
echo   - Statut : docker-compose -f %COMPOSE_FILE% ps
echo   - Logs : docker-compose -f %COMPOSE_FILE% logs -f
echo   - Arrêt : docker-compose -f %COMPOSE_FILE% down
echo   - Redémarrage : docker-compose -f %COMPOSE_FILE% restart
echo.
echo ✅ RESTART AUTOMATIQUE ACTIVÉ
echo   Le service redémarrera automatiquement :
echo   - En cas de crash
echo   - Après un reboot de la machine
echo   - Si Docker redémarre
echo.

:end
pause
