# 🚀 Système de Déploiement Automatisé - qiwiiz.space

Un système complet de déploiement automatisé pour applications web avec **Caddy**, **Docker** et **Makefile**, spécialement configuré pour qiwiiz.space.

## ✨ Fonctionnalités

- **Déploiement Docker** d'applications statiques et dynamiques
- **Serveur web Caddy** avec SSL automatique
- **Makefile** pour automatiser toutes les tâches
- **Sécurité avancée** avec fail2ban, monitoring et alertes
- **Rollback automatique** en cas d'échec
- **Intégration GitHub** avec GitHub Actions
- **Monitoring en temps réel** des services et ressources

## 🛠️ Configuration du Serveur

### Informations de connexion
- **Serveur**: qiwiiz@51.159.6.66
- **Domaine**: https://qiwiiz.space
- **Serveur web**: Caddy
- **Conteneurisation**: Docker
- **Sécurité**: fail2ban, UFW, monitoring

### Installation rapide

```bash
# 1. Configuration du serveur
make setup-server

# 2. Vérification de la sécurité
make security-check

# 3. Test de connexion
make test-all
```

## 📋 Utilisation avec Makefile

### Commandes principales

```bash
# Configuration
make setup-server          # Configurer le serveur
make install-deps          # Installer les dépendances locales

# Déploiement
make deploy APP=react      # Déployer une app React
make deploy APP=node       # Déployer une API Node.js
make deploy APP=python     # Déployer une app Python
make deploy APP=php        # Déployer une app PHP

# Gestion
make list                  # Lister les déploiements
make status               # Statut des services
make cleanup              # Nettoyer les sauvegardes
make docker-cleanup        # Nettoyer Docker

# Monitoring
make logs                 # Logs de déploiement
make logs-server          # Logs du serveur
make logs-docker CONTAINER=nom  # Logs d'un conteneur
make monitor              # Monitoring temps réel

# Sécurité
make security-check       # Vérifier la sécurité
make update-security      # Mettre à jour la sécurité
make setup-ssl            # Configurer SSL

# Maintenance
make backup               # Sauvegarde complète
make restore BACKUP_FILE=chemin  # Restaurer
make info                 # Informations système
```

## 🐳 Déploiement Docker

### Applications statiques (React, Vue, Angular)

```bash
# Configuration
cat > react-config.json << 'EOF'
{
  "app_name": "mon-app-react",
  "app_type": "static",
  "build_dir": "./build",
  "domain": "app.qiwiiz.space"
}
EOF

# Déploiement
make deploy APP=react
```

### Applications dynamiques (Node.js, Python, PHP)

```bash
# Configuration Node.js
cat > node-config.json << 'EOF'
{
  "app_name": "mon-api-node",
  "app_type": "dynamic",
  "build_dir": "./",
  "domain": "api.qiwiiz.space",
  "framework": "node",
  "port": 3000
}
EOF

# Déploiement
make deploy APP=node
```

## 🔒 Sécurité Avancée

### Vérification de sécurité

```bash
# Vérifier la configuration de sécurité
make security-check

# Mettre à jour la sécurité
make update-security
```

### Fonctionnalités de sécurité

- **Pare-feu UFW** avec règles avancées
- **Fail2ban** pour détecter les attaques
- **SSL automatique** avec Let's Encrypt
- **Monitoring des fichiers** avec AIDE
- **Surveillance réseau** avec psad
- **Alertes automatiques** par email/webhook
- **Logs centralisés** et rotation automatique

## 📊 Monitoring et Logs

### Logs disponibles

```bash
# Logs de déploiement local
make logs

# Logs du serveur Caddy
make logs-server

# Logs d'un conteneur spécifique
make logs-docker CONTAINER=mon-app

# Monitoring en temps réel
make monitor
```

### Surveillance automatique

- **Utilisation CPU/Mémoire**
- **Espace disque**
- **Connexions réseau**
- **Tentatives d'intrusion**
- **Statut des services**
- **Certificats SSL**

## 🔄 Rollback et Sauvegardes

### Sauvegardes automatiques

- Chaque déploiement crée une sauvegarde
- Stockage dans `/tmp/deploy-backups/`
- Format : `{app_name}_backup_{timestamp}`

### Rollback automatique

```bash
# Rollback en cas d'échec
# Le système effectue automatiquement un rollback si :
# - La configuration Caddy est invalide
# - Le conteneur Docker ne démarre pas
# - Une erreur survient pendant le déploiement
```

### Gestion des sauvegardes

```bash
# Nettoyer les anciennes sauvegardes
make cleanup DAYS=7

# Sauvegarde complète
make backup

# Restaurer depuis une sauvegarde
make restore BACKUP_FILE=/tmp/full-backup-20240101_120000.tar.gz
```

## 🌐 Configuration Caddy

### Configuration automatique

Le système configure automatiquement Caddy avec :

- **SSL automatique** pour tous les domaines
- **Headers de sécurité** (HSTS, CSP, etc.)
- **Compression gzip**
- **Cache des assets statiques**
- **Rate limiting**
- **Reverse proxy** pour les applications

### Configuration manuelle

```bash
# Éditer la configuration Caddy
ssh qiwiiz@51.159.6.66 "sudo nano /etc/caddy/Caddyfile"

# Recharger Caddy
make restart-caddy
```

## 🐳 Gestion Docker

### Conteneurs et réseaux

```bash
# Lister les conteneurs
make list

# Statut des conteneurs
make status

# Nettoyer les images inutilisées
make docker-cleanup
```

### Réseau Caddy

- Tous les conteneurs utilisent le réseau `caddy-network`
- Communication interne sécurisée
- Reverse proxy automatique

## 📈 Performance et Optimisation

### Optimisations automatiques

- **Compression gzip** pour tous les contenus
- **Cache des assets statiques** (1 an)
- **Limitation de débit** pour éviter les abus
- **Headers de sécurité** optimisés
- **Monitoring des ressources** en temps réel

### Surveillance des performances

```bash
# Monitoring en temps réel
make monitor

# Informations système
make info
```

## 🔧 Dépannage

### Problèmes courants

```bash
# Test de connexion
make test-connection

# Test Docker
make test-docker

# Test Caddy
make test-caddy

# Tous les tests
make test-all
```

### Logs de débogage

```bash
# Logs de déploiement
tail -f deploy.log

# Logs du serveur
make logs-server

# Logs Docker
make logs-docker CONTAINER=nom
```

## 🚀 Déploiement depuis GitHub

### Configuration des secrets

Dans votre repository GitHub, ajoutez :
- `SSH_USER`: `qiwiiz`
- `SSH_HOST`: `51.159.6.66`
- `SSH_PASSWORD`: `changeme`

### Workflow automatique

```bash
# Déploiement automatique à chaque push
git push origin main
```

### Déploiement manuel

```bash
# Déployer depuis un repository GitHub
make deploy-github REPO=https://github.com/user/my-app.git CONFIG=config.json
```

## 📁 Structure du Projet

```
Deploy/
├── Makefile                    # Commandes automatisées
├── deploy-docker.sh           # Script de déploiement Docker
├── setup-server-caddy.sh      # Configuration serveur
├── security-check.sh          # Vérification sécurité
├── update-security.sh        # Mise à jour sécurité
├── examples/                  # Configurations d'exemple
│   ├── react-app.json
│   ├── node-api.json
│   ├── python-app.json
│   └── php-app.json
├── .github/workflows/         # GitHub Actions
│   └── deploy.yml
└── README.md                  # Cette documentation
```

## 🎯 Exemples d'Utilisation

### Déploiement d'une application React

```bash
# 1. Créer l'application
npx create-react-app mon-app
cd mon-app
npm run build

# 2. Configurer le déploiement
cat > deploy-config.json << 'EOF'
{
  "app_name": "mon-app-react",
  "app_type": "static",
  "build_dir": "./build",
  "domain": "app.qiwiiz.space"
}
EOF

# 3. Déployer
make deploy APP=react
```

### Déploiement d'une API Node.js

```bash
# 1. Créer l'API
mkdir mon-api
cd mon-api
npm init -y
npm install express

# 2. Créer server.js
cat > server.js << 'EOF'
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({ message: 'API déployée sur qiwiiz.space!' });
});

app.listen(port, () => {
  console.log(`Serveur démarré sur le port ${port}`);
});
EOF

# 3. Configurer le déploiement
cat > deploy-config.json << 'EOF'
{
  "app_name": "mon-api-node",
  "app_type": "dynamic",
  "build_dir": "./",
  "domain": "api.qiwiiz.space",
  "framework": "node",
  "port": 3000
}
EOF

# 4. Déployer
make deploy APP=node
```

## 🆘 Support et Maintenance

### Commandes de maintenance

```bash
# Mise à jour complète
make update-security

# Nettoyage complet
make full-cleanup

# Redémarrage des services
make restart-caddy
make restart-docker
```

### Surveillance continue

```bash
# Monitoring en temps réel
make monitor

# Vérification de sécurité
make security-check

# Informations système
make info
```

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

---

**Système de déploiement qiwiiz.space opérationnel ! 🚀**

Pour commencer : `make setup-server` puis `make deploy APP=react`
