# Makefile pour le système de déploiement automatisé
# Configuration pour qiwiiz.space avec Caddy et Docker

# Variables de configuration
SSH_USER = qiwiiz
SSH_HOST = 51.159.6.66
SSH_PASSWORD = changeme
DOMAIN = qiwiiz.space
REMOTE_DEPLOY_DIR = /home/qiwiiz/apps
DOCKER_COMPOSE_DIR = /home/qiwiiz/docker-compose

# Couleurs pour les logs
BLUE = \033[0;34m
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m

# Aide par défaut
.PHONY: help
help: ## Afficher cette aide
	@echo "$(BLUE)Système de déploiement automatisé avec Caddy et Docker$(NC)"
	@echo ""
	@echo "$(GREEN)Commandes disponibles:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)Exemples d'utilisation:$(NC)"
	@echo "  make setup-server          # Configurer le serveur"
	@echo "  make deploy APP=react      # Déployer une app React"
	@echo "  make deploy APP=node       # Déployer une API Node.js"
	@echo "  make deploy APP=python     # Déployer une app Python"
	@echo "  make deploy APP=php        # Déployer une app PHP"
	@echo "  make list                  # Lister les déploiements"
	@echo "  make cleanup               # Nettoyer les sauvegardes"

# Configuration du serveur
.PHONY: setup-server
setup-server: ## Configurer le serveur Ubuntu avec Caddy et Docker
	@echo "$(BLUE)Configuration du serveur Ubuntu...$(NC)"
	@sshpass -p $(SSH_PASSWORD) ssh -o StrictHostKeyChecking=no $(SSH_USER)@$(SSH_HOST) 'bash -s' < setup-server-caddy.sh
	@echo "$(GREEN)✓ Serveur configuré avec succès$(NC)"

# Déploiement d'applications
.PHONY: deploy
deploy: ## Déployer une application (APP=react|node|python|php)
	@if [ -z "$(APP)" ]; then \
		echo "$(RED)Erreur: Spécifiez APP=react|node|python|php$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Déploiement de l'application $(APP)...$(NC)"
	@./deploy-docker.sh deploy examples/$(APP)-app.json
	@echo "$(GREEN)✓ Application $(APP) déployée avec succès$(NC)"

# Déploiement avec SSL automatique
.PHONY: deploy-ssl
deploy-ssl: ## Déployer avec SSL automatique (APP=nom TYPE=static|node|python|php PORT=port DOMAIN=domaine)
	@if [ -z "$(APP)" ] || [ -z "$(TYPE)" ]; then \
		echo "$(RED)Erreur: Spécifiez APP=nom TYPE=static|node|python|php$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Déploiement SSL de l'application $(APP)...$(NC)"
	@./ssl-deploy.sh deploy $(APP) $(TYPE) $(PORT) $(DOMAIN)
	@echo "$(GREEN)✓ Application $(APP) déployée avec SSL$(NC)"

# Déploiement rapide avec SSL
.PHONY: quick-ssl
quick-ssl: ## Déploiement rapide avec SSL (APP=nom TYPE=static|node|python|php PORT=port)
	@if [ -z "$(APP)" ] || [ -z "$(TYPE)" ]; then \
		echo "$(RED)Erreur: Spécifiez APP=nom TYPE=static|node|python|php$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Déploiement rapide SSL de $(APP)...$(NC)"
	@./ssl-deploy.sh quick-deploy $(APP) $(TYPE) $(PORT)
	@echo "$(GREEN)✓ Application $(APP) déployée rapidement avec SSL$(NC)"

# Déploiement spécifique par type
.PHONY: deploy-react deploy-node deploy-python deploy-php
deploy-react: ## Déployer une application React
	@$(MAKE) deploy APP=react

deploy-node: ## Déployer une API Node.js
	@$(MAKE) deploy APP=node

deploy-python: ## Déployer une application Python
	@$(MAKE) deploy APP=python

deploy-php: ## Déployer une application PHP
	@$(MAKE) deploy APP=php

# Gestion des sous-domaines qiwiiz.space
.PHONY: list-subdomains
list-subdomains: ## Lister les sous-domaines disponibles
	@echo "$(BLUE)Sous-domaines disponibles:$(NC)"
	@./subdomain-manager.sh list-available

.PHONY: list-used-subdomains
list-used-subdomains: ## Lister les sous-domaines utilisés
	@echo "$(BLUE)Sous-domaines utilisés:$(NC)"
	@./subdomain-manager.sh list-used

.PHONY: assign-subdomain
assign-subdomain: ## Assigner un sous-domaine (APP=nom SUBDOMAIN=subdomain TYPE=type PORT=port)
	@if [ -z "$(APP)" ] || [ -z "$(SUBDOMAIN)" ] || [ -z "$(TYPE)" ]; then \
		echo "$(RED)Erreur: Spécifiez APP=nom SUBDOMAIN=subdomain TYPE=type$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Assignation du sous-domaine $(SUBDOMAIN) à $(APP)...$(NC)"
	@./subdomain-manager.sh assign $(APP) $(SUBDOMAIN) $(TYPE) $(PORT)
	@echo "$(GREEN)✓ Sous-domaine $(SUBDOMAIN).qiwiiz.space assigné$(NC)"

.PHONY: suggest-subdomain
suggest-subdomain: ## Suggérer un sous-domaine (APP=nom TYPE=type)
	@if [ -z "$(APP)" ] || [ -z "$(TYPE)" ]; then \
		echo "$(RED)Erreur: Spécifiez APP=nom TYPE=type$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Suggestion de sous-domaine pour $(APP)...$(NC)"
	@./subdomain-manager.sh suggest $(APP) $(TYPE)

.PHONY: deploy-auto-subdomain
deploy-auto-subdomain: ## Déployer avec sous-domaine automatique (APP=nom TYPE=type PORT=port IMAGE=image TAG=tag)
	@if [ -z "$(APP)" ] || [ -z "$(TYPE)" ] || [ -z "$(IMAGE)" ] || [ -z "$(TAG)" ]; then \
		echo "$(RED)Erreur: Spécifiez APP=nom TYPE=type IMAGE=image TAG=tag$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Déploiement avec sous-domaine automatique: $(APP)...$(NC)"
	@./subdomain-manager.sh deploy-auto $(APP) $(TYPE) $(PORT) $(IMAGE) $(TAG)
	@echo "$(GREEN)✓ Application $(APP) déployée avec sous-domaine automatique$(NC)"

.PHONY: subdomain-status
subdomain-status: ## Afficher le statut des sous-domaines
	@echo "$(BLUE)Statut des sous-domaines:$(NC)"
	@./subdomain-manager.sh status

.PHONY: status
status: ## Vérifier le statut des services
	@echo "$(BLUE)Statut des services:$(NC)"
	@sshpass -p $(SSH_PASSWORD) ssh -o StrictHostKeyChecking=no $(SSH_USER)@$(SSH_HOST) 'systemctl status caddy docker'
	@echo "$(BLUE)Conteneurs Docker actifs:$(NC)"
	@sshpass -p $(SSH_PASSWORD) ssh -o StrictHostKeyChecking=no $(SSH_USER)@$(SSH_HOST) 'docker ps'

# Nettoyage
.PHONY: cleanup
cleanup: ## Nettoyer les anciennes sauvegardes (DAYS=7)
	@echo "$(BLUE)Nettoyage des sauvegardes...$(NC)"
	@./deploy-docker.sh cleanup $(DAYS)
	@echo "$(GREEN)✓ Nettoyage terminé$(NC)"

.PHONY: docker-cleanup
docker-cleanup: ## Nettoyer les images Docker inutilisées
	@echo "$(BLUE)Nettoyage des images Docker...$(NC)"
	@./deploy-docker.sh docker-cleanup
	@echo "$(GREEN)✓ Nettoyage Docker terminé$(NC)"

.PHONY: full-cleanup
full-cleanup: cleanup docker-cleanup ## Nettoyage complet (sauvegardes + Docker)

# Gestion des logs
.PHONY: logs
logs: ## Afficher les logs de déploiement
	@echo "$(BLUE)Logs de déploiement:$(NC)"
	@tail -f deploy.log

.PHONY: logs-server
logs-server: ## Afficher les logs du serveur
	@echo "$(BLUE)Logs du serveur:$(NC)"
	@sshpass -p $(SSH_PASSWORD) ssh -o StrictHostKeyChecking=no $(SSH_USER)@$(SSH_HOST) 'journalctl -u caddy -f'

.PHONY: logs-docker
logs-docker: ## Afficher les logs Docker (CONTAINER=nom)
	@if [ -z "$(CONTAINER)" ]; then \
		echo "$(RED)Erreur: Spécifiez CONTAINER=nom_du_conteneur$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Logs du conteneur $(CONTAINER):$(NC)"
	@sshpass -p $(SSH_PASSWORD) ssh -o StrictHostKeyChecking=no $(SSH_USER)@$(SSH_HOST) 'docker logs -f $(CONTAINER)'

# Sécurité
.PHONY: security-check
security-check: ## Vérifier la configuration de sécurité
	@echo "$(BLUE)Vérification de la sécurité...$(NC)"
	@sshpass -p $(SSH_PASSWORD) ssh -o StrictHostKeyChecking=no $(SSH_USER)@$(SSH_HOST) 'bash -s' < security-check.sh
	@echo "$(GREEN)✓ Vérification de sécurité terminée$(NC)"

.PHONY: update-security
update-security: ## Mettre à jour les règles de sécurité
	@echo "$(BLUE)Mise à jour de la sécurité...$(NC)"
	@sshpass -p $(SSH_PASSWORD) ssh -o StrictHostKeyChecking=no $(SSH_USER)@$(SSH_HOST) 'bash -s' < update-security.sh
	@echo "$(GREEN)✓ Sécurité mise à jour$(NC)"

# Maintenance
.PHONY: backup
backup: ## Créer une sauvegarde complète
	@echo "$(BLUE)Création d'une sauvegarde complète...$(NC)"
	@sshpass -p $(SSH_PASSWORD) ssh -o StrictHostKeyChecking=no $(SSH_USER)@$(SSH_HOST) 'tar -czf /tmp/full-backup-$(shell date +%Y%m%d_%H%M%S).tar.gz $(DOCKER_COMPOSE_DIR) $(REMOTE_DEPLOY_DIR) /etc/caddy'
	@echo "$(GREEN)✓ Sauvegarde complète créée$(NC)"

.PHONY: restore
restore: ## Restaurer depuis une sauvegarde (BACKUP_FILE=chemin)
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "$(RED)Erreur: Spécifiez BACKUP_FILE=chemin_vers_sauvegarde$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Restauration depuis $(BACKUP_FILE)...$(NC)"
	@sshpass -p $(SSH_PASSWORD) ssh -o StrictHostKeyChecking=no $(SSH_USER)@$(SSH_HOST) 'tar -xzf $(BACKUP_FILE) -C /'
	@echo "$(GREEN)✓ Restauration terminée$(NC)"

# Déploiement Docker avec images pré-construites
.PHONY: deploy-docker-image
deploy-docker-image: ## Déployer une image Docker (APP=nom IMAGE=image TAG=tag PORT=port DOMAIN=domaine)
	@if [ -z "$(APP)" ] || [ -z "$(IMAGE)" ] || [ -z "$(TAG)" ]; then \
		echo "$(RED)Erreur: Spécifiez APP=nom IMAGE=image TAG=tag$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Déploiement de l'image Docker $(IMAGE):$(TAG)...$(NC)"
	@./docker-image-deploy.sh deploy $(APP) $(IMAGE) $(TAG) $(PORT) $(DOMAIN)
	@echo "$(GREEN)✓ Image Docker déployée avec succès$(NC)"

.PHONY: update-docker-image
update-docker-image: ## Mettre à jour une image Docker (APP=nom IMAGE=image TAG=tag)
	@if [ -z "$(APP)" ] || [ -z "$(IMAGE)" ] || [ -z "$(TAG)" ]; then \
		echo "$(RED)Erreur: Spécifiez APP=nom IMAGE=image TAG=tag$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Mise à jour de l'image Docker $(IMAGE):$(TAG)...$(NC)"
	@./docker-image-deploy.sh update $(APP) $(IMAGE) $(TAG)
	@echo "$(GREEN)✓ Image Docker mise à jour$(NC)"

.PHONY: deploy-github-docker
deploy-github-docker: ## Déployer depuis GitHub (REPO=repo APP=nom TYPE=type PORT=port)
	@if [ -z "$(REPO)" ] || [ -z "$(APP)" ] || [ -z "$(TYPE)" ]; then \
		echo "$(RED)Erreur: Spécifiez REPO=repo APP=nom TYPE=type$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Déploiement depuis GitHub: $(REPO)...$(NC)"
	@./docker-image-deploy.sh github-deploy $(REPO) $(APP) $(TYPE) $(PORT)
	@echo "$(GREEN)✓ Déploiement GitHub Docker terminé$(NC)"

.PHONY: list-docker-images
list-docker-images: ## Lister les images Docker déployées
	@echo "$(BLUE)Liste des images Docker:$(NC)"
	@./docker-image-deploy.sh list-images

# Tests
.PHONY: test-connection
test-connection: ## Tester la connexion SSH
	@echo "$(BLUE)Test de connexion SSH...$(NC)"
	@sshpass -p $(SSH_PASSWORD) ssh -o StrictHostKeyChecking=no $(SSH_USER)@$(SSH_HOST) 'echo "Connexion SSH réussie"'
	@echo "$(GREEN)✓ Connexion SSH OK$(NC)"

.PHONY: test-docker
test-docker: ## Tester Docker sur le serveur
	@echo "$(BLUE)Test de Docker...$(NC)"
	@sshpass -p $(SSH_PASSWORD) ssh -o StrictHostKeyChecking=no $(SSH_USER)@$(SSH_HOST) 'docker --version && docker ps'
	@echo "$(GREEN)✓ Docker OK$(NC)"

.PHONY: test-caddy
test-caddy: ## Tester Caddy sur le serveur
	@echo "$(BLUE)Test de Caddy...$(NC)"
	@sshpass -p $(SSH_PASSWORD) ssh -o StrictHostKeyChecking=no $(SSH_USER)@$(SSH_HOST) 'caddy version && systemctl status caddy'
	@echo "$(GREEN)✓ Caddy OK$(NC)"

.PHONY: test-all
test-all: test-connection test-docker test-caddy ## Tous les tests

# Installation des dépendances locales
.PHONY: install-deps
install-deps: ## Installer les dépendances locales
	@echo "$(BLUE)Installation des dépendances locales...$(NC)"
	@sudo apt update
	@sudo apt install -y sshpass jq git make
	@echo "$(GREEN)✓ Dépendances installées$(NC)"

# Configuration SSL
.PHONY: setup-ssl
setup-ssl: ## Configurer SSL avec Let's Encrypt
	@echo "$(BLUE)Configuration SSL...$(NC)"
	@sshpass -p $(SSH_PASSWORD) ssh -o StrictHostKeyChecking=no $(SSH_USER)@$(SSH_HOST) 'caddy trust && caddy reload --config /etc/caddy/Caddyfile'
	@echo "$(GREEN)✓ SSL configuré$(NC)"

.PHONY: create-subdomain
create-subdomain: ## Créer un sous-domaine (APP=nom TYPE=static|node|python|php PORT=port)
	@if [ -z "$(APP)" ] || [ -z "$(TYPE)" ]; then \
		echo "$(RED)Erreur: Spécifiez APP=nom TYPE=static|node|python|php$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Création du sous-domaine $(APP)...$(NC)"
	@./caddy-manager.sh create-subdomain $(APP) $(TYPE) $(PORT)
	@echo "$(GREEN)✓ Sous-domaine $(APP).qiwiiz.space créé$(NC)"

.PHONY: create-alias
create-alias: ## Créer un alias pour un domaine externe (APP=nom DOMAIN=domaine PORT=port)
	@if [ -z "$(APP)" ] || [ -z "$(DOMAIN)" ]; then \
		echo "$(RED)Erreur: Spécifiez APP=nom DOMAIN=domaine$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Création de l'alias $(DOMAIN) pour $(APP)...$(NC)"
	@./ssl-deploy.sh create-alias $(APP) $(DOMAIN) $(PORT)
	@echo "$(GREEN)✓ Alias $(DOMAIN) créé pour $(APP)$(NC)"

.PHONY: renew-ssl
renew-ssl: ## Renouveler tous les certificats SSL
	@echo "$(BLUE)Renouvellement des certificats SSL...$(NC)"
	@./ssl-deploy.sh renew-ssl
	@echo "$(GREEN)✓ Certificats SSL renouvelés$(NC)"

# Monitoring
.PHONY: monitor
monitor: ## Afficher le monitoring en temps réel
	@echo "$(BLUE)Monitoring en temps réel...$(NC)"
	@sshpass -p $(SSH_PASSWORD) ssh -o StrictHostKeyChecking=no $(SSH_USER)@$(SSH_HOST) 'watch -n 5 "docker stats --no-stream && echo && systemctl status caddy --no-pager"'

# Redémarrage des services
.PHONY: restart-caddy
restart-caddy: ## Redémarrer Caddy
	@echo "$(BLUE)Redémarrage de Caddy...$(NC)"
	@sshpass -p $(SSH_PASSWORD) ssh -o StrictHostKeyChecking=no $(SSH_USER)@$(SSH_HOST) 'systemctl restart caddy'
	@echo "$(GREEN)✓ Caddy redémarré$(NC)"

.PHONY: restart-docker
restart-docker: ## Redémarrer Docker
	@echo "$(BLUE)Redémarrage de Docker...$(NC)"
	@sshpass -p $(SSH_PASSWORD) ssh -o StrictHostKeyChecking=no $(SSH_USER)@$(SSH_HOST) 'systemctl restart docker'
	@echo "$(GREEN)✓ Docker redémarré$(NC)"

# Informations système
.PHONY: info
info: ## Afficher les informations système
	@echo "$(BLUE)Informations système:$(NC)"
	@echo "Serveur: $(SSH_USER)@$(SSH_HOST)"
	@echo "Domaine: $(DOMAIN)"
	@echo "Répertoire de déploiement: $(REMOTE_DEPLOY_DIR)"
	@echo "Répertoire Docker Compose: $(DOCKER_COMPOSE_DIR)"
	@sshpass -p $(SSH_PASSWORD) ssh -o StrictHostKeyChecking=no $(SSH_USER)@$(SSH_HOST) 'echo "OS: $$(lsb_release -d | cut -f2)" && echo "Uptime: $$(uptime -p)" && echo "Load: $$(uptime | awk -F"load average:" '"'"'{ print $$2 }'"'"')"'

# Interface interactive
.PHONY: interactive
interactive: ## Lancer l'interface interactive
	@echo "$(BLUE)Lancement de l'interface interactive...$(NC)"
	@./interactive-deploy.sh
