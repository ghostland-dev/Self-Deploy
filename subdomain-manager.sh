#!/bin/bash

# Gestionnaire de sous-domaines qiwiiz.space
# Utilise les sous-domaines DNS pré-configurés

set -e

# Configuration
SSH_USER="qiwiiz"
SSH_HOST="51.159.6.66"
SSH_PASSWORD="changeme"
DOMAIN="qiwiiz.space"
CADDY_CONFIG_DIR="/etc/caddy"
DOCKER_COMPOSE_DIR="/home/qiwiiz/docker-compose"

# Sous-domaines disponibles (basés sur votre configuration DNS)
AVAILABLE_SUBDOMAINS=(
    "admin" "api" "app" "bot" "data"
    "app1" "app2" "app3" "app4" "app5" "app6" "app7" "app8" "app9"
    "api1" "api2" "api3" "api4" "api5" "api6" "api7" "api8" "api9"
    "bot1" "bot2" "bot3" "bot4" "bot5" "bot6" "bot7" "bot8" "bot9"
)

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0;33m' # No Color

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "subdomain-manager.log"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✓${NC} $1" | tee -a "subdomain-manager.log"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ✗${NC} $1" | tee -a "subdomain-manager.log"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠${NC} $1" | tee -a "subdomain-manager.log"
}

# Fonction pour exécuter des commandes SSH
ssh_exec() {
    sshpass -p "$SSH_PASSWORD" ssh -o StrictHostKeyChecking=no "$SSH_USER@$SSH_HOST" "$1"
}

# Fonction pour lister les sous-domaines disponibles
list_available_subdomains() {
    log "Sous-domaines disponibles sur qiwiiz.space:"
    echo ""
    echo "🌐 Sous-domaines principaux:"
    echo "  - admin.qiwiiz.space"
    echo "  - api.qiwiiz.space"
    echo "  - app.qiwiiz.space"
    echo "  - bot.qiwiiz.space"
    echo "  - data.qiwiiz.space"
    echo ""
    echo "📱 Applications (app1-app9):"
    for i in {1..9}; do
        echo "  - app${i}.qiwiiz.space"
    done
    echo ""
    echo "🔌 APIs (api1-api9):"
    for i in {1..9}; do
        echo "  - api${i}.qiwiiz.space"
    done
    echo ""
    echo "🤖 Bots (bot1-bot9):"
    for i in {1..9}; do
        echo "  - bot${i}.qiwiiz.space"
    done
}

# Fonction pour lister les sous-domaines utilisés
list_used_subdomains() {
    log "Sous-domaines actuellement utilisés:"
    
    if ssh_exec "test -f '$CADDY_CONFIG_DIR/Caddyfile'"; then
        ssh_exec "grep -E '^[a-zA-Z0-9.-]+\.$DOMAIN' '$CADDY_CONFIG_DIR/Caddyfile' | sed 's/ {//' | sort"
    else
        log_warning "Fichier Caddyfile non trouvé"
    fi
}

# Fonction pour assigner un sous-domaine à une application
assign_subdomain() {
    local app_name="$1"
    local subdomain="$2"
    local app_type="$3"
    local port="$4"
    
    log "Assignation du sous-domaine $subdomain à l'application $app_name"
    
    # Vérifier que le sous-domaine est disponible
    if ! printf '%s\n' "${AVAILABLE_SUBDOMAINS[@]}" | grep -q "^$subdomain$"; then
        log_error "Sous-domaine $subdomain non disponible"
        log "Sous-domaines disponibles: ${AVAILABLE_SUBDOMAINS[*]}"
        return 1
    fi
    
    # Vérifier que le sous-domaine n'est pas déjà utilisé
    if ssh_exec "grep -q '$subdomain\.$DOMAIN' '$CADDY_CONFIG_DIR/Caddyfile' 2>/dev/null"; then
        log_warning "Le sous-domaine $subdomain.$DOMAIN est déjà utilisé"
        return 1
    fi
    
    local full_domain="$subdomain.$DOMAIN"
    
    # Créer la configuration Caddy
    create_caddy_config "$app_name" "$full_domain" "$app_type" "$port"
    
    # Recharger Caddy
    if ssh_exec "caddy reload --config '$CADDY_CONFIG_DIR/Caddyfile'"; then
        log_success "Sous-domaine $full_domain assigné à $app_name"
        log "Application accessible sur: https://$full_domain"
        return 0
    else
        log_error "Erreur lors de l'assignation du sous-domaine"
        return 1
    fi
}

