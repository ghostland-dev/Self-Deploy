# 🔒 SSL Automatique et Alias - qiwiiz.space

Système complet de gestion SSL automatique avec Caddy et création d'alias pour les nouvelles applications sur qiwiiz.space.

## ✨ Fonctionnalités SSL Automatiques

- **SSL automatique** avec Let's Encrypt pour tous les sous-domaines
- **Création automatique de sous-domaines** pour chaque application
- **Alias personnalisés** pour domaines externes
- **Renouvellement automatique** des certificats SSL
- **Configuration Caddy dynamique** avec headers de sécurité
- **Monitoring SSL** en temps réel

## 🚀 Utilisation Rapide

### Déploiement avec SSL automatique

```bash
# Déploiement rapide avec SSL
make quick-ssl APP=mon-app TYPE=static

# Déploiement avec SSL et domaine personnalisé
make deploy-ssl APP=mon-app TYPE=node PORT=3000 DOMAIN=app.mondomaine.com

# Créer un alias pour un domaine externe
make create-alias APP=mon-app DOMAIN=mondomaine.com PORT=3000
```

### Commandes SSL spécialisées

```bash
# Créer un sous-domaine
make create-subdomain APP=mon-app TYPE=static PORT=8080

# Lister tous les déploiements SSL
make list-ssl

# Renouveler tous les certificats SSL
make renew-ssl

# Configurer SSL initial
make setup-ssl
```

## 🛠️ Scripts SSL Avancés

### Gestionnaire Caddy (`caddy-manager.sh`)

```bash
# Créer un sous-domaine automatique
./caddy-manager.sh create-subdomain mon-app static 8080

# Supprimer un sous-domaine
./caddy-manager.sh remove-subdomain mon-app

# Lister tous les sous-domaines
./caddy-manager.sh list-subdomains

# Vérifier le statut SSL
./caddy-manager.sh check-ssl mon-app

# Renouveler tous les certificats
./caddy-manager.sh renew-certificates

# Créer un alias personnalisé
./caddy-manager.sh create-alias mon-app app.mondomaine.com static 8080

# Configurer un domaine externe
./caddy-manager.sh setup-external mondomaine.com mon-app 3000
```

### Déploiement SSL (`ssl-deploy.sh`)

```bash
# Déploiement avec SSL automatique
./ssl-deploy.sh deploy mon-app static 8080

# Déploiement rapide avec app de test
./ssl-deploy.sh quick-deploy test-app static

# Créer un alias pour domaine externe
./ssl-deploy.sh create-alias mon-app mondomaine.com 3000

# Lister tous les déploiements SSL
./ssl-deploy.sh list-ssl

# Renouveler tous les certificats SSL
./ssl-deploy.sh renew-ssl
```

## 🌐 Configuration Caddy Automatique

### Sous-domaines automatiques

Chaque application déployée obtient automatiquement :
- **Sous-domaine** : `{app-name}.qiwiiz.space`
- **SSL automatique** avec Let's Encrypt
- **Redirection HTTPS** automatique
- **Headers de sécurité** complets
- **Compression gzip**
- **Rate limiting**
- **Logs spécifiques**

### Configuration générée automatiquement

```caddy
# Configuration pour mon-app
mon-app.qiwiiz.space {
    redir https://{host}{uri} permanent
}

https://mon-app.qiwiiz.space {
    reverse_proxy localhost:8080 {
        health_uri /health
        health_interval 30s
        health_timeout 5s
    }
    
    # Headers de sécurité
    header {
        X-Content-Type-Options nosniff
        X-Frame-Options DENY
        X-XSS-Protection "1; mode=block"
        Referrer-Policy strict-origin-when-cross-origin
        Permissions-Policy "geolocation=(), microphone=(), camera=()"
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
    }
    
    # Compression et cache
    encode gzip
    header @static Cache-Control "public, max-age=31536000"
    
    # Rate limiting
    rate_limit {
        zone static {
            key {remote_host}
            events 100
            window 1m
        }
    }
    
    # Logs spécifiques
    log {
        output file /var/log/caddy/mon-app.log
        format json
    }
}
```

## 🔧 Types d'Applications Supportées

### Applications Statiques
```bash
# React, Vue, Angular, HTML/CSS/JS
make quick-ssl APP=mon-site TYPE=static
# → https://mon-site.qiwiiz.space
```

### Applications Node.js
```bash
# Express, Next.js, API Node.js
make quick-ssl APP=mon-api TYPE=node PORT=3000
# → https://mon-api.qiwiiz.space
```

### Applications Python
```bash
# Flask, Django, FastAPI
make quick-ssl APP=mon-app TYPE=python PORT=5000
# → https://mon-app.qiwiiz.space
```

