#!/bin/bash

# Script de vérification de sécurité pour qiwiiz.space
# Vérifie la configuration de sécurité du serveur

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

# Variables de sécurité
SECURITY_SCORE=0
TOTAL_CHECKS=0

# Fonction pour incrémenter le score
increment_score() {
    SECURITY_SCORE=$((SECURITY_SCORE + 1))
}

# Fonction pour vérifier le pare-feu
check_firewall() {
    log "Vérification du pare-feu..."
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if ufw status | grep -q "Status: active"; then
        log_success "Pare-feu UFW actif"
        increment_score
        
        # Vérifier les règles
        if ufw status | grep -q "22/tcp"; then
            log_success "Port SSH (22) autorisé"
            increment_score
        else
            log_warning "Port SSH (22) non autorisé"
        fi
        
        if ufw status | grep -q "80/tcp"; then
            log_success "Port HTTP (80) autorisé"
            increment_score
        else
            log_warning "Port HTTP (80) non autorisé"
        fi
        
        if ufw status | grep -q "443/tcp"; then
            log_success "Port HTTPS (443) autorisé"
            increment_score
        else
            log_warning "Port HTTPS (443) non autorisé"
        fi
    else
        log_error "Pare-feu UFW inactif"
    fi
}

# Fonction pour vérifier fail2ban
check_fail2ban() {
    log "Vérification de fail2ban..."
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if systemctl is-active --quiet fail2ban; then
        log_success "Fail2ban actif"
        increment_score
        
        # Vérifier les prisons
        if fail2ban-client status | grep -q "caddy-http-auth"; then
            log_success "Prison caddy-http-auth configurée"
            increment_score
        else
            log_warning "Prison caddy-http-auth non configurée"
        fi
        
        if fail2ban-client status | grep -q "caddy-rate-limit"; then
            log_success "Prison caddy-rate-limit configurée"
            increment_score
        else
            log_warning "Prison caddy-rate-limit non configurée"
        fi
    else
        log_error "Fail2ban inactif"
    fi
}

# Fonction pour vérifier les certificats SSL
check_ssl() {
    log "Vérification des certificats SSL..."
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if command -v caddy &> /dev/null; then
        if caddy list-certificates | grep -q "qiwiiz.space"; then
            log_success "Certificat SSL pour qiwiiz.space présent"
            increment_score
            
            # Vérifier la date d'expiration
            CERT_EXPIRY=$(caddy list-certificates | grep "qiwiiz.space" | awk '{print $3}')
            if [ ! -z "$CERT_EXPIRY" ]; then
                log_success "Certificat SSL valide jusqu'au: $CERT_EXPIRY"
                increment_score
            fi
        else
            log_warning "Certificat SSL pour qiwiiz.space non trouvé"
        fi
    else
        log_error "Caddy non installé"
    fi
}

# Fonction pour vérifier les services
check_services() {
    log "Vérification des services..."
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    # Vérifier Caddy
    if systemctl is-active --quiet caddy; then
        log_success "Service Caddy actif"
        increment_score
    else
        log_error "Service Caddy inactif"
    fi
    
    # Vérifier Docker
    if systemctl is-active --quiet docker; then
        log_success "Service Docker actif"
        increment_score
    else
        log_error "Service Docker inactif"
    fi
    
    # Vérifier SSH
    if systemctl is-active --quiet ssh; then
        log_success "Service SSH actif"
        increment_score
    else
        log_error "Service SSH inactif"
    fi
}

# Fonction pour vérifier les permissions
check_permissions() {
    log "Vérification des permissions..."
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    # Vérifier les permissions des répertoires critiques
    if [ -d "/home/qiwiiz/apps" ]; then
        OWNER=$(stat -c '%U' /home/qiwiiz/apps)
        if [ "$OWNER" = "qiwiiz" ]; then
            log_success "Permissions correctes pour /home/qiwiiz/apps"
            increment_score
        else
            log_warning "Permissions incorrectes pour /home/qiwiiz/apps (propriétaire: $OWNER)"
        fi
    else
        log_warning "Répertoire /home/qiwiiz/apps non trouvé"
    fi
    
    # Vérifier les permissions des logs
    if [ -d "/var/log/caddy" ]; then
        OWNER=$(stat -c '%U' /var/log/caddy)
        if [ "$OWNER" = "caddy" ]; then
            log_success "Permissions correctes pour /var/log/caddy"
            increment_score
        else
            log_warning "Permissions incorrectes pour /var/log/caddy (propriétaire: $OWNER)"
        fi
    else
        log_warning "Répertoire /var/log/caddy non trouvé"
    fi
}

# Fonction pour vérifier les conteneurs Docker
check_docker_containers() {
    log "Vérification des conteneurs Docker..."
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    # Vérifier le réseau Caddy
    if docker network ls | grep -q "caddy-network"; then
        log_success "Réseau caddy-network présent"
        increment_score
    else
        log_warning "Réseau caddy-network non trouvé"
    fi
    
    # Vérifier les conteneurs en cours d'exécution
    CONTAINER_COUNT=$(docker ps -q | wc -l)
    if [ $CONTAINER_COUNT -gt 0 ]; then
        log_success "$CONTAINER_COUNT conteneur(s) Docker en cours d'exécution"
        increment_score
    else
        log_warning "Aucun conteneur Docker en cours d'exécution"
    fi
}

# Fonction pour vérifier les mises à jour de sécurité
check_security_updates() {
    log "Vérification des mises à jour de sécurité..."
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    # Vérifier les mises à jour disponibles
    UPDATES=$(apt list --upgradable 2>/dev/null | wc -l)
    if [ $UPDATES -gt 1 ]; then
        log_warning "$UPDATES mises à jour disponibles"
        log "Exécutez 'apt update && apt upgrade' pour les installer"
    else
        log_success "Système à jour"
        increment_score
    fi
}

# Fonction pour vérifier la configuration SSH
check_ssh_config() {
    log "Vérification de la configuration SSH..."
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    # Vérifier la configuration SSH
    if grep -q "PermitRootLogin no" /etc/ssh/sshd_config; then
        log_success "Connexion root SSH désactivée"
        increment_score
    else
        log_warning "Connexion root SSH activée (recommandé: désactiver)"
    fi
    
    if grep -q "PasswordAuthentication no" /etc/ssh/sshd_config; then
        log_success "Authentification par mot de passe SSH désactivée"
        increment_score
    else
        log_warning "Authentification par mot de passe SSH activée (recommandé: utiliser les clés)"
    fi
    
    if grep -q "PubkeyAuthentication yes" /etc/ssh/sshd_config; then
        log_success "Authentification par clé publique SSH activée"
        increment_score
    else
        log_warning "Authentification par clé publique SSH désactivée"
    fi
}

# Fonction pour vérifier les logs
check_logs() {
    log "Vérification des logs..."
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    # Vérifier les logs Caddy
    if [ -f "/var/log/caddy/access.log" ]; then
        log_success "Logs d'accès Caddy présents"
        increment_score
    else
        log_warning "Logs d'accès Caddy non trouvés"
    fi
    
    if [ -f "/var/log/caddy/error.log" ]; then
        log_success "Logs d'erreur Caddy présents"
        increment_score
    else
        log_warning "Logs d'erreur Caddy non trouvés"
    fi
    
    # Vérifier les logs de déploiement
    if [ -f "/var/log/deploy/monitor.log" ]; then
        log_success "Logs de monitoring présents"
        increment_score
    else
        log_warning "Logs de monitoring non trouvés"
    fi
}

# Fonction pour vérifier les sauvegardes
check_backups() {
    log "Vérification des sauvegardes..."
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ -d "/tmp/deploy-backups" ]; then
        BACKUP_COUNT=$(ls -1 /tmp/deploy-backups | wc -l)
        if [ $BACKUP_COUNT -gt 0 ]; then
            log_success "$BACKUP_COUNT sauvegarde(s) présente(s)"
            increment_score
        else
            log_warning "Répertoire de sauvegardes vide"
        fi
    else
        log_warning "Répertoire de sauvegardes non trouvé"
    fi
}

# Fonction pour afficher le rapport de sécurité
show_security_report() {
    log "Rapport de sécurité terminé"
    echo ""
    echo "=========================================="
    echo "           RAPPORT DE SÉCURITÉ"
    echo "=========================================="
    echo ""
    echo "Score de sécurité: $SECURITY_SCORE/$TOTAL_CHECKS"
    
    # Calculer le pourcentage
    PERCENTAGE=$((SECURITY_SCORE * 100 / TOTAL_CHECKS))
    
    if [ $PERCENTAGE -ge 90 ]; then
        echo -e "Statut: ${GREEN}EXCELLENT${NC} ($PERCENTAGE%)"
    elif [ $PERCENTAGE -ge 75 ]; then
        echo -e "Statut: ${GREEN}BON${NC} ($PERCENTAGE%)"
    elif [ $PERCENTAGE -ge 60 ]; then
        echo -e "Statut: ${YELLOW}MOYEN${NC} ($PERCENTAGE%)"
    else
        echo -e "Statut: ${RED}FAIBLE${NC} ($PERCENTAGE%)"
    fi
    
    echo ""
    echo "Recommandations:"
    if [ $PERCENTAGE -lt 90 ]; then
        echo "- Vérifiez les éléments marqués en orange ou rouge"
        echo "- Exécutez 'make update-security' pour appliquer les corrections"
        echo "- Consultez la documentation pour plus de détails"
    else
        echo "- Configuration de sécurité excellente!"
        echo "- Continuez à surveiller régulièrement"
    fi
    echo ""
}

# Fonction principale
main() {
    log "Démarrage de la vérification de sécurité..."
    
    # Vérifier que le script est exécuté en tant que root
    if [ "$EUID" -ne 0 ]; then
        log_error "Ce script doit être exécuté en tant que root"
        exit 1
    fi
    
    # Exécuter toutes les vérifications
    check_firewall
    check_fail2ban
    check_ssl
    check_services
    check_permissions
    check_docker_containers
    check_security_updates
    check_ssh_config
    check_logs
    check_backups
    
    # Afficher le rapport
    show_security_report
}

# Exécuter la fonction principale
main "$@"
