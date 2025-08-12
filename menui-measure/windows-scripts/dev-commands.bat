@echo off
setlocal enabledelayedexpansion

:: Verifier que nous sommes dans le bon repertoire
if not exist "laravel-app" (
    echo ERREUR: Ce script doit etre execute depuis le dossier racine de menui-measure
    pause
    exit /b 1
)

if "%1"=="" goto :show_help

if /i "%1"=="migrate" (
    echo Execution des migrations...
    cd laravel-app && php artisan migrate
    goto :end
)

if /i "%1"=="fresh" (
    echo Reinitialisation de la base de donnees...
    cd laravel-app && php artisan migrate:fresh --seed
    goto :end
)

if /i "%1"=="cache" (
    echo Vidage des caches...
    cd laravel-app
    php artisan cache:clear
    php artisan config:clear
    php artisan route:clear
    php artisan view:clear
    echo Caches vides.
    goto :end
)

if /i "%1"=="optimize" (
    echo Optimisation pour la production...
    cd laravel-app
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
    echo Optimisation terminee.
    goto :end
)

if /i "%1"=="queue" (
    echo Demarrage du worker de queue...
    cd laravel-app && php artisan queue:work --tries=3
    goto :end
)

if /i "%1"=="test" (
    echo Execution des tests...
    cd laravel-app && php artisan test
    goto :end
)

if /i "%1"=="tinker" (
    echo Ouverture de Laravel Tinker...
    cd laravel-app && php artisan tinker
    goto :end
)

if /i "%1"=="npm-dev" (
    echo Demarrage de Vite en mode developpement...
    cd laravel-app && npm run dev
    goto :end
)

if /i "%1"=="npm-build" (
    echo Compilation des assets pour la production...
    cd laravel-app && npm run build
    goto :end
)

if /i "%1"=="storage-link" (
    echo Creation du lien symbolique pour le storage...
    cd laravel-app && php artisan storage:link
    goto :end
)

if /i "%1"=="logs" (
    echo Affichage des logs Laravel...
    cd laravel-app
    if exist "storage\logs\laravel.log" (
        type storage\logs\laravel.log | more
    ) else (
        echo Aucun fichier de log trouve.
    )
    goto :end
)

if /i "%1"=="clear-logs" (
    echo Suppression des logs...
    cd laravel-app
    if exist "storage\logs\*.log" (
        del /q storage\logs\*.log
        echo Logs supprimes.
    ) else (
        echo Aucun log a supprimer.
    )
    goto :end
)

if /i "%1"=="create-admin" (
    echo Creation d'un utilisateur admin...
    cd laravel-app
    echo.
    echo Executez les commandes suivantes dans Tinker:
    echo.
    echo $user = new App\Models\User;
    echo $user-^>name = 'Admin';
    echo $user-^>email = 'admin@menui.test';
    echo $user-^>password = bcrypt('password');
    echo $user-^>role = 'admin';
    echo $user-^>save();
    echo exit
    echo.
    php artisan tinker
    goto :end
)

if /i "%1"=="backup" (
    echo Creation d'une sauvegarde...
    set backup_dir=C:\laragon\backups\menui
    set datetime=!date:~-4!!date:~3,2!!date:~0,2!_!time:~0,2!!time:~3,2!
    set datetime=!datetime: =0!
    
    mkdir "!backup_dir!\!datetime!" 2>nul
    
    echo Sauvegarde de la base de donnees...
    "C:\laragon\bin\mysql\mysql-8.0.30-winx64\bin\mysqldump.exe" -u root menui > "!backup_dir!\!datetime!\menui.sql"
    
    echo Sauvegarde des fichiers uploades...
    xcopy "laravel-app\storage\app\public" "!backup_dir!\!datetime!\storage" /E /I /Y /Q
    
    echo Sauvegarde terminee dans !backup_dir!\!datetime!
    goto :end
)

:show_help
echo ====================================
echo   Commandes de developpement Menui
echo ====================================
echo.
echo Utilisation: dev-commands [commande]
echo.
echo Commandes disponibles:
echo.
echo   migrate       - Executer les migrations
echo   fresh         - Reinitialiser la base de donnees
echo   cache         - Vider tous les caches
echo   optimize      - Optimiser pour la production
echo   queue         - Demarrer le worker de queue
echo   test          - Executer les tests
echo   tinker        - Ouvrir Laravel Tinker
echo   npm-dev       - Demarrer Vite en mode dev
echo   npm-build     - Compiler les assets
echo   storage-link  - Creer le lien symbolique storage
echo   logs          - Afficher les logs Laravel
echo   clear-logs    - Supprimer les logs
echo   create-admin  - Creer un utilisateur admin
echo   backup        - Sauvegarder la base et les fichiers
echo.

:end
endlocal