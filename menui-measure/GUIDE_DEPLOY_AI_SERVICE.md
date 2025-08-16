# Guide de Déploiement - Service IA uniquement

## 🎯 Objectif
Déployer uniquement le service IA sur votre VPS OVH `vps-df0c2336.vps.ovh.net` via Docker.

## 📋 Prérequis
- Accès SSH au VPS configuré
- Docker Hub account
- Windows avec Docker Desktop (pour le build)

## 🚀 Étapes de déploiement

### 1. Configuration initiale
```bash
# Configurer votre nom d'utilisateur Docker Hub
setup-ai-docker-username.bat
```

### 2. Construction et envoi de l'image
```bash
# Construire l'image et l'envoyer sur Docker Hub
build-ai-service.bat
```

### 3. Déploiement sur le VPS
```bash
# Déployer le service IA sur le VPS
deploy-ai-service.bat
```

### 4. Test du déploiement
```bash
# Tester le service déployé
test-ai-service-remote.bat
```

## 🔧 Configuration Laravel

Une fois le service IA déployé, configurez Laravel pour l'utiliser :

```bash
# Dans votre application Laravel locale
cd menui-measure\windows-scripts
setup-ai-service.bat
# Choisir option 4 pour VPS distant
```

Ou manuellement dans votre `.env` :
```env
AI_SERVICE_URL=http://vps-df0c2336.vps.ovh.net:8001
AI_SERVICE_TIMEOUT=60
```

## 📡 URLs du service

Après déploiement, le service sera accessible à :
- **API** : http://vps-df0c2336.vps.ovh.net:8001
- **Health check** : http://vps-df0c2336.vps.ovh.net:8001/health
- **Documentation** : http://vps-df0c2336.vps.ovh.net:8001/docs

## 🛠 Gestion du service

### Redémarrer le service
```bash
ssh root@vps-df0c2336.vps.ovh.net "docker restart menui-ai-service"
```

### Voir les logs
```bash
ssh root@vps-df0c2336.vps.ovh.net "docker logs menui-ai-service"
```

### Mettre à jour le service
1. Modifier le code
2. Relancer `build-ai-service.bat`
3. Relancer `deploy-ai-service.bat`

## 📁 Structure des fichiers

```
menui-measure/
├── ai-service/
│   ├── Dockerfile          # Dockerfile du service IA
│   ├── .dockerignore       # Fichiers à ignorer
│   └── ... (code Python)
├── build-ai-service.bat    # Script de build et push
├── deploy-ai-service.bat   # Script de déploiement
├── test-ai-service-remote.bat  # Script de test
└── setup-ai-docker-username.bat  # Configuration Docker Hub
```

## ⚠️ Notes importantes

1. **Première utilisation** : Exécutez `setup-ai-docker-username.bat` en premier
2. **Clés SSH** : Assurez-vous que vos clés SSH sont configurées pour le VPS
3. **Ports** : Le service utilise le port 8001 sur le VPS
4. **Persistence** : Les uploads sont stockés dans `/opt/menui-ai/` sur le VPS
5. **Redémarrage automatique** : Le conteneur redémarre automatiquement après un reboot du VPS

## 🔍 Résolution de problèmes

### Connexion SSH échoue
```bash
# Tester la connexion SSH
ssh root@vps-df0c2336.vps.ovh.net "echo 'Test connexion'"
```

### Service ne démarre pas
```bash
# Voir les logs détaillés
ssh root@vps-df0c2336.vps.ovh.net "docker logs menui-ai-service"
```

### Port non accessible
```bash
# Vérifier que le port est ouvert
ssh root@vps-df0c2336.vps.ovh.net "netstat -tlnp | grep 8001"
```

## 🎉 Félicitations !

Votre service IA est maintenant déployé et accessible depuis n'importe où !


