@echo off
echo Redémarrage du service IA...

echo Arrêt du service IA existant...
taskkill /f /im python.exe 2>nul
taskkill /f /im uvicorn.exe 2>nul

echo Attente de 2 secondes...
timeout /t 2 >nul

echo Redémarrage du service IA...
cd /d "C:\laragon\www\Mesure\menui-measure\ai-service"

if exist "venv" (
    echo Activation de l'environnement virtuel...
    call venv\Scripts\activate.bat
) else (
    echo Création de l'environnement virtuel...
    python -m venv venv
    call venv\Scripts\activate.bat
    pip install -r requirements.txt
)

echo Démarrage du service sur le port 8001...
uvicorn main:app --host 0.0.0.0 --port 8001 --reload
