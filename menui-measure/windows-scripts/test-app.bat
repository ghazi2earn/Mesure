@echo off
echo Test complet de l'application Mesure...

cd /d "C:\laragon\www\Mesure\menui-measure\laravel-app"

echo ========================================
echo Test de l'infrastructure
echo ========================================

REM Test de connectivité à la base de données
echo Test 1/6: Connexion à la base de données...
php artisan migrate:status > nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ Base de données accessible
) else (
    echo ✗ Problème de connexion à la base de données
    echo Vérifiez la configuration dans .env
)

REM Test de l'application Laravel
echo.
echo Test 2/6: Application Laravel...
php artisan route:list > nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ Application Laravel fonctionnelle
) else (
    echo ✗ Problème avec l'application Laravel
)

REM Test du cache Redis
echo.
echo Test 3/6: Cache Redis...
php artisan cache:clear > nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ Cache accessible
) else (
    echo ⚠ Problème avec le cache (utilisation des fichiers)
)

REM Test de la queue
echo.
echo Test 4/6: Système de queue...
php artisan queue:work --once --timeout=1 > nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ Système de queue fonctionnel
) else (
    echo ⚠ Problème avec la queue
)

echo.
echo ========================================
echo Test du service IA
echo ========================================

REM Test du service IA
echo Test 5/6: Connectivité du service IA...
powershell -Command "try { $response = Invoke-WebRequest -Uri 'http://127.0.0.1:8001/health' -TimeoutSec 5; if ($response.StatusCode -eq 200) { Write-Host '✓ Service IA accessible' } } catch { Write-Host '✗ Service IA non accessible' }"

REM Test d'intégration Laravel <-> IA
echo.
echo Test 6/6: Intégration Laravel <-> Service IA...
php -r "
\$config = include 'config/services.php';
\$aiUrl = \$config['ai']['url'] ?? 'non configuré';
echo 'Configuration IA : ' . \$aiUrl . PHP_EOL;

if (strpos(\$aiUrl, 'localhost:8000') !== false) {
    echo '⚠ Mode simulation activé' . PHP_EOL;
} else {
    try {
        \$context = stream_context_create(['http' => ['timeout' => 5]]);
        \$response = file_get_contents(\$aiUrl . '/health', false, \$context);
        if (\$response) {
            echo '✓ Intégration IA fonctionnelle' . PHP_EOL;
        }
    } catch (Exception \$e) {
        echo '✗ Problème d'intégration IA' . PHP_EOL;
    }
}
"

echo.
echo ========================================
echo Résumé
echo ========================================
echo.
echo URLs d'accès :
echo - Application principale : http://mesure.test
echo - Service IA (dev) : http://127.0.0.1:8001
echo - Documentation IA : http://127.0.0.1:8001/docs
echo.
echo Commandes utiles :
echo - Démarrer la queue : php artisan queue:work
echo - Voir les logs : tail -f storage/logs/laravel.log
echo - Redémarrer services : stop-all.bat puis start-all.bat
echo.
pause

