# Guide de Dépannage Docker - Service IA

## Problème rencontré

Erreur lors du build Docker :
```
ERROR: failed to solve: process "/bin/sh -c apt-get update && apt-get install..." did not complete successfully: exit code: 100
```

## Solutions proposées

### 1. Scripts de diagnostic et test

Nous avons créé plusieurs scripts pour vous aider :

- **`diagnose-docker.bat`** : Diagnostic complet de votre installation Docker
- **`test-build-progressive.bat`** : Test de différentes approches de build
- **`build-ai-service-robust.bat`** : Version améliorée du script de build

### 2. Dockerfiles alternatifs

#### Dockerfile.minimal
- Version minimaliste avec moins de dépendances système
- Utilise `opencv-python-headless` (pas d'interface graphique)
- Recommandé pour les environnements serveur

#### Dockerfile.robust
- Version avec gestion d'erreurs améliorée
- Installation progressive des packages
- Utilisateur non-root pour la sécurité
- Health check intégré

#### Dockerfile (original corrigé)
- Suppression des packages dupliqués
- Ajout de packages manquants
- Optimisation de la liste d'installation

### 3. Étapes de dépannage recommandées

#### Étape 1 : Diagnostic
```bash
diagnose-docker.bat
```

#### Étape 2 : Test progressif
```bash
test-build-progressive.bat
```

#### Étape 3 : Build avec la méthode qui fonctionne
Si l'approche minimale fonctionne :
```bash
cd ai-service
docker build -f Dockerfile.minimal -t ghazitounsi/menui-ai-service:latest .
```

Si l'approche robuste fonctionne :
```bash
cd ai-service
docker build -f Dockerfile.robust -t ghazitounsi/menui-ai-service:latest .
```

### 4. Problèmes courants et solutions

#### Problème : Packages système non trouvés
**Solution** : Utilisez `Dockerfile.minimal` qui installe moins de packages

#### Problème : Connexion Internet lente/instable
**Solution** : 
- Vérifiez votre connexion
- Utilisez un VPN si nécessaire
- Essayez à un moment de moindre affluence

#### Problème : Espace disque insuffisant
**Solution** :
```bash
docker system prune -a
```

#### Problème : Cache Docker corrompu
**Solution** :
```bash
docker builder prune -a
```

#### Problème : Docker Desktop non démarré
**Solution** :
- Démarrez Docker Desktop manuellement
- Attendez qu'il soit complètement initialisé
- Relancez le script

### 5. Configuration requise

#### Minimum :
- Docker Desktop installé et fonctionnel
- 4 GB d'espace disque libre
- Connexion Internet stable

#### Recommandé :
- 8 GB RAM ou plus
- SSD pour de meilleures performances
- Docker Desktop avec WSL2 (sur Windows)

### 6. Variables d'environnement importantes

Modifiez ces variables dans les scripts selon vos besoins :
- `DOCKER_USERNAME` : Votre nom d'utilisateur Docker Hub
- `IMAGE_NAME` : Nom de votre image
- `VERSION` : Version de l'image

### 7. Commandes de nettoyage utiles

```bash
# Suppression des images non utilisées
docker image prune -a

# Suppression complète du cache
docker system prune -a --volumes

# Redémarrage de Docker (Windows)
net stop com.docker.service
net start com.docker.service
```

### 8. Support

Si aucune des solutions ci-dessus ne fonctionne :

1. Exécutez `diagnose-docker.bat` et partagez les résultats
2. Vérifiez les logs Docker Desktop
3. Essayez de construire l'image sur une autre machine
4. Contactez le support Docker si le problème persiste

### 9. Notes importantes

- L'approche minimale (`Dockerfile.minimal`) est souvent la plus fiable
- Pour la production, préférez `Dockerfile.robust` qui inclut plus de sécurité
- Assurez-vous d'avoir les permissions administrateur si nécessaire
- Sur Windows, préférez WSL2 comme backend Docker
