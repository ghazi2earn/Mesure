@echo off
echo ====================================
echo   Configuration initiale pour Laragon
echo ====================================
echo.

:: Verifier que nous sommes dans le bon repertoire
if not exist "laravel-app" (
    echo ERREUR: Ce script doit etre execute depuis le dossier racine de menui-measure
    echo Placez le projet dans C:\laragon\www\menui-measure
    pause
    exit /b 1
)

echo Ce script va configurer Menui Measure pour Laragon.
echo Assurez-vous que Laragon est installe et demarre.
echo.
pause

:: 1. Configuration Laravel
echo.
echo [1/6] Configuration de Laravel...
cd laravel-app

if not exist ".env" (
    echo Creation du fichier .env...
    copy .env.example .env >nul
    echo Fichier .env cree.
) else (
    echo Fichier .env existe deja.
)

:: 2. Installation des dependances PHP
echo.
echo [2/6] Installation des dependances PHP avec Composer...
call composer install
if %errorlevel% neq 0 (
    echo ERREUR: Composer a echoue. Verifiez que Composer est installe.
    pause
    exit /b 1
)

:: 3. Generation de la cle d'application
echo.
echo [3/6] Generation de la cle d'application...
php artisan key:generate

:: 4. Installation des dependances JavaScript
echo.
echo [4/6] Installation des dependances JavaScript...
call npm install
if %errorlevel% neq 0 (
    echo ERREUR: npm a echoue. Verifiez que Node.js est installe.
    pause
    exit /b 1
)

:: 5. Build des assets
echo.
echo [5/6] Compilation des assets...
call npm run build

:: 6. Configuration Python
echo.
echo [6/6] Configuration du service IA Python...
cd ..\ai-service

if not exist "venv" (
    echo Creation de l'environnement virtuel Python...
    python -m venv venv
    if %errorlevel% neq 0 (
        echo ERREUR: Python n'est pas installe ou pas dans le PATH.
        echo Installez Python 3.11 depuis python.org
        pause
        exit /b 1
    )
)

echo Installation des dependances Python...
call venv\Scripts\activate.bat && pip install -r requirements.txt

:: Creation des dossiers necessaires
echo.
echo Creation des dossiers necessaires...
cd ..
mkdir laravel-app\storage\logs 2>nul
mkdir laravel-app\storage\app\public 2>nul
mkdir ai-service\uploads 2>nul
mkdir ai-service\processed 2>nul

:: Instructions finales
echo.
echo ====================================
echo   Configuration terminee!
echo ====================================
echo.
echo Prochaines etapes:
echo.
echo 1. Creez la base de donnees 'menui' dans HeidiSQL
echo.
echo 2. Executez les migrations:
echo    cd laravel-app
echo    php artisan migrate
echo.
echo 3. Creez le lien symbolique pour le storage:
echo    php artisan storage:link
echo.
echo 4. Configurez le virtual host dans Laragon:
echo    - Clic droit sur Laragon
echo    - Menu "Apache" > "sites-enabled"
echo    - Creez menui.test.conf
echo.
echo 5. Ajoutez dans C:\Windows\System32\drivers\etc\hosts:
echo    127.0.0.1 menui.test
echo.
echo 6. Demarrez l'application avec: start-all.bat
echo.
pause