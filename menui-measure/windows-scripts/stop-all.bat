@echo off
echo ====================================
echo   Arret des services Menui Measure
echo ====================================
echo.

echo Arret de Redis...
taskkill /F /IM redis-server.exe 2>nul
if %errorlevel%==0 (
    echo Redis arrete.
) else (
    echo Redis n'etait pas en cours d'execution.
)

echo.
echo Arret du service IA...
taskkill /F /FI "WindowTitle eq Service IA - Menui*" 2>nul
if %errorlevel%==0 (
    echo Service IA arrete.
) else (
    echo Service IA n'etait pas en cours d'execution.
)

echo.
echo Arret de la queue Laravel...
taskkill /F /FI "WindowTitle eq Queue Laravel - Menui*" 2>nul
if %errorlevel%==0 (
    echo Queue Laravel arretee.
) else (
    echo Queue Laravel n'etait pas en cours d'execution.
)

echo.
echo Arret de Vite...
taskkill /F /FI "WindowTitle eq Vite Dev - Menui*" 2>nul
if %errorlevel%==0 (
    echo Vite arrete.
) else (
    echo Vite n'etait pas en cours d'execution.
)

echo.
echo ====================================
echo   Tous les services sont arretes!
echo ====================================
echo.
echo Note: Laragon (Apache/MySQL) reste actif.
echo.
pause