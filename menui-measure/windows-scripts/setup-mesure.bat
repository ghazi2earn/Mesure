@echo off
echo Configuration de mesure.test pour Laragon...

REM Créer le fichier de configuration Apache pour mesure.test
echo ^<VirtualHost *:80^> > "C:\laragon\etc\apache2\sites-enabled\mesure.test.conf"
echo     DocumentRoot "C:/laragon/www/Mesure/menui-measure/laravel-app/public" >> "C:\laragon\etc\apache2\sites-enabled\mesure.test.conf"
echo     ServerName mesure.test >> "C:\laragon\etc\apache2\sites-enabled\mesure.test.conf"
echo     ServerAlias *.mesure.test >> "C:\laragon\etc\apache2\sites-enabled\mesure.test.conf"
echo. >> "C:\laragon\etc\apache2\sites-enabled\mesure.test.conf"
echo     ^<Directory "C:/laragon/www/Mesure/menui-measure/laravel-app/public"^> >> "C:\laragon\etc\apache2\sites-enabled\mesure.test.conf"
echo         AllowOverride All >> "C:\laragon\etc\apache2\sites-enabled\mesure.test.conf"
echo         Require all granted >> "C:\laragon\etc\apache2\sites-enabled\mesure.test.conf"
echo         Options Indexes FollowSymLinks >> "C:\laragon\etc\apache2\sites-enabled\mesure.test.conf"
echo     ^</Directory^> >> "C:\laragon\etc\apache2\sites-enabled\mesure.test.conf"
echo ^</VirtualHost^> >> "C:\laragon\etc\apache2\sites-enabled\mesure.test.conf"

REM Ajouter mesure.test au fichier hosts
echo 127.0.0.1 mesure.test >> C:\Windows\System32\drivers\etc\hosts

echo Configuration terminée !
echo Redémarrez Laragon pour appliquer les changements.
pause


