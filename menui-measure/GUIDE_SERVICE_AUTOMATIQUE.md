# Guide Service Automatique - Menui AI

Ce guide vous explique comment configurer votre service IA pour qu'il démarre automatiquement selon votre environnement.

## 🎯 Solutions Disponibles

### 1. **Docker Compose + Auto-Restart** (Recommandé)

**Avantages** :
- ✅ Fonctionne sur Windows, Linux, macOS
- ✅ Redémarrage automatique en cas de crash
- ✅ Gestion des volumes persistants
- ✅ Configuration centralisée
- ✅ Health check intégré

**Utilisation** :
```bash
# Démarrage simple
start-ai-service-auto.bat

# Ou manuellement
docker-compose -f docker-compose-ai-service.yml up -d
```

### 2. **Service Windows** (Développement Local)

**Avantages** :
- ✅ Service Windows natif
- ✅ Démarrage automatique au boot
- ✅ Gestion via Services Windows
- ✅ Integration système complète

**Installation** :
```bash
# Exécuter en tant qu'administrateur
windows-scripts\install-ai-service.bat
```

### 3. **Service Systemd** (VPS Linux)

**Avantages** :
- ✅ Service système Linux natif
- ✅ Démarrage automatique au boot
- ✅ Gestion via systemctl
- ✅ Logs centralisés avec journald

**Déploiement** :
```bash
# Déploiement automatique sur VPS
deploy-ai-service-autostart.bat
```

## 📋 Instructions par Environnement

### 🖥️ **Windows (Développement)**

#### Option 1 : Service Windows (Recommandé)
```bash
# 1. Ouvrir PowerShell en tant qu'administrateur
# 2. Naviguer vers le projet
cd C:\laragon\www\Mesure\menui-measure
# 3. Installer le service
windows-scripts\install-ai-service.bat
```

#### Option 2 : Docker Compose
```bash
# Démarrage simple
start-ai-service-auto.bat
```

### 🐧 **Linux/VPS (Production)**

#### Option 1 : Déploiement Automatique
```bash
# Depuis Windows vers VPS
deploy-ai-service-autostart.bat
```

#### Option 2 : Installation Manuelle
```bash
# Sur le VPS
sudo cp deploy/menui-ai-service.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable menui-ai-service
sudo systemctl start menui-ai-service
```

### 🍎 **macOS**

#### Docker Compose (Seule option)
```bash
# Terminal
chmod +x start-ai-service-auto.sh  # Si vous avez le script .sh
docker-compose -f docker-compose-ai-service.yml up -d
```

## 🔧 Gestion des Services

### **Docker Compose**
```bash
# Statut
docker-compose -f docker-compose-ai-service.yml ps

# Logs en temps réel
docker-compose -f docker-compose-ai-service.yml logs -f

# Redémarrage
docker-compose -f docker-compose-ai-service.yml restart

# Arrêt
docker-compose -f docker-compose-ai-service.yml down

# Mise à jour
docker-compose -f docker-compose-ai-service.yml pull
docker-compose -f docker-compose-ai-service.yml up -d
```

### **Service Windows**
```bash
# Statut
sc query MenuiAIService

# Démarrage
sc start MenuiAIService

# Arrêt
sc stop MenuiAIService

# Désinstallation
sc stop MenuiAIService && sc delete MenuiAIService
```

### **Service Linux (systemd)**
```bash
# Statut
sudo systemctl status menui-ai-service

# Démarrage
sudo systemctl start menui-ai-service

# Arrêt
sudo systemctl stop menui-ai-service

# Redémarrage
sudo systemctl restart menui-ai-service

# Logs
sudo journalctl -u menui-ai-service -f

# Désactiver auto-start
sudo systemctl disable menui-ai-service
```

## 🏥 Surveillance et Health Check

### **Vérification de Santé**
```bash
# Test local
curl http://localhost:8000/health

# Test VPS
curl http://your-vps-ip:8000/health

# Test avec réponse détaillée
curl -v http://localhost:8000/health
```

### **Monitoring**
```bash
# Docker stats
docker stats menui-ai-service

# Logs en temps réel
docker logs -f menui-ai-service

# Health check status
docker inspect menui-ai-service | grep Health -A 10
```

## 🛠️ Configuration Avancée

### **Variables d'Environnement**

Modifiez `docker-compose-ai-service.yml` :
```yaml
environment:
  - APP_ENV=production
  - LOG_LEVEL=DEBUG          # DEBUG, INFO, WARNING, ERROR
  - MAX_UPLOAD_SIZE=10MB     # Taille max des uploads
  - WORKER_PROCESSES=2       # Nombre de workers
```

### **Ressources**

Ajustez les limites dans `docker-compose-ai-service.yml` :
```yaml
deploy:
  resources:
    limits:
      memory: 2G      # Limite mémoire
      cpus: '2.0'     # Limite CPU
```

### **Ports**

Changez le port dans `docker-compose-ai-service.yml` :
```yaml
ports:
  - "8080:8000"  # Port externe:interne
```

## 🔒 Sécurité

### **Firewall (VPS)**
```bash
# Ouvrir le port 8000
sudo ufw allow 8000

# Ou restreindre à des IPs spécifiques
sudo ufw allow from YOUR_IP to any port 8000
```

### **HTTPS (Production)**
Utilisez un reverse proxy (nginx, traefik) pour HTTPS.

### **Sauvegarde**
```bash
# Sauvegarde des volumes
docker run --rm \
  -v menui-ai-uploads:/backup-source \
  -v $(pwd):/backup-dest \
  alpine tar czf /backup-dest/ai-uploads-backup.tar.gz -C /backup-source .
```

## 🚨 Dépannage

### **Service ne démarre pas**
1. Vérifiez les logs : `docker logs menui-ai-service`
2. Vérifiez le port : `netstat -an | grep 8000`
3. Vérifiez Docker : `docker ps -a`

### **Service crash au redémarrage**
1. Vérifiez les ressources : `docker stats`
2. Augmentez les limites mémoire
3. Vérifiez les volumes : `docker volume ls`

### **API non accessible**
1. Vérifiez le firewall
2. Testez en local : `curl localhost:8000/health`
3. Vérifiez les logs nginx/proxy si utilisé

## ✅ Validation

Votre service est correctement configuré si :
- ✅ `curl http://localhost:8000/health` retourne `{"status": "healthy"}`
- ✅ Le service redémarre après `docker restart menui-ai-service`
- ✅ Le service redémarre après un reboot système
- ✅ Les logs ne montrent pas d'erreurs : `docker logs menui-ai-service`
