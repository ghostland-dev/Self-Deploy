# 🌐 Gestionnaire de Sous-domaines qiwiiz.space

Système complet de gestion des sous-domaines DNS pré-configurés pour qiwiiz.space avec assignation automatique et déploiement intelligent.

## ✨ Sous-domaines Disponibles

### 🌐 Sous-domaines principaux
- **admin.qiwiiz.space** - Interface d'administration
- **api.qiwiiz.space** - API principale
- **app.qiwiiz.space** - Application principale
- **bot.qiwiiz.space** - Bot principal
- **data.qiwiiz.space** - Interface de données

### 📱 Applications (app1-app9)
- **app1.qiwiiz.space** à **app9.qiwiiz.space**
- Parfait pour les applications frontend, sites statiques, dashboards

### 🔌 APIs (api1-api9)
- **api1.qiwiiz.space** à **api9.qiwiiz.space**
- Idéal pour les APIs backend, microservices, services

### 🤖 Bots (bot1-bot9)
- **bot1.qiwiiz.space** à **bot9.qiwiiz.space**
- Parfait pour les bots, automations, services de traitement

## 🚀 Utilisation Rapide

### Lister les sous-domaines disponibles

```bash
# Voir tous les sous-domaines disponibles
make list-subdomains

# Voir les sous-domaines utilisés
make list-used-subdomains

# Statut complet des sous-domaines
make subdomain-status
```

### Assignation manuelle

```bash
# Assigner un sous-domaine spécifique
make assign-subdomain APP=mon-app SUBDOMAIN=app1 TYPE=static PORT=8080

# Assigner une API
make assign-subdomain APP=mon-api SUBDOMAIN=api1 TYPE=api PORT=3000

# Assigner un bot
make assign-subdomain APP=mon-bot SUBDOMAIN=bot1 TYPE=bot PORT=3000
```

### Suggestion automatique

```bash
# Obtenir une suggestion de sous-domaine
make suggest-subdomain APP=mon-app TYPE=static
# → Suggestion: app1.qiwiiz.space

make suggest-subdomain APP=mon-api TYPE=api
# → Suggestion: api1.qiwiiz.space
```

### Déploiement avec sous-domaine automatique

```bash
# Déploiement automatique avec suggestion de sous-domaine
make deploy-auto-subdomain \
  APP=mon-app \
  TYPE=static \
  PORT=8080 \
  IMAGE=ghcr.io/username/repo \
  TAG=static-latest
```

## 🛠️ Scripts Avancés

### Gestionnaire de sous-domaines (`subdomain-manager.sh`)

```bash
# Lister les sous-domaines disponibles
./subdomain-manager.sh list-available

# Lister les sous-domaines utilisés
./subdomain-manager.sh list-used

# Assigner un sous-domaine
./subdomain-manager.sh assign mon-app app1 static 8080

# Libérer un sous-domaine
./subdomain-manager.sh release app1

# Suggérer un sous-domaine
./subdomain-manager.sh suggest mon-api api

# Déploiement automatique
./subdomain-manager.sh deploy-auto mon-app static 8080 ghcr.io/user/repo static-latest

# Statut des sous-domaines
./subdomain-manager.sh status
```

## 🎯 Logique de Suggestion Intelligente

### Types d'applications et suggestions

| Type | Suggestion | Description |
|------|------------|-------------|
| `admin` | `admin` | Interface d'administration |
| `api` | `api1`, `api2`, etc. | APIs backend |
| `app` | `app1`, `app2`, etc. | Applications frontend |
| `bot` | `bot1`, `bot2`, etc. | Bots et automations |
| `data` | `data` | Interface de données |
| `static` | `app1`, `app2`, etc. | Sites statiques |
| `dynamic` | `app1`, `app2`, etc. | Applications dynamiques |

### Algorithme de suggestion

1. **Vérification du type** d'application
2. **Recherche du premier sous-domaine** disponible dans la catégorie
3. **Assignation automatique** si disponible
4. **Fallback** vers une catégorie alternative si nécessaire

## 🔧 Configuration Automatique

### Configuration Caddy générée

```caddy
# Configuration pour mon-app
app1.qiwiiz.space {
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
        zone static {
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

## 📊 Monitoring des Sous-domaines

### Vérification du statut

```bash
# Statut complet
make subdomain-status

# Vérifier les certificats SSL
ssh qiwiiz@51.159.6.66 "caddy list-certificates | grep qiwiiz.space"

# Vérifier les conteneurs actifs
ssh qiwiiz@51.159.6.66 "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'"
```

### Logs spécifiques

```bash
# Logs d'une application spécifique
ssh qiwiiz@51.159.6.66 "tail -f /var/log/caddy/mon-app.log"

# Logs de déploiement
tail -f subdomain-manager.log
```

## 🎯 Exemples d'Utilisation

### Déploiement d'un site React

```bash
# 1. Suggestion automatique
make suggest-subdomain APP=mon-site TYPE=static
# → Suggestion: app1.qiwiiz.space

