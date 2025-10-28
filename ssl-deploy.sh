#!/bin/bash

# Script de déploiement avec SSL automatique et alias
# Configuration pour qiwiiz.space

set -e

# Configuration
SSH_USER="qiwiiz"
SSH_HOST="51.159.6.66"
SSH_PASSWORD="changeme"
DOMAIN="qiwiiz.space"

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✓${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ✗${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠${NC} $1"
}

# Fonction pour créer une configuration de déploiement avec SSL
create_ssl_deploy_config() {
    local app_name="$1"
    local app_type="$2"
    local port="$3"
    local custom_domain="$4"
    
    log "Création de la configuration de déploiement SSL pour $app_name"
    
    # Créer le fichier de configuration
    local config_file="ssl-deploy-${app_name}.json"
    
    cat > "$config_file" << EOF
{
  "app_name": "$app_name",
  "app_type": "$app_type",
  "build_dir": "./",
  "domain": "$app_name.$DOMAIN",
  "framework": "$app_type",
  "port": $port,
  "ssl": {
    "enabled": true,
    "auto_renew": true,
    "subdomain": "$app_name.$DOMAIN"
EOF

    if [ ! -z "$custom_domain" ]; then
        cat >> "$config_file" << EOF
,
    "custom_domain": "$custom_domain"
EOF
    fi
    
    cat >> "$config_file" << EOF
  },
  "caddy": {
    "enabled": true,
    "reverse_proxy": true,
    "security_headers": true,
    "compression": true,
    "rate_limiting": true
  }
}
EOF
    
    log_success "Configuration SSL créée: $config_file"
    echo "$config_file"
}

# Fonction pour déployer avec SSL automatique
deploy_with_ssl() {
    local app_name="$1"
    local app_type="$2"
    local port="$3"
    local custom_domain="$4"
    local build_dir="$5"
    
    log "Déploiement avec SSL automatique: $app_name"
    
    # Créer la configuration SSL
    local config_file=$(create_ssl_deploy_config "$app_name" "$app_type" "$port" "$custom_domain")
    
    # Déployer l'application
    log "Déploiement de l'application..."
    ./deploy-docker.sh deploy "$config_file"
    
    # Créer le sous-domaine automatique
    log "Création du sous-domaine automatique..."
    ./caddy-manager.sh create-subdomain "$app_name" "$app_type" "$port"
    
    # Si un domaine personnalisé est fourni, le configurer
    if [ ! -z "$custom_domain" ]; then
        log "Configuration du domaine personnalisé $custom_domain..."
        ./caddy-manager.sh create-alias "$app_name" "$custom_domain" "$app_type" "$port"
    fi
    
    # Vérifier le statut SSL
    log "Vérification du statut SSL..."
    ./caddy-manager.sh check-ssl "$app_name"
    
    log_success "Déploiement terminé avec SSL automatique!"
    log "Application accessible sur: https://${app_name}.$DOMAIN"
    if [ ! -z "$custom_domain" ]; then
        log "Et aussi sur: https://$custom_domain"
    fi
    
    # Nettoyer le fichier de configuration temporaire
    rm -f "$config_file"
}

# Fonction pour créer un déploiement rapide
quick_deploy() {
    local app_name="$1"
    local app_type="$2"
    local port="$3"
    
    log "Déploiement rapide: $app_name"
    
    # Créer un répertoire de build temporaire
    local temp_build_dir="/tmp/quick-deploy-${app_name}-$$"
    mkdir -p "$temp_build_dir"
    
    # Créer un fichier de test simple
    case "$app_type" in
        "static")
            cat > "$temp_build_dir/index.html" << EOF
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$app_name - qiwiiz.space</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            text-align: center;
            max-width: 600px;
            padding: 2rem;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 20px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
        }
        h1 {
            font-size: 3rem;
            margin-bottom: 1rem;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        .status {
            background: rgba(76, 175, 80, 0.2);
            border: 1px solid rgba(76, 175, 80, 0.3);
            border-radius: 10px;
            padding: 1rem;
            margin: 1rem 0;
        }
        .info {
            background: rgba(33, 150, 243, 0.2);
            border: 1px solid rgba(33, 150, 243, 0.3);
            border-radius: 10px;
            padding: 1rem;
            margin: 1rem 0;
        }
        .tech-stack {
            display: flex;
            justify-content: center;
            gap: 1rem;
            margin-top: 2rem;
            flex-wrap: wrap;
        }
        .tech {
            background: rgba(255, 255, 255, 0.2);
            padding: 0.5rem 1rem;
            border-radius: 20px;
            font-size: 0.9rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 $app_name</h1>
        <div class="status">
            <h2>✅ Application Déployée</h2>
            <p>Déployée automatiquement sur qiwiiz.space avec SSL</p>
        </div>
        <div class="info">
            <h3>📊 Informations</h3>
            <p><strong>Type:</strong> $app_type</p>
            <p><strong>Domaine:</strong> $app_name.$DOMAIN</p>
            <p><strong>SSL:</strong> Automatique avec Let's Encrypt</p>
            <p><strong>Statut:</strong> Opérationnel</p>
        </div>
        <div class="tech-stack">
            <span class="tech">🐳 Docker</span>
            <span class="tech">🌐 Caddy</span>
            <span class="tech">🔒 SSL</span>
            <span class="tech">🛡️ Sécurité</span>
            <span class="tech">📈 Monitoring</span>
        </div>
    </div>
</body>
</html>
EOF
            ;;
        "dynamic")
            case "$app_type" in
                "node")
                    cat > "$temp_build_dir/package.json" << EOF
{
  "name": "$app_name",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.0"
  }
}
EOF
                    cat > "$temp_build_dir/server.js" << EOF
