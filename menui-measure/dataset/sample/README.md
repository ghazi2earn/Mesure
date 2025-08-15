# Échantillons de test

Ce dossier contient des images d'exemple pour tester l'application Menui Measure.

## Images de test recommandées

Pour tester l'application, vous devez créer des photos avec les caractéristiques suivantes :

### 1. Photo idéale (test_ideal.jpg)
- Feuille A4 posée à plat sur une surface
- Photo prise directement au-dessus (angle 0°)
- Bon éclairage uniforme
- Feuille A4 entièrement visible
- Objet à mesurer sur le même plan que la feuille

### 2. Photo avec angle (test_angle.jpg)
- Feuille A4 visible
- Photo prise avec un angle de 15-30°
- Test de la correction de perspective

### 3. Photo complexe (test_complex.jpg)
- Plusieurs objets à mesurer
- Feuille A4 comme référence
- Test de la détection de contours multiples

## Comment créer des images de test

1. **Matériel nécessaire**
   - Une feuille A4 standard (210 x 297 mm)
   - Objets à mesurer (livre, téléphone, etc.)
   - Appareil photo ou smartphone

2. **Procédure**
   - Placer la feuille A4 sur une surface plane
   - Disposer les objets à mesurer à côté
   - Prendre la photo en incluant toute la feuille A4
   - Éviter les ombres portées sur la feuille

3. **Conseils**
   - Utiliser un fond contrasté (table sombre pour feuille blanche)
   - S'assurer que les bords de la feuille A4 sont nets
   - Éviter les reflets sur la feuille

## Résultats attendus

L'application devrait :
- Détecter automatiquement la feuille A4
- Calculer le facteur pixels_per_mm
- Suggérer des contours pour les objets présents
- Permettre de mesurer avec une précision < 5mm

## Structure des données de test

```json
{
  "test_cases": [
    {
      "image": "test_ideal.jpg",
      "expected_a4_detected": true,
      "expected_accuracy_mm": 5
    },
    {
      "image": "test_angle.jpg", 
      "expected_a4_detected": true,
      "expected_accuracy_mm": 10
    },
    {
      "image": "test_no_a4.jpg",
      "expected_a4_detected": false,
      "expected_error": "Aucun marqueur A4 détecté"
    }
  ]
}
```