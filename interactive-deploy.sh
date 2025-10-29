#!/bin/bash

# Interface interactive pour le système de déploiement qiwiiz.space
# Menu principal avec sélections guidées

set -e

# Configuration
SSH_USER="qiwiiz"
SSH_HOST="51.159.6.66"
SSH_PASSWORD="changeme"
DOMAIN="qiwiiz.space"

# Couleurs pour l'interface
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Fonction pour afficher le logo
show_logo() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║    🚀 SYSTÈME DE DÉPLOIEMENT QIWIIZ.SPACE 🚀                ║"
    echo "║                                                              ║"
    echo "║    Déploiement automatisé avec Docker, Caddy et SSL         ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# Fonction pour afficher un message de bienvenue
show_welcome() {
    echo -e "${GREEN}🎉 Bienvenue dans le système de déploiement qiwiiz.space !${NC}"
    echo -e "${BLUE}Ce système vous permet de déployer facilement vos applications${NC}"
    echo -e "${BLUE}avec SSL automatique et gestion des sous-domaines.${NC}"
    echo ""
}

# Fonction pour afficher le menu principal
show_main_menu() {
    echo -e "${WHITE}📋 MENU PRINCIPAL${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}1.${NC} 🚀 Déploiement rapide"
    echo -e "${YELLOW}2.${NC} 🐳 Déploiement Docker"
    echo -e "${YELLOW}3.${NC} 🌐 Gestion des sous-domaines"
    echo -e "${YELLOW}4.${NC} 🔒 Gestion SSL"
    echo -e "${YELLOW}5.${NC} 📊 Monitoring et statut"
    echo -e "${YELLOW}6.${NC} 🛠️ Configuration serveur"
    echo -e "${YELLOW}7.${NC} 🔧 Maintenance"
    echo -e "${YELLOW}8.${NC} 📚 Aide et documentation"
    echo -e "${YELLOW}9.${NC} 🚪 Quitter"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
}

# Fonction pour lire la sélection de l'utilisateur
read_selection() {
    echo -e "${WHITE}Votre choix [1-9]: ${NC}"
    read -r choice
    echo ""
}

# Fonction pour afficher le menu de déploiement rapide
show_quick_deploy_menu() {
    echo -e "${WHITE}🚀 DÉPLOIEMENT RAPIDE${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}1.${NC} 📱 Application React/Vue/Angular (statique)"
    echo -e "${YELLOW}2.${NC} 🔌 API Node.js/Express"
    echo -e "${YELLOW}3.${NC} 🐍 Application Python/Flask"
    echo -e "${YELLOW}4.${NC} 🐘 Application PHP/Laravel"
    echo -e "${YELLOW}5.${NC} 🔙 Retour au menu principal"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
}

# Fonction pour afficher le menu Docker
show_docker_menu() {
    echo -e "${WHITE}🐳 DÉPLOIEMENT DOCKER${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}1.${NC} 🚀 Déploiement avec image pré-construite"
    echo -e "${YELLOW}2.${NC} 📦 Déploiement depuis GitHub"
    echo -e "${YELLOW}3.${NC} 🔄 Mise à jour d'une application"
    echo -e "${YELLOW}4.${NC} 📋 Lister les applications déployées"
    echo -e "${YELLOW}5.${NC} 🔙 Retour au menu principal"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
}

# Fonction pour afficher le menu des sous-domaines
show_subdomain_menu() {
    echo -e "${WHITE}🌐 GESTION DES SOUS-DOMAINES${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}1.${NC} 📋 Lister les sous-domaines disponibles"
    echo -e "${YELLOW}2.${NC} 📊 Voir les sous-domaines utilisés"
    echo -e "${YELLOW}3.${NC} 🎯 Suggérer un sous-domaine"
    echo -e "${YELLOW}4.${NC} 🔗 Assigner un sous-domaine"
    echo -e "${YELLOW}5.${NC} 🔓 Libérer un sous-domaine"
    echo -e "${YELLOW}6.${NC} 📈 Statut des sous-domaines"
    echo -e "${YELLOW}7.${NC} 🔙 Retour au menu principal"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
}

