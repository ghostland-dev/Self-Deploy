#!/bin/bash

# Système de déploiement automatisé avec Caddy et Docker
# Configuration pour qiwiiz.space

set -e

# Configuration
DEPLOY_CONFIG_FILE="deploy-config.json"
LOG_FILE="deploy.log"
BACKUP_DIR="/tmp/deploy-backups"
SSH_USER="qiwiiz"
SSH_HOST="51.159.6.66"
SSH_PASSWORD="changeme"
REMOTE_DEPLOY_DIR="/home/qiwiiz/apps"
CADDY_CONFIG_DIR="/etc/caddy"
CADDY_DATA_DIR="/var/lib/caddy"
DOCKER_COMPOSE_DIR="/home/qiwiiz/docker-compose"

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction de logging
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✓${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ✗${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠${NC} $1" | tee -a "$LOG_FILE"
}

# Fonction pour exécuter des commandes SSH
ssh_exec() {
    sshpass -p "$SSH_PASSWORD" ssh -o StrictHostKeyChecking=no "$SSH_USER@$SSH_HOST" "$1"
}

# Fonction pour copier des fichiers via SCP
scp_copy() {
    sshpass -p "$SSH_PASSWORD" scp -o StrictHostKeyChecking=no -r "$1" "$SSH_USER@$SSH_HOST:$2"
}

# Fonction pour créer une sauvegarde Docker
create_docker_backup() {
    local app_name="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_name="${app_name}_backup_${timestamp}"
    
    log "Création de la sauvegarde Docker: $backup_name"
    
    # Créer le répertoire de sauvegarde sur le serveur
    ssh_exec "mkdir -p $BACKUP_DIR"
    
    # Sauvegarder les volumes Docker
    ssh_exec "if [ -d '$DOCKER_COMPOSE_DIR/$app_name' ]; then cp -r '$DOCKER_COMPOSE_DIR/$app_name' '$BACKUP_DIR/$backup_name'; fi"
    
    # Sauvegarder la configuration Caddy
    ssh_exec "if [ -f '$CADDY_CONFIG_DIR/Caddyfile' ]; then cp '$CADDY_CONFIG_DIR/Caddyfile' '$BACKUP_DIR/${backup_name}_caddy'; fi"
    
    echo "$backup_name"
}

# Fonction de rollback Docker
rollback_docker() {
    local app_name="$1"
    local backup_name="$2"
    
    log_error "Démarrage du rollback Docker vers: $backup_name"
    
    # Arrêter les conteneurs actuels
    ssh_exec "cd '$DOCKER_COMPOSE_DIR/$app_name' && docker-compose down"
    
    # Restaurer la configuration
    ssh_exec "rm -rf '$DOCKER_COMPOSE_DIR/$app_name'"
    ssh_exec "cp -r '$BACKUP_DIR/$backup_name' '$DOCKER_COMPOSE_DIR/$app_name'"
    
    # Restaurer la configuration Caddy
    ssh_exec "if [ -f '$BACKUP_DIR/${backup_name}_caddy' ]; then cp '$BACKUP_DIR/${backup_name}_caddy' '$CADDY_CONFIG_DIR/Caddyfile'; fi"
    
    # Redémarrer les services
    ssh_exec "cd '$DOCKER_COMPOSE_DIR/$app_name' && docker-compose up -d"
    ssh_exec "systemctl reload caddy"
    
    log_success "Rollback Docker terminé avec succès"
}

# Fonction pour déployer une application statique avec Docker
deploy_static_docker() {
    local app_name="$1"
    local build_dir="$2"
    local domain="$3"
    
    log "Déploiement de l'application statique avec Docker: $app_name"
    
    # Créer la sauvegarde
    local backup_name=$(create_docker_backup "$app_name")
    
    # Créer le répertoire de déploiement
    ssh_exec "mkdir -p '$DOCKER_COMPOSE_DIR/$app_name'"
    
    # Créer le Dockerfile pour l'application statique
    cat > /tmp/Dockerfile << EOF
FROM nginx:alpine
COPY . /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF
    
    # Créer le docker-compose.yml
    cat > /tmp/docker-compose.yml << EOF
version: '3.8'
services:
  $app_name:
    build: .
    container_name: $app_name
    restart: unless-stopped
    ports:
      - "8080:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    networks:
      - caddy-network

networks:
  caddy-network:
    external: true
EOF
    
    # Créer la configuration nginx pour le conteneur
    cat > /tmp/nginx.conf << EOF
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    server {
        listen 80;
        server_name localhost;
        root /usr/share/nginx/html;
        index index.html;
        
        location / {
            try_files \$uri \$uri/ /index.html;
        }
        
        location ~* \\.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
EOF
    
    # Copier les fichiers
    scp_copy "$build_dir" "$DOCKER_COMPOSE_DIR/$app_name/"
    scp_copy "/tmp/Dockerfile" "$DOCKER_COMPOSE_DIR/$app_name/"
    scp_copy "/tmp/docker-compose.yml" "$DOCKER_COMPOSE_DIR/$app_name/"
    scp_copy "/tmp/nginx.conf" "$DOCKER_COMPOSE_DIR/$app_name/"
    
    # Créer la configuration Caddy
    create_caddy_config "$app_name" "$domain" "static"
    
    # Construire et démarrer le conteneur
    if ssh_exec "cd '$DOCKER_COMPOSE_DIR/$app_name' && docker-compose up -d --build"; then
        ssh_exec "systemctl reload caddy"
        log_success "Application statique Docker déployée avec succès"
    else
        log_error "Erreur lors du déploiement Docker, rollback..."
        rollback_docker "$app_name" "$backup_name"
        exit 1
    fi
    
    # Nettoyer les fichiers temporaires
    rm -f /tmp/Dockerfile /tmp/docker-compose.yml /tmp/nginx.conf
}

# Fonction pour déployer une application dynamique avec Docker
deploy_dynamic_docker() {
    local app_name="$1"
    local build_dir="$2"
    local domain="$3"
    local framework="$4"
    local port="$5"
    
    log "Déploiement de l'application dynamique avec Docker: $app_name (Framework: $framework)"
    
    # Créer la sauvegarde
    local backup_name=$(create_docker_backup "$app_name")
    
    # Créer le répertoire de déploiement
    ssh_exec "mkdir -p '$DOCKER_COMPOSE_DIR/$app_name'"
    
    # Copier les fichiers de l'application
    scp_copy "$build_dir" "$DOCKER_COMPOSE_DIR/$app_name/"
    
    # Créer les fichiers Docker selon le framework
    case "$framework" in
        "node"|"express"|"next")
            create_node_docker_files "$app_name" "$port"
            ;;
        "python"|"django"|"flask")
            create_python_docker_files "$app_name" "$port"
            ;;
        "php"|"laravel"|"symfony")
            create_php_docker_files "$app_name"
            ;;
        *)
            log_error "Framework non supporté: $framework"
            rollback_docker "$app_name" "$backup_name"
            exit 1
            ;;
    esac
    
    # Créer la configuration Caddy
    create_caddy_config "$app_name" "$domain" "dynamic" "$port"
    
    # Construire et démarrer le conteneur
    if ssh_exec "cd '$DOCKER_COMPOSE_DIR/$app_name' && docker-compose up -d --build"; then
        ssh_exec "systemctl reload caddy"
        log_success "Application dynamique Docker déployée avec succès"
    else
        log_error "Erreur lors du déploiement Docker, rollback..."
        rollback_docker "$app_name" "$backup_name"
        exit 1
    fi
}

# Fonction pour créer les fichiers Docker pour Node.js
create_node_docker_files() {
    local app_name="$1"
    local port="$2"
    
    # Dockerfile pour Node.js
    cat > /tmp/Dockerfile << EOF
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE $port
CMD ["npm", "start"]
EOF
    
    # docker-compose.yml pour Node.js
    cat > /tmp/docker-compose.yml << EOF
version: '3.8'
services:
  $app_name:
    build: .
    container_name: $app_name
    restart: unless-stopped
    ports:
      - "$port:$port"
    environment:
      - NODE_ENV=production
      - PORT=$port
    networks:
      - caddy-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:$port"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  caddy-network:
    external: true
EOF
    
    # Copier les fichiers
    scp_copy "/tmp/Dockerfile" "$DOCKER_COMPOSE_DIR/$app_name/"
    scp_copy "/tmp/docker-compose.yml" "$DOCKER_COMPOSE_DIR/$app_name/"
    
    rm -f /tmp/Dockerfile /tmp/docker-compose.yml
}

# Fonction pour créer les fichiers Docker pour Python
create_python_docker_files() {
    local app_name="$1"
    local port="$2"
    
    # Dockerfile pour Python
    cat > /tmp/Dockerfile << EOF
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE $port
CMD ["python", "app.py"]
EOF
    
    # docker-compose.yml pour Python
    cat > /tmp/docker-compose.yml << EOF
version: '3.8'
services:
  $app_name:
    build: .
    container_name: $app_name
    restart: unless-stopped
    ports:
      - "$port:$port"
    environment:
      - FLASK_ENV=production
      - PORT=$port
    networks:
      - caddy-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:$port"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  caddy-network:
    external: true
EOF
    
    # Copier les fichiers
    scp_copy "/tmp/Dockerfile" "$DOCKER_COMPOSE_DIR/$app_name/"
    scp_copy "/tmp/docker-compose.yml" "$DOCKER_COMPOSE_DIR/$app_name/"
    
    rm -f /tmp/Dockerfile /tmp/docker-compose.yml
}

# Fonction pour créer les fichiers Docker pour PHP
create_php_docker_files() {
    local app_name="$1"
    
    # Dockerfile pour PHP
    cat > /tmp/Dockerfile << EOF
FROM php:8.2-fpm-alpine
WORKDIR /var/www/html
RUN apk add --no-cache nginx
COPY . .
RUN chown -R www-data:www-data /var/www/html
EXPOSE 80
CMD ["php-fpm"]
EOF
    
    # docker-compose.yml pour PHP
    cat > /tmp/docker-compose.yml << EOF
version: '3.8'
services:
  $app_name:
    build: .
    container_name: $app_name
    restart: unless-stopped
    ports:
      - "8080:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    networks:
      - caddy-network

networks:
  caddy-network:
    external: true
EOF
    
    # Copier les fichiers
    scp_copy "/tmp/Dockerfile" "$DOCKER_COMPOSE_DIR/$app_name/"
    scp_copy "/tmp/docker-compose.yml" "$DOCKER_COMPOSE_DIR/$app_name/"
    
    rm -f /tmp/Dockerfile /tmp/docker-compose.yml
}

# Fonction pour créer la configuration Caddy
create_caddy_config() {
    local app_name="$1"
    local domain="$2"
    local type="$3"
    local port="$4"
    
    # Créer la configuration Caddy
    if [ "$type" = "static" ]; then
        ssh_exec "cat >> '$CADDY_CONFIG_DIR/Caddyfile' << 'EOF'

# Configuration pour $app_name
$domain {
    reverse_proxy localhost:8080
    
    # Headers de sécurité
    header {
        X-Content-Type-Options nosniff
        X-Frame-Options DENY
        X-XSS-Protection \"1; mode=block\"
        Referrer-Policy strict-origin-when-cross-origin
        Permissions-Policy \"geolocation=(), microphone=(), camera=()\"
    }
    
    # Cache pour les assets statiques
    @static {
        path *.css *.js *.png *.jpg *.jpeg *.gif *.ico *.svg *.woff *.woff2
    }
    header @static Cache-Control \"public, max-age=31536000\"
}
EOF"
    else
        ssh_exec "cat >> '$CADDY_CONFIG_DIR/Caddyfile' << 'EOF'

# Configuration pour $app_name
$domain {
    reverse_proxy localhost:$port {
        health_uri /health
        health_interval 30s
        health_timeout 5s
    }
    
    # Headers de sécurité
    header {
        X-Content-Type-Options nosniff
        X-Frame-Options DENY
        X-XSS-Protection \"1; mode=block\"
        Referrer-Policy strict-origin-when-cross-origin
        Permissions-Policy \"geolocation=(), microphone=(), camera=()\"
    }
    
    # Rate limiting
    rate_limit {
        zone static {
            key {remote_host}
            events 100
            window 1m
        }
    }
}
EOF"
    fi
}

