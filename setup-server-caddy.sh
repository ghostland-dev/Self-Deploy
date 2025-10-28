#!/bin/bash

# Script de configuration du serveur Ubuntu avec Caddy et Docker
# Configuration pour qiwiiz.space

set -e

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

# Fonction pour installer les dépendances système
install_system_dependencies() {
    log "Mise à jour du système..."
    apt update && apt upgrade -y
    
    log "Installation des dépendances de base..."
    apt install -y \
        curl \
        wget \
        git \
        unzip \
        jq \
        htop \
        ufw \
        fail2ban \
        docker.io \
        docker-compose \
        nodejs \
        npm \
        python3 \
        python3-pip \
        python3-venv \
        php \
        php-fpm \
        php-cli \
        php-mysql \
        php-xml \
        php-mbstring \
        php-curl \
        php-zip \
        composer \
        caddy
    
    log_success "Dépendances système installées"
}

# Fonction pour configurer Docker
configure_docker() {
    log "Configuration de Docker..."
    
    # Ajouter l'utilisateur au groupe docker
    usermod -aG docker qiwiiz
    
    # Configurer Docker pour démarrer au boot
    systemctl enable docker
    systemctl start docker
    
    # Créer le réseau Caddy
    docker network create caddy-network 2>/dev/null || true
    
    log_success "Docker configuré"
}

# Fonction pour configurer Caddy
configure_caddy() {
    log "Configuration de Caddy..."
    
    # Créer les répertoires nécessaires
    mkdir -p /etc/caddy
    mkdir -p /var/lib/caddy
    mkdir -p /var/log/caddy
    
    # Créer la configuration Caddy de base
    cat > /etc/caddy/Caddyfile << 'EOF'
# Configuration globale
{
    # Configuration de sécurité
    security {
        hide_versions
    }
    
    # Logs
    log {
        output file /var/log/caddy/access.log {
            roll_size 100mb
            roll_keep 5
            roll_keep_for 720h
        }
        format json
    }
    
    # Configuration des erreurs
    errors {
        log {
            output file /var/log/caddy/error.log {
                roll_size 100mb
                roll_keep 5
                roll_keep_for 720h
            }
        }
    }
}

# Configuration par défaut pour qiwiiz.space
qiwiiz.space {
    # Rediriger HTTP vers HTTPS
    redir https://{host}{uri} permanent
}

# Configuration HTTPS par défaut
https://qiwiiz.space {
    # Page d'accueil par défaut
    root * /var/www/html
    file_server
    
    # Headers de sécurité
    header {
        X-Content-Type-Options nosniff
        X-Frame-Options DENY
        X-XSS-Protection "1; mode=block"
        Referrer-Policy strict-origin-when-cross-origin
        Permissions-Policy "geolocation=(), microphone=(), camera=()"
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
    }
    
    # Compression
    encode gzip
    
    # Cache pour les assets statiques
    @static {
        path *.css *.js *.png *.jpg *.jpeg *.gif *.ico *.svg *.woff *.woff2
    }
    header @static Cache-Control "public, max-age=31536000"
    
    # Rate limiting
    rate_limit {
        zone static {
            key {remote_host}
            events 100
            window 1m
        }
    }
}
EOF
    
    # Configurer les permissions
    chown -R caddy:caddy /var/lib/caddy
    chown -R caddy:caddy /var/log/caddy
    
    # Démarrer et activer Caddy
    systemctl enable caddy
    systemctl start caddy
    
    log_success "Caddy configuré et démarré"
}

# Fonction pour configurer le pare-feu
configure_firewall() {
    log "Configuration du pare-feu..."
    
    # Activer UFW
    ufw --force enable
    
    # Autoriser SSH
    ufw allow ssh
    
    # Autoriser HTTP et HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # Autoriser les ports pour les applications Docker (3000-5000)
    ufw allow 3000:5000/tcp
    
    # Autoriser les ports Docker
    ufw allow 8080/tcp
    
    log_success "Pare-feu configuré"
}

# Fonction pour configurer fail2ban
configure_fail2ban() {
    log "Configuration de fail2ban..."
    
    # Créer la configuration pour Caddy
    cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[caddy-http-auth]
enabled = true
filter = caddy-http-auth
action = iptables-multiport[name=CaddyAuth, port="http,https", protocol=tcp]
logpath = /var/log/caddy/error.log
maxretry = 5

[caddy-rate-limit]
enabled = true
filter = caddy-rate-limit
action = iptables-multiport[name=CaddyRateLimit, port="http,https", protocol=tcp]
logpath = /var/log/caddy/access.log
maxretry = 10
EOF
    
    # Créer les filtres personnalisés
    cat > /etc/fail2ban/filter.d/caddy-http-auth.conf << 'EOF'
[Definition]
failregex = ^<HOST> - .* ".*" 401 .*$
ignoreregex =
EOF
    
    cat > /etc/fail2ban/filter.d/caddy-rate-limit.conf << 'EOF'
[Definition]
failregex = ^<HOST> - .* ".*" 429 .*$
ignoreregex =
EOF
    
    # Redémarrer fail2ban
    systemctl enable fail2ban
    systemctl restart fail2ban
    
    log_success "Fail2ban configuré"
}

# Fonction pour créer les utilisateurs et permissions
configure_users() {
    log "Configuration des utilisateurs et permissions..."
    
    # Créer les répertoires nécessaires
    mkdir -p /home/qiwiiz/apps
    mkdir -p /home/qiwiiz/docker-compose
    mkdir -p /var/www/html
    
    # Configurer les permissions
    chown -R qiwiiz:qiwiiz /home/qiwiiz/apps
    chown -R qiwiiz:qiwiiz /home/qiwiiz/docker-compose
    chown -R www-data:www-data /var/www/html
    
    # Créer le répertoire de logs
    mkdir -p /var/log/deploy
    chown qiwiiz:qiwiiz /var/log/deploy
    
    log_success "Utilisateurs et permissions configurés"
}