const express = require('express');
const app = express();
const port = process.env.PORT || $port;

app.get('/', (req, res) => {
  res.json({ 
    message: 'Application $app_name déployée sur qiwiiz.space!',
    domain: '$app_name.$DOMAIN',
    ssl: 'Automatique avec Let\'s Encrypt',
    timestamp: new Date().toISOString()
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

app.listen(port, () => {
  console.log(\`Serveur \$app_name démarré sur le port \${port}\`);
});
EOF
                    ;;
                "python")
                    cat > "$temp_build_dir/requirements.txt" << EOF
Flask==2.3.0
gunicorn==21.2.0
EOF
                    cat > "$temp_build_dir/app.py" << EOF
from flask import Flask, jsonify
import os
from datetime import datetime

app = Flask(__name__)

@app.route('/')
def hello():
    return jsonify({
        'message': 'Application $app_name déployée sur qiwiiz.space!',
        'domain': '$app_name.$DOMAIN',
        'ssl': 'Automatique avec Let\'s Encrypt',
        'timestamp': datetime.now().isoformat()
    })

@app.route('/health')
def health():
    return jsonify({'status': 'OK', 'timestamp': datetime.now().isoformat()})

if __name__ == '__main__':
    port = int(os.environ.get('PORT', $port))
    app.run(host='0.0.0.0', port=port)
EOF
                    ;;
            esac
            ;;
    esac
    
    # Déployer avec SSL
    deploy_with_ssl "$app_name" "$app_type" "$port" "" "$temp_build_dir"
    
    # Nettoyer
    rm -rf "$temp_build_dir"
}

# Fonction pour créer un alias pour un domaine existant
create_domain_alias() {
    local app_name="$1"
    local external_domain="$2"
    local port="$3"
    
    log "Création d'un alias pour le domaine externe: $external_domain"
    
    # Vérifier que l'application existe
    if ! ./caddy-manager.sh list-subdomains | grep -q "$app_name.$DOMAIN"; then
        log_error "L'application $app_name n'existe pas"
        return 1
    fi
    
    # Configurer le domaine externe
    ./caddy-manager.sh setup-external "$external_domain" "$app_name" "$port"
    
    log_success "Alias créé pour $external_domain"
}

# Fonction pour lister tous les déploiements SSL
list_ssl_deployments() {
    log "Liste des déploiements SSL:"
    
    ./caddy-manager.sh list-subdomains
    
    log "Statut des certificats SSL:"
    ./caddy-manager.sh renew-certificates
}

# Fonction pour renouveler tous les certificats SSL
renew_all_ssl() {
    log "Renouvellement de tous les certificats SSL"
    
    ./caddy-manager.sh renew-certificates
    
    log_success "Tous les certificats SSL ont été renouvelés"
}

# Fonction d'aide
show_help() {
    echo "Déploiement SSL automatique pour qiwiiz.space"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  deploy <app_name> <type> [port] [domain]     Déployer avec SSL automatique"
    echo "  quick-deploy <app_name> <type> [port]         Déploiement rapide avec app de test"
    echo "  create-alias <app_name> <domain> [port]      Créer un alias pour un domaine externe"
    echo "  list-ssl                                      Lister tous les déploiements SSL"
    echo "  renew-ssl                                     Renouveler tous les certificats SSL"
    echo "  help                                          Afficher cette aide"
    echo ""
    echo "Types d'applications:"
    echo "  static                                        Application statique (HTML/CSS/JS)"
    echo "  node                                          Application Node.js/Express"
    echo "  python                                        Application Python/Flask"
    echo "  php                                           Application PHP"
    echo ""
    echo "Exemples:"
    echo "  $0 deploy mon-app static"
    echo "  $0 deploy mon-api node 3000"
    echo "  $0 deploy mon-app static 8080 app.mondomaine.com"
    echo "  $0 quick-deploy test-app static"
    echo "  $0 create-alias mon-app mondomaine.com 3000"
}

# Point d'entrée principal
main() {
    case "${1:-help}" in
        "deploy")
            deploy_with_ssl "$2" "$3" "$4" "$5" "$6"
            ;;
        "quick-deploy")
            quick_deploy "$2" "$3" "$4"
            ;;
        "create-alias")
            create_domain_alias "$2" "$3" "$4"
            ;;
        "list-ssl")
            list_ssl_deployments
            ;;
        "renew-ssl")
            renew_all_ssl
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
    
    if [ ! -f "./deploy-docker.sh" ]; then
        log_error "Script deploy-docker.sh non trouvé"
        exit 1
    fi
    
    if [ ! -f "./caddy-manager.sh" ]; then
        log_error "Script caddy-manager.sh non trouvé"
        exit 1
    fi
    
    if ! command -v sshpass &> /dev/null; then
        missing_deps+=("sshpass")
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