# Fonction principale de déploiement
deploy() {
    local config_file="$1"
    
    if [ ! -f "$config_file" ]; then
        log_error "Fichier de configuration non trouvé: $config_file"
        exit 1
    fi
    
    # Charger la configuration
    local app_name=$(jq -r '.app_name' "$config_file")
    local app_type=$(jq -r '.app_type' "$config_file")
    local build_dir=$(jq -r '.build_dir' "$config_file")
    local domain=$(jq -r '.domain' "$config_file")
    local framework=$(jq -r '.framework // "unknown"' "$config_file")
    local port=$(jq -r '.port // 3000' "$config_file")
    
    log "Démarrage du déploiement Docker de: $app_name"
    log "Type: $app_type, Framework: $framework, Port: $port"
    
    # Vérifier que le répertoire de build existe
    if [ ! -d "$build_dir" ]; then
        log_error "Répertoire de build non trouvé: $build_dir"
        exit 1
    fi
    
    # Créer le réseau Docker si nécessaire
    ssh_exec "docker network create caddy-network 2>/dev/null || true"
    
    # Déployer selon le type
    case "$app_type" in
        "static")
            deploy_static_docker "$app_name" "$build_dir" "$domain"
            ;;
        "dynamic")
            deploy_dynamic_docker "$app_name" "$build_dir" "$domain" "$framework" "$port"
            ;;
        *)
            log_error "Type d'application non supporté: $app_type"
            exit 1
            ;;
    esac
    
    log_success "Déploiement Docker terminé avec succès!"
}

# Fonction pour lister les déploiements Docker
list_docker_deployments() {
    log "Liste des applications Docker déployées:"
    ssh_exec "ls -la $DOCKER_COMPOSE_DIR"
    
    log "Liste des conteneurs actifs:"
    ssh_exec "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
    
    log "Liste des réseaux Docker:"
    ssh_exec "docker network ls"
}

# Fonction pour nettoyer les anciennes sauvegardes
cleanup_backups() {
    local days="${1:-7}"
    log "Nettoyage des sauvegardes Docker plus anciennes que $days jours"
    ssh_exec "find $BACKUP_DIR -type d -mtime +$days -exec rm -rf {} +"
    log_success "Nettoyage terminé"
}

# Fonction pour nettoyer les images Docker inutilisées
cleanup_docker() {
    log "Nettoyage des images Docker inutilisées"
    ssh_exec "docker system prune -f"
    ssh_exec "docker image prune -f"
    log_success "Nettoyage Docker terminé"
}

# Fonction d'aide
show_help() {
    echo "Système de déploiement automatisé avec Caddy et Docker"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  deploy <config.json>     Déployer une application avec Docker"
    echo "  list                     Lister les déploiements Docker"
    echo "  cleanup [days]           Nettoyer les anciennes sauvegardes (défaut: 7 jours)"
    echo "  docker-cleanup           Nettoyer les images Docker inutilisées"
    echo "  help                     Afficher cette aide"
    echo ""
    echo "Exemples de fichiers de configuration dans le répertoire examples/"
}

# Point d'entrée principal
main() {
    case "${1:-help}" in
        "deploy")
            deploy "$2"
            ;;
        "list")
            list_docker_deployments
            ;;
        "cleanup")
            cleanup_backups "$2"
            ;;
        "docker-cleanup")
            cleanup_docker
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
