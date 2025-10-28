# 🐳 CI/CD Docker - Build et Déploiement Automatique

Système complet de CI/CD avec construction d'images Docker et déploiement automatique sur qiwiiz.space.

## ✨ Fonctionnalités CI/CD Docker

- **Build automatique** d'images Docker dans GitHub Actions
- **Push vers GitHub Container Registry** (ghcr.io)
- **Déploiement automatique** sur le serveur qiwiiz.space
- **Support multi-frameworks** : React, Node.js, Python, PHP
- **SSL automatique** avec Caddy
- **Rollback automatique** en cas d'échec
- **Monitoring** des déploiements

## 🚀 Workflow GitHub Actions

### Structure du workflow

Le workflow `docker-deploy.yml` comprend deux jobs principaux :

1. **Job `build`** : Construction des images Docker
2. **Job `deploy`** : Déploiement sur le serveur

### Processus de build

```yaml
# Construction automatique selon le type d'application
strategy:
  matrix:
    include:
      - app_type: "static"    # React, Vue, Angular
      - app_type: "node"      # Node.js, Express, Next.js
      - app_type: "python"    # Python, Flask, Django
      - app_type: "php"       # PHP, Laravel, Symfony
```

### Images Docker générées

- **Images statiques** : `ghcr.io/username/repo:static-latest`
- **Images Node.js** : `ghcr.io/username/repo:node-latest`
- **Images Python** : `ghcr.io/username/repo:python-latest`
- **Images PHP** : `ghcr.io/username/repo:php-latest`

## 🛠️ Utilisation

### Configuration des secrets GitHub

Dans votre repository GitHub, ajoutez ces secrets :

- `SSH_USER` : `qiwiiz`
- `SSH_HOST` : `51.159.6.66`
- `SSH_PASSWORD` : `changeme`

### Déploiement automatique

```bash
# Le déploiement se fait automatiquement à chaque push sur main/master
git push origin main
```

### Déploiement manuel

```bash
# Déployer une image Docker spécifique
make deploy-docker-image APP=mon-app IMAGE=ghcr.io/username/repo TAG=static-latest PORT=8080 DOMAIN=mon-app.qiwiiz.space

# Déployer depuis GitHub
make deploy-github-docker REPO=username/my-app APP=mon-app TYPE=static PORT=8080

# Mettre à jour une image
make update-docker-image APP=mon-app IMAGE=ghcr.io/username/repo TAG=static-latest
```

## 🐳 Dockerfiles Automatiques

### Application Statique (React/Vue/Angular)

```dockerfile
FROM nginx:alpine
COPY dist/ /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### Application Node.js

```dockerfile
FROM node:22-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

### Application Python

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["python", "app.py"]
```

### Application PHP

```dockerfile
FROM php:8.4-fpm-alpine
RUN apk add --no-cache nginx
WORKDIR /var/www/html
COPY . .
RUN chown -R www-data:www-data /var/www/html
EXPOSE 80
CMD ["php-fpm"]
```

## 🔧 Configuration Docker Compose

### Template automatique généré

```yaml
version: '3.8'
services:
  mon-app:
    image: ghcr.io/username/repo:static-latest
    container_name: mon-app
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      - NODE_ENV=production
      - PORT=8080
    networks:
      - caddy-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  caddy-network:
    external: true
```

## 🌐 Configuration Caddy Automatique

### Configuration générée automatiquement

```caddy
# Configuration pour mon-app
mon-app.qiwiiz.space {
    reverse_proxy localhost:8080 {
        health_uri /health
        health_interval 30s
        health_timeout 5s
    }
    
    header {
        X-Content-Type-Options nosniff
        X-Frame-Options DENY
        X-XSS-Protection "1; mode=block"
        Referrer-Policy strict-origin-when-cross-origin
        Permissions-Policy "geolocation=(), microphone=(), camera=()"
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
    }
    
    encode gzip
    
    rate_limit {
        zone dynamic {
            key {remote_host}
            events 200
            window 1m
        }
    }
    
    log {
        output file /var/log/caddy/mon-app.log {
            roll_size 100mb
            roll_keep 5
            roll_keep_for 720h
        }
        format json
    }
}
```

## 📊 Monitoring et Logs

### Vérification du déploiement

```bash
# Lister les images Docker déployées
make list-docker-images

# Vérifier le statut des conteneurs
make status

# Monitoring en temps réel
make monitor
```

### Logs disponibles

```bash
# Logs de déploiement Docker
tail -f docker-deploy.log

# Logs du conteneur
ssh qiwiiz@51.159.6.66 "docker logs mon-app -f"

