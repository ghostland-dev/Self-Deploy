#!/bin/bash

# Script de gestion automatique SSL et alias pour Caddy
# Configuration pour qiwiiz.space avec sous-domaines automatiques

set -e

# Configuration
SSH_USER="qiwiiz"
SSH_HOST="51.159.6.66"
SSH_PASSWORD="changeme"
DOMAIN="qiwiiz.space"
CADDY_CONFIG_DIR="/etc/caddy"
CADDY_DATA_DIR="/var/lib/caddy"
DOCKER_COMPOSE_DIR="/home/qiwiiz/docker-compose"

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "caddy-manager.log"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✓${NC} $1" | tee -a "caddy-manager.log"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ✗${NC} $1" | tee -a "caddy-manager.log"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠${NC} $1" | tee -a "caddy-manager.log"
}

# Fonction pour exécuter des commandes SSH
ssh_exec() {
    sshpass -p "$SSH_PASSWORD" ssh -o StrictHostKeyChecking=no "$SSH_USER@$SSH_HOST" "$1"
}

# Fonction pour créer un sous-domaine automatique
create_subdomain() {
    local app_name="$1"
    local app_type="$2"
    local port="$3"
    local subdomain="${app_name}.${DOMAIN}"
    
    log "Création du sous-domaine: $subdomain"
    
    # Vérifier si le sous-domaine existe déjà
    if ssh_exec "grep -q '$subdomain' '$CADDY_CONFIG_DIR/Caddyfile'"; then
        log_warning "Le sous-domaine $subdomain existe déjà"
        return 1
    fi
    
    # Créer la configuration Caddy pour le sous-domaine
    local caddy_config=""
    
    if [ "$app_type" = "static" ]; then
        caddy_config="
# Configuration pour $app_name
$subdomain {
    # Redirection automatique vers HTTPS
    redir https://{host}{uri} permanent
}

https://$subdomain {
    # Reverse proxy vers le conteneur Docker
    reverse_proxy localhost:8080 {
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
        Strict-Transport-Security \"max-age=31536000; includeSubDomains\"
    }
    
    # Compression
    encode gzip
    
    # Cache pour les assets statiques
    @static {
        path *.css *.js *.png *.jpg *.jpeg *.gif *.ico *.svg *.woff *.woff2
    }
    header @static Cache-Control \"public, max-age=31536000\"
    
    # Rate limiting
    rate_limit {
        zone static {
            key {remote_host}
            events 100
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
}"
    else
        caddy_config="
# Configuration pour $app_name
$subdomain {
    # Redirection automatique vers HTTPS
    redir https://{host}{uri} permanent
}

https://$subdomain {
    # Reverse proxy vers l'application
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
        Strict-Transport-Security \"max-age=31536000; includeSubDomains\"
    }
    
    # Compression
    encode gzip
    
    # Rate limiting
    rate_limit {
        zone dynamic {
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
}"
    fi
    
    # Ajouter la configuration au fichier Caddy
    ssh_exec "cat >> '$CADDY_CONFIG_DIR/Caddyfile' << 'EOF'
$caddy_config
EOF"
    
    # Recharger Caddy pour appliquer les changements
    if ssh_exec "caddy reload --config '$CADDY_CONFIG_DIR/Caddyfile'"; then
        log_success "Sous-domaine $subdomain créé avec succès"
        log "SSL automatique configuré pour https://$subdomain"
        return 0
    else
        log_error "Erreur lors de la création du sous-domaine $subdomain"
        return 1
    fi
}

# Fonction pour supprimer un sous-domaine
remove_subdomain() {
    local app_name="$1"
    local subdomain="${app_name}.${DOMAIN}"
    
    log "Suppression du sous-domaine: $subdomain"
    
    # Supprimer la configuration du sous-domaine
    ssh_exec "sed -i '/# Configuration pour $app_name/,/^$/d' '$CADDY_CONFIG_DIR/Caddyfile'"
    
    # Recharger Caddy
    if ssh_exec "caddy reload --config '$CADDY_CONFIG_DIR/Caddyfile'"; then
        log_success "Sous-domaine $subdomain supprimé avec succès"
        return 0
    else
        log_error "Erreur lors de la suppression du sous-domaine $subdomain"
        return 1
    fi
}

# Fonction pour lister tous les sous-domaines
list_subdomains() {
    log "Liste des sous-domaines configurés:"
    
    ssh_exec "grep -E '^[a-zA-Z0-9.-]+\.$DOMAIN' '$CADDY_CONFIG_DIR/Caddyfile' | sed 's/ {//' | sort"
    
    log "Statut des certificats SSL:"
    ssh_exec "caddy list-certificates | grep '$DOMAIN'"
}

# Fonction pour vérifier le statut SSL d'un sous-domaine
check_ssl_status() {
    local app_name="$1"
    local subdomain="${app_name}.${DOMAIN}"
    
    log "Vérification du statut SSL pour $subdomain"
    
    # Vérifier le certificat
    if ssh_exec "caddy list-certificates | grep -q '$subdomain'"; then
        log_success "Certificat SSL valide pour $subdomain"
        
        # Afficher les détails du certificat
        local cert_info=$(ssh_exec "caddy list-certificates | grep '$subdomain'")
        log "Détails du certificat: $cert_info"
        
        return 0
    else
        log_warning "Certificat SSL non trouvé pour $subdomain"
        return 1
    fi
}

# Fonction pour renouveler tous les certificats SSL
renew_all_certificates() {
    log "Renouvellement de tous les certificats SSL"
    
    if ssh_exec "caddy reload --config '$CADDY_CONFIG_DIR/Caddyfile'"; then
        log_success "Tous les certificats SSL ont été renouvelés"
        return 0
    else
        log_error "Erreur lors du renouvellement des certificats SSL"
        return 1
    fi
}

# Fonction pour créer un alias personnalisé
create_custom_alias() {
    local app_name="$1"
    local custom_domain="$2"
    local app_type="$3"
    local port="$4"
    
    log "Création de l'alias personnalisé: $custom_domain"
    
    # Vérifier si l'alias existe déjà
    if ssh_exec "grep -q '$custom_domain' '$CADDY_CONFIG_DIR/Caddyfile'"; then
        log_warning "L'alias $custom_domain existe déjà"
        return 1
    fi
    
    # Créer la configuration pour l'alias personnalisé
    local alias_config="
# Configuration pour $app_name (alias: $custom_domain)
$custom_domain {
    # Redirection automatique vers HTTPS
    redir https://{host}{uri} permanent
}

https://$custom_domain {
    # Reverse proxy vers l'application
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
        Strict-Transport-Security \"max-age=31536000; includeSubDomains\"
    }
    
    # Compression
    encode gzip
    
    # Rate limiting
    rate_limit {
        zone custom {
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
}"
    
    # Ajouter la configuration au fichier Caddy
    ssh_exec "cat >> '$CADDY_CONFIG_DIR/Caddyfile' << 'EOF'
$alias_config
EOF"
    
    # Recharger Caddy
    if ssh_exec "caddy reload --config '$CADDY_CONFIG_DIR/Caddyfile'"; then
        log_success "Alias personnalisé $custom_domain créé avec succès"
        log "SSL automatique configuré pour https://$custom_domain"
        return 0
    else
        log_error "Erreur lors de la création de l'alias $custom_domain"
        return 1
    fi
}

# Fonction pour configurer un domaine externe
setup_external_domain() {
    local external_domain="$1"
    local app_name="$2"
    local port="$3"
    
    log "Configuration du domaine externe: $external_domain"
    
    # Vérifier que le domaine pointe vers le serveur
    local server_ip=$(ssh_exec "curl -s ifconfig.me")
    local domain_ip=$(dig +short "$external_domain" | tail -n1)
    
    if [ "$domain_ip" != "$server_ip" ]; then
        log_warning "Le domaine $external_domain ne pointe pas vers ce serveur ($server_ip)"
        log "IP du domaine: $domain_ip"
        log "IP du serveur: $server_ip"
        log "Veuillez configurer le DNS pour pointer vers ce serveur"
    fi
    
    # Créer la configuration pour le domaine externe
    local external_config="
# Configuration pour $app_name (domaine externe: $external_domain)
$external_domain {
    # Redirection automatique vers HTTPS
    redir https://{host}{uri} permanent
}

https://$external_domain {
    # Reverse proxy vers l'application
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
        Strict-Transport-Security \"max-age=31536000; includeSubDomains\"
    }
    
    # Compression
    encode gzip
    
    # Rate limiting
    rate_limit {
        zone external {
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
}"
    
    # Ajouter la configuration au fichier Caddy
    ssh_exec "cat >> '$CADDY_CONFIG_DIR/Caddyfile' << 'EOF'
$external_config
EOF"
    
    # Recharger Caddy
    if ssh_exec "caddy reload --config '$CADDY_CONFIG_DIR/Caddyfile'"; then
        log_success "Domaine externe $external_domain configuré avec succès"
        log "SSL automatique configuré pour https://$external_domain"
        return 0
    else
        log_error "Erreur lors de la configuration du domaine externe $external_domain"
        return 1
    fi
}

# Fonction pour créer un script de déploiement avec SSL automatique
create_ssl_deploy_script() {
    log "Création du script de déploiement avec SSL automatique"
    
    cat > ssl-deploy.sh << 'EOF'
#!/bin/bash

# Script de déploiement avec SSL automatique
# Usage: ./ssl-deploy.sh <app_name> <app_type> [port] [custom_domain]

set -e

APP_NAME="$1"
APP_TYPE="$2"
PORT="${3:-3000}"
CUSTOM_DOMAIN="$4"

if [ -z "$APP_NAME" ] || [ -z "$APP_TYPE" ]; then
    echo "Usage: $0 <app_name> <app_type> [port] [custom_domain]"
    echo "Exemples:"
    echo "  $0 mon-app static"
    echo "  $0 mon-api dynamic 3000"
    echo "  $0 mon-app static 8080 app.mondomaine.com"
    exit 1
fi

# Déployer l'application
echo "Déploiement de l'application $APP_NAME..."
./deploy-docker.sh deploy "examples/${APP_TYPE}-app.json"

# Créer le sous-domaine automatique
echo "Création du sous-domaine automatique..."
./caddy-manager.sh create-subdomain "$APP_NAME" "$APP_TYPE" "$PORT"

# Si un domaine personnalisé est fourni, le configurer
if [ ! -z "$CUSTOM_DOMAIN" ]; then
    echo "Configuration du domaine personnalisé $CUSTOM_DOMAIN..."
    ./caddy-manager.sh create-alias "$APP_NAME" "$CUSTOM_DOMAIN" "$APP_TYPE" "$PORT"
fi

echo "Déploiement terminé avec SSL automatique!"
echo "Application accessible sur: https://${APP_NAME}.qiwiiz.space"
if [ ! -z "$CUSTOM_DOMAIN" ]; then
    echo "Et aussi sur: https://$CUSTOM_DOMAIN"
fi
EOF
    
    chmod +x ssl-deploy.sh
    log_success "Script ssl-deploy.sh créé"
}

# Fonction d'aide
show_help() {
    echo "Gestionnaire Caddy pour qiwiiz.space"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  create-subdomain <app_name> <app_type> [port]     Créer un sous-domaine automatique"
    echo "  remove-subdomain <app_name>                       Supprimer un sous-domaine"
    echo "  list-subdomains                                   Lister tous les sous-domaines"
    echo "  check-ssl <app_name>                              Vérifier le statut SSL"
    echo "  renew-certificates                                Renouveler tous les certificats"
    echo "  create-alias <app_name> <domain> <type> [port]   Créer un alias personnalisé"
    echo "  setup-external <domain> <app_name> [port]         Configurer un domaine externe"
    echo "  create-ssl-script                                Créer le script de déploiement SSL"
    echo "  help                                              Afficher cette aide"
    echo ""
    echo "Exemples:"
    echo "  $0 create-subdomain mon-app static"
    echo "  $0 create-subdomain mon-api dynamic 3000"
    echo "  $0 create-alias mon-app app.mondomaine.com static"
    echo "  $0 setup-external mondomaine.com mon-app 3000"
}

# Point d'entrée principal
main() {
    case "${1:-help}" in
        "create-subdomain")
            create_subdomain "$2" "$3" "$4"
            ;;
        "remove-subdomain")
            remove_subdomain "$2"
            ;;
        "list-subdomains")
            list_subdomains
            ;;
        "check-ssl")
            check_ssl_status "$2"
            ;;
        "renew-certificates")
            renew_all_certificates
            ;;
        "create-alias")
            create_custom_alias "$2" "$3" "$4" "$5"
            ;;
        "setup-external")
            setup_external_domain "$2" "$3" "$4"
            ;;
        "create-ssl-script")
            create_ssl_deploy_script
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
    
    if ! command -v dig &> /dev/null; then
        missing_deps+=("dnsutils")
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
