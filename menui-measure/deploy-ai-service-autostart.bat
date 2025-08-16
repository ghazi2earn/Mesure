@echo off
echo ========================================
echo  DÉPLOIEMENT VPS AVEC DÉMARRAGE AUTO
echo ========================================
echo.

REM Configuration
set VPS_HOST=vps-df0c2336.vps.ovh.net
set VPS_USER=root
set SERVICE_NAME=menui-ai-service
set IMAGE_NAME=ghazitounsi/menui-ai-service:latest

echo Configuration :
echo - VPS : %VPS_HOST%
echo - Utilisateur : %VPS_USER%
echo - Service : %SERVICE_NAME%
echo - Image : %IMAGE_NAME%
echo.

REM Vérification de la connexion SSH
echo [1/5] Test de connexion SSH...
ssh -o ConnectTimeout=10 %VPS_USER%@%VPS_HOST% "echo 'Connexion SSH OK'"
if errorlevel 1 (
    echo ❌ Impossible de se connecter au VPS
    echo Vérifiez vos clés SSH et la configuration
    pause
    exit /b 1
)
echo ✅ Connexion SSH établie

REM Transfert des fichiers de service
echo.
echo [2/5] Transfert des fichiers de configuration...
scp deploy\menui-ai-service.service %VPS_USER%@%VPS_HOST%:/tmp/
scp docker-compose-ai-service.yml %VPS_USER%@%VPS_HOST%:/tmp/
if errorlevel 1 (
    echo ❌ Échec du transfert des fichiers
    pause
    exit /b 1
)
echo ✅ Fichiers transférés

REM Installation et configuration sur le VPS
echo.
echo [3/5] Installation sur le VPS...
ssh %VPS_USER%@%VPS_HOST% "
echo '=== Installation du service IA Menui ==='

# Création du répertoire de travail
mkdir -p /opt/menui-ai-service
cd /opt/menui-ai-service

# Copie des fichiers de configuration
cp /tmp/docker-compose-ai-service.yml .
cp /tmp/menui-ai-service.service .

# Pull de la dernière image
echo 'Téléchargement de la dernière image...'
docker pull %IMAGE_NAME%

# Arrêt des services existants
echo 'Arrêt des services existants...'
systemctl stop menui-ai-service 2>/dev/null || true
docker stop menui-ai-service 2>/dev/null || true
docker rm menui-ai-service 2>/dev/null || true

# Installation du service systemd
echo 'Installation du service systemd...'
cp menui-ai-service.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable menui-ai-service

echo 'Service installé avec succès !'
"

if errorlevel 1 (
    echo ❌ Erreur lors de l'installation sur le VPS
    pause
    exit /b 1
)
echo ✅ Service installé sur le VPS

REM Démarrage du service
echo.
echo [4/5] Démarrage du service...
ssh %VPS_USER%@%VPS_HOST% "
echo 'Démarrage du service Menui AI...'
systemctl start menui-ai-service

# Attendre quelques secondes
sleep 10

# Vérifier le statut
echo '=== Statut du service ==='
systemctl status menui-ai-service --no-pager

echo '=== Statut du conteneur ==='
docker ps | grep menui-ai-service

echo '=== Test de santé ==='
curl -f http://localhost:8000/health && echo 'Service OK' || echo 'Service non accessible'
"

if errorlevel 1 (
    echo ⚠️  Problème lors du démarrage, mais service installé
) else (
    echo ✅ Service démarré avec succès
)

REM Test final
echo.
echo [5/5] Test final depuis l'extérieur...
echo Test de l'API depuis l'extérieur...
curl -f http://%VPS_HOST%:8000/health
if errorlevel 1 (
    echo ⚠️  Service non accessible depuis l'extérieur
    echo Vérifiez le firewall du VPS (port 8000)
) else (
    echo ✅ Service accessible depuis l'extérieur !
)

echo.
echo ========================================
echo      DÉPLOIEMENT AUTOMATIQUE TERMINÉ !
echo ========================================
echo.
echo 🎯 Service installé sur : %VPS_HOST%
echo 🌐 URL d'accès : http://%VPS_HOST%:8000
echo 🔧 Commandes de gestion SSH :
echo.
echo   # Statut du service
echo   ssh %VPS_USER%@%VPS_HOST% "systemctl status menui-ai-service"
echo.
echo   # Logs du service
echo   ssh %VPS_USER%@%VPS_HOST% "journalctl -u menui-ai-service -f"
echo.
echo   # Redémarrer le service
echo   ssh %VPS_USER%@%VPS_HOST% "systemctl restart menui-ai-service"
echo.
echo ✅ Le service démarrera automatiquement au boot du VPS
echo.
pause
