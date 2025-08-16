#!/bin/bash

# Script pour construire et publier l'image sur Docker Hub
set -e

# Configuration
DOCKER_USERNAME="votre-username"  # Remplacez par votre nom d'utilisateur Docker Hub
IMAGE_NAME="menui-measure"
VERSION="latest"
FULL_IMAGE_NAME="$DOCKER_USERNAME/$IMAGE_NAME:$VERSION"

echo "🐳 Construction et publication de l'image Docker"
echo "==============================================="

# Vérification de la connexion Docker Hub
echo "🔐 Vérification de la connexion Docker Hub..."
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker n'est pas en cours d'exécution"
    exit 1
fi

# Construction de l'image
echo "🔨 Construction de l'image Docker..."
docker build -f Dockerfile.monolith -t $FULL_IMAGE_NAME .

# Test local de l'image
echo "🧪 Test local de l'image..."
docker run --rm -d --name menui-test -p 8080:80 $FULL_IMAGE_NAME
sleep 30

# Test de santé
if curl -f http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ Test local réussi"
    docker stop menui-test
else
    echo "❌ Test local échoué"
    docker stop menui-test
    exit 1
fi

# Connexion à Docker Hub
echo "🔐 Connexion à Docker Hub..."
echo "Entrez votre mot de passe Docker Hub:"
docker login -u $DOCKER_USERNAME

# Publication de l'image
echo "📤 Publication de l'image sur Docker Hub..."
docker push $FULL_IMAGE_NAME

# Nettoyage
echo "🧹 Nettoyage..."
docker image prune -f

echo ""
echo "🎉 Image publiée avec succès !"
echo "==============================="
echo "📦 Image: $FULL_IMAGE_NAME"
echo "🌐 URL Docker Hub: https://hub.docker.com/r/$DOCKER_USERNAME/$IMAGE_NAME"
echo ""
echo "📋 Pour déployer sur votre serveur:"
echo "   docker run -d --name menui-measure -p 80:80 -p 8001:8001 $FULL_IMAGE_NAME"
echo ""
echo "📋 Avec volumes persistants:"
echo "   docker run -d --name menui-measure \\"
echo "     -p 80:80 -p 8001:8001 \\"
echo "     -v menui_mysql:/var/lib/mysql \\"
echo "     -v menui_storage:/var/www/menui/laravel-app/storage \\"
echo "     $FULL_IMAGE_NAME"



