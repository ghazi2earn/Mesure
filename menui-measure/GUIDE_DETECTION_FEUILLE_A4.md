# Guide : Comment le système identifie une feuille A4

## 🔍 **Méthode de détection automatique**

Le service IA utilise la **vision par ordinateur (OpenCV)** pour détecter automatiquement une feuille A4 dans les photos. **Aucun marqueur spécial n'est nécessaire** - juste une feuille A4 normale.

## 📋 **Processus de détection détaillé**

### 1. **Préparation de l'image**
```python
# Conversion en niveaux de gris
gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

# Flou gaussien pour réduire le bruit
blurred = cv2.GaussianBlur(gray, (5, 5), 0)

# Détection des contours avec l'algorithme Canny
edges = cv2.Canny(blurred, 50, 150)
```

### 2. **Recherche des contours**
- Le système trouve **tous les contours** dans l'image
- Les contours sont **triés par taille** (du plus grand au plus petit)
- Seuls les **10 plus grands contours** sont analysés

### 3. **Filtres de validation**

Pour qu'un contour soit reconnu comme une feuille A4, il doit respecter ces critères :

#### ✅ **Forme rectangulaire**
- Le contour doit pouvoir être **approximé à un quadrilatère** (4 coins)
- Utilise l'algorithme `approxPolyDP` avec 2% de tolérance

#### ✅ **Taille minimale**
- Surface minimale : **10 000 pixels²**
- Évite la détection de petits objets rectangulaires

#### ✅ **Ratio d'aspect A4**
- **Ratio cible** : 210/297 = **0.707** (format A4)
- **Tolérance** : ±10% (soit entre 0.637 et 0.777)
- Fonctionne en **portrait ET paysage**

```python
# Calcul du ratio
width = distance_entre_coins_horizontal
height = distance_entre_coins_vertical
ratio = min(width, height) / max(width, height)

# Validation
if abs(ratio - 0.707) < 0.1:  # 10% de tolérance
    # C'est probablement une feuille A4 !
```

## 📐 **Calcul de l'échelle (pixels/mm)**

Une fois la feuille détectée :

### 1. **Détermination de l'orientation**
```python
if width < height:  # Portrait
    pixels_per_mm_w = width / 210.0   # largeur = 210mm
    pixels_per_mm_h = height / 297.0  # hauteur = 297mm
else:  # Paysage
    pixels_per_mm_w = width / 297.0   # largeur = 297mm
    pixels_per_mm_h = height / 210.0  # hauteur = 210mm
```

### 2. **Moyenne des échelles**
```python
pixels_per_mm = (pixels_per_mm_w + pixels_per_mm_h) / 2.0
```

Cette valeur permet de **convertir les pixels en millimètres** pour toutes les mesures.

## 🎯 **Conditions optimales pour la détection**

### ✅ **Ce qui fonctionne bien**

1. **Feuille A4 standard** (blanche ou colorée)
2. **Contraste suffisant** avec l'arrière-plan
3. **Feuille bien visible** et non pliée
4. **Éclairage uniforme** sans ombres fortes
5. **Feuille dans le cadre** (au moins 80% visible)
6. **Perspective raisonnable** (pas trop inclinée)

### ❌ **Ce qui peut poser problème**

1. **Feuille froissée ou pliée**
2. **Arrière-plan de même couleur** que la feuille
3. **Ombres fortes** qui cassent les contours
4. **Perspective extrême** (très inclinée)
5. **Feuille partiellement cachée**
6. **Éclairage très faible** ou surexposition

## 🖼️ **Annotation visuelle**

Quand une feuille A4 est détectée, le système :

### 1. **Contour vert**
- Dessine un **contour vert épais** autour de la feuille
- Couleur : `(0, 255, 0)` - vert vif

### 2. **Coins numérotés**
- **Cercles verts** à chaque coin
- **Labels C1, C2, C3, C4** pour identifier les coins
- Ordre : haut-gauche → haut-droit → bas-droit → bas-gauche

```python
# Code d'annotation
cv2.drawContours(annotated, [marker_corners.astype(int)], -1, (0, 255, 0), 3)

for i, corner in enumerate(marker_corners):
    cv2.circle(annotated, tuple(corner.astype(int)), 8, (0, 255, 0), -1)
    cv2.putText(annotated, f"C{i+1}", tuple(corner.astype(int) + 10), 
               cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
```

## 🔧 **Paramètres ajustables**

Dans le code, vous pouvez modifier ces valeurs :

```python
# Tolérance du ratio A4 (actuellement 10%)
tolerance = 0.1

# Taille minimale des contours
min_area = 10000

# Nombre de contours analysés
max_contours = 10

# Précision de l'approximation polygonale
epsilon = 0.02  # 2% du périmètre
```

## 🎨 **Types de feuilles supportées**

### ✅ **Fonctionne avec**
- Feuille A4 **blanche** standard
- Feuille A4 **colorée** (rouge, bleu, jaune, etc.)
- Feuille avec **texte imprimé**
- Feuille avec **dessins** ou **schémas**
- **Carton** ou **panneau** au format A4

### ❌ **Ne fonctionne pas avec**
- Feuilles **transparentes** ou **translucides**
- Surfaces **réfléchissantes** (métal poli)
- Objets **3D** même rectangulaires
- Feuilles **très abîmées** ou déchirées

## 💡 **Conseils pour une meilleure détection**

### 📸 **Prise de photo**
1. **Placez la feuille sur un fond contrastant**
2. **Éclairage uniforme** (évitez les ombres)
3. **Perspective droite** autant que possible
4. **Incluez toute la feuille** dans le cadre
5. **Évitez les reflets** et surexpositions

### 🎯 **Optimisation**
- Si la détection échoue, essayez avec un **fond différent**
- **Défroissez** la feuille si elle est pliée
- **Ajustez l'éclairage** pour améliorer le contraste
- **Repositionnez** la feuille pour une vue plus droite

## 🚀 **Fonctionnalités avancées**

### 1. **Correction de perspective**
- Une fois détectée, la feuille peut être **"dépliée"** virtuellement
- Transformation en vue parfaitement de dessus
- Génère une image **2480 x 3508 pixels** (A4 à 300 DPI)

### 2. **Détection d'objets à mesurer**
- Après détection de l'A4, le système suggère **automatiquement** des objets à mesurer
- Utilise la même technologie de détection de contours
- Filtre par taille et forme pour proposer des mesures pertinentes

La feuille A4 sert donc de **référence d'échelle universelle** - simple, efficace et accessible à tous ! 📏
