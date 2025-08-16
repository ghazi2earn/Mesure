@echo off
echo Démarrage du worker de queue pour le traitement des images...

cd /d "C:\laragon\www\Mesure\menui-measure\laravel-app"

echo Worker de queue démarré en arrière-plan
echo Les images uploadées seront maintenant traitées automatiquement
echo.
echo Pour arrêter le worker: Ctrl+C
echo.

php artisan queue:work --daemon





