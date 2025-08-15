@echo off
echo Démarrage du service IA...

echo.
echo Choix du mode de démarrage :
echo 1. Docker Compose (recommandé pour le développement)
echo 2. Python directement (nécessite Python 3.11+)
echo 3. Service IA seul avec Docker
echo.
set /p choice="Entrez votre choix (1-3): "

if "%choice%"=="1" goto docker_compose
if "%choice%"=="2" goto python_direct
if "%choice%"=="3" goto docker_ai_only
goto invalid_choice

:docker_compose
echo.
echo Démarrage avec Docker Compose...
cd /d "C:\laragon\www\Mesure\menui-measure"
echo Démarrage de tous les services (Laravel, IA, DB, Redis)...
docker-compose up -d
echo.
echo Services démarrés !
echo - Application Laravel : http://localhost:8000
echo - Service IA : http://localhost:8001
echo - API IA documentation : http://localhost:8001/docs
goto end

:python_direct
echo.
echo Démarrage avec Python...
cd /d "C:\laragon\www\Mesure\menui-measure\ai-service"

REM Vérifier si les dépendances sont installées
if not exist "venv" (
    echo Création de l'environnement virtuel...
    python -m venv venv
)

echo Activation de l'environnement virtuel...
call venv\Scripts\activate.bat

echo Installation/mise à jour des dépendances...
pip install -r requirements.txt

echo Démarrage du service IA sur le port 8001...
uvicorn main:app --host 0.0.0.0 --port 8001 --reload
goto end

:docker_ai_only
echo.
echo Démarrage du service IA seul avec Docker...
cd /d "C:\laragon\www\Mesure\menui-measure"
docker-compose up -d ai-service
echo.
echo Service IA démarré !
echo - Service IA : http://localhost:8001
echo - API IA documentation : http://localhost:8001/docs
goto end

:invalid_choice
echo Choix invalide. Veuillez relancer le script.

:end
echo.
echo Pour arrêter les services :
echo - Docker : docker-compose down
echo - Python : Ctrl+C dans cette fenêtre
pause
