#!/bin/bash

# Script de test pour diagnostiquer l'erreur 422 upload photos
# Usage: ./test-upload-422.sh

TOKEN="Pa6oRll3llBfm1PiY7Scx8PczVB4Ru4w"
BASE_URL="https://mesures.calendrize.com"

echo "=== TEST DIAGNOSTIC ERREUR 422 UPLOAD ==="
echo ""

# 1. Test du token
echo "1. Vérification du token..."
curl -s -X GET "$BASE_URL/guest/$TOKEN/check" | jq .
echo ""

# 2. Test avec endpoint de debug
echo "2. Test upload avec endpoint de debug..."
echo "   Créer une petite image de test..."

# Créer une image de test très petite (1x1 pixel PNG)
echo -n -e '\x89\x50\x4e\x47\x0d\x0a\x1a\x0a\x00\x00\x00\x0d\x49\x48\x44\x52\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90\x77\x53\xde\x00\x00\x00\x0c\x49\x44\x41\x54\x08\x d7\x63\xf8\x00\x00\x00\x01\x00\x01\x00\x18\xdd\x8d\xb4\x1c\x00\x00\x00\x00\x49\x45\x4e\x44\xae\x42\x60\x82' > test.png

echo "   Upload vers endpoint de debug..."
curl -v -X POST \
  -F "photos[]=@test.png" \
  -F "contact_email=test@example.com" \
  "$BASE_URL/guest/$TOKEN/photos-debug" \
  -H "Accept: application/json" \
  -H "X-Requested-With: XMLHttpRequest" \
  2>&1 | tee debug_response.txt

echo ""
echo "3. Informations système serveur..."

echo "   Configuration PHP:"
curl -s "$BASE_URL/info.php" 2>/dev/null | grep -E "(upload_max_filesize|post_max_size|max_file_uploads)" || echo "   info.php non accessible"

echo ""
echo "4. Test avec différentes tailles..."

# Test avec image plus grande (simulée)
echo "   Test avec données plus importantes..."
dd if=/dev/zero of=large_test.jpg bs=1024 count=100 2>/dev/null # 100KB
curl -s -X POST \
  -F "photos[]=@large_test.jpg" \
  "$BASE_URL/guest/$TOKEN/photos-debug" \
  -H "Accept: application/json" \
  2>&1 | head -10

echo ""
echo "5. Test avec endpoint original..."
curl -v -X POST \
  -F "photos[]=@test.png" \
  "$BASE_URL/guest/$TOKEN/photos" \
  -H "Accept: application/json" \
  -H "X-Requested-With: XMLHttpRequest" \
  2>&1 | head -20

# Nettoyage
rm -f test.png large_test.jpg

echo ""
echo "=== FIN DU TEST ==="
echo ""
echo "Vérifiez les logs Laravel sur le serveur:"
echo "tail -f /var/www/votre-app/laravel-app/storage/logs/laravel.log"
echo ""
echo "Si le debug fonctionne mais pas l'original, le problème est dans le contrôleur principal."
echo "Si rien ne fonctionne, le problème est dans la configuration serveur."