# Fonction pour afficher le menu SSL
show_ssl_menu() {
    echo -e "${WHITE}🔒 GESTION SSL${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}1.${NC} 🔍 Vérifier les certificats SSL"
    echo -e "${YELLOW}2.${NC} 🔄 Renouveler les certificats"
    echo -e "${YELLOW}3.${NC} ⚙️ Configurer SSL"
    echo -e "${YELLOW}4.${NC} 📋 Lister les déploiements SSL"
    echo -e "${YELLOW}5.${NC} 🔙 Retour au menu principal"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
}

# Fonction pour afficher le menu monitoring
show_monitoring_menu() {
    echo -e "${WHITE}📊 MONITORING ET STATUT${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}1.${NC} 📈 Statut des services"
    echo -e "${YELLOW}2.${NC} 🐳 Conteneurs Docker"
    echo -e "${YELLOW}3.${NC} 🌐 Sites web actifs"
    echo -e "${YELLOW}4.${NC} 📊 Monitoring en temps réel"
    echo -e "${YELLOW}5.${NC} 📋 Logs des applications"
    echo -e "${YELLOW}6.${NC} 🔙 Retour au menu principal"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
}

# Fonction pour afficher le menu configuration
show_config_menu() {
    echo -e "${WHITE}🛠️ CONFIGURATION SERVEUR${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}1.${NC} ⚙️ Configuration initiale du serveur"
    echo -e "${YELLOW}2.${NC} 🔒 Vérification de sécurité"
    echo -e "${YELLOW}3.${NC} 🔄 Mise à jour de sécurité"
    echo -e "${YELLOW}4.${NC} 🧪 Tests de connexion"
    echo -e "${YELLOW}5.${NC} 📊 Informations système"
    echo -e "${YELLOW}6.${NC} 🔙 Retour au menu principal"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
}

# Fonction pour afficher le menu maintenance
show_maintenance_menu() {
    echo -e "${WHITE}🔧 MAINTENANCE${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}1.${NC} 🧹 Nettoyage des sauvegardes"
    echo -e "${YELLOW}2.${NC} 🐳 Nettoyage Docker"
    echo -e "${YELLOW}3.${NC} 💾 Sauvegarde complète"
    echo -e "${YELLOW}4.${NC} 🔄 Restauration"
    echo -e "${YELLOW}5.${NC} 🔙 Retour au menu principal"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
}

# Fonction pour afficher le menu d'aide
show_help_menu() {
    echo -e "${WHITE}📚 AIDE ET DOCUMENTATION${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}1.${NC} 📖 Guide de démarrage rapide"
    echo -e "${YELLOW}2.${NC} 🐳 Documentation Docker"
    echo -e "${YELLOW}3.${NC} 🌐 Guide des sous-domaines"
    echo -e "${YELLOW}4.${NC} 🔒 Guide SSL"
    echo -e "${YELLOW}5.${NC} 🛠️ Commandes disponibles"
    echo -e "${YELLOW}6.${NC} 🔙 Retour au menu principal"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
}

# Fonction pour demander le nom de l'application
ask_app_name() {
    echo -e "${WHITE}📝 Nom de l'application: ${NC}"
    read -r app_name
    if [ -z "$app_name" ]; then
        echo -e "${RED}❌ Le nom de l'application est requis${NC}"
        return 1
    fi
    echo "$app_name"
}

# Fonction pour demander le port
ask_port() {
    local default_port="$1"
    echo -e "${WHITE}🔌 Port de l'application [${default_port}]: ${NC}"
    read -r port
    if [ -z "$port" ]; then
        port="$default_port"
    fi
    echo "$port"
}

# Fonction pour demander l'image Docker
ask_docker_image() {
    echo -e "${WHITE}🐳 Image Docker (ex: ghcr.io/username/repo): ${NC}"
    read -r docker_image
    if [ -z "$docker_image" ]; then
        echo -e "${RED}❌ L'image Docker est requise${NC}"
        return 1
    fi
    echo "$docker_image"
}