# Fonction pour créer la configuration Caddy
create_caddy_config() {
    local app_name="$1"
    local domain="$2"
    local app_type="$3"
    local port="$4"
    
    log "Création de la configuration Caddy pour $domain"
    
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
    
    # Rate limiting selon le type d'application
    rate_limit {
        zone $app_type {
            key {remote_host}
            events 200
            window 1m
        }
    }
    
    # Logs spécifiques
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

# Fonction pour libérer un sous-domaine
release_subdomain() {
    local subdomain="$1"
    
    log "Libération du sous-domaine $subdomain.$DOMAIN"
    
    # Supprimer la configuration du sous-domaine
    ssh_exec "sed -i '/# Configuration pour .*$subdomain/,/^$/d' '$CADDY_CONFIG_DIR/Caddyfile'"
    
    # Recharger Caddy
    if ssh_exec "caddy reload --config '$CADDY_CONFIG_DIR/Caddyfile'"; then
        log_success "Sous-domaine $subdomain.$DOMAIN libéré"
        return 0
    else
        log_error "Erreur lors de la libération du sous-domaine"
        return 1
    fi
}

# Fonction pour suggérer un sous-domaine automatiquement
suggest_subdomain() {
    local app_name="$1"
    local app_type="$2"
    
    log "Suggestion de sous-domaine pour $app_name (type: $app_type)"
    
    # Logique de suggestion basée sur le type d'application
    case "$app_type" in
        "admin"|"dashboard")
            suggested="admin"
            ;;
        "api"|"backend")
            # Trouver le premier api disponible
            for i in {1..9}; do
                if ! ssh_exec "grep -q 'api${i}\.$DOMAIN' '$CADDY_CONFIG_DIR/Caddyfile' 2>/dev/null"; then
                    suggested="api${i}"
                    break
                fi
            done
            ;;
        "app"|"frontend"|"static")
            # Trouver le premier app disponible
            for i in {1..9}; do
                if ! ssh_exec "grep -q 'app${i}\.$DOMAIN' '$CADDY_CONFIG_DIR/Caddyfile' 2>/dev/null"; then
                    suggested="app${i}"
                    break
                fi
            done
            ;;
        "bot"|"automation")
            # Trouver le premier bot disponible
            for i in {1..9}; do
                if ! ssh_exec "grep -q 'bot${i}\.$DOMAIN' '$CADDY_CONFIG_DIR/Caddyfile' 2>/dev/null"; then
                    suggested="bot${i}"
                    break
                fi
            done
            ;;
        "data"|"database")
            suggested="data"
            ;;
        *)
            # Par défaut, utiliser app
            for i in {1..9}; do
                if ! ssh_exec "grep -q 'app${i}\.$DOMAIN' '$CADDY_CONFIG_DIR/Caddyfile' 2>/dev/null"; then
                    suggested="app${i}"
                    break
                fi
            done
            ;;
    esac
    
    if [ ! -z "$suggested" ]; then
        log_success "Suggestion: $suggested.$DOMAIN"
        echo "$suggested"
    else
        log_warning "Aucun sous-domaine disponible pour le type $app_type"
        echo ""
    fi
}

# Fonction pour déployer avec sous-domaine automatique
deploy_with_auto_subdomain() {
    local app_name="$1"
    local app_type="$2"
    local port="$3"
    local docker_image="$4"
    local docker_tag="$5"
    
    log "Déploiement avec sous-domaine automatique: $app_name"
    
    # Suggérer un sous-domaine
    local suggested_subdomain=$(suggest_subdomain "$app_name" "$app_type")
    
    if [ -z "$suggested_subdomain" ]; then
        log_error "Aucun sous-domaine disponible"
        return 1
    fi
    
    # Déployer l'application Docker
    log "Déploiement de l'application Docker..."
    ./docker-image-deploy.sh deploy "$app_name" "$docker_image" "$docker_tag" "$port" "$suggested_subdomain.$DOMAIN"
    
    # Assigner le sous-domaine
    assign_subdomain "$app_name" "$suggested_subdomain" "$app_type" "$port"
    
    log_success "Déploiement terminé!"
    log "Application accessible sur: https://$suggested_subdomain.$DOMAIN"
}

