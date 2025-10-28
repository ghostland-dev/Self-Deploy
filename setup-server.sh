#!/bin/bash

# Script de configuration du serveur Ubuntu pour le déploiement
# Ce script doit être exécuté sur le serveur de destination

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
        nginx \
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
        git \
        curl \
        wget \
        unzip \
        jq \
        htop \
        ufw \
        fail2ban
    
    log_success "Dépendances système installées"
}

# Fonction pour configurer nginx
configure_nginx() {
    log "Configuration de nginx..."
    
    # Supprimer la configuration par défaut
    rm -f /etc/nginx/sites-enabled/default
    
    # Créer la configuration principale
    cat > /etc/nginx/nginx.conf << 'EOF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 1024;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;
    
    # Include site configurations
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF
    
    # Créer les répertoires nécessaires
    mkdir -p /var/www
    mkdir -p /etc/nginx/sites-available
    mkdir -p /etc/nginx/sites-enabled
    mkdir -p /etc/nginx/conf.d
    
    # Tester la configuration
    nginx -t
    
    # Démarrer et activer nginx
    systemctl enable nginx
    systemctl restart nginx
    
    log_success "Nginx configuré et démarré"
}

# Fonction pour configurer PHP-FPM
configure_php_fpm() {
    log "Configuration de PHP-FPM..."
    
    # Configurer PHP-FPM pour nginx
    sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php/*/fpm/php.ini
    
    # Redémarrer PHP-FPM
    systemctl enable php*-fpm
    systemctl restart php*-fpm
    
    log_success "PHP-FPM configuré"
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
    
    # Autoriser les ports pour les applications (3000-5000)
    ufw allow 3000:5000/tcp
    
    log_success "Pare-feu configuré"
}

# Fonction pour configurer fail2ban
configure_fail2ban() {
    log "Configuration de fail2ban..."
    
    # Créer la configuration pour nginx
    cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[nginx-http-auth]
enabled = true

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
action = iptables-multiport[name=ReqLimit, port="http,https", protocol=tcp]
logpath = /var/log/nginx/error.log
maxretry = 10
EOF
    
    # Redémarrer fail2ban
    systemctl enable fail2ban
    systemctl restart fail2ban
    
    log_success "Fail2ban configuré"
}

# Fonction pour créer les utilisateurs et permissions
configure_users() {
    log "Configuration des utilisateurs et permissions..."
    
    # Créer le groupe www-data s'il n'existe pas
    groupadd -f www-data
    
    # Configurer les permissions pour /var/www
    chown -R www-data:www-data /var/www
    chmod -R 755 /var/www
    
    # Créer le répertoire de logs
    mkdir -p /var/log/deploy
    chown www-data:www-data /var/log/deploy
    
    log_success "Utilisateurs et permissions configurés"
}

# Fonction pour installer PM2 pour Node.js
install_pm2() {
    log "Installation de PM2..."
    
    npm install -g pm2
    
    # Configurer PM2 pour démarrer au boot
    pm2 startup
    pm2 save
    
    log_success "PM2 installé et configuré"
}

# Fonction pour configurer les certificats SSL (Let's Encrypt)
configure_ssl() {
    log "Installation de Certbot pour SSL..."
    
    apt install -y certbot python3-certbot-nginx
    
    log_success "Certbot installé (utilisez 'certbot --nginx' pour configurer SSL)"
}

# Fonction pour créer un script de monitoring
create_monitoring_script() {
    log "Création du script de monitoring..."
    
    cat > /usr/local/bin/monitor-deployments.sh << 'EOF'
#!/bin/bash

# Script de monitoring des déploiements

LOG_FILE="/var/log/deploy/monitor.log"
NGINX_STATUS=$(systemctl is-active nginx)
PHP_FPM_STATUS=$(systemctl is-active php*-fpm)

echo "$(date): Nginx: $NGINX_STATUS, PHP-FPM: $PHP_FPM_STATUS" >> $LOG_FILE

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

echo "$(date): Nettoyage terminé" >> /var/log/deploy/cleanup.log
EOF
    
    chmod +x /usr/local/bin/cleanup-deployments.sh
    
    # Ajouter au crontab (exécution quotidienne à 2h du matin)
    (crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/cleanup-deployments.sh") | crontab -
    
    log_success "Script de nettoyage créé"
}

# Fonction principale
main() {
    log "Démarrage de la configuration du serveur de déploiement..."
    
    # Vérifier que le script est exécuté en tant que root
    if [ "$EUID" -ne 0 ]; then
        log_error "Ce script doit être exécuté en tant que root"
        exit 1
    fi
    
    # Installer les dépendances
    install_system_dependencies
    
    # Configurer les services
    configure_nginx
    configure_php_fpm
    configure_firewall
    configure_fail2ban
    configure_users
    
    # Installer les outils supplémentaires
    install_pm2
    configure_ssl
    
    # Créer les scripts utilitaires
    create_monitoring_script
    create_cleanup_script
    
    log_success "Configuration du serveur terminée avec succès!"
    log "Le serveur est maintenant prêt pour les déploiements"
    log "Vous pouvez maintenant utiliser le script de déploiement depuis votre machine locale"
}

# Exécuter la fonction principale
main "$@"