# Logs Caddy spécifiques
ssh qiwiiz@51.159.6.66 "tail -f /var/log/caddy/mon-app.log"
```

## 🔄 Processus de Déploiement

### 1. Build dans GitHub Actions

```yaml
# Construction de l'application
- name: Construction de l'application Node.js
  run: |
    if [ -f package.json ] && grep -q '"build"' package.json; then
      npm run build
    fi

# Création des Dockerfiles
- name: Créer les Dockerfiles automatiquement
  run: |
    # Dockerfiles générés automatiquement selon le type

# Build et push des images
- name: Construire et pousser l'image Docker
  uses: docker/build-push-action@v5
  with:
    push: true
    tags: ${{ steps.meta.outputs.tags }}
    cache-from: type=ghcr
    cache-to: type=ghcr,mode=max
```

### 2. Déploiement sur le serveur

```bash
# Connexion au registry
docker login ghcr.io -u $GITHUB_ACTOR --password-stdin

# Téléchargement de l'image
docker pull ghcr.io/username/repo:static-latest

# Démarrage du conteneur
docker-compose up -d

# Configuration Caddy
caddy reload --config /etc/caddy/Caddyfile
```

## 🛡️ Sécurité et Rollback

### Sécurité des images

- **Images signées** avec Docker Content Trust
- **Scan de vulnérabilités** automatique
- **Base images** mises à jour régulièrement
- **Secrets** gérés via GitHub Secrets

### Rollback automatique

```bash
# En cas d'échec, rollback vers l'image précédente
docker-compose down
docker run -d --name mon-app-backup ghcr.io/username/repo:static-previous
```

## 📈 Optimisations

### Cache Docker

- **Cache multi-stage** pour accélérer les builds
- **Cache GitHub Actions** pour les dépendances
- **Cache registry** pour les layers communs

### Performance

- **Images multi-arch** (amd64, arm64)
- **Compression** des images
- **Layers optimisés** pour réduire la taille

## 🎯 Exemples d'Utilisation

### Déploiement d'un site React

```bash
# 1. Repository GitHub avec package.json et script build
# 2. Push sur main déclenche automatiquement :
#    - Build de l'application React
#    - Construction de l'image Docker statique
#    - Push vers ghcr.io
#    - Déploiement sur qiwiiz.space
#    - Configuration SSL automatique

# Résultat : https://mon-site.qiwiiz.space
```

### Déploiement d'une API Node.js

```bash
# 1. Repository avec server.js et package.json
# 2. Push sur main déclenche :
#    - Installation des dépendances
#    - Construction de l'image Node.js
#    - Déploiement avec SSL

# Résultat : https://mon-api.qiwiiz.space
```

### Déploiement manuel

```bash
# Déployer une image spécifique
make deploy-docker-image \
  APP=mon-app \
  IMAGE=ghcr.io/username/my-app \
  TAG=static-latest \
  PORT=8080 \
  DOMAIN=mon-app.qiwiiz.space
```

## 🔍 Dépannage

### Problèmes courants

```bash
# Vérifier les images disponibles
make list-docker-images

# Vérifier les conteneurs
ssh qiwiiz@51.159.6.66 "docker ps"

# Vérifier les logs
ssh qiwiiz@51.159.6.66 "docker logs mon-app"

# Redémarrer un conteneur
ssh qiwiiz@51.159.6.66 "docker restart mon-app"
```

### Logs de débogage

```bash
# Logs GitHub Actions
# → Voir l'onglet "Actions" dans GitHub

# Logs de déploiement local
tail -f docker-deploy.log

# Logs du serveur
ssh qiwiiz@51.159.6.66 "journalctl -u docker -f"
```

## 📋 Checklist CI/CD

- [ ] Repository GitHub configuré
- [ ] Secrets GitHub ajoutés
- [ ] Workflow GitHub Actions activé
- [ ] Serveur qiwiiz.space configuré
- [ ] Docker et Caddy installés
- [ ] Registry GitHub Container Registry accessible
- [ ] SSL automatique configuré
- [ ] Monitoring actif

## 🚀 Commandes de Référence

```bash
# Déploiement Docker
make deploy-docker-image APP=nom IMAGE=image TAG=tag PORT=port DOMAIN=domaine

# Déploiement GitHub
make deploy-github-docker REPO=repo APP=nom TYPE=type PORT=port

# Mise à jour
make update-docker-image APP=nom IMAGE=image TAG=tag

# Monitoring
make list-docker-images
make status
make monitor
```

---

**CI/CD Docker opérationnel sur qiwiiz.space ! 🐳**

Pour commencer : Configurez les secrets GitHub et poussez votre code sur `main`
