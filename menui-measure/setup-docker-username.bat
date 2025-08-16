@echo off
echo =============================================
echo 🔧 Configuration du nom d'utilisateur Docker Hub
echo =============================================
echo.

REM Demander le nom d'utilisateur
set /p DOCKER_USER="Entrez votre nom d'utilisateur Docker Hub: "

if "%DOCKER_USER%"=="" (
    echo ❌ Nom d'utilisateur requis
    pause
    exit /b 1
)

echo.
echo 📝 Mise à jour des scripts avec le nom d'utilisateur: %DOCKER_USER%

REM Mise à jour du script de build
powershell -Command "(Get-Content 'build-and-push.bat') -replace 'set DOCKER_USERNAME=votre-username', 'set DOCKER_USERNAME=%DOCKER_USER%' | Set-Content 'build-and-push.bat'"

REM Mise à jour du script de déploiement  
powershell -Command "(Get-Content 'deploy-from-dockerhub.bat') -replace 'set DOCKER_USERNAME=votre-username', 'set DOCKER_USERNAME=%DOCKER_USER%' | Set-Content 'deploy-from-dockerhub.bat'"

echo ✅ Scripts mis à jour avec succès !
echo.
echo 📋 Prochaines étapes:
echo    1. Construire l'image: build-and-push.bat
echo    2. Déployer sur serveur: deploy-from-dockerhub.bat
echo.
pause



