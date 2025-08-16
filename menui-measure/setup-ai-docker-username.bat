@echo off
echo ========================================
echo  CONFIGURATION DOCKER HUB USERNAME
echo ========================================
echo.

echo Ce script va configurer votre nom d'utilisateur Docker Hub
echo dans les scripts de build et déploiement du service IA.
echo.

REM Demander le nom d'utilisateur
set /p docker_username="Entrez votre nom d'utilisateur Docker Hub : "

REM Vérifier que l'utilisateur a entré quelque chose
if "%docker_username%"=="" (
    echo ❌ Erreur : Nom d'utilisateur requis
    pause
    exit /b 1
)

echo.
echo Configuration du nom d'utilisateur : %docker_username%
echo.

REM Mise à jour du script de build
echo [1/2] Mise à jour de build-ai-service.bat...
if exist "build-ai-service.bat" (
    powershell -Command "(Get-Content 'build-ai-service.bat') -replace 'set DOCKER_USERNAME=YOUR_DOCKER_USERNAME', 'set DOCKER_USERNAME=%docker_username%' | Set-Content 'build-ai-service.bat'"
    echo ✅ build-ai-service.bat mis à jour
) else (
    echo ⚠️  build-ai-service.bat non trouvé
)

REM Mise à jour du script de déploiement
echo [2/2] Mise à jour de deploy-ai-service.bat...
if exist "deploy-ai-service.bat" (
    powershell -Command "(Get-Content 'deploy-ai-service.bat') -replace 'set DOCKER_USERNAME=YOUR_DOCKER_USERNAME', 'set DOCKER_USERNAME=%docker_username%' | Set-Content 'deploy-ai-service.bat'"
    echo ✅ deploy-ai-service.bat mis à jour
) else (
    echo ⚠️  deploy-ai-service.bat non trouvé
)

echo.
echo ========================================
echo      CONFIGURATION TERMINÉE !
echo ========================================
echo.
echo Nom d'utilisateur configuré : %docker_username%
echo.
echo Prochaines étapes :
echo 1. Lancez build-ai-service.bat pour construire l'image
echo 2. Lancez deploy-ai-service.bat pour déployer sur le VPS
echo.
pause


