#!/bin/bash

# Script de déploiement Docker avec images pré-construites
# Utilise les images Docker construites par GitHub Actions

set -e

# Configuration
SSH_USER="qiwiiz"
SSH_HOST="51.159.6.66"
SSH_PASSWORD="changeme"
DOCKER_REGISTRY="ghcr.io"
DOCKER_COMPOSE_DIR="/home/qiwiiz/docker-compose"
CADDY_CONFIG_DIR="/etc/caddy"

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "docker-deploy.log"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✓${NC} $1" | tee -a "docker-deploy.log"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ✗${NC} $1" | tee -a "docker-deploy.log"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠${NC} $1" | tee -a "docker-deploy.log"
}

# Fonction pour exécuter des commandes SSH
ssh_exec() {
    sshpass -p "$SSH_PASSWORD" ssh -o StrictHostKeyChecking=no "$SSH_USER@$SSH_HOST" "$1"
}

# Fonction pour déployer une image Docker
deploy_docker_image() {
    local app_name="$1"
    local image_name="$2"
    local image_tag="$3"
    local port="$4"
    local domain="$5"
    
    log "Déploiement de l'image Docker: $image_name:$image_tag"
    
    # Créer le répertoire de déploiement
    ssh_exec "mkdir -p '$DOCKER_COMPOSE_DIR/$app_name'"
    
    # Créer le docker-compose.yml pour l'image pré-construite
    ssh_exec "cat > '$DOCKER_COMPOSE_DIR/$app_name/docker-compose.yml' << 'EOF'
version: '3.8'
services:
  $app_name:
    image: $image_name:$image_tag
    container_name: $app_name
    restart: unless-stopped
    ports:
      - \"$port:$port\"
    environment:
      - NODE_ENV=production
      - PORT=$port
    networks:
      - caddy-network
    healthcheck:
      test: [\"CMD\", \"curl\", \"-f\", \"http://localhost:$port/health\"]
      interval: 30s
      timeout: 10s
      retries: 3
    labels:
      - \"traefik.enable=true\"
      - \"traefik.http.routers.$app_name.rule=Host(\`$domain\`)"
      - \"traefik.http.routers.$app_name.tls=true\"
      - \"traefik.http.routers.$app_name.tls.certresolver=letsencrypt\"

networks:
  caddy-network:
    external: true
EOF"
    
    # Créer le réseau Docker si nécessaire
    ssh_exec "docker network create caddy-network 2>/dev/null || true"
    
    # Arrêter l'ancien conteneur s'il existe
    ssh_exec "cd '$DOCKER_COMPOSE_DIR/$app_name' && docker-compose down || true"
    
    # Tirer la nouvelle image
    log "Téléchargement de l'image Docker..."
    ssh_exec "docker pull $image_name:$image_tag"
    
    # Démarrer le nouveau conteneur
    log "Démarrage du conteneur..."
    ssh_exec "cd '$DOCKER_COMPOSE_DIR/$app_name' && docker-compose up -d"
    
    # Attendre que le conteneur soit prêt
    log "Attente du démarrage du conteneur..."
    sleep 10
    
    # Vérifier que le conteneur est en cours d'exécution
    if ssh_exec "docker ps | grep -q $app_name"; then
        log_success "Conteneur $app_name démarré avec succès"
    else
        log_error "Échec du démarrage du conteneur $app_name"
        return 1
    fi
    
    # Créer la configuration Caddy
    create_caddy_config "$app_name" "$domain" "$port"
    
    # Recharger Caddy
    ssh_exec "caddy reload --config '$CADDY_CONFIG_DIR/Caddyfile'"
    
    log_success "Déploiement Docker terminé avec succès!"
    log "Application accessible sur: https://$domain"
}

# Fonction pour créer la configuration Caddy
create_caddy_config() {
    local app_name="$1"
    local domain="$2"
    local port="$3"
    
    log "Création de la configuration Caddy pour $domain"
    
    # Vérifier si la configuration existe déjà
    if ssh_exec "grep -q '$domain' '$CADDY_CONFIG_DIR/Caddyfile'"; then
        log_warning "Configuration Caddy pour $domain existe déjà, mise à jour..."
        ssh_exec "sed -i '/# Configuration pour $app_name/,/^$/d' '$CADDY_CONFIG_DIR/Caddyfile'"
    fi
    
    # Créer la configuration Caddy
    ssh_exec "cat >> '$CADDY_CONFIG_DIR/Caddyfile' << 'EOF'

# Configuration pour $app_name
$domain {
    reverse_proxy localhost:$port {
        health_uri /health
        health_interval 30s
        health_timeout 5s
    }
    
    header {
        X-Content-Type-Options nosniff
        X-Frame-Options DENY
        X-XSS-Protection \"1; mode=block\"
        Referrer-Policy strict-origin-when-cross-origin
        Permissions-Policy \"geolocation=(), microphone=(), camera=()\"
        Strict-Transport-Security \"max-age=31536000; includeSubDomains\"
    }
    
    encode gzip
    
    rate_limit {
        zone dynamic {
            key {remote_host}
            events 200
            window 1m
        }
    }
    
    log {
        output file /var/log/caddy/$app_name.log {
            roll_size 100mb
            roll_keep 5
            roll_keep_for 720h
        }
        format json
    }
}
EOF"
    
    log_success "Configuration Caddy créée pour $domain"
}

# Fonction pour mettre à jour une image Docker
update_docker_image() {
    local app_name="$1"
    local image_name="$2"
    local image_tag="$3"
    
    log "Mise à jour de l'image Docker: $image_name:$image_tag"
    
    # Arrêter le conteneur actuel
    ssh_exec "cd '$DOCKER_COMPOSE_DIR/$app_name' && docker-compose down"
    
    # Tirer la nouvelle image
    ssh_exec "docker pull $image_name:$image_tag"
    
    # Redémarrer le conteneur
    ssh_exec "cd '$DOCKER_COMPOSE_DIR/$app_name' && docker-compose up -d"
    
    log_success "Image Docker mise à jour avec succès"
}

# Fonction pour lister les images Docker déployées
list_docker_images() {
    log "Liste des images Docker déployées:"
    
    ssh_exec "docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}' | grep -E '(ghcr.io|docker.io)'"
    
    log "Liste des conteneurs en cours d'exécution:"
    ssh_exec "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'"
}

# Fonction pour nettoyer les images Docker inutilisées
cleanup_docker_images() {
    log "Nettoyage des images Docker inutilisées..."
    
    # Supprimer les images non utilisées
    ssh_exec "docker image prune -f"
    
    # Supprimer les conteneurs arrêtés
    ssh_exec "docker container prune -f"
    
    # Supprimer les volumes non utilisés
    ssh_exec "docker volume prune -f"
    
    # Supprimer les réseaux non utilisés
    ssh_exec "docker network prune -f"
    
    log_success "Nettoyage Docker terminé"
}

# Fonction pour créer un déploiement rapide depuis GitHub
deploy_from_github() {
    local github_repo="$1"
    local app_name="$2"
    local app_type="$3"
    local port="$4"
    
    log "Déploiement depuis GitHub: $github_repo"
    
    # Extraire le nom du repository
    local repo_name=$(echo "$github_repo" | sed 's/.*\///' | sed 's/\.git$//')
    
    # Construire le nom de l'image
    local image_name="$DOCKER_REGISTRY/$github_repo"
    local image_tag="${app_type}-latest"
    local domain="${app_name}.qiwiiz.space"
    
    # Déployer l'image
    deploy_docker_image "$app_name" "$image_name" "$image_tag" "$port" "$domain"
}

# Fonction pour créer un script de déploiement automatique
create_auto_deploy_script() {
    log "Création du script de déploiement automatique"
    
    cat > auto-deploy-docker.sh << 'EOF'
#!/bin/bash

# Script de déploiement automatique Docker
# Usage: ./auto-deploy-docker.sh <github_repo> <app_name> <app_type> [port]

set -e

GITHUB_REPO="$1"
APP_NAME="$2"
APP_TYPE="$3"
PORT="${4:-3000}"

if [ -z "$GITHUB_REPO" ] || [ -z "$APP_NAME" ] || [ -z "$APP_TYPE" ]; then
    echo "Usage: $0 <github_repo> <app_name> <app_type> [port]"
    echo "Exemples:"
    echo "  $0 username/my-react-app mon-site static 8080"
    echo "  $0 username/my-api mon-api node 3000"
    echo "  $0 username/my-app mon-app python 5000"
    exit 1
fi

# Construire le nom de l'image
DOCKER_REGISTRY="ghcr.io"
IMAGE_NAME="$DOCKER_REGISTRY/$GITHUB_REPO"
IMAGE_TAG="${APP_TYPE}-latest"
DOMAIN="${APP_NAME}.qiwiiz.space"

echo "Déploiement automatique Docker"
echo "Repository: $GITHUB_REPO"
echo "Application: $APP_NAME"
echo "Type: $APP_TYPE"
echo "Port: $PORT"
echo "Image: $IMAGE_NAME:$IMAGE_TAG"
echo "Domaine: $DOMAIN"

# Déployer l'image
./docker-image-deploy.sh deploy "$APP_NAME" "$IMAGE_NAME" "$IMAGE_TAG" "$PORT" "$DOMAIN"

echo "Déploiement terminé!"
echo "Application accessible sur: https://$DOMAIN"
EOF
    
    chmod +x auto-deploy-docker.sh
    log_success "Script auto-deploy-docker.sh créé"
}

# Fonction d'aide
show_help() {
    echo "Déploiement Docker avec images pré-construites"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  deploy <app_name> <image_name> <image_tag> <port> <domain>     Déployer une image Docker"
    echo "  update <app_name> <image_name> <image_tag>                       Mettre à jour une image Docker"
    echo "  github-deploy <github_repo> <app_name> <app_type> [port]         Déployer depuis GitHub"
    echo "  list-images                                                      Lister les images Docker"
    echo "  cleanup                                                           Nettoyer les images inutilisées"
    echo "  create-auto-script                                               Créer le script de déploiement automatique"
    echo "  help                                                              Afficher cette aide"
    echo ""
    echo "Exemples:"
    echo "  $0 deploy mon-app ghcr.io/username/my-app static-latest 8080 mon-app.qiwiiz.space"
    echo "  $0 github-deploy username/my-react-app mon-site static 8080"
    echo "  $0 update mon-app ghcr.io/username/my-app static-latest"
}

# Point d'entrée principal
main() {
    case "${1:-help}" in
        "deploy")
            deploy_docker_image "$2" "$3" "$4" "$5" "$6"
            ;;
        "update")
            update_docker_image "$2" "$3" "$4"
            ;;
        "github-deploy")
            deploy_from_github "$2" "$3" "$4" "$5"
            ;;
        "list-images")
            list_docker_images
            ;;
        "cleanup")
            cleanup_docker_images
            ;;
        "create-auto-script")
            create_auto_deploy_script
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            log_error "Commande inconnue: $1"
            show_help
            exit 1
            ;;
    esac
}

# Vérifier les dépendances
check_dependencies() {
    local missing_deps=()
    
    if ! command -v sshpass &> /dev/null; then
        missing_deps+=("sshpass")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Dépendances manquantes: ${missing_deps[*]}"
        log "Installez-les avec: sudo apt install ${missing_deps[*]}"
        exit 1
    fi
}

# Vérifier les dépendances au démarrage
check_dependencies

# Exécuter la fonction principale
main "$@"
