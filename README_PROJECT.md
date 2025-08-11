# Menui Measure

Application web pour mesurer surfaces et longueurs à partir de photos en utilisant une feuille A4 comme référence.

## 🚀 Technologies

- **Backend :** Laravel 12 + Inertia.js
- **Frontend :** React 18 + Tailwind CSS + shadcn/ui
- **Service IA :** Python 3.11 + FastAPI + OpenCV + NumPy
- **Base de données :** MySQL 8
- **Cache/Queue :** Redis
- **Stockage :** S3-compatible (OVH Object Storage) ou local
- **Déploiement :** Docker Compose + Nginx + OVH VPS + Certbot

## 📋 Fonctionnalités

- ✅ Détection automatique de feuilles A4 dans les photos
- ✅ Calcul de l'échelle (pixels par mm) basé sur la référence A4
- ✅ Interface d'annotation avec Konva.js (polygones et distances)
- ✅ Mesure de surfaces (m²) et de longueurs (m)
- ✅ Gestion de tâches avec liens invités
- ✅ Upload public sécurisé avec tokens temporaires
- ✅ Traitement asynchrone des images
- ✅ Interface d'administration complète

## 🏗️ Architecture

```
menui-measure/
├── laravel-app/          # Application Laravel + React (Inertia)
├── ai-service/           # Service FastAPI + OpenCV
├── deploy/               # Scripts et configurations de déploiement
├── dataset/sample/       # Images d'exemple pour tests
├── docker-compose.yml    # Configuration développement
└── docker-compose.prod.yml # Configuration production
```

## 🚀 Installation et lancement (Développement)

### Prérequis
- Docker et Docker Compose
- Git

### 1. Cloner le repository
```bash
git clone https://github.com/votre-username/menui-measure.git
cd menui-measure
```

### 2. Lancer l'environnement de développement
```bash
# Construire et lancer tous les services
docker-compose up --build

# En arrière-plan
docker-compose up -d --build
```

### 3. Initialiser la base de données
```bash
# Attendre que les services soient prêts (30-60 secondes)
sleep 60

# Exécuter les migrations
docker-compose exec laravel php artisan migrate

# Créer un utilisateur admin
docker-compose exec laravel php artisan tinker
```

Dans Tinker, exécuter :
```php
App\Models\User::create([
    'name' => 'Admin',
    'email' => 'admin@example.com',
    'password' => bcrypt('password'),
    'role' => 'admin'
]);
exit
```

### 4. Installer les dépendances frontend
```bash
# Installer les dépendances NPM
docker-compose exec laravel npm install

# Lancer le serveur de développement Vite
docker-compose exec laravel npm run dev
```

### 5. Accéder à l'application
- **Application principale :** http://localhost:8000
- **Service IA :** http://localhost:8001
- **Base de données :** localhost:3306 (menui/menui)
- **Redis :** localhost:6379

## 🧪 Tests

### Test rapide du service IA
```bash
curl -X POST "http://localhost:8001/analyze" \
  -F "file=@dataset/sample/votre-image.jpg" \
  -F "metadata={\"expect_marker\":\"A4\"}"
```

### Test de l'application complète
1. Connectez-vous avec admin@example.com / password
2. Créez une nouvelle tâche
3. Générez un lien invité
4. Utilisez le lien pour uploader une photo avec une feuille A4
5. Visualisez les résultats et effectuez des mesures

## 📊 Utilisation

### Pour les administrateurs
1. **Créer une tâche :** Définissez le titre et la description
2. **Générer un lien invité :** Partagez le lien avec le client
3. **Analyser les photos :** Une fois uploadées, les photos sont traitées automatiquement
4. **Effectuer des mesures :** Utilisez l'interface d'annotation pour mesurer

### Pour les invités
1. **Ouvrir le lien :** Accédez au lien fourni par l'administrateur
2. **Lire les instructions :** Suivez le guide pour placer la feuille A4
3. **Uploader les photos :** Sélectionnez et envoyez vos photos
4. **Confirmation :** Recevez une confirmation d'envoi

## 🔧 Configuration

### Variables d'environnement importantes

```env
# Application
APP_NAME=menui
APP_ENV=local
APP_URL=http://localhost:8000

# Base de données
DB_CONNECTION=mysql
DB_HOST=db
DB_DATABASE=menui
DB_USERNAME=menui
DB_PASSWORD=menui

# Service IA
AI_SERVICE_URL=http://ai-service:8000

# Configuration invités
GUEST_TOKEN_EXPIRY_DAYS=7
MAX_UPLOAD_SIZE=10240
ALLOWED_IMAGE_TYPES=jpg,jpeg,png
```

## 🛠️ Développement

### Structure des migrations
- `users` : Utilisateurs avec rôles (admin/client)
- `tasks` : Tâches de mesure avec tokens invités
- `photos` : Photos uploadées avec métadonnées EXIF
- `measurements` : Mesures calculées (longueurs/surfaces)
- `subtasks` : Sous-tâches pour organisation
- `notifications_log` : Journal des notifications

### API du service IA

#### POST /analyze
Analyse une image pour détecter le marqueur A4 et suggérer des mesures.

**Entrée :**
- `file` : Image (multipart)
- `metadata` : JSON avec paramètres optionnels

**Sortie :**
```json
{
  "marker": {
    "corners": [[x,y], ...],
    "pixels_per_mm": 2.83,
    "confidence": 0.85
  },
  "suggestions": [...],
  "preliminary_measurements": [...],
  "annotated_image_url": "/storage/annotated/..."
}
```

#### POST /warp
Applique une correction de perspective basée sur les coins du marqueur A4.

### Endpoints Laravel

- `GET /` : Dashboard principal
- `POST /tasks` : Créer une tâche (admin)
- `POST /tasks/{id}/guest-link` : Générer un lien invité
- `GET /guest/{token}` : Page d'upload public
- `POST /guest/{token}/photos` : Upload de photos
- `POST /tasks/{id}/photos/{photo}/measure` : Sauvegarder une mesure

## 🚀 Déploiement en production

Voir le guide détaillé : [deploy/ovh.md](deploy/ovh.md)

### Résumé rapide
```bash
# Sur le serveur OVH
git clone https://github.com/votre-username/menui-measure.git
cd menui-measure
cp laravel-app/.env.example laravel-app/.env.prod
# Éditer .env.prod avec les variables de production
docker-compose -f docker-compose.prod.yml up -d --build
```

## 📈 Métriques de qualité

- **Objectif initial :** MAE < 10 mm sur dataset contrôlé
- **Objectif après améliorations :** MAE < 5 mm avec bonnes photos (A4 sur même plan, angle <15°)

## 🔐 Sécurité

- **Tokens invités :** UUID + signature HMAC, expiration configurable (défaut 7 jours)
- **Uploads :** Taille max 10MB, formats jpg/png uniquement
- **Rate limiting :** Limitation par IP pour les endpoints invités

## 🤝 Contribution

1. Fork le projet
2. Créez une branche feature (`git checkout -b feature/nouvelle-fonctionnalite`)
3. Committez vos changements (`git commit -am 'Ajout nouvelle fonctionnalité'`)
4. Push sur la branche (`git push origin feature/nouvelle-fonctionnalite`)
5. Créez une Pull Request

## 📝 Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 👥 Auteurs

- **Ghazi Tounsi** - Développement initial

## 🆘 Support

Pour toute question ou problème :
1. Consultez la documentation dans `/deploy/ovh.md`
2. Vérifiez les logs : `docker-compose logs`
3. Ouvrez une issue sur GitHub