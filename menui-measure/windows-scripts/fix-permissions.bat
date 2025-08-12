@echo off
echo ====================================
echo   Correction des permissions
echo ====================================
echo.

cd /d C:\laragon\www\Mesure\menui-measure\laravel-app

echo Creation des repertoires manquants...

:: Bootstrap cache
if not exist "bootstrap\cache" mkdir "bootstrap\cache"

:: Storage directories
if not exist "storage\app" mkdir "storage\app"
if not exist "storage\app\public" mkdir "storage\app\public"
if not exist "storage\framework" mkdir "storage\framework"
if not exist "storage\framework\cache" mkdir "storage\framework\cache"
if not exist "storage\framework\cache\data" mkdir "storage\framework\cache\data"
if not exist "storage\framework\sessions" mkdir "storage\framework\sessions"
if not exist "storage\framework\testing" mkdir "storage\framework\testing"
if not exist "storage\framework\views" mkdir "storage\framework\views"
if not exist "storage\logs" mkdir "storage\logs"

echo.
echo Repertoires crees avec succes!
echo.

:: Donner les permissions completes (Windows)
echo Attribution des permissions...
icacls "bootstrap\cache" /grant Everyone:F /T >nul 2>&1
icacls "storage" /grant Everyone:F /T >nul 2>&1

echo.
echo Permissions corrigees!
echo.
echo Vous pouvez maintenant executer: composer install
echo.
pause