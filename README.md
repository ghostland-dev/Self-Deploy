# 🚀 Système de Déploiement Automatisé

Un système complet de déploiement automatisé pour applications web (statiques et dynamiques) avec rollback automatique et intégration GitHub.

## ✨ Fonctionnalités

- **Déploiement automatique** d'applications statiques et dynamiques
- **Support multi-frameworks** : React, Vue, Angular, Node.js, Python, PHP
- **Rollback automatique** en cas d'échec
- **Intégration GitHub** avec GitHub Actions
- **Configuration nginx** automatique
- **Services systemd** pour les applications dynamiques
- **Monitoring et logs** détaillés
- **Sauvegardes automatiques** avant chaque déploiement

## 🛠️ Installation

### 1. Configuration du serveur

Exécutez le script de configuration sur votre serveur Ubuntu :

```bash
# Sur votre serveur Ubuntu (232.23.32.32)
sudo ./setup-server.sh
```

### 2. Installation des dépendances locales

Sur votre machine locale :

```bash
# Ubuntu/Debian
sudo apt install sshpass jq git

# macOS
brew install sshpass jq git

# Rendre les scripts exécutables
chmod +x deploy.sh github-deploy.sh setup-server.sh
```

## 📋 Configuration

### Variables d'environnement

Les informations de connexion sont configurées dans le script `deploy.sh` :

```bash
SSH_USER="user"
SSH_HOST="232.23.32.32"
SSH_PASSWORD="changeme"
```

### Fichiers de configuration

Créez un fichier JSON pour chaque application à déployer :

#### Application React/Vue/Angular (Statique)
```json
{
  "app_name": "mon-app-react",
  "app_type": "static",
  "build_dir": "./dist",
  "domain": "mon-app.qiwiiz.space"
}
```

#### API Node.js/Express (Dynamique)
```json
{
  "app_name": "mon-api-node",
  "app_type": "dynamic",
  "build_dir": "./",
  "domain": "api.qiwiiz.space",
  "framework": "node",
  "port": 3000
}
```

#### Application Next.js (Dynamique)
```json
{
  "app_name": "mon-app-nextjs",
  "app_type": "dynamic",
  "build_dir": "./",
  "domain": "app.qiwiiz.space",
  "framework": "next",
  "port": 3001
}
```

#### Application Python/Flask (Dynamique)
```json
{
  "app_name": "mon-app-python",
  "app_type": "dynamic",
  "build_dir": "./",
  "domain": "python.qiwiiz.space",
  "framework": "python",
  "port": 5000
}
```

#### Application PHP/Laravel (Dynamique)
```json
{
  "app_name": "mon-app-php",
  "app_type": "dynamic",
  "build_dir": "./",
  "domain": "php.qiwiiz.space",
  "framework": "php"
}
```

## 🚀 Utilisation

### Déploiement local

```bash
# Déployer une application
./deploy.sh deploy examples/react-app.json

# Lister les déploiements
./deploy.sh list

# Nettoyer les anciennes sauvegardes
./deploy.sh cleanup 7
```

### Déploiement avec GitHub

#### 1. Configuration des secrets GitHub

Dans votre repository GitHub, ajoutez ces secrets :

- `SSH_USER` : `user`
- `SSH_HOST` : `232.23.32.32`
- `SSH_PASSWORD` : `changeme`

#### 2. Utilisation du workflow GitHub Actions

Le fichier `.github/workflows/deploy.yml` est automatiquement déclenché lors des push sur `main` ou `master`.

#### 3. Déploiement manuel depuis GitHub

```bash
# Déployer depuis un repository GitHub
./github-deploy.sh deploy-github https://github.com/user/my-app.git examples/react-app.json
```

## 📁 Structure du projet

```
Deploy/
├── deploy.sh                 # Script principal de déploiement
├── github-deploy.sh          # Script de déploiement GitHub
├── setup-server.sh           # Script de configuration serveur
├── examples/                 # Exemples de configurations
│   ├── react-app.json
│   ├── node-api.json
│   ├── nextjs-app.json
│   ├── python-app.json
│   └── php-app.json
├── .github/workflows/        # Workflows GitHub Actions
│   └── deploy.yml
└── README.md                 # Cette documentation
```

## 🔧 Commandes disponibles

### Script principal (`deploy.sh`)