# Fonction pour créer un mapping des applications
create_app_mapping() {
    log "Création du mapping des applications"
    
    cat > app-mapping.json << 'EOF'
{
  "applications": {
    "admin": {
      "subdomain": "admin",
      "type": "admin",
      "port": 8080,
      "description": "Interface d'administration"
    },
    "api": {
      "subdomain": "api",
      "type": "api",
      "port": 3000,
      "description": "API principale"
    },
    "app": {
      "subdomain": "app",
      "type": "app",
      "port": 8080,
      "description": "Application principale"
    },
    "bot": {
      "subdomain": "bot",
      "type": "bot",
      "port": 3000,
      "description": "Bot principal"
    },
    "data": {
      "subdomain": "data",
      "type": "data",
      "port": 8080,
      "description": "Interface de données"
    }
  },
  "available_subdomains": {
    "apps": ["app1", "app2", "app3", "app4", "app5", "app6", "app7", "app8", "app9"],
    "apis": ["api1", "api2", "api3", "api4", "api5", "api6", "api7", "api8", "api9"],
    "bots": ["bot1", "bot2", "bot3", "bot4", "bot5", "bot6", "bot7", "bot8", "bot9"]
  }
}
EOF
    
    log_success "Mapping des applications créé: app-mapping.json"
}

# Fonction pour afficher le statut des sous-domaines
show_subdomain_status() {
    log "Statut des sous-domaines qiwiiz.space"
    echo ""
    
    echo "📊 Sous-domaines utilisés:"
    list_used_subdomains
    echo ""
    
    echo "✅ Sous-domaines disponibles:"
    for subdomain in "${AVAILABLE_SUBDOMAINS[@]}"; do
        if ! ssh_exec "grep -q '$subdomain\.$DOMAIN' '$CADDY_CONFIG_DIR/Caddyfile' 2>/dev/null"; then
            echo "  - $subdomain.$DOMAIN"
        fi
    done
    echo ""
    
    echo "🔒 Certificats SSL:"
    ssh_exec "caddy list-certificates | grep '$DOMAIN' | head -10"
}

# Fonction d'aide
show_help() {
    echo "Gestionnaire de sous-domaines qiwiiz.space"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  list-available                    Lister les sous-domaines disponibles"
    echo "  list-used                         Lister les sous-domaines utilisés"
    echo "  assign <app_name> <subdomain> <type> [port]  Assigner un sous-domaine"
    echo "  release <subdomain>               Libérer un sous-domaine"
    echo "  suggest <app_name> <type>         Suggérer un sous-domaine"
    echo "  deploy-auto <app_name> <type> <port> <image> <tag>  Déployer avec sous-domaine auto"
    echo "  create-mapping                    Créer le mapping des applications"
    echo "  status                            Afficher le statut des sous-domaines"
    echo "  help                              Afficher cette aide"
    echo ""
    echo "Types d'applications:"
    echo "  admin, api, app, bot, data, static, dynamic"
    echo ""
    echo "Exemples:"
    echo "  $0 list-available"
    echo "  $0 assign mon-app app1 static 8080"
    echo "  $0 suggest mon-api api"
    echo "  $0 deploy-auto mon-app static 8080 ghcr.io/user/repo static-latest"
}

# Point d'entrée principal
main() {
    case "${1:-help}" in
        "list-available")
            list_available_subdomains
            ;;
        "list-used")
            list_used_subdomains
            ;;
        "assign")
            assign_subdomain "$2" "$3" "$4" "$5"
            ;;
        "release")
            release_subdomain "$2"
            ;;
        "suggest")
            suggest_subdomain "$2" "$3"
            ;;
        "deploy-auto")
            deploy_with_auto_subdomain "$2" "$3" "$4" "$5" "$6"
            ;;
        "create-mapping")
            create_app_mapping
            ;;
        "status")
            show_subdomain_status
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
