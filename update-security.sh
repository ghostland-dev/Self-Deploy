#!/bin/bash

# Script de mise à jour de sécurité pour qiwiiz.space
# Applique les corrections de sécurité recommandées

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

# Fonction pour mettre à jour le système
update_system() {
    log "Mise à jour du système..."
    
    apt update
    apt upgrade -y
    apt autoremove -y
    apt autoclean
    
    log_success "Système mis à jour"
}

# Fonction pour renforcer la configuration SSH
harden_ssh() {
    log "Renforcement de la configuration SSH..."
    
    # Sauvegarder la configuration actuelle
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)
    
    # Configuration SSH sécurisée
    cat > /etc/ssh/sshd_config << 'EOF'
# Configuration SSH sécurisée pour qiwiiz.space

# Port SSH (garder le port par défaut pour éviter la détection)
Port 22

# Protocole SSH
Protocol 2

# Authentification
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

# Configuration des utilisateurs
AllowUsers qiwiiz
DenyUsers root

# Configuration des connexions
MaxAuthTries 3
MaxSessions 10
LoginGraceTime 30

# Configuration des timeouts
ClientAliveInterval 300
ClientAliveCountMax 2

# Configuration des logs
SyslogFacility AUTH
LogLevel INFO

# Configuration de sécurité
X11Forwarding no
X11DisplayOffset 10
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes

# Configuration des ciphers
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,hmac-sha2-256,hmac-sha2-512
KexAlgorithms curve25519-sha256@libssh.org,ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521

# Configuration des hosts
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Configuration des permissions
StrictModes yes
IgnoreRhosts yes
HostbasedAuthentication no
RhostsRSAAuthentication no

# Configuration des tunnels
AllowTcpForwarding no
AllowStreamLocalForwarding no
GatewayPorts no
PermitTunnel no

# Configuration des agents
AllowAgentForwarding no
PermitUserEnvironment no
Compression no
EOF
    
    # Redémarrer SSH
    systemctl restart ssh
    
    log_success "Configuration SSH renforcée"
}

# Fonction pour configurer les limites de ressources
configure_resource_limits() {
    log "Configuration des limites de ressources..."
    
    # Configuration des limites système
    cat >> /etc/security/limits.conf << 'EOF'

# Limites pour qiwiiz
qiwiiz soft nofile 65536
qiwiiz hard nofile 65536
qiwiiz soft nproc 32768
qiwiiz hard nproc 32768

# Limites pour www-data
www-data soft nofile 65536
www-data hard nofile 65536
www-data soft nproc 32768
www-data hard nproc 32768
EOF
    
    # Configuration des limites système
    cat >> /etc/sysctl.conf << 'EOF'

# Configuration de sécurité réseau
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_rfc1337 = 1

# Configuration de sécurité IPv6
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Configuration de sécurité mémoire
kernel.exec-shield = 1
kernel.randomize_va_space = 2
EOF
    
    # Appliquer les modifications
    sysctl -p
    
    log_success "Limites de ressources configurées"
}

# Fonction pour configurer les règles de pare-feu avancées
configure_advanced_firewall() {
    log "Configuration du pare-feu avancé..."
    
    # Règles UFW avancées
    ufw --force reset
    ufw --force enable
    
    # Règles de base
    ufw default deny incoming
    ufw default allow outgoing
    
    # Règles spécifiques
    ufw allow ssh
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # Règles pour les applications Docker
    ufw allow 3000:5000/tcp
    ufw allow 8080/tcp
    
    # Règles de protection contre les attaques
    ufw limit ssh
    ufw deny 23/tcp    # Telnet
    ufw deny 21/tcp    # FTP
    ufw deny 25/tcp    # SMTP
    ufw deny 110/tcp   # POP3
    ufw deny 143/tcp   # IMAP
    ufw deny 993/tcp   # IMAPS
    ufw deny 995/tcp   # POP3S
    
    log_success "Pare-feu avancé configuré"
}

