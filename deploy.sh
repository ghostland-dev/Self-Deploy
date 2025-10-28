#!/bin/bash

# Système de déploiement automatisé pour applications web
# Supporte les apps statiques et dynamiques avec rollback automatique

set -e

# Configuration
DEPLOY_CONFIG_FILE="deploy-config.json"
LOG_FILE="deploy.log"
BACKUP_DIR="/tmp/deploy-backups"
SSH_USER="user"
SSH_HOST="232.23.32.32"
SSH_PASSWORD="changeme"
REMOTE_DEPLOY_DIR="/var/www"
NGINX_CONFIG_DIR="/etc/nginx/sites-available"
NGINX_ENABLED_DIR="/etc/nginx/sites-enabled"

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

# Fonction pour créer une sauvegarde
create_backup() {
    local app_name="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_name="${app_name}_backup_${timestamp}"
    
    log "Création de la sauvegarde: $backup_name"
    
    # Créer le répertoire de sauvegarde sur le serveur
    ssh_exec "mkdir -p $BACKUP_DIR"
    
    # Sauvegarder l'application actuelle
    ssh_exec "if [ -d '$REMOTE_DEPLOY_DIR/$app_name' ]; then cp -r '$REMOTE_DEPLOY_DIR/$app_name' '$BACKUP_DIR/$backup_name'; fi"
    
    # Sauvegarder la configuration nginx si elle existe
    ssh_exec "if [ -f '$NGINX_CONFIG_DIR/$app_name' ]; then cp '$NGINX_CONFIG_DIR/$app_name' '$BACKUP_DIR/${backup_name}_nginx'; fi"
    
    echo "$backup_name"
}

# Fonction de rollback
rollback() {
    local app_name="$1"
    local backup_name="$2"
    
    log_error "Démarrage du rollback vers: $backup_name"
    
    # Restaurer l'application
    ssh_exec "rm -rf '$REMOTE_DEPLOY_DIR/$app_name'"
    ssh_exec "cp -r '$BACKUP_DIR/$backup_name' '$REMOTE_DEPLOY_DIR/$app_name'"
    
    # Restaurer la configuration nginx
    ssh_exec "if [ -f '$BACKUP_DIR/${backup_name}_nginx' ]; then cp '$BACKUP_DIR/${backup_name}_nginx' '$NGINX_CONFIG_DIR/$app_name'; fi"
    
    # Recharger nginx
    ssh_exec "nginx -t && systemctl reload nginx"
    
    log_success "Rollback terminé avec succès"
}

# Fonction pour déployer une application statique
deploy_static() {
    local app_name="$1"
    local build_dir="$2"
    local domain="$3"
    
    log "Déploiement de l'application statique: $app_name"
    
    # Créer la sauvegarde
    local backup_name=$(create_backup "$app_name")
    
    # Créer le répertoire de déploiement
    ssh_exec "mkdir -p '$REMOTE_DEPLOY_DIR/$app_name'"
    
    # Copier les fichiers
    scp_copy "$build_dir/*" "$REMOTE_DEPLOY_DIR/$app_name/"
    
    # Créer la configuration nginx
    create_nginx_config "$app_name" "$domain" "static"
    
    # Tester et recharger nginx
    if ssh_exec "nginx -t"; then
        ssh_exec "systemctl reload nginx"
        log_success "Application statique déployée avec succès"
    else
        log_error "Erreur de configuration nginx, rollback..."
        rollback "$app_name" "$backup_name"
        exit 1
    fi
}

# Fonction pour déployer une application dynamique
deploy_dynamic() {
    local app_name="$1"
    local build_dir="$2"
    local domain="$3"
    local framework="$4"
    local port="$5"
    
    log "Déploiement de l'application dynamique: $app_name (Framework: $framework)"
    
    # Créer la sauvegarde
    local backup_name=$(create_backup "$app_name")
    
    # Créer le répertoire de déploiement
    ssh_exec "mkdir -p '$REMOTE_DEPLOY_DIR/$app_name'"
    
    # Copier les fichiers
    scp_copy "$build_dir" "$REMOTE_DEPLOY_DIR/$app_name/"
    
    # Installer les dépendances et démarrer l'application
    case "$framework" in
        "node"|"express"|"next")
            deploy_node_app "$app_name" "$port"
            ;;
        "python"|"django"|"flask")
            deploy_python_app "$app_name" "$port"
            ;;
        "php"|"laravel"|"symfony")
            deploy_php_app "$app_name"
            ;;
        *)
            log_error "Framework non supporté: $framework"
            rollback "$app_name" "$backup_name"
            exit 1
            ;;
    esac
    
    # Créer la configuration nginx
    create_nginx_config "$app_name" "$domain" "dynamic" "$port"
    
    # Tester et recharger nginx
    if ssh_exec "nginx -t"; then
        ssh_exec "systemctl reload nginx"
        log_success "Application dynamique déployée avec succès"
    else
        log_error "Erreur de configuration nginx, rollback..."
        rollback "$app_name" "$backup_name"
        exit 1
    fi
}

# Fonction pour déployer une application Node.js
deploy_node_app() {
    local app_name="$1"
    local port="$2"
    
    log "Configuration de l'application Node.js"
    
    # Installer les dépendances
    ssh_exec "cd '$REMOTE_DEPLOY_DIR/$app_name' && npm install --production"
    
    # Créer le service systemd
    create_systemd_service "$app_name" "$port" "node"
    
    # Démarrer le service
    ssh_exec "systemctl daemon-reload"
    ssh_exec "systemctl enable $app_name"
    ssh_exec "systemctl restart $app_name"
}