# Fonction pour demander le tag Docker
ask_docker_tag() {
    echo -e "${WHITE}🏷️ Tag Docker [latest]: ${NC}"
    read -r docker_tag
    if [ -z "$docker_tag" ]; then
        docker_tag="latest"
    fi
    echo "$docker_tag"
}

# Fonction pour demander le repository GitHub
ask_github_repo() {
    echo -e "${WHITE}📦 Repository GitHub (ex: username/repo): ${NC}"
    read -r github_repo
    if [ -z "$github_repo" ]; then
        echo -e "${RED}❌ Le repository GitHub est requis${NC}"
        return 1
    fi
    echo "$github_repo"
}

# Fonction pour demander le sous-domaine
ask_subdomain() {
    echo -e "${WHITE}🌐 Sous-domaine (ex: app1, api1, bot1): ${NC}"
    read -r subdomain
    if [ -z "$subdomain" ]; then
        echo -e "${RED}❌ Le sous-domaine est requis${NC}"
        return 1
    fi
    echo "$subdomain"
}

# Fonction pour confirmer une action
confirm_action() {
    local message="$1"
    echo -e "${YELLOW}❓ $message [y/N]: ${NC}"
    read -r confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Fonction pour attendre la pression d'une touche
wait_for_key() {
    echo -e "${CYAN}Appuyez sur Entrée pour continuer...${NC}"
    read -r
}

# Fonction pour afficher un message de succès
show_success() {
    local message="$1"
    echo -e "${GREEN}✅ $message${NC}"
    echo ""
}

# Fonction pour afficher un message d'erreur
show_error() {
    local message="$1"
    echo -e "${RED}❌ $message${NC}"
    echo ""
}

# Fonction pour afficher un message d'information
show_info() {
    local message="$1"
    echo -e "${BLUE}ℹ️ $message${NC}"
    echo ""
}

# Fonction pour gérer le déploiement rapide
handle_quick_deploy() {
    while true; do
        show_quick_deploy_menu
        read_selection
        
        case $choice in
            1)
                echo -e "${WHITE}📱 DÉPLOIEMENT APPLICATION STATIQUE${NC}"
                echo ""
                app_name=$(ask_app_name)
                if [ $? -eq 0 ]; then
                    port=$(ask_port "8080")
                    if confirm_action "Déployer l'application statique '$app_name' sur le port $port ?"; then
                        make quick-ssl APP="$app_name" TYPE=static PORT="$port"
                        show_success "Application statique déployée avec succès !"
                        wait_for_key
                    fi
                fi
                ;;
            2)
                echo -e "${WHITE}🔌 DÉPLOIEMENT API NODE.JS${NC}"
                echo ""
                app_name=$(ask_app_name)
                if [ $? -eq 0 ]; then
                    port=$(ask_port "3000")
                    if confirm_action "Déployer l'API Node.js '$app_name' sur le port $port ?"; then
                        make quick-ssl APP="$app_name" TYPE=node PORT="$port"
                        show_success "API Node.js déployée avec succès !"
                        wait_for_key
                    fi
                fi
                ;;
            3)
                echo -e "${WHITE}🐍 DÉPLOIEMENT APPLICATION PYTHON${NC}"
                echo ""
                app_name=$(ask_app_name)
                if [ $? -eq 0 ]; then
                    port=$(ask_port "5000")
                    if confirm_action "Déployer l'application Python '$app_name' sur le port $port ?"; then
                        make quick-ssl APP="$app_name" TYPE=python PORT="$port"
                        show_success "Application Python déployée avec succès !"
                        wait_for_key
                    fi
                fi
                ;;
            4)
                echo -e "${WHITE}🐘 DÉPLOIEMENT APPLICATION PHP${NC}"
                echo ""
                app_name=$(ask_app_name)
                if [ $? -eq 0 ]; then
                    port=$(ask_port "8080")
                    if confirm_action "Déployer l'application PHP '$app_name' sur le port $port ?"; then
                        make quick-ssl APP="$app_name" TYPE=php PORT="$port"
                        show_success "Application PHP déployée avec succès !"
                        wait_for_key
                    fi
                fi
                ;;
            5)
                return
                ;;
            *)
                show_error "Choix invalide. Veuillez sélectionner 1-5."
                wait_for_key
                ;;
        esac
    done
}

# Fonction pour gérer le déploiement Docker
handle_docker_deploy() {
    while true; do
        show_docker_menu
        read_selection
        
        case $choice in
            1)
                echo -e "${WHITE}🚀 DÉPLOIEMENT IMAGE DOCKER${NC}"
                echo ""
                app_name=$(ask_app_name)
                if [ $? -eq 0 ]; then
                    docker_image=$(ask_docker_image)
                    if [ $? -eq 0 ]; then
                        docker_tag=$(ask_docker_tag)
                        port=$(ask_port "8080")
                        if confirm_action "Déployer l'image '$docker_image:$docker_tag' pour '$app_name' ?"; then
                            make deploy-docker-image APP="$app_name" IMAGE="$docker_image" TAG="$docker_tag" PORT="$port"
                            show_success "Image Docker déployée avec succès !"
                            wait_for_key
                        fi
                    fi
                fi
                ;;
            2)
                echo -e "${WHITE}📦 DÉPLOIEMENT DEPUIS GITHUB${NC}"
                echo ""
                github_repo=$(ask_github_repo)
                if [ $? -eq 0 ]; then
                    app_name=$(ask_app_name)
                    if [ $? -eq 0 ]; then
                        echo -e "${WHITE}Type d'application:${NC}"
                        echo "1. static"
                        echo "2. node"
                        echo "3. python"
                        echo "4. php"
                        echo -e "${WHITE}Votre choix [1-4]: ${NC}"
                        read -r app_type_choice
                        case $app_type_choice in
                            1) app_type="static"; port=$(ask_port "8080") ;;
                            2) app_type="node"; port=$(ask_port "3000") ;;
                            3) app_type="python"; port=$(ask_port "5000") ;;
                            4) app_type="php"; port=$(ask_port "8080") ;;
                            *) show_error "Choix invalide"; continue ;;
                        esac
                        if confirm_action "Déployer depuis GitHub '$github_repo' ?"; then
                            make deploy-github-docker REPO="$github_repo" APP="$app_name" TYPE="$app_type" PORT="$port"
                            show_success "Déploiement GitHub terminé avec succès !"
                            wait_for_key
                        fi
                    fi
                fi
                ;;
            3)
                echo -e "${WHITE}🔄 MISE À JOUR APPLICATION${NC}"
                echo ""
                app_name=$(ask_app_name)
                if [ $? -eq 0 ]; then
                    docker_image=$(ask_docker_image)
                    if [ $? -eq 0 ]; then
                        docker_tag=$(ask_docker_tag)
                        if confirm_action "Mettre à jour l'application '$app_name' ?"; then
                            make update-docker-image APP="$app_name" IMAGE="$docker_image" TAG="$docker_tag"
                            show_success "Application mise à jour avec succès !"
                            wait_for_key
                        fi
                    fi
                fi
                ;;
            4)
                echo -e "${WHITE}📋 APPLICATIONS DÉPLOYÉES${NC}"
                echo ""
                make list-docker-images
                wait_for_key
                ;;
            5)
                return
                ;;
            *)
                show_error "Choix invalide. Veuillez sélectionner 1-5."
                wait_for_key
                ;;
        esac
    done
}

# Fonction pour gérer les sous-domaines
handle_subdomain_management() {
    while true; do
        show_subdomain_menu
        read_selection
        
        case $choice in
            1)
                echo -e "${WHITE}📋 SOUS-DOMAINES DISPONIBLES${NC}"
                echo ""
                make list-subdomains
                wait_for_key
                ;;
            2)
                echo -e "${WHITE}📊 SOUS-DOMAINES UTILISÉS${NC}"
                echo ""
                make list-used-subdomains
                wait_for_key
                ;;
            3)
                echo -e "${WHITE}🎯 SUGGESTION SOUS-DOMAINES${NC}"
                echo ""
                app_name=$(ask_app_name)
                if [ $? -eq 0 ]; then
                    echo -e "${WHITE}Type d'application:${NC}"
                    echo "1. admin"
                    echo "2. api"
                    echo "3. app"
                    echo "4. bot"
                    echo "5. static"
                    echo -e "${WHITE}Votre choix [1-5]: ${NC}"
                    read -r type_choice
                    case $type_choice in
                        1) app_type="admin" ;;
                        2) app_type="api" ;;
                        3) app_type="app" ;;
                        4) app_type="bot" ;;
                        5) app_type="static" ;;
                        *) show_error "Choix invalide"; continue ;;
                    esac
                    make suggest-subdomain APP="$app_name" TYPE="$app_type"
                    wait_for_key
                fi
                ;;
            4)
                echo -e "${WHITE}🔗 ASSIGNATION SOUS-DOMAINES${NC}"
                echo ""
                app_name=$(ask_app_name)
                if [ $? -eq 0 ]; then
                    subdomain=$(ask_subdomain)
                    if [ $? -eq 0 ]; then
                        echo -e "${WHITE}Type d'application:${NC}"
                        echo "1. admin"
                        echo "2. api"
                        echo "3. app"
                        echo "4. bot"
                        echo "5. static"
                        echo -e "${WHITE}Votre choix [1-5]: ${NC}"
                        read -r type_choice
                        case $type_choice in
                            1) app_type="admin" ;;
                            2) app_type="api" ;;
                            3) app_type="app" ;;
                            4) app_type="bot" ;;
                            5) app_type="static" ;;
                            *) show_error "Choix invalide"; continue ;;
                        esac
                        port=$(ask_port "8080")
                        if confirm_action "Assigner '$subdomain.qiwiiz.space' à '$app_name' ?"; then
                            make assign-subdomain APP="$app_name" SUBDOMAIN="$subdomain" TYPE="$app_type" PORT="$port"
                            show_success "Sous-domaine assigné avec succès !"
                            wait_for_key
                        fi
                    fi
                fi
                ;;
            5)
                echo -e "${WHITE}🔓 LIBÉRATION SOUS-DOMAINES${NC}"
                echo ""
                subdomain=$(ask_subdomain)
                if [ $? -eq 0 ]; then
                    if confirm_action "Libérer le sous-domaine '$subdomain.qiwiiz.space' ?"; then
                        ./subdomain-manager.sh release "$subdomain"
                        show_success "Sous-domaine libéré avec succès !"
                        wait_for_key
                    fi
                fi
                ;;
            6)
                echo -e "${WHITE}📈 STATUT SOUS-DOMAINES${NC}"
                echo ""
                make subdomain-status
                wait_for_key
                ;;
            7)
                return
                ;;
            *)
                show_error "Choix invalide. Veuillez sélectionner 1-7."
                wait_for_key
                ;;
        esac
    done
}

# Fonction pour gérer SSL
handle_ssl_management() {
    while true; do
        show_ssl_menu
        read_selection
        
        case $choice in
            1)
                echo -e "${WHITE}🔍 VÉRIFICATION CERTIFICATS SSL${NC}"
                echo ""
                ssh qiwiiz@51.159.6.66 "caddy list-certificates | grep qiwiiz.space"
                wait_for_key
                ;;
            2)
                echo -e "${WHITE}🔄 RENOUVELLEMENT CERTIFICATS SSL${NC}"
                echo ""
                if confirm_action "Renouveler tous les certificats SSL ?"; then
                    make renew-ssl
                    show_success "Certificats SSL renouvelés avec succès !"
                    wait_for_key
                fi
                ;;
            3)
                echo -e "${WHITE}⚙️ CONFIGURATION SSL${NC}"
                echo ""
                if confirm_action "Configurer SSL sur le serveur ?"; then
                    make setup-ssl
                    show_success "SSL configuré avec succès !"
                    wait_for_key
                fi
                ;;
            4)
                echo -e "${WHITE}📋 DÉPLOIEMENTS SSL${NC}"
                echo ""
                make list-ssl
                wait_for_key
                ;;
            5)
                return
                ;;
            *)
                show_error "Choix invalide. Veuillez sélectionner 1-5."
                wait_for_key
                ;;
        esac
    done
}

