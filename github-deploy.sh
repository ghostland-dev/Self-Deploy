#!/bin/bash

# Script de déploiement avec GitHub Actions
# Ce script peut être utilisé dans un workflow GitHub Actions

set -e

# Configuration
GITHUB_TOKEN="${{ secrets.GITHUB_TOKEN }}"
REPO_NAME="${{ github.repository }}"
BRANCH="${{ github.ref_name }}"
COMMIT_SHA="${{ github.sha }}"

# Fonction pour créer un déploiement GitHub
create_github_deployment() {
    local environment="$1"
    local description="$2"
    
    curl -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$REPO_NAME/deployments" \
        -d "{
            \"ref\": \"$COMMIT_SHA\",
            \"environment\": \"$environment\",
            \"description\": \"$description\",
            \"auto_merge\": false,
            \"required_contexts\": []
        }"
}

# Fonction pour mettre à jour le statut du déploiement
update_deployment_status() {
    local deployment_id="$1"
    local state="$2"
    local description="$3"
    local environment_url="$4"
    
    curl -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$REPO_NAME/deployments/$deployment_id/statuses" \
        -d "{
            \"state\": \"$state\",
            \"description\": \"$description\",
            \"environment_url\": \"$environment_url\"
        }"
}

# Fonction principale de déploiement avec GitHub
deploy_with_github() {
    local config_file="$1"
    local environment="${2:-production}"
    
    # Créer le déploiement GitHub
    echo "Création du déploiement GitHub..."
    local deployment_response=$(create_github_deployment "$environment" "Déploiement automatique")
    local deployment_id=$(echo "$deployment_response" | jq -r '.id')
    
    if [ "$deployment_id" = "null" ]; then
        echo "Erreur: Impossible de créer le déploiement GitHub"
        exit 1
    fi
    
    echo "Déploiement GitHub créé avec l'ID: $deployment_id"
    
    # Mettre à jour le statut à "in_progress"
    update_deployment_status "$deployment_id" "in_progress" "Déploiement en cours..."
    
    # Exécuter le déploiement
    if ./deploy.sh deploy "$config_file"; then
        # Succès
        local domain=$(jq -r '.domain' "$config_file")
        update_deployment_status "$deployment_id" "success" "Déploiement réussi" "http://$domain"
        echo "✅ Déploiement réussi!"
    else
        # Échec
        update_deployment_status "$deployment_id" "failure" "Échec du déploiement"
        echo "❌ Échec du déploiement"
        exit 1
    fi
}

# Fonction pour déployer depuis GitHub
deploy_from_github() {
    local repo_url="$1"
    local config_file="$2"
    local temp_dir="/tmp/github-deploy-$$"
    
    echo "Clonage du repository: $repo_url"
    
    # Cloner le repository
    git clone "$repo_url" "$temp_dir"
    cd "$temp_dir"
    
    # Construire l'application si nécessaire
    if [ -f "package.json" ]; then
        echo "Installation des dépendances Node.js..."
        npm install
        
        if [ -f "package.json" ] && grep -q '"build"' package.json; then
            echo "Construction de l'application..."
            npm run build
        fi
    fi
    
    if [ -f "requirements.txt" ]; then
        echo "Installation des dépendances Python..."
        pip install -r requirements.txt
    fi
    
    if [ -f "composer.json" ]; then
        echo "Installation des dépendances PHP..."
        composer install --no-dev --optimize-autoloader
    fi
    
    # Modifier le chemin de build dans la config temporaire
    local temp_config="/tmp/config-$$.json"
    jq --arg build_dir "$temp_dir" '.build_dir = $build_dir' "$config_file" > "$temp_config"
    
    # Déployer
    deploy_with_github "$temp_config"
    
    # Nettoyer
    cd /
    rm -rf "$temp_dir" "$temp_config"
}

# Fonction d'aide
show_help() {
    echo "Script de déploiement avec GitHub"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  deploy <config.json> [environment]     Déployer avec GitHub Actions"
    echo "  deploy-github <repo-url> <config.json> Déployer depuis un repository GitHub"
    echo "  help                                    Afficher cette aide"
    echo ""
    echo "Exemples:"
    echo "  $0 deploy examples/react-app.json production"
    echo "  $0 deploy-github https://github.com/user/my-app.git examples/react-app.json"
}

# Point d'entrée principal
main() {
    case "${1:-help}" in
        "deploy")
            deploy_with_github "$2" "$3"
            ;;
        "deploy-github")
            deploy_from_github "$2" "$3"
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            echo "Commande inconnue: $1"
            show_help
            exit 1
            ;;
    esac
}

# Vérifier les dépendances
if ! command -v jq &> /dev/null; then
    echo "Erreur: jq est requis pour ce script"
    echo "Installez-le avec: sudo apt install jq"
    exit 1
fi

if ! command -v git &> /dev/null; then
    echo "Erreur: git est requis pour ce script"
    echo "Installez-le avec: sudo apt install git"
    exit 1
fi

# Exécuter la fonction principale
main "$@"
