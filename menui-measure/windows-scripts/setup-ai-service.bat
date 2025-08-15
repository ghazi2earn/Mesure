@echo off
echo Configuration du service IA pour le traitement des images...

cd /d "C:\laragon\www\Mesure\menui-measure\laravel-app"

echo.
echo Choix du mode de fonctionnement :
echo 1. Mode développement local (avec service IA réel sur port 8001)
echo 2. Mode simulation (sans service IA)
echo 3. Mode Docker (service IA sur réseau interne)
echo.
set /p choice="Entrez votre choix (1-3): "

if "%choice%"=="1" goto dev_mode
if "%choice%"=="2" goto simulation_mode
if "%choice%"=="3" goto docker_mode
goto invalid_choice

:dev_mode
echo.
echo Configuration en mode développement...
echo AI_SERVICE_URL=http://127.0.0.1:8001 >> .env
echo AI_SERVICE_TIMEOUT=60 >> .env
echo.
echo Configuration terminée !
echo Le service IA est configuré pour fonctionner sur http://127.0.0.1:8001
echo Assurez-vous que le service IA est démarré avec Docker ou Python.
goto end

:simulation_mode
echo.
echo Configuration en mode simulation...
echo AI_SERVICE_URL=http://localhost:8000 >> .env
echo AI_SERVICE_TIMEOUT=60 >> .env
echo.
echo Configuration terminée !
echo Le service IA est configuré en mode simulation.
echo Les photos seront marquées comme traitées sans appel réel au service IA.
goto end

:docker_mode
echo.
echo Configuration en mode Docker...
echo AI_SERVICE_URL=http://ai-service:8000 >> .env
echo AI_SERVICE_TIMEOUT=60 >> .env
echo.
echo Configuration terminée !
echo Le service IA est configuré pour Docker Compose.
goto end

:invalid_choice
echo Choix invalide. Veuillez relancer le script.

:end
pause