# 2. Déploiement avec sous-domaine automatique
make deploy-auto-subdomain \
  APP=mon-site \
  TYPE=static \
  PORT=8080 \
  IMAGE=ghcr.io/username/my-react-app \
  TAG=static-latest

# 3. Résultat
# → https://app1.qiwiiz.space
```

### Déploiement d'une API Node.js

```bash
# 1. Suggestion automatique
make suggest-subdomain APP=mon-api TYPE=api
# → Suggestion: api1.qiwiiz.space

# 2. Déploiement
make deploy-auto-subdomain \
  APP=mon-api \
  TYPE=api \
  PORT=3000 \
  IMAGE=ghcr.io/username/my-api \
  TAG=node-latest

# 3. Résultat
# → https://api1.qiwiiz.space
```

### Déploiement d'un bot

```bash
# 1. Suggestion automatique
make suggest-subdomain APP=mon-bot TYPE=bot
# → Suggestion: bot1.qiwiiz.space

# 2. Déploiement
make deploy-auto-subdomain \
  APP=mon-bot \
  TYPE=bot \
  PORT=3000 \
  IMAGE=ghcr.io/username/my-bot \
  TAG=node-latest

# 3. Résultat
# → https://bot1.qiwiiz.space
```

## 🔄 Gestion des Sous-domaines

### Libération d'un sous-domaine

```bash
# Libérer un sous-domaine
./subdomain-manager.sh release app1

# Vérifier la libération
make list-used-subdomains
```

### Réassignation

```bash
# Réassigner un sous-domaine à une autre application
make assign-subdomain APP=nouvelle-app SUBDOMAIN=app1 TYPE=static PORT=8080
```

## 📋 Mapping des Applications

### Création du mapping

```bash
# Créer le mapping des applications
./subdomain-manager.sh create-mapping

# Le fichier app-mapping.json est créé avec :
{
  "applications": {
    "admin": {
      "subdomain": "admin",
      "type": "admin",
      "port": 8080,
      "description": "Interface d'administration"
    },
    "api": {
      "subdomain": "api",
      "type": "api",
      "port": 3000,
      "description": "API principale"
    }
  },
  "available_subdomains": {
    "apps": ["app1", "app2", "app3", "app4", "app5", "app6", "app7", "app8", "app9"],
    "apis": ["api1", "api2", "api3", "api4", "api5", "api6", "api7", "api8", "api9"],
    "bots": ["bot1", "bot2", "bot3", "bot4", "bot5", "bot6", "bot7", "bot8", "bot9"]
  }
}
```

## 🛡️ Sécurité et SSL

### SSL automatique

- **Certificats Let's Encrypt** automatiques pour tous les sous-domaines
- **Renouvellement automatique** des certificats
- **Headers de sécurité** complets
- **Rate limiting** par type d'application

### Vérification SSL

```bash
# Vérifier tous les certificats
ssh qiwiiz@51.159.6.66 "caddy list-certificates | grep qiwiiz.space"

# Tester un sous-domaine spécifique
curl -I https://app1.qiwiiz.space
```

## 🔍 Dépannage

### Problèmes courants

```bash
# Vérifier qu'un sous-domaine est disponible
make list-subdomains

# Vérifier les sous-domaines utilisés
make list-used-subdomains

# Vérifier la configuration Caddy
ssh qiwiiz@51.159.6.66 "caddy validate --config /etc/caddy/Caddyfile"

# Redémarrer Caddy
ssh qiwiiz@51.159.6.66 "systemctl restart caddy"
```

### Logs de débogage

```bash
# Logs du gestionnaire de sous-domaines
tail -f subdomain-manager.log

# Logs Caddy
ssh qiwiiz@51.159.6.66 "journalctl -u caddy -f"

# Logs Docker
ssh qiwiiz@51.159.6.66 "docker logs mon-app -f"
```

## 📈 Optimisations

### Performance

- **Cache DNS** optimisé
- **Compression gzip** automatique
- **Rate limiting** intelligent
- **Health checks** intégrés

### Monitoring

- **Logs centralisés** par application
- **Métriques** de performance
- **Alertes** automatiques
- **Dashboard** de statut

## 🎯 Commandes de Référence

```bash
# Gestion des sous-domaines
make list-subdomains
make list-used-subdomains
make subdomain-status

# Assignation
make assign-subdomain APP=nom SUBDOMAIN=subdomain TYPE=type PORT=port
make suggest-subdomain APP=nom TYPE=type

# Déploiement automatique
make deploy-auto-subdomain APP=nom TYPE=type PORT=port IMAGE=image TAG=tag

# Scripts avancés
./subdomain-manager.sh list-available
./subdomain-manager.sh assign mon-app app1 static 8080
./subdomain-manager.sh deploy-auto mon-app static 8080 ghcr.io/user/repo static-latest
```

---

**Gestionnaire de sous-domaines qiwiiz.space opérationnel ! 🌐**

Pour commencer : `make list-subdomains` puis `make suggest-subdomain APP=mon-app TYPE=static`
