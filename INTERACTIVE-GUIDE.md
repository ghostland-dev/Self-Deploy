# 🎮 Interface Interactive - Système de Déploiement qiwiiz.space

Interface utilisateur interactive complète pour le système de déploiement qiwiiz.space avec menus guidés et sélections intuitives.

## ✨ Fonctionnalités Interactives

- **🎨 Interface colorée** avec logo et menus stylisés
- **📋 Menus guidés** pour toutes les opérations
- **🔄 Navigation intuitive** entre les sections
- **✅ Confirmations** pour les actions importantes
- **📝 Saisie guidée** des paramètres
- **🎯 Suggestions automatiques** pour les sous-domaines
- **📊 Affichage en temps réel** des résultats

## 🚀 Lancement de l'Interface

### Méthode simple

```bash
# Lancer l'interface interactive
make interactive

# Ou directement
./interactive-deploy.sh
```

### Interface principale

```
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║    🚀 SYSTÈME DE DÉPLOIEMENT QIWIIZ.SPACE 🚀                ║
║                                                              ║
║    Déploiement automatisé avec Docker, Caddy et SSL         ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

🎉 Bienvenue dans le système de déploiement qiwiiz.space !
Ce système vous permet de déployer facilement vos applications
avec SSL automatique et gestion des sous-domaines.

📋 MENU PRINCIPAL
═══════════════════════════════════════════════════════════════

1. 🚀 Déploiement rapide
2. 🐳 Déploiement Docker
3. 🌐 Gestion des sous-domaines
4. 🔒 Gestion SSL
5. 📊 Monitoring et statut
6. 🛠️ Configuration serveur
7. 🔧 Maintenance
8. 📚 Aide et documentation
9. 🚪 Quitter

═══════════════════════════════════════════════════════════════
Votre choix [1-9]:
```

## 🎯 Menus Disponibles

### 1. 🚀 Déploiement Rapide

Menu pour déployer rapidement des applications avec SSL automatique :

```
🚀 DÉPLOIEMENT RAPIDE
═══════════════════════════════════════════════════════════════

1. 📱 Application React/Vue/Angular (statique)
2. 🔌 API Node.js/Express
3. 🐍 Application Python/Flask
4. 🐘 Application PHP/Laravel
5. 🔙 Retour au menu principal

═══════════════════════════════════════════════════════════════
```

**Exemple d'utilisation :**
- Sélectionnez `1` pour une app React
- Saisissez le nom : `mon-site`
- Confirmez le port : `8080`
- L'application est déployée automatiquement avec SSL

### 2. 🐳 Déploiement Docker

Menu pour déployer des images Docker pré-construites :

```
🐳 DÉPLOIEMENT DOCKER
═══════════════════════════════════════════════════════════════

1. 🚀 Déploiement avec image pré-construite
2. 📦 Déploiement depuis GitHub
3. 🔄 Mise à jour d'une application
4. 📋 Lister les applications déployées
5. 🔙 Retour au menu principal

═══════════════════════════════════════════════════════════════
```

**Exemple d'utilisation :**
- Sélectionnez `1` pour une image pré-construite
- Saisissez le nom : `mon-app`
- Saisissez l'image : `ghcr.io/username/repo`
- Saisissez le tag : `static-latest`
- Confirmez le port : `8080`

### 3. 🌐 Gestion des Sous-domaines

Menu pour gérer les sous-domaines qiwiiz.space :

```
🌐 GESTION DES SOUS-DOMAINES
═══════════════════════════════════════════════════════════════

1. 📋 Lister les sous-domaines disponibles
2. 📊 Voir les sous-domaines utilisés
3. 🎯 Suggérer un sous-domaine
4. 🔗 Assigner un sous-domaine
5. 🔓 Libérer un sous-domaine
6. 📈 Statut des sous-domaines
7. 🔙 Retour au menu principal

═══════════════════════════════════════════════════════════════
```

**Exemple d'utilisation :**
- Sélectionnez `3` pour une suggestion
- Saisissez le nom : `mon-api`
- Sélectionnez le type : `api`
- Le système suggère : `api1.qiwiiz.space`

### 4. 🔒 Gestion SSL

Menu pour gérer les certificats SSL :

```
🔒 GESTION SSL
═══════════════════════════════════════════════════════════════

1. 🔍 Vérifier les certificats SSL
2. 🔄 Renouveler les certificats
3. ⚙️ Configurer SSL
4. 📋 Lister les déploiements SSL
5. 🔙 Retour au menu principal

═══════════════════════════════════════════════════════════════
```

### 5. 📊 Monitoring et Statut

Menu pour surveiller les applications :

```
📊 MONITORING ET STATUT
═══════════════════════════════════════════════════════════════

1. 📈 Statut des services
2. 🐳 Conteneurs Docker
3. 🌐 Sites web actifs
4. 📊 Monitoring en temps réel
5. 📋 Logs des applications
6. 🔙 Retour au menu principal

═══════════════════════════════════════════════════════════════
```

### 6. 🛠️ Configuration Serveur

Menu pour configurer le serveur :

```
🛠️ CONFIGURATION SERVEUR
═══════════════════════════════════════════════════════════════

1. ⚙️ Configuration initiale du serveur
2. 🔒 Vérification de sécurité
3. 🔄 Mise à jour de sécurité
4. 🧪 Tests de connexion
5. 📊 Informations système
6. 🔙 Retour au menu principal

═══════════════════════════════════════════════════════════════
```

### 7. 🔧 Maintenance

Menu pour la maintenance du système :

```
🔧 MAINTENANCE
═══════════════════════════════════════════════════════════════

1. 🧹 Nettoyage des sauvegardes
2. 🐳 Nettoyage Docker
3. 💾 Sauvegarde complète
4. 🔄 Restauration
5. 🔙 Retour au menu principal

═══════════════════════════════════════════════════════════════
```

