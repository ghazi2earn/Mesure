# 🪟 Guide de Déploiement Windows - Menui Mesure

## 📋 Prérequis

1. **Docker Desktop** installé et en cours d'exécution
   - Télécharger : https://www.docker.com/products/docker-desktop
   - Vérifier avec : `docker --version`

2. **Compte Docker Hub** créé
   - S'inscrire sur : https://hub.docker.com/

## 🚀 Étapes de Déploiement

### **ÉTAPE 1 : Configuration du nom d'utilisateur Docker Hub**

```cmd
# Dans le répertoire menui-measure
.\setup-docker-username.bat
```

**Entrez votre nom d'utilisateur Docker Hub quand demandé**

### **ÉTAPE 2 : Construction et publication de l'image**

```cmd
# Construire et publier sur Docker Hub
.\build-and-push.bat
```

**Ce script va :**
- ✅ Construire l'image Docker monolithique
- ✅ Tester l'image localement 
- ✅ Se connecter à Docker Hub (mot de passe requis)
- ✅ Publier l'image sur Docker Hub

### **ÉTAPE 3 : Déploiement sur serveur**

**Sur votre serveur Linux/VPS :**

```bash
# Télécharger le script de déploiement
wget https://raw.githubusercontent.com/votre-nom/votre-repo/main/deploy-from-dockerhub.sh

# Ou créer le fichier manuellement
nano deploy-from-dockerhub.sh
# Copier le contenu du script

# Rendre exécutable
chmod +x deploy-from-dockerhub.sh

# Modifier le nom d'utilisateur Docker Hub
nano deploy-from-dockerhub.sh
# Remplacer "votre-username" par votre vrai nom d'utilisateur

# Déployer
./deploy-from-dockerhub.sh
```

### **ÉTAPE 4 : Test local (optionnel)**

```cmd
# Tester localement sur Windows avec Docker Desktop
.\deploy-from-dockerhub.bat
```

## 🎯 Résultat Final

Après déploiement, vous aurez :

- **📱 Application web** : `http://votre-ip-serveur`
- **🤖 Service IA** : `http://votre-ip-serveur:8001`
- **📚 Documentation API** : `http://votre-ip-serveur/ai-docs`
- **💾 Base de données MySQL** : `localhost:3306`

## 🔧 Commandes Utiles

### **Gestion du conteneur :**
```cmd
# Voir les logs
docker logs -f menui-measure

# Redémarrer
docker restart menui-measure

# Arrêter
docker stop menui-measure

# Entrer dans le conteneur
docker exec -it menui-measure bash
```

### **Sauvegarde base de données :**
```cmd
docker exec menui-measure mysqldump -u menui_user -pmenui_password_2024! menui_prod > backup.sql
```

### **Mise à jour :**
```cmd
# Reconstruire et republier
.\build-and-push.bat

# Redéployer sur serveur
.\deploy-from-dockerhub.bat
```

## 🐛 Dépannage

### **Problème : Docker ne fonctionne pas**
```cmd
# Vérifier le statut
docker --version
docker info
```
**Solution :** Redémarrer Docker Desktop

### **Problème : Erreur de connexion Docker Hub**
```cmd
# Se reconnecter
docker login
```

### **Problème : Port déjà utilisé**
```cmd
# Voir les processus utilisant le port 80
netstat -ano | findstr :80

# Arrêter le processus (remplacer PID)
taskkill /F /PID 1234
```

### **Problème : L'image ne démarre pas**
```cmd
# Voir les logs détaillés
docker logs menui-measure

# Redémarrer le conteneur
docker restart menui-measure
```

## 📊 Structure de l'Image

L'image Docker monolithique contient :
- **MySQL 8.0** (base de données)
- **Redis** (cache et queues)
- **PHP 8.1 + Laravel** (application web)
- **Python 3 + FastAPI** (service IA)
- **Nginx** (serveur web)
- **Node.js** (compilation des assets)

## 🔒 Sécurité

**Informations d'accès par défaut :**
- **Database** : `menui_user` / `menui_password_2024!`
- **Database name** : `menui_prod`

**⚠️ Important :** Changez les mots de passe en production !

## 📞 Support

En cas de problème :
1. Vérifiez les logs : `docker logs -f menui-measure`
2. Consultez la documentation : `/ai-docs`
3. Testez la connectivité : `curl http://localhost/health`