### Applications PHP
```bash
# Laravel, Symfony, WordPress
make quick-ssl APP=mon-site TYPE=php
# → https://mon-site.qiwiiz.space
```

## 🌍 Domaines Externes et Alias

### Configuration d'un domaine externe

```bash
# 1. Configurer le DNS pour pointer vers 51.159.6.66
# 2. Créer l'alias
make create-alias APP=mon-app DOMAIN=mondomaine.com PORT=3000

# Ou utiliser le script directement
./ssl-deploy.sh create-alias mon-app mondomaine.com 3000
```

### Vérification DNS automatique

Le système vérifie automatiquement :
- **Résolution DNS** du domaine externe
- **Correspondance IP** avec le serveur
- **Configuration SSL** automatique

## 📊 Monitoring SSL

### Vérification des certificats

```bash
# Vérifier le statut SSL d'une application
./caddy-manager.sh check-ssl mon-app

# Lister tous les certificats
./caddy-manager.sh list-subdomains
```

### Logs SSL

```bash
# Logs spécifiques à une application
ssh qiwiiz@51.159.6.66 "tail -f /var/log/caddy/mon-app.log"

# Logs généraux Caddy
ssh qiwiiz@51.159.6.66 "tail -f /var/log/caddy/access.log"
```

## 🔄 Renouvellement Automatique

### Configuration automatique

- **Renouvellement automatique** des certificats SSL
- **Monitoring** des dates d'expiration
- **Alertes** en cas de problème
- **Rollback** automatique en cas d'échec

### Renouvellement manuel

```bash
# Renouveler tous les certificats
make renew-ssl

# Ou utiliser le script
./ssl-deploy.sh renew-ssl
```

## 🛡️ Sécurité SSL Avancée

### Headers de sécurité automatiques

- **HSTS** (HTTP Strict Transport Security)
- **CSP** (Content Security Policy)
- **X-Frame-Options** : DENY
- **X-Content-Type-Options** : nosniff
- **X-XSS-Protection** : 1; mode=block
- **Referrer-Policy** : strict-origin-when-cross-origin

### Rate Limiting

- **Limitation par IP** : 100-200 requêtes/minute
- **Protection DDoS** automatique
- **Blocage temporaire** des IPs abusives

## 📈 Exemples d'Utilisation

### Déploiement d'un site React

```bash
# 1. Créer l'application
npx create-react-app mon-site
cd mon-site
npm run build

# 2. Déployer avec SSL automatique
make deploy-ssl APP=mon-site TYPE=static PORT=8080

# 3. Accéder au site
# → https://mon-site.qiwiiz.space
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

# 3. Déployer avec SSL
make deploy-ssl APP=mon-api TYPE=node PORT=3000

# 4. Accéder à l'API
# → https://mon-api.qiwiiz.space
```

### Configuration d'un domaine externe

```bash
# 1. Configurer le DNS pour mondomaine.com → 51.159.6.66
# 2. Créer l'alias
make create-alias APP=mon-app DOMAIN=mondomaine.com PORT=3000

# 3. Accéder au site
# → https://mondomaine.com (pointe vers mon-app.qiwiiz.space)
```

## 🔍 Dépannage SSL

### Problèmes courants

```bash
# Vérifier la configuration Caddy
ssh qiwiiz@51.159.6.66 "caddy validate --config /etc/caddy/Caddyfile"

# Vérifier les certificats
ssh qiwiiz@51.159.6.66 "caddy list-certificates"

# Redémarrer Caddy
ssh qiwiiz@51.159.6.66 "systemctl restart caddy"
```

### Logs de débogage

```bash
# Logs Caddy
ssh qiwiiz@51.159.6.66 "journalctl -u caddy -f"

# Logs SSL spécifiques
ssh qiwiiz@51.159.6.66 "tail -f /var/log/caddy/error.log"
```

## 📋 Checklist SSL

- [ ] Serveur configuré avec Caddy
- [ ] DNS configuré pour qiwiiz.space
- [ ] Ports 80 et 443 ouverts
- [ ] Application déployée avec Docker
- [ ] Sous-domaine créé automatiquement
- [ ] Certificat SSL généré
- [ ] Headers de sécurité configurés
- [ ] Monitoring SSL actif

## 🎯 Commandes de Référence

```bash
# Déploiement rapide
make quick-ssl APP=nom TYPE=static|node|python|php

# Déploiement avec domaine personnalisé
make deploy-ssl APP=nom TYPE=type PORT=port DOMAIN=domaine

# Créer un alias
make create-alias APP=nom DOMAIN=domaine PORT=port

# Gestion SSL
make list-ssl
make renew-ssl
make setup-ssl

# Monitoring
make monitor
make status
```

---

**SSL automatique opérationnel sur qiwiiz.space ! 🔒**

Pour commencer : `make quick-ssl APP=test TYPE=static`
