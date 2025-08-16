#!/bin/bash

# Script de déploiement depuis Docker Hub
set -e

# Configuration - MODIFIEZ CES VALEURS
DOCKER_USERNAME="votre-username"  # Remplacez par votre nom d'utilisateur Docker Hub
IMAGE_NAME="menui-measure"
VERSION="latest"
CONTAINER_NAME="menui-measure"
HTTP_PORT="80"
AI_PORT="8001"
MYSQL_PORT="3306"  # Optionnel - pour accès externe à MySQL

FULL_IMAGE_NAME="$DOCKER_USERNAME/$IMAGE_NAME:$VERSION"

echo "🚀 Déploiement de Menui Mesure depuis Docker Hub"
echo "================================================"

# Vérification de Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé"
    echo "Installez Docker avec: curl -fsSL https://get.docker.com | sh"
    exit 1
fi

# Arrêt et suppression de l'ancien conteneur si existant
echo "🛑 Arrêt de l'ancien conteneur..."
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true

# Téléchargement de la dernière image
echo "📥 Téléchargement de l'image depuis Docker Hub..."
docker pull $FULL_IMAGE_NAME

# Création des volumes persistants
echo "💾 Création des volumes persistants..."
docker volume create menui_mysql_data
docker volume create menui_storage_data
docker volume create menui_redis_data

# Démarrage du conteneur
echo "🚀 Démarrage du conteneur..."
docker run -d \
    --name $CONTAINER_NAME \
    --restart unless-stopped \
    -p $HTTP_PORT:80 \
    -p $AI_PORT:8001 \
    -p 127.0.0.1:$MYSQL_PORT:3306 \
    -v menui_mysql_data:/var/lib/mysql \
    -v menui_storage_data:/var/www/menui/laravel-app/storage \
    -v menui_redis_data:/var/lib/redis \
    -e APP_URL=http://$(curl -s ifconfig.me) \
    $FULL_IMAGE_NAME

# Attente du démarrage
echo "⏳ Attente du démarrage complet..."
sleep 60

# Vérification du statut
echo "🔍 Vérification du statut..."
if docker ps | grep -q $CONTAINER_NAME; then
    echo "✅ Conteneur en cours d'exécution"
else
    echo "❌ Problème de démarrage du conteneur"
    echo "📋 Logs du conteneur:"
    docker logs $CONTAINER_NAME
    exit 1
fi

# Test de connectivité
echo "🌐 Test de connectivité..."
SERVER_IP=$(curl -s ifconfig.me)

# Test application web
if curl -f http://localhost:$HTTP_PORT/health > /dev/null 2>&1; then
    echo "✅ Application web accessible"
else
    echo "⚠️  Application web non accessible localement"
fi

# Test service IA
if curl -f http://localhost:$AI_PORT/health > /dev/null 2>&1; then
    echo "✅ Service IA accessible"
else
    echo "⚠️  Service IA non accessible"
fi

# Informations finales
echo ""
echo "🎉 Déploiement terminé avec succès !"
echo "===================================="
echo ""
echo "📱 Application web:"
echo "   • Local: http://localhost:$HTTP_PORT"
echo "   • Public: http://$SERVER_IP:$HTTP_PORT"
echo ""
echo "🤖 Service IA:"
echo "   • Local: http://localhost:$AI_PORT"
echo "   • Public: http://$SERVER_IP:$AI_PORT"
echo "   • Documentation: http://$SERVER_IP:$HTTP_PORT/ai-docs"
echo ""
echo "💾 Base de données MySQL:"
echo "   • Host: localhost:$MYSQL_PORT"
echo "   • Database: menui_prod"
echo "   • Username: menui_user"
echo "   • Password: menui_password_2024!"
echo ""
echo "🔧 Commandes utiles:"
echo "   • Voir les logs: docker logs -f $CONTAINER_NAME"
echo "   • Redémarrer: docker restart $CONTAINER_NAME"
echo "   • Arrêter: docker stop $CONTAINER_NAME"
echo "   • Shell dans le conteneur: docker exec -it $CONTAINER_NAME bash"
echo ""
echo "📋 Sauvegarde base de données:"
echo "   docker exec $CONTAINER_NAME mysqldump -u menui_user -pmenui_password_2024! menui_prod > backup.sql"
echo ""
echo "🔄 Mise à jour:"
echo "   ./deploy-from-dockerhub.sh"