# Fonction pour installer PM2 pour Node.js
install_pm2() {
    log "Installation de PM2..."
    
    npm install -g pm2
    
    # Configurer PM2 pour démarrer au boot
    sudo -u qiwiiz pm2 startup
    sudo -u qiwiiz pm2 save
    
    log_success "PM2 installé et configuré"
}

# Fonction pour créer un script de monitoring
create_monitoring_script() {
    log "Création du script de monitoring..."
    
    cat > /usr/local/bin/monitor-deployments.sh << 'EOF'
#!/bin/bash

# Script de monitoring des déploiements

LOG_FILE="/var/log/deploy/monitor.log"
CADDY_STATUS=$(systemctl is-active caddy)
DOCKER_STATUS=$(systemctl is-active docker)

echo "$(date): Caddy: $CADDY_STATUS, Docker: $DOCKER_STATUS" >> $LOG_FILE

# Vérifier l'espace disque
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "$(date): ATTENTION: Espace disque faible ($DISK_USAGE%)" >> $LOG_FILE
fi

# Vérifier la mémoire
MEMORY_USAGE=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
if [ $MEMORY_USAGE -gt 90 ]; then
    echo "$(date): ATTENTION: Utilisation mémoire élevée ($MEMORY_USAGE%)" >> $LOG_FILE
fi

# Vérifier les conteneurs Docker
CONTAINER_COUNT=$(docker ps -q | wc -l)
echo "$(date): Conteneurs Docker actifs: $CONTAINER_COUNT" >> $LOG_FILE

# Vérifier les certificats SSL
if command -v caddy &> /dev/null; then
    CERT_EXPIRY=$(caddy list-certificates 2>/dev/null | grep qiwiiz.space | awk '{print $3}')
    if [ ! -z "$CERT_EXPIRY" ]; then
        echo "$(date): Certificat SSL expire le: $CERT_EXPIRY" >> $LOG_FILE
    fi
fi
EOF
    
    chmod +x /usr/local/bin/monitor-deployments.sh
    
    # Ajouter au crontab
    (crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/monitor-deployments.sh") | crontab -
    
    log_success "Script de monitoring créé"
}

# Fonction pour créer un script de nettoyage
create_cleanup_script() {
    log "Création du script de nettoyage..."
    
    cat > /usr/local/bin/cleanup-deployments.sh << 'EOF'
#!/bin/bash

# Script de nettoyage des déploiements

BACKUP_DIR="/tmp/deploy-backups"
LOG_RETENTION_DAYS=30
BACKUP_RETENTION_DAYS=7

# Nettoyer les logs anciens
find /var/log -name "*.log" -mtime +$LOG_RETENTION_DAYS -delete

# Nettoyer les sauvegardes anciennes
if [ -d "$BACKUP_DIR" ]; then
    find "$BACKUP_DIR" -type d -mtime +$BACKUP_RETENTION_DAYS -exec rm -rf {} +
fi

# Nettoyer les fichiers temporaires
find /tmp -type f -mtime +1 -delete

# Nettoyer les images Docker inutilisées
docker system prune -f
docker image prune -f

echo "$(date): Nettoyage terminé" >> /var/log/deploy/cleanup.log
EOF
    
    chmod +x /usr/local/bin/cleanup-deployments.sh
    
    # Ajouter au crontab (exécution quotidienne à 2h du matin)
    (crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/cleanup-deployments.sh") | crontab -
    
    log_success "Script de nettoyage créé"
}

# Fonction pour créer la page d'accueil par défaut
create_default_page() {
    log "Création de la page d'accueil par défaut..."
    
    cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>qiwiiz.space - Serveur de Déploiement</title>
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
        <h1>🚀 qiwiiz.space</h1>
        <div class="status">
            <h2>✅ Serveur Opérationnel</h2>
            <p>Système de déploiement automatisé avec Caddy et Docker</p>
        </div>
        <div class="info">
            <h3>📊 Informations Système</h3>
            <p><strong>Serveur:</strong> Ubuntu avec Caddy + Docker</p>
            <p><strong>Domaine:</strong> qiwiiz.space</p>
            <p><strong>SSL:</strong> Automatique avec Let's Encrypt</p>
            <p><strong>Statut:</strong> Prêt pour les déploiements</p>
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
    
    log_success "Page d'accueil créée"
}

# Fonction principale
main() {
    log "Démarrage de la configuration du serveur qiwiiz.space..."
    
    # Vérifier que le script est exécuté en tant que root
    if [ "$EUID" -ne 0 ]; then
        log_error "Ce script doit être exécuté en tant que root"
        exit 1
    fi
    
    # Installer les dépendances
    install_system_dependencies
    
    # Configurer les services
    configure_docker
    configure_caddy
    configure_firewall
    configure_fail2ban
    configure_users
    
    # Installer les outils supplémentaires
    install_pm2
    
    # Créer les scripts utilitaires
    create_monitoring_script
    create_cleanup_script
    
    # Créer la page d'accueil
    create_default_page
    
    log_success "Configuration du serveur qiwiiz.space terminée avec succès!"
    log "Le serveur est maintenant prêt pour les déploiements avec Caddy et Docker"
    log "Accédez à https://qiwiiz.space pour voir la page d'accueil"
}

# Exécuter la fonction principale
main "$@"