# Fonction pour gérer le monitoring
handle_monitoring() {
    while true; do
        show_monitoring_menu
        read_selection
        
        case $choice in
            1)
                echo -e "${WHITE}📈 STATUT DES SERVICES${NC}"
                echo ""
                make status
                wait_for_key
                ;;
            2)
                echo -e "${WHITE}🐳 CONTENEURS DOCKER${NC}"
                echo ""
                ssh qiwiiz@51.159.6.66 "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'"
                wait_for_key
                ;;
            3)
                echo -e "${WHITE}🌐 SITES WEB ACTIFS${NC}"
                echo ""
                make list-used-subdomains
                wait_for_key
                ;;
            4)
                echo -e "${WHITE}📊 MONITORING TEMPS RÉEL${NC}"
                echo ""
                show_info "Démarrage du monitoring en temps réel..."
                make monitor
                ;;
            5)
                echo -e "${WHITE}📋 LOGS DES APPLICATIONS${NC}"
                echo ""
                echo "1. Logs de déploiement"
                echo "2. Logs du serveur"
                echo "3. Logs Docker"
                echo -e "${WHITE}Votre choix [1-3]: ${NC}"
                read -r log_choice
                case $log_choice in
                    1) tail -f deploy.log ;;
                    2) ssh qiwiiz@51.159.6.66 "journalctl -u caddy -f" ;;
                    3) ssh qiwiiz@51.159.6.66 "docker logs -f" ;;
                    *) show_error "Choix invalide" ;;
                esac
                ;;
            6)
                return
                ;;
            *)
                show_error "Choix invalide. Veuillez sélectionner 1-6."
                wait_for_key
                ;;
        esac
    done
}

# Fonction pour gérer la configuration
handle_configuration() {
    while true; do
        show_config_menu
        read_selection
        
        case $choice in
            1)
                echo -e "${WHITE}⚙️ CONFIGURATION INITIALE SERVEUR${NC}"
                echo ""
                if confirm_action "Configurer le serveur qiwiiz.space ?"; then
                    make setup-server
                    show_success "Serveur configuré avec succès !"
                    wait_for_key
                fi
                ;;
            2)
                echo -e "${WHITE}🔒 VÉRIFICATION SÉCURITÉ${NC}"
                echo ""
                make security-check
                wait_for_key
                ;;
            3)
                echo -e "${WHITE}🔄 MISE À JOUR SÉCURITÉ${NC}"
                echo ""
                if confirm_action "Mettre à jour la sécurité du serveur ?"; then
                    make update-security
                    show_success "Sécurité mise à jour avec succès !"
                    wait_for_key
                fi
                ;;
            4)
                echo -e "${WHITE}🧪 TESTS DE CONNEXION${NC}"
                echo ""
                make test-all
                wait_for_key
                ;;
            5)
                echo -e "${WHITE}📊 INFORMATIONS SYSTÈME${NC}"
                echo ""
                make info
                wait_for_key
                ;;
            6)
                return
                ;;
            *)
                show_error "Choix invalide. Veuillez sélectionner 1-6."
                wait_for_key
                ;;
        esac
    done
}