# Fonction pour déployer une application Python
deploy_python_app() {
    local app_name="$1"
    local port="$2"
    
    log "Configuration de l'application Python"
    
    # Créer l'environnement virtuel
    ssh_exec "cd '$REMOTE_DEPLOY_DIR/$app_name' && python3 -m venv venv"
    ssh_exec "cd '$REMOTE_DEPLOY_DIR/$app_name' && source venv/bin/activate && pip install -r requirements.txt"
    
    # Créer le service systemd
    create_systemd_service "$app_name" "$port" "python"
    
    # Démarrer le service
    ssh_exec "systemctl daemon-reload"
    ssh_exec "systemctl enable $app_name"
    ssh_exec "systemctl restart $app_name"
}

# Fonction pour déployer une application PHP
deploy_php_app() {
    local app_name="$1"
    
    log "Configuration de l'application PHP"
    
    # Installer les dépendances avec Composer
    ssh_exec "cd '$REMOTE_DEPLOY_DIR/$app_name' && composer install --no-dev --optimize-autoloader"
    
    # Configurer les permissions
    ssh_exec "chown -R www-data:www-data '$REMOTE_DEPLOY_DIR/$app_name'"
    ssh_exec "chmod -R 755 '$REMOTE_DEPLOY_DIR/$app_name'"
}

# Fonction pour créer un service systemd
create_systemd_service() {
    local app_name="$1"
    local port="$2"
    local type="$3"
    
    local service_file="/etc/systemd/system/$app_name.service"
    
    case "$type" in
        "node")
            ssh_exec "cat > $service_file << EOF
[Unit]
Description=$app_name Node.js App
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=$REMOTE_DEPLOY_DIR/$app_name
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=PORT=$port

[Install]
WantedBy=multi-user.target
EOF"
            ;;
        "python")
            ssh_exec "cat > $service_file << EOF
[Unit]
Description=$app_name Python App
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=$REMOTE_DEPLOY_DIR/$app_name
ExecStart=$REMOTE_DEPLOY_DIR/$app_name/venv/bin/python app.py
Restart=always
RestartSec=10
Environment=FLASK_ENV=production
Environment=PORT=$port

[Install]
WantedBy=multi-user.target
EOF"
            ;;
    esac
}

# Fonction pour créer la configuration nginx
create_nginx_config() {
    local app_name="$1"
    local domain="$2"
    local type="$3"
    local port="$4"
    
    local config_file="$NGINX_CONFIG_DIR/$app_name"
    
    if [ "$type" = "static" ]; then
        ssh_exec "cat > $config_file << EOF
server {
    listen 80;
    server_name $domain;
    root $REMOTE_DEPLOY_DIR/$app_name;
    index index.html index.htm;
    
    location / {
        try_files \\\$uri \\\$uri/ /index.html;
    }
    
    location ~* \\.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control \"public, immutable\";
    }
}
EOF"
    else
        ssh_exec "cat > $config_file << EOF
server {
    listen 80;
    server_name $domain;
    
    location / {
        proxy_pass http://127.0.0.1:$port;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \\\$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \\\$host;
        proxy_set_header X-Real-IP \\\$remote_addr;
        proxy_set_header X-Forwarded-For \\\$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \\\$scheme;
        proxy_cache_bypass \\\$http_upgrade;
    }
}
EOF"
    fi
    
    # Activer le site
    ssh_exec "ln -sf $config_file $NGINX_ENABLED_DIR/"
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
    
    log "Démarrage du déploiement de: $app_name"
    log "Type: $app_type, Framework: $framework, Port: $port"
    
    # Vérifier que le répertoire de build existe
    if [ ! -d "$build_dir" ]; then
        log_error "Répertoire de build non trouvé: $build_dir"
        exit 1
    fi
    
    # Déployer selon le type
    case "$app_type" in
        "static")
            deploy_static "$app_name" "$build_dir" "$domain"
            ;;
        "dynamic")
            deploy_dynamic "$app_name" "$build_dir" "$domain" "$framework" "$port"
            ;;
        *)
            log_error "Type d'application non supporté: $app_type"
            exit 1
            ;;
    esac
    
    log_success "Déploiement terminé avec succès!"
}

# Fonction pour lister les déploiements
list_deployments() {
    log "Liste des applications déployées:"
    ssh_exec "ls -la $REMOTE_DEPLOY_DIR"
    
    log "Liste des services actifs:"
    ssh_exec "systemctl list-units --type=service --state=active | grep -E '(www|app|web)'"
    
    log "Liste des sites nginx:"
    ssh_exec "ls -la $NGINX_ENABLED_DIR"
}

# Fonction pour nettoyer les anciennes sauvegardes
cleanup_backups() {
    local days="${1:-7}"
    log "Nettoyage des sauvegardes plus anciennes que $days jours"
    ssh_exec "find $BACKUP_DIR -type d -mtime +$days -exec rm -rf {} +"
    log_success "Nettoyage terminé"
}

# Fonction d'aide
show_help() {
    echo "Système de déploiement automatisé"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  deploy <config.json>     Déployer une application"
    echo "  list                     Lister les déploiements"
    echo "  cleanup [days]           Nettoyer les anciennes sauvegardes (défaut: 7 jours)"
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
            list_deployments
            ;;
        "cleanup")
            cleanup_backups "$2"
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