### 8. 📚 Aide et Documentation

Menu pour accéder à la documentation :

```
📚 AIDE ET DOCUMENTATION
═══════════════════════════════════════════════════════════════

1. 📖 Guide de démarrage rapide
2. 🐳 Documentation Docker
3. 🌐 Guide des sous-domaines
4. 🔒 Guide SSL
5. 🛠️ Commandes disponibles
6. 🔙 Retour au menu principal

═══════════════════════════════════════════════════════════════
```

## 🎨 Fonctionnalités de l'Interface

### Couleurs et Style

- **🔵 Bleu** : Informations générales
- **🟢 Vert** : Succès et confirmations
- **🔴 Rouge** : Erreurs et avertissements
- **🟡 Jaune** : Sélections et choix
- **🟣 Violet** : Titres et headers
- **🔵 Cyan** : Bordures et séparateurs

### Interactions Utilisateur

#### Saisie Guidée

```bash
📝 Nom de l'application: mon-app
🔌 Port de l'application [8080]: 3000
🐳 Image Docker (ex: ghcr.io/username/repo): ghcr.io/user/my-app
🏷️ Tag Docker [latest]: v1.0.0
```

#### Confirmations

```bash
❓ Déployer l'application 'mon-app' sur le port 3000 ? [y/N]: y
✅ Application déployée avec succès !

Appuyez sur Entrée pour continuer...
```

#### Sélections Multiples

```bash
Type d'application:
1. static
2. node
3. python
4. php
Votre choix [1-4]: 2
```

### Navigation

- **Retour au menu principal** : Option disponible dans chaque sous-menu
- **Quitter** : Option `9` dans le menu principal
- **Attente de touche** : `Appuyez sur Entrée pour continuer...`

## 🎯 Exemples d'Utilisation

### Déploiement d'un Site React

1. Lancez l'interface : `make interactive`
2. Sélectionnez `1` (Déploiement rapide)
3. Sélectionnez `1` (Application statique)
4. Saisissez le nom : `mon-site`
5. Confirmez le port : `8080`
6. Confirmez le déploiement : `y`
7. ✅ Site déployé sur `https://app1.qiwiiz.space`

### Déploiement d'une API Node.js

1. Lancez l'interface : `make interactive`
2. Sélectionnez `2` (Déploiement Docker)
3. Sélectionnez `1` (Image pré-construite)
4. Saisissez le nom : `mon-api`
5. Saisissez l'image : `ghcr.io/username/my-api`
6. Saisissez le tag : `node-latest`
7. Confirmez le port : `3000`
8. ✅ API déployée sur `https://api1.qiwiiz.space`

### Gestion des Sous-domaines

1. Lancez l'interface : `make interactive`
2. Sélectionnez `3` (Gestion sous-domaines)
3. Sélectionnez `3` (Suggestion)
4. Saisissez le nom : `mon-bot`
5. Sélectionnez le type : `bot`
6. ✅ Suggestion : `bot1.qiwiiz.space`

## 🔧 Fonctionnalités Avancées

### Suggestion Intelligente

L'interface suggère automatiquement le meilleur sous-domaine :

- **admin** → `admin.qiwiiz.space`
- **api** → `api1.qiwiiz.space` (premier disponible)
- **app** → `app1.qiwiiz.space` (premier disponible)
- **bot** → `bot1.qiwiiz.space` (premier disponible)

### Validation des Entrées

- **Vérification des champs requis**
- **Validation des formats**
- **Confirmation des actions critiques**
- **Messages d'erreur explicites**

### Affichage en Temps Réel

- **Statut des services** en direct
- **Logs des applications** en streaming
- **Monitoring** en temps réel
- **Progression** des opérations

## 🛡️ Sécurité

### Confirmations Obligatoires

- **Déploiements** : Confirmation requise
- **Suppressions** : Double confirmation
- **Mises à jour** : Confirmation avec détails
- **Actions critiques** : Confirmation explicite

### Validation des Paramètres

- **Noms d'applications** : Validation du format
- **Ports** : Vérification de la disponibilité
- **Images Docker** : Validation de l'existence
- **Sous-domaines** : Vérification de la disponibilité

## 📊 Monitoring Intégré

### Affichage des Statuts

```bash
📈 STATUT DES SERVICES
systemctl status caddy docker

🐳 CONTENEURS DOCKER
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'

🌐 SITES WEB ACTIFS
Liste des sous-domaines utilisés
```

### Logs en Temps Réel

- **Logs de déploiement** : `tail -f deploy.log`
- **Logs du serveur** : `journalctl -u caddy -f`
- **Logs Docker** : `docker logs -f`

## 🎮 Commandes de Référence

```bash
# Lancement de l'interface
make interactive
./interactive-deploy.sh

# Commandes directes (si nécessaire)
make quick-ssl APP=mon-app TYPE=static PORT=8080
make deploy-docker-image APP=mon-app IMAGE=ghcr.io/user/repo TAG=latest
make list-subdomains
make subdomain-status
```

## 🔍 Dépannage

### Problèmes Courants

```bash
# Interface ne se lance pas
chmod +x interactive-deploy.sh

# Dépendances manquantes
sudo apt install sshpass jq

# Problème de connexion SSH
make test-connection
```

### Logs de Débogage

```bash
# Logs de l'interface
tail -f interactive-deploy.log

# Logs de déploiement
tail -f deploy.log

# Logs du serveur
ssh qiwiiz@51.159.6.66 "journalctl -u caddy -f"
```

---

**Interface Interactive opérationnelle ! 🎮**

Pour commencer : `make interactive` et suivez les menus guidés !