# Fonction pour gérer la maintenance
handle_maintenance() {
    while true; do
        show_maintenance_menu
        read_selection
        
        case $choice in
            1)
                echo -e "${WHITE}🧹 NETTOYAGE SAUVEGARDES${NC}"
                echo ""
                echo -e "${WHITE}Nombre de jours [7]: ${NC}"
                read -r days
                if [ -z "$days" ]; then
                    days="7"
                fi
                if confirm_action "Nettoyer les sauvegardes plus anciennes que $days jours ?"; then
                    make cleanup DAYS="$days"
                    show_success "Nettoyage terminé avec succès !"
                    wait_for_key
                fi
                ;;
            2)
                echo -e "${WHITE}🐳 NETTOYAGE DOCKER${NC}"
                echo ""
                if confirm_action "Nettoyer les images Docker inutilisées ?"; then
                    make docker-cleanup
                    show_success "Nettoyage Docker terminé avec succès !"
                    wait_for_key
                fi
                ;;
            3)
                echo -e "${WHITE}💾 SAUVEGARDE COMPLÈTE${NC}"
                echo ""
                if confirm_action "Créer une sauvegarde complète du serveur ?"; then
                    make backup
                    show_success "Sauvegarde créée avec succès !"
                    wait_for_key
                fi
                ;;
            4)
                echo -e "${WHITE}🔄 RESTAURATION${NC}"
                echo ""
                echo -e "${WHITE}Chemin vers la sauvegarde: ${NC}"
                read -r backup_file
                if [ ! -z "$backup_file" ]; then
                    if confirm_action "Restaurer depuis '$backup_file' ?"; then
                        make restore BACKUP_FILE="$backup_file"
                        show_success "Restauration terminée avec succès !"
                        wait_for_key
                    fi
                fi
                ;;
            5)
                return
                ;;
            *)
                show_error "Choix invalide. Veuillez sélectionner 1-5."
                wait_for_key
                ;;
        esac
    done
}

# Fonction pour gérer l'aide
handle_help() {
    while true; do
        show_help_menu
        read_selection
        
        case $choice in
            1)
                echo -e "${WHITE}📖 GUIDE DE DÉMARRAGE RAPIDE${NC}"
                echo ""
                cat QUICKSTART.md | head -50
                wait_for_key
                ;;
            2)
                echo -e "${WHITE}🐳 DOCUMENTATION DOCKER${NC}"
                echo ""
                cat DOCKER-CICD.md | head -50
                wait_for_key
                ;;
            3)
                echo -e "${WHITE}🌐 GUIDE SOUS-DOMAINES${NC}"
                echo ""
                cat SUBDOMAIN-GUIDE.md | head -50
                wait_for_key
                ;;
            4)
                echo -e "${WHITE}🔒 GUIDE SSL${NC}"
                echo ""
                cat SSL-GUIDE.md | head -50
                wait_for_key
                ;;
            5)
                echo -e "${WHITE}🛠️ COMMANDES DISPONIBLES${NC}"
                echo ""
                make help
                wait_for_key
                ;;
            6)
                return
                ;;
            *)
                show_error "Choix invalide. Veuillez sélectionner 1-6."
                wait_for_key
                ;;
        esac
    done
}

# Fonction principale
main() {
    # Vérifier les dépendances
    if ! command -v sshpass &> /dev/null; then
        show_error "sshpass n'est pas installé. Installez-le avec: sudo apt install sshpass"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        show_error "jq n'est pas installé. Installez-le avec: sudo apt install jq"
        exit 1
    fi
    
    # Boucle principale
    while true; do
        show_logo
        show_welcome
        show_main_menu
        read_selection
        
        case $choice in
            1)
                handle_quick_deploy
                ;;
            2)
                handle_docker_deploy
                ;;
            3)
                handle_subdomain_management
                ;;
            4)
                handle_ssl_management
                ;;
            5)
                handle_monitoring
                ;;
            6)
                handle_configuration
                ;;
            7)
                handle_maintenance
                ;;
            8)
                handle_help
                ;;
            9)
                echo -e "${GREEN}👋 Merci d'avoir utilisé le système de déploiement qiwiiz.space !${NC}"
                echo -e "${BLUE}À bientôt ! 🚀${NC}"
                exit 0
                ;;
            *)
                show_error "Choix invalide. Veuillez sélectionner 1-9."
                wait_for_key
                ;;
        esac
    done
}

# Exécuter la fonction principale
main "$@"