```bash
./deploy.sh deploy <config.json>     # Déployer une application
./deploy.sh list                     # Lister les déploiements
./deploy.sh cleanup [days]           # Nettoyer les sauvegardes
./deploy.sh help                     # Afficher l'aide
```

### Script GitHub (`github-deploy.sh`)

```bash
./github-deploy.sh deploy <config.json> [environment]           # Déployer avec GitHub Actions
./github-deploy.sh deploy-github <repo-url> <config.json>        # Déployer depuis GitHub
./github-deploy.sh help                                          # Afficher l'aide
```

## 🛡️ Sécurité et Rollback

### Sauvegardes automatiques

- Chaque déploiement crée une sauvegarde automatique
- Les sauvegardes sont stockées dans `/tmp/deploy-backups/`
- Format : `{app_name}_backup_{timestamp}`

### Rollback automatique

Le système effectue un rollback automatique si :
- La configuration nginx est invalide
- Le service systemd ne démarre pas
- Une erreur survient pendant le déploiement

### Rollback manuel

```bash
# Lister les sauvegardes disponibles
ssh user@232.23.32.32 "ls -la /tmp/deploy-backups/"

# Restaurer une sauvegarde spécifique
ssh user@232.23.32.32 "cp -r /tmp/deploy-backups/mon-app_backup_20240101_120000 /var/www/mon-app"
```

## 📊 Monitoring

### Logs

- **Déploiement** : `deploy.log` (local)
- **Serveur** : `/var/log/nginx/` et `/var/log/deploy/`
- **Services** : `journalctl -u {service-name}`

### Monitoring automatique

Le serveur inclut un script de monitoring qui vérifie :
- Statut des services (nginx, php-fpm)
- Utilisation de l'espace disque
- Utilisation de la mémoire
- Logs dans `/var/log/deploy/monitor.log`

## 🔍 Dépannage

### Problèmes courants

1. **Erreur de connexion SSH**
   ```bash
   # Tester la connexion
   ssh user@232.23.32.32
   ```

2. **Erreur de permissions**
   ```bash
   # Vérifier les permissions sur le serveur
   ssh user@232.23.32.32 "ls -la /var/www/"
   ```

3. **Service ne démarre pas**
   ```bash
   # Vérifier les logs du service
   ssh user@232.23.32.32 "journalctl -u mon-app -f"
   ```

4. **Configuration nginx invalide**
   ```bash
   # Tester la configuration nginx
   ssh user@232.23.32.32 "nginx -t"
   ```

### Logs utiles

```bash
# Logs de déploiement local
tail -f deploy.log

# Logs nginx
ssh user@232.23.32.32 "tail -f /var/log/nginx/error.log"

# Logs de monitoring
ssh user@232.23.32.32 "tail -f /var/log/deploy/monitor.log"
```

## 🌐 Configuration DNS

Pour que vos domaines fonctionnent, configurez vos enregistrements DNS :

```
A    mon-app.qiwiiz.space    → 232.23.32.32
A    api.qiwiiz.space        → 232.23.32.32
A    app.qiwiiz.space        → 232.23.32.32
```

## 🔐 SSL/HTTPS

Pour activer HTTPS :

```bash
# Sur le serveur
sudo certbot --nginx -d mon-app.qiwiiz.space
```

## 📈 Optimisations

### Performance nginx

Le script configure automatiquement :
- Compression gzip
- Cache des fichiers statiques
- Optimisation des connexions

### Monitoring avancé

Pour un monitoring plus avancé, considérez :
- Prometheus + Grafana
- ELK Stack (Elasticsearch, Logstash, Kibana)
- Uptime monitoring (UptimeRobot, Pingdom)

## 🤝 Contribution

Pour améliorer ce système :

1. Fork le repository
2. Créez une branche feature
3. Commitez vos changements
4. Poussez vers la branche
5. Ouvrez une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 🆘 Support

Pour toute question ou problème :

1. Vérifiez la documentation
2. Consultez les logs
3. Ouvrez une issue sur GitHub
4. Contactez l'équipe de développement

---

**Bon déploiement ! 🚀**

## Author

**Ismail.M**, Software Engineer & DevOps

- GitHub: [@ghostland-dev](https://github.com/ghostland-dev)
- Website: [ismail-mouyahada.com](https://www.ismail-mouyahada.com)
