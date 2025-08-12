@echo off
echo ====================================
echo   Demarrage de Menui Measure
echo ====================================
echo.

:: Verifier que nous sommes dans le bon repertoire
if not exist "laravel-app" (
    echo ERREUR: Ce script doit etre execute depuis le dossier racine de menui-measure
    pause
    exit /b 1
)

:: Verifier Laragon
echo [1/5] Verification de Laragon...
echo Assurez-vous que Laragon est demarre avec Apache et MySQL actifs
echo.
pause

:: Demarrer Redis
echo [2/5] Demarrage de Redis...
if exist "C:\Redis\redis-server.exe" (
    start "Redis Server" /MIN cmd /c "C:\Redis\redis-server.exe"
    echo Redis demarre.
) else if exist "C:\laragon\bin\redis\redis-server.exe" (
    start "Redis Server" /MIN cmd /c "C:\laragon\bin\redis\redis-server.exe"
    echo Redis demarre depuis Laragon.
) else (
    echo ATTENTION: Redis non trouve. Installez Redis ou verifiez le chemin.
)
timeout /t 2 >nul

:: Demarrer le service IA
echo.
echo [3/5] Demarrage du service IA Python...
if exist "ai-service\venv\Scripts\activate.bat" (
    start "Service IA - Menui" cmd /k "cd /d ai-service && venv\Scripts\activate && python -m uvicorn main:app --host 127.0.0.1 --port 8001 --reload"
    echo Service IA demarre sur http://localhost:8001
) else (
    echo ERREUR: Environment virtuel Python non trouve.
    echo Executez d'abord: cd ai-service && python -m venv venv
)
timeout /t 3 >nul

:: Demarrer la queue Laravel
echo.
echo [4/5] Demarrage de la queue Laravel...
start "Queue Laravel - Menui" cmd /k "cd /d laravel-app && php artisan queue:work --tries=3 --timeout=90"
echo Queue Laravel demarree.
timeout /t 2 >nul

:: Demarrer Vite
echo.
echo [5/5] Demarrage de Vite (dev server)...
start "Vite Dev - Menui" cmd /k "cd /d laravel-app && npm run dev"
echo Vite demarre pour le developpement.
timeout /t 3 >nul

:: Afficher les informations
echo.
echo ====================================
echo   Tous les services sont demarres!
echo ====================================
echo.
echo Application Web    : http://menui.test
echo Service IA (API)   : http://localhost:8001
echo Documentation API  : http://localhost:8001/docs
echo PHPMyAdmin        : http://localhost/phpmyadmin
echo.
echo Pour arreter tous les services, executez: stop-all.bat
echo.
pause