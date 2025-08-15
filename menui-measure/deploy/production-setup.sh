#!/bin/bash

# Script de déploiement pour VPS - Menui Mesure
# Usage: ./production-setup.sh

set -e

echo "🚀 Déploiement de Menui Mesure sur VPS"
echo "======================================"

# Variables
PROJECT_DIR="$HOME/menui-measure"
GITHUB_REPO="votre-username/menui-measure"  # À modifier
DOMAIN="votre-domaine.com"  # À modifier

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonctions utilitaires
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Vérification des prérequis
check_requirements() {
    print_status "Vérification des prérequis..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker n'est pas installé"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose n'est pas installé"
        exit 1
    fi
    
    if ! command -v git &> /dev/null; then
        print_error "Git n'est pas installé"
        exit 1
    fi
    
    print_status "Tous les prérequis sont installés"
}

# Clone ou mise à jour du repository
setup_code() {
    print_status "Configuration du code source..."
    
    if [ -d "$PROJECT_DIR" ]; then
        print_warning "Le répertoire existe déjà, mise à jour..."
        cd $PROJECT_DIR
        git pull origin main
    else
        print_status "Clonage du repository..."
        git clone https://github.com/$GITHUB_REPO.git $PROJECT_DIR
        cd $PROJECT_DIR
    fi
}

# Configuration de l'environnement
setup_environment() {
    print_status "Configuration de l'environnement..."
    
    # Copie du fichier .env
    if [ ! -f ".env" ]; then
        cp .env.production .env
        print_warning "Fichier .env créé. IMPORTANT: Modifiez les mots de passe!"
    fi
    
    # Génération de la clé Laravel
    print_status "Génération de la clé d'application..."
    docker run --rm -v $(pwd)/laravel-app:/app -w /app php:8.2-cli php artisan key:generate --show > .app_key
    APP_KEY=$(cat .app_key)
    sed -i "s/APP_KEY=.*/APP_KEY=$APP_KEY/" .env
    rm .app_key
    
    # Mise à jour du domaine
    sed -i "s/votre-domaine.com/$DOMAIN/g" .env
    sed -i "s/votre-domaine.com/$DOMAIN/g" docker/nginx/sites/laravel.conf
}

# Configuration SSL avec Let's Encrypt
setup_ssl() {
    print_status "Configuration SSL..."
    
    # Installation de Certbot
    if ! command -v certbot &> /dev/null; then
        apt install certbot -y
    fi
    
    # Création des certificats
    mkdir -p docker/ssl
    
    print_warning "Génération des certificats SSL pour $DOMAIN"
    print_warning "Assurez-vous que votre domaine pointe vers ce serveur!"
    
    # Arrêt temporaire de nginx s'il tourne
    docker-compose -f docker-compose.prod.yml stop nginx 2>/dev/null || true
    
    # Génération du certificat
    certbot certonly --standalone \
        --preferred-challenges http \
        --email admin@$DOMAIN \
        --agree-tos \
        --no-eff-email \
        -d $DOMAIN \
        -d www.$DOMAIN
    
    # Copie des certificats
    cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem docker/ssl/
    cp /etc/letsencrypt/live/$DOMAIN/privkey.pem docker/ssl/
    
    # Permissions
    chmod 644 docker/ssl/fullchain.pem
    chmod 600 docker/ssl/privkey.pem
}

# Déploiement avec Docker
deploy_application() {
    print_status "Déploiement de l'application..."
    
    # Construction et démarrage des containers
    docker-compose -f docker-compose.prod.yml build --no-cache
    docker-compose -f docker-compose.prod.yml up -d
    
    # Attente que les services soient prêts
    print_status "Attente du démarrage des services..."
    sleep 30
    
    # Migration de la base de données
    print_status "Migration de la base de données..."
    docker-compose -f docker-compose.prod.yml exec laravel php artisan migrate --force
    
    # Optimisations Laravel
    print_status "Optimisations Laravel..."
    docker-compose -f docker-compose.prod.yml exec laravel php artisan config:cache
    docker-compose -f docker-compose.prod.yml exec laravel php artisan route:cache
    docker-compose -f docker-compose.prod.yml exec laravel php artisan view:cache
    
    # Création du lien symbolique pour le storage
    docker-compose -f docker-compose.prod.yml exec laravel php artisan storage:link
}

# Configuration du cron pour le renouvellement SSL
setup_cron() {
    print_status "Configuration du renouvellement automatique SSL..."
    
    # Script de renouvellement
    cat > /etc/cron.d/certbot-renew << EOF
0 12 * * * root certbot renew --quiet --hook-post "docker-compose -f $PROJECT_DIR/docker-compose.prod.yml restart nginx"
EOF
}

# Tests de fonctionnement
run_tests() {
    print_status "Tests de fonctionnement..."
    
    # Test de connectivité
    if curl -f https://$DOMAIN > /dev/null 2>&1; then
        print_status "Site accessible via HTTPS"
    else
        print_error "Problème d'accès au site"
    fi
    
    # Test du service IA
    if docker-compose -f docker-compose.prod.yml exec ai-service curl -f http://localhost:8000/health > /dev/null 2>&1; then
        print_status "Service IA fonctionnel"
    else
        print_warning "Problème avec le service IA"
    fi
}

# Affichage des informations finales
show_final_info() {
    echo ""
    echo "🎉 Déploiement terminé!"
    echo "======================="
    echo ""
    echo "📱 Site web: https://$DOMAIN"
    echo "🔧 Documentation IA: https://$DOMAIN/ai-docs"
    echo ""
    echo "🐳 Commandes utiles:"
    echo "  docker-compose -f docker-compose.prod.yml logs -f    # Voir les logs"
    echo "  docker-compose -f docker-compose.prod.yml restart    # Redémarrer"
    echo "  docker-compose -f docker-compose.prod.yml down       # Arrêter"
    echo ""
    echo "📋 Prochaines étapes:"
    echo "  1. Modifiez le fichier .env avec vos vrais mots de passe"
    echo "  2. Configurez votre email SMTP"
    echo "  3. Testez l'upload d'images avec marqueur A4"
    echo ""
    print_warning "IMPORTANT: Sauvegardez régulièrement votre base de données!"
}

# Exécution du script
main() {
    cd /root  # ou le répertoire home de votre utilisateur
    
    check_requirements
    setup_code
    setup_environment
    
    # Demander confirmation pour SSL
    echo ""
    read -p "Voulez-vous configurer SSL avec Let's Encrypt? (y/N): " setup_ssl_confirm
    if [[ $setup_ssl_confirm =~ ^[Yy]$ ]]; then
        setup_ssl
    else
        print_warning "SSL non configuré. L'application sera accessible en HTTP uniquement."
        # Modification pour HTTP seulement
        sed -i 's/listen 443 ssl http2;/listen 80;/' docker/nginx/sites/laravel.conf
        sed -i '/ssl_/d' docker/nginx/sites/laravel.conf
        sed -i '/return 301/d' docker/nginx/sites/laravel.conf
    fi
    
    deploy_application
    setup_cron
    run_tests
    show_final_info
}

# Exécution
main "$@"
