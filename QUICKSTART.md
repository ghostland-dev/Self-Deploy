# Guide de Démarrage Rapide

Ce guide vous aidera à déployer votre première application en quelques minutes.

## 🚀 Déploiement Express (5 minutes)

### 1. Préparation du serveur

```bash
# Sur votre serveur Ubuntu (232.23.32.32)
sudo ./setup-server.sh
```

### 2. Test de connexion

```bash
# Depuis votre machine locale
ssh user@232.23.32.32
```

### 3. Déploiement d'une application React

```bash
# Créer un projet React de test
npx create-react-app mon-premier-deploy
cd mon-premier-deploy
npm run build

# Créer la configuration
cat > deploy-config.json << 'EOF'
{
  "app_name": "mon-premier-deploy",
  "app_type": "static",
  "build_dir": "./build",
  "domain": "test.qiwiiz.space"
}
EOF

# Déployer
../deploy.sh deploy deploy-config.json
```

### 4. Vérification

```bash
# Vérifier que l'application est déployée
curl http://test.qiwiiz.space
```

## 📱 Déploiement d'une API Node.js

### 1. Créer une API simple

```bash
mkdir mon-api
cd mon-api

# Créer package.json
cat > package.json << 'EOF'
{
  "name": "mon-api",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.0"
  }
}
EOF

# Créer server.js
cat > server.js << 'EOF'
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({ message: 'API déployée avec succès!', timestamp: new Date() });
});

app.listen(port, () => {
  console.log(`Serveur démarré sur le port ${port}`);
});
EOF

npm install
```

### 2. Configuration et déploiement

```bash
# Créer la configuration
cat > deploy-config.json << 'EOF'
{
  "app_name": "mon-api",
  "app_type": "dynamic",
  "build_dir": "./",
  "domain": "api.qiwiiz.space",
  "framework": "node",
  "port": 3000
}
EOF

# Déployer
../deploy.sh deploy deploy-config.json
```

## 🐍 Déploiement d'une application Python

### 1. Créer une app Flask

```bash
mkdir mon-app-python
cd mon-app-python

# Créer requirements.txt
cat > requirements.txt << 'EOF'
Flask==2.3.0
gunicorn==21.2.0
EOF

# Créer app.py
cat > app.py << 'EOF'
from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/')
def hello():
    return jsonify({
        'message': 'Application Python déployée!',
        'port': os.environ.get('PORT', 5000)
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)
EOF
```

### 2. Configuration et déploiement

```bash
# Créer la configuration
cat > deploy-config.json << 'EOF'
{
  "app_name": "mon-app-python",
  "app_type": "dynamic",
  "build_dir": "./",
  "domain": "python.qiwiiz.space",
  "framework": "python",
  "port": 5000
}
EOF

# Déployer
../deploy.sh deploy deploy-config.json
```

## 🔄 Déploiement avec GitHub Actions

### 1. Configuration des secrets

Dans votre repository GitHub :
- `SSH_USER` : `user`
- `SSH_HOST` : `232.23.32.32`
- `SSH_PASSWORD` : `changeme`

### 2. Ajouter le workflow

Copiez le fichier `.github/workflows/deploy.yml` dans votre repository.

### 3. Créer deploy-config.json dans votre projet

```json
{
  "app_name": "mon-projet-github",
  "app_type": "static",
  "build_dir": "./dist",
  "domain": "github.qiwiiz.space"
}
```

### 4. Push et déploiement automatique

```bash
git add .
git commit -m "Ajout configuration de déploiement"
git push origin main
```

## 🛠️ Commandes utiles

### Vérifier les déploiements

```bash
# Lister toutes les applications
./deploy.sh list

# Vérifier les services sur le serveur
ssh user@232.23.32.32 "systemctl list-units --type=service --state=active"
```

### Gérer les sauvegardes

```bash
# Lister les sauvegardes
ssh user@232.23.32.32 "ls -la /tmp/deploy-backups/"

# Nettoyer les anciennes sauvegardes
./deploy.sh cleanup 7
```

### Logs et monitoring

```bash
# Logs de déploiement local
tail -f deploy.log

# Logs nginx
ssh user@232.23.32.32 "tail -f /var/log/nginx/error.log"

# Logs d'une application spécifique
ssh user@232.23.32.32 "journalctl -u mon-api -f"
```

## 🚨 Dépannage rapide

### Problème : Erreur de connexion SSH

```bash
# Tester la connexion
ssh user@232.23.32.32

# Vérifier les permissions
chmod 600 ~/.ssh/id_rsa
```

### Problème : Service ne démarre pas

```bash
# Vérifier les logs
ssh user@232.23.32.32 "journalctl -u mon-api -n 50"

# Redémarrer le service
ssh user@232.23.32.32 "systemctl restart mon-api"
```

### Problème : Configuration nginx invalide

```bash
# Tester la configuration
ssh user@232.23.32.32 "nginx -t"

# Recharger nginx
ssh user@232.23.32.32 "systemctl reload nginx"
```

## ✅ Checklist de déploiement

- [ ] Serveur configuré avec `setup-server.sh`
- [ ] Connexion SSH fonctionnelle
- [ ] Fichier de configuration JSON créé
- [ ] Application construite (si nécessaire)
- [ ] Déploiement testé avec `./deploy.sh deploy`
- [ ] Application accessible via le domaine
- [ ] Logs vérifiés
- [ ] Sauvegardes fonctionnelles

## 🎯 Prochaines étapes

1. **SSL/HTTPS** : Configurez Certbot pour HTTPS
2. **Monitoring** : Ajoutez des outils de monitoring
3. **CI/CD** : Intégrez avec GitHub Actions
4. **Scaling** : Configurez la répartition de charge
5. **Backup** : Mettez en place des sauvegardes automatiques

---

**Félicitations ! Votre système de déploiement est opérationnel ! 🎉**