# Fonction pour configurer fail2ban avancé
configure_advanced_fail2ban() {
    log "Configuration de fail2ban avancé..."
    
    # Configuration fail2ban avancée
    cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
ignoreip = 127.0.0.1/8 ::1
backend = systemd

[caddy-http-auth]
enabled = true
filter = caddy-http-auth
action = iptables-multiport[name=CaddyAuth, port="http,https", protocol=tcp]
logpath = /var/log/caddy/error.log
maxretry = 5
bantime = 7200

[caddy-rate-limit]
enabled = true
filter = caddy-rate-limit
action = iptables-multiport[name=CaddyRateLimit, port="http,https", protocol=tcp]
logpath = /var/log/caddy/access.log
maxretry = 10
bantime = 1800

[ssh]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600

[ssh-ddos]
enabled = true
port = ssh
filter = sshd-ddos
logpath = /var/log/auth.log
maxretry = 6
bantime = 7200

[docker]
enabled = true
filter = docker
action = iptables-multiport[name=Docker, port="http,https", protocol=tcp]
logpath = /var/log/syslog
maxretry = 5
bantime = 3600
EOF
    
    # Créer les filtres personnalisés
    cat > /etc/fail2ban/filter.d/caddy-http-auth.conf << 'EOF'
[Definition]
failregex = ^<HOST> - .* ".*" 401 .*$
            ^<HOST> - .* ".*" 403 .*$
ignoreregex =
EOF
    
    cat > /etc/fail2ban/filter.d/caddy-rate-limit.conf << 'EOF'
[Definition]
failregex = ^<HOST> - .* ".*" 429 .*$
ignoreregex =
EOF
    
    cat > /etc/fail2ban/filter.d/docker.conf << 'EOF'
[Definition]
failregex = ^.*docker.*<HOST>.*error.*$
            ^.*docker.*<HOST>.*failed.*$
ignoreregex =
EOF
    
    # Redémarrer fail2ban
    systemctl restart fail2ban
    
    log_success "Fail2ban avancé configuré"
}

# Fonction pour configurer les logs avancés
configure_advanced_logging() {
    log "Configuration des logs avancés..."
    
    # Configuration rsyslog avancée
    cat > /etc/rsyslog.d/50-security.conf << 'EOF'
# Logs de sécurité
auth,authpriv.*                 /var/log/auth.log
*.*;auth,authpriv.none          -/var/log/syslog
kern.*                          -/var/log/kern.log
mail.*                          -/var/log/mail.log
mail.err                        /var/log/mail.err
*.emerg                         :omusrmsg:*
uucp,news.crit                  -/var/log/spooler
local7.*                        -/var/log/boot.log

# Logs Docker
:programname, isequal, "docker" /var/log/docker.log
& stop

# Logs Caddy
:programname, isequal, "caddy" /var/log/caddy.log
& stop
EOF
    
    # Configuration logrotate
    cat > /etc/logrotate.d/qiwiiz-security << 'EOF'
/var/log/auth.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 640 root adm
}

/var/log/syslog {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 640 root adm
}

/var/log/caddy/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 640 caddy caddy
}

/var/log/deploy/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 640 qiwiiz qiwiiz
}
EOF
    
    # Redémarrer rsyslog
    systemctl restart rsyslog
    
    log_success "Logs avancés configurés"
}

# Fonction pour configurer la surveillance des fichiers
configure_file_monitoring() {
    log "Configuration de la surveillance des fichiers..."
    
    # Installation d'AIDE (Advanced Intrusion Detection Environment)
    apt install -y aide
    
    # Initialisation de la base de données AIDE
    aide --init
    mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
    
    # Configuration du cron pour AIDE
    (crontab -l 2>/dev/null; echo "0 2 * * * /usr/bin/aide --check") | crontab -
    
    log_success "Surveillance des fichiers configurée"
}

# Fonction pour configurer la surveillance des processus
configure_process_monitoring() {
    log "Configuration de la surveillance des processus..."
    
    # Installation de psad (Port Scan Attack Detector)
    apt install -y psad
    
    # Configuration de psad
    sed -i 's/ENABLE_AUTO_IDS.*/ENABLE_AUTO_IDS = Y;/' /etc/psad/psad.conf
    sed -i 's/AUTO_IDS_DANGER_LEVEL.*/AUTO_IDS_DANGER_LEVEL = 3;/' /etc/psad/psad.conf
    
    # Démarrer psad
    systemctl enable psad
    systemctl start psad
    
    log_success "Surveillance des processus configurée"
}

# Fonction pour configurer la surveillance des réseaux
configure_network_monitoring() {
    log "Configuration de la surveillance des réseaux..."
    
    # Installation de nethogs pour surveiller l'utilisation réseau
    apt install -y nethogs
    
    # Installation de iftop pour surveiller le trafic réseau
    apt install -y iftop
    
    # Configuration du monitoring réseau
    cat > /usr/local/bin/network-monitor.sh << 'EOF'
#!/bin/bash

# Script de monitoring réseau
LOG_FILE="/var/log/deploy/network-monitor.log"

echo "$(date): Surveillance réseau" >> $LOG_FILE

# Vérifier les connexions suspectes
netstat -tuln | grep -E ':(23|21|25|110|143|993|995)' >> $LOG_FILE

# Vérifier l'utilisation réseau
nethogs -t -d 1 | head -20 >> $LOG_FILE

# Vérifier les connexions établies
ss -tuln | wc -l >> $LOG_FILE
EOF
    
    chmod +x /usr/local/bin/network-monitor.sh
    
    # Ajouter au crontab
    (crontab -l 2>/dev/null; echo "*/10 * * * * /usr/local/bin/network-monitor.sh") | crontab -
    
    log_success "Surveillance des réseaux configurée"
}

# Fonction pour configurer les alertes de sécurité
configure_security_alerts() {
    log "Configuration des alertes de sécurité..."
    
    # Script d'alerte de sécurité
    cat > /usr/local/bin/security-alert.sh << 'EOF'
#!/bin/bash

# Script d'alerte de sécurité
ALERT_EMAIL="admin@qiwiiz.space"
LOG_FILE="/var/log/deploy/security-alerts.log"

# Fonction d'alerte
send_alert() {
    local message="$1"
    echo "$(date): ALERTE SÉCURITÉ - $message" >> $LOG_FILE
    
    # Envoyer par email si mail est configuré
    if command -v mail &> /dev/null; then
        echo "$message" | mail -s "Alerte Sécurité qiwiiz.space" $ALERT_EMAIL
    fi
    
    # Envoyer par webhook si configuré
    if [ ! -z "$WEBHOOK_URL" ]; then
        curl -X POST -H "Content-Type: application/json" \
             -d "{\"text\":\"🚨 Alerte Sécurité qiwiiz.space: $message\"}" \
             "$WEBHOOK_URL"
    fi
}

# Vérifier les tentatives de connexion SSH échouées
FAILED_SSH=$(grep "Failed password" /var/log/auth.log | tail -10 | wc -l)
if [ $FAILED_SSH -gt 5 ]; then
    send_alert "Tentatives de connexion SSH échouées: $FAILED_SSH"
fi

# Vérifier les attaques par force brute
BRUTE_FORCE=$(fail2ban-client status ssh | grep "Currently banned" | awk '{print $4}')
if [ ! -z "$BRUTE_FORCE" ] && [ $BRUTE_FORCE -gt 0 ]; then
    send_alert "Attaques par force brute détectées: $BRUTE_FORCE IPs bannies"
fi

# Vérifier l'utilisation disque
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 90 ]; then
    send_alert "Espace disque critique: ${DISK_USAGE}%"
fi

# Vérifier l'utilisation mémoire
MEMORY_USAGE=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
if [ $MEMORY_USAGE -gt 95 ]; then
    send_alert "Utilisation mémoire critique: ${MEMORY_USAGE}%"
fi
EOF
    
    chmod +x /usr/local/bin/security-alert.sh
    
    # Ajouter au crontab
    (crontab -l 2>/dev/null; echo "*/15 * * * * /usr/local/bin/security-alert.sh") | crontab -
    
    log_success "Alertes de sécurité configurées"
}

# Fonction principale
main() {
    log "Démarrage de la mise à jour de sécurité..."
    
    # Vérifier que le script est exécuté en tant que root
    if [ "$EUID" -ne 0 ]; then
        log_error "Ce script doit être exécuté en tant que root"
        exit 1
    fi
    
    # Appliquer toutes les mises à jour de sécurité
    update_system
    harden_ssh
    configure_resource_limits
    configure_advanced_firewall
    configure_advanced_fail2ban
    configure_advanced_logging
    configure_file_monitoring
    configure_process_monitoring
    configure_network_monitoring
    configure_security_alerts
    
    log_success "Mise à jour de sécurité terminée avec succès!"
    log "Le serveur qiwiiz.space est maintenant sécurisé"
    log "Exécutez 'make security-check' pour vérifier la configuration"
}

# Exécuter la fonction principale
main "$@"
