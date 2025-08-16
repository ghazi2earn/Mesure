@echo off
echo ========================================
echo     TEST SERVICE IA SUR VPS
echo ========================================
echo.

REM Configuration
set VPS_HOST=vps-df0c2336.vps.ovh.net
set VPS_USER=root
set HOST_PORT=8001
set CONTAINER_NAME=menui-ai-service

echo Test du service IA sur : %VPS_HOST%:%HOST_PORT%
echo.

REM Test 1: Health check
echo [1/4] Test Health Check...
curl -s -o nul -w "HTTP Status: %%{http_code}\nTemps de réponse: %%{time_total}s\n" http://%VPS_HOST%:%HOST_PORT%/health
if errorlevel 1 (
    echo ❌ Health check échoué
) else (
    echo ✅ Health check réussi
)
echo.

REM Test 2: Documentation API
echo [2/4] Test Documentation API...
curl -s -o nul -w "HTTP Status: %%{http_code}\n" http://%VPS_HOST%:%HOST_PORT%/docs
if errorlevel 1 (
    echo ❌ Documentation non accessible
) else (
    echo ✅ Documentation accessible
)
echo.

REM Test 3: Statut du conteneur
echo [3/4] Vérification statut conteneur...
ssh %VPS_USER%@%VPS_HOST% "
    if docker ps | grep -q %CONTAINER_NAME%; then
        echo '✅ Conteneur en cours d exécution'
        echo 'Détails du conteneur :'
        docker ps --filter name=%CONTAINER_NAME% --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
    else
        echo '❌ Conteneur non trouvé ou arrêté'
        echo 'Conteneurs disponibles :'
        docker ps -a --filter name=%CONTAINER_NAME%
    fi
"
echo.

REM Test 4: Logs récents
echo [4/4] Vérification logs récents...
ssh %VPS_USER%@%VPS_HOST% "
    echo 'Dernières 10 lignes des logs :'
    docker logs --tail 10 %CONTAINER_NAME% 2>&1 || echo 'Impossible d obtenir les logs'
"
echo.

echo ========================================
echo           TEST TERMINÉ
echo ========================================
echo.
echo URLs disponibles :
echo - Health : http://%VPS_HOST%:%HOST_PORT%/health
echo - Docs   : http://%VPS_HOST%:%HOST_PORT%/docs
echo - API    : http://%VPS_HOST%:%HOST_PORT%
echo.
echo Pour redémarrer le service :
echo ssh %VPS_USER%@%VPS_HOST% "docker restart %CONTAINER_NAME%"
echo.
echo Pour voir tous les logs :
echo ssh %VPS_USER%@%VPS_HOST% "docker logs %CONTAINER_NAME%"
echo.
pause


