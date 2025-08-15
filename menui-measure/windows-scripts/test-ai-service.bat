@echo off
echo Test du service IA...

set /p ai_url="URL du service IA (par défaut: http://127.0.0.1:8001): "
if "%ai_url%"=="" set ai_url=http://127.0.0.1:8001

echo.
echo Test de connectivité vers %ai_url%...

REM Test de la route health
echo Test 1/3: Vérification de l'état du service...
curl -s "%ai_url%/health" > nul
if %errorlevel% equ 0 (
    echo ✓ Service accessible
    curl -s "%ai_url%/health"
    echo.
) else (
    echo ✗ Service non accessible
    echo Vérifiez que le service IA est démarré
    goto end
)

REM Test de la route racine
echo Test 2/3: Informations du service...
curl -s "%ai_url%/" > nul
if %errorlevel% equ 0 (
    echo ✓ API disponible
    curl -s "%ai_url%/"
    echo.
) else (
    echo ✗ API non disponible
)

REM Test avec une image de démonstration
echo Test 3/3: Test d'analyse d'image...
echo Vérification de la présence d'une image de test...

if exist "C:\laragon\www\Mesure\menui-measure\dataset\sample\test.jpg" (
    echo ✓ Image de test trouvée
    echo Test d'analyse en cours...
    curl -X POST "%ai_url%/analyze" -F "file=@C:\laragon\www\Mesure\menui-measure\dataset\sample\test.jpg" -s > test_result.json
    if %errorlevel% equ 0 (
        echo ✓ Test d'analyse réussi
        echo Résultat sauvegardé dans test_result.json
    ) else (
        echo ✗ Échec du test d'analyse
    )
) else (
    echo ⚠ Aucune image de test disponible
    echo Placez une image test.jpg dans le dossier dataset/sample/ pour tester l'analyse
)

echo.
echo Documentation de l'API disponible sur : %ai_url%/docs

:end
echo.
pause
