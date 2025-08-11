# Menui Measure

Application web pour mesurer surfaces et longueurs à partir de photos en utilisant une feuille A4 comme référence.

## 🚀 Fonctionnalités

- **Détection automatique de feuille A4** : Utilise OpenCV pour détecter automatiquement une feuille A4 dans les photos
- **Mesures précises** : Calcul de distances et surfaces avec une précision < 5mm dans de bonnes conditions
- **Interface intuitive** : Interface de dessin avec Konva.js pour tracer des polygones et mesurer des distances
- **Upload public** : Liens de partage pour permettre aux clients d'uploader leurs photos
- **Traitement asynchrone** : Queue Laravel pour traiter les photos en arrière-plan
- **Stockage cloud** : Compatible avec OVH Object Storage (S3)

## 🛠 Stack Technique

- **Backend** : Laravel 11 + Inertia.js
- **Frontend** : React 18 + Tailwind CSS + shadcn/ui
- **Service IA** : Python 3.11 + FastAPI + OpenCV + NumPy
- **Base de données** : MySQL 8
- **Queue** : Redis + Laravel Queue
- **Déploiement** : Docker Compose + Nginx

## 📋 Prérequis

- Docker et Docker Compose
- Git
- 4GB RAM minimum
- 20GB d'espace disque

## 🚀 Installation rapide

1. **Cloner le repository**
```bash
git clone https://github.com/votre-repo/menui-measure.git
cd menui-measure
```

2. **Configurer l'environnement**
```bash
cp laravel-app/.env.example laravel-app/.env
```

3. **Lancer avec Docker Compose**
```bash
docker-compose up -d --build
```

4. **Initialiser l'application**
```bash
# Attendre que les conteneurs soient prêts (environ 30 secondes)
docker-compose exec laravel php artisan key:generate
docker-compose exec laravel php artisan migrate
docker-compose exec laravel php artisan storage:link
```

5. **Accéder à l'application**
- Application web : http://localhost:8000
- Service IA : http://localhost:8001/docs

## 📸 Guide d'utilisation

### Pour les administrateurs

1. **Créer une tâche**
   - Se connecter au dashboard
   - Cliquer sur "Nouvelle tâche"
   - Remplir le titre et la description

2. **Générer un lien invité**
   - Dans la page de la tâche, cliquer sur "Générer un lien"
   - Copier et partager le lien avec le client

3. **Analyser les photos**
   - Une fois les photos uploadées, elles sont automatiquement analysées
   - Utiliser l'outil d'annotation pour affiner les mesures
   - Enregistrer les mesures finales

### Pour les invités

1. **Prendre les photos**
   - Placer une feuille A4 sur la même surface que l'objet à mesurer
   - S'assurer que la feuille est complètement visible et plate
   - Prendre la photo de face (angle < 15°)
   - Éviter les ombres et reflets

2. **Uploader les photos**
   - Ouvrir le lien reçu
   - Sélectionner ou glisser les photos (max 10 photos, 10MB/photo)
   - Optionnel : laisser ses coordonnées
   - Cliquer sur "Envoyer"

## 🏗 Architecture

```
menui-measure/
├── laravel-app/          # Application Laravel
│   ├── app/
│   │   ├── Models/       # Modèles Eloquent
│   │   ├── Http/         # Contrôleurs et middleware
│   │   └── Jobs/         # Jobs asynchrones
│   ├── resources/
│   │   └── js/           # Composants React
│   └── database/         # Migrations
├── ai-service/           # Service Python FastAPI
│   └── main.py          # Endpoints IA
├── docker-compose.yml    # Configuration Docker dev
└── deploy/              # Scripts de déploiement
```

## 🔧 Configuration

### Variables d'environnement importantes

```env
# Service IA
AI_SERVICE_URL=http://ai-service:8000

# Durée de validité des liens invités (jours)
GUEST_TOKEN_EXPIRY_DAYS=7

# Stockage S3 (OVH Object Storage)
OVH_ACCESS_KEY_ID=your_key
OVH_SECRET_ACCESS_KEY=your_secret
OVH_BUCKET=menui-storage
OVH_ENDPOINT=https://s3.bhs.io.cloud.ovh.net
```

## 📊 API Endpoints

### Laravel

- `POST /tasks` - Créer une tâche
- `POST /tasks/{id}/guest-link` - Générer un lien invité
- `GET /guest/{token}` - Page d'upload public
- `POST /guest/{token}/photos` - Upload de photos
- `POST /tasks/{id}/photos/{photo}/measure` - Enregistrer une mesure

### Service IA

- `POST /analyze` - Analyser une image
  - Détecte la feuille A4
  - Calcule pixels_per_mm
  - Suggère des zones à mesurer
  
- `POST /warp` - Corriger la perspective
  - Transforme l'image en vue de dessus

## 🧪 Tests

```bash
# Tests unitaires Laravel
docker-compose exec laravel php artisan test

# Tests Python
docker-compose exec ai-service pytest
```

## 📈 Performance

- Traitement d'image : ~2-5 secondes par photo
- Précision : MAE < 5mm avec de bonnes photos
- Capacité : 100+ photos simultanées

## 🚀 Déploiement

Voir [deploy/ovh.md](deploy/ovh.md) pour le guide complet de déploiement sur OVH.

## 🤝 Contribution

1. Fork le projet
2. Créer une branche (`git checkout -b feature/AmazingFeature`)
3. Commit les changements (`git commit -m 'Add AmazingFeature'`)
4. Push la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## 📝 Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 👥 Auteur

**Ghazi Tounsi**

## 🙏 Remerciements

- OpenCV pour la détection d'images
- Laravel pour le framework backend
- React et Konva.js pour l'interface d'annotation
- FastAPI pour le service IA performant