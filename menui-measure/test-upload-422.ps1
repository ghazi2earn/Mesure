# Script PowerShell pour diagnostiquer l'erreur 422 upload photos

$TOKEN = "Pa6oRll3llBfm1PiY7Scx8PczVB4Ru4w"
$BASE_URL = "https://mesures.calendrize.com"

Write-Host "=== TEST DIAGNOSTIC ERREUR 422 UPLOAD ===" -ForegroundColor Green
Write-Host ""

# 1. Test du token
Write-Host "1. Vérification du token..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/guest/$TOKEN/check" -Method GET
    Write-Host "   Token valide: $($response.valid)" -ForegroundColor Green
    if ($response.task) {
        Write-Host "   Tâche: $($response.task.title)" -ForegroundColor Green
    }
} catch {
    Write-Host "   Erreur token: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# 2. Créer une image de test
Write-Host "2. Création d'une image de test..." -ForegroundColor Yellow
$testImagePath = "test.jpg"
# Créer un fichier JPEG minimal (header + données)
$jpegHeader = [byte[]](0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, 0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43, 0x00, 0xFF, 0xD9)
[System.IO.File]::WriteAllBytes($testImagePath, $jpegHeader)
Write-Host "   Image test créée: $testImagePath ($(Get-Item $testImagePath).Length) bytes)" -ForegroundColor Green

# 3. Test avec endpoint de debug
Write-Host "3. Test upload avec endpoint de debug..." -ForegroundColor Yellow
try {
    $form = @{
        'photos[]' = Get-Item $testImagePath
        'contact_email' = 'test@example.com'
    }
    
    $response = Invoke-RestMethod -Uri "$BASE_URL/guest/$TOKEN/photos-debug" -Method POST -Form $form -ContentType "multipart/form-data"
    Write-Host "   Debug upload réussi!" -ForegroundColor Green
    Write-Host "   Réponse: $($response.message)" -ForegroundColor Green
} catch {
    Write-Host "   Erreur debug upload: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "   Code statut: $statusCode" -ForegroundColor Red
        
        # Lire le contenu de la réponse d'erreur
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "   Détails: $responseBody" -ForegroundColor Red
    }
}
Write-Host ""

# 4. Test avec endpoint original
Write-Host "4. Test upload avec endpoint original..." -ForegroundColor Yellow
try {
    $form = @{
        'photos[]' = Get-Item $testImagePath
        'contact_email' = 'test@example.com'
    }
    
    $response = Invoke-RestMethod -Uri "$BASE_URL/guest/$TOKEN/photos" -Method POST -Form $form -ContentType "multipart/form-data"
    Write-Host "   Upload original réussi!" -ForegroundColor Green
    Write-Host "   Réponse: $($response.message)" -ForegroundColor Green
} catch {
    Write-Host "   Erreur upload original: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "   Code statut: $statusCode" -ForegroundColor Red
        
        # Lire le contenu de la réponse d'erreur
        try {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host "   Détails: $responseBody" -ForegroundColor Red
        } catch {
            Write-Host "   Impossible de lire les détails de l'erreur" -ForegroundColor Red
        }
    }
}
Write-Host ""

# 5. Test avec différentes tailles
Write-Host "5. Test avec image plus grande..." -ForegroundColor Yellow
$largeImagePath = "large_test.jpg"
# Créer une image plus grande (1KB)
$largeData = @(0xFF, 0xD8) + @(0x00) * 1020 + @(0xFF, 0xD9)
[System.IO.File]::WriteAllBytes($largeImagePath, $largeData)

try {
    $form = @{
        'photos[]' = Get-Item $largeImagePath
    }
    
    $response = Invoke-RestMethod -Uri "$BASE_URL/guest/$TOKEN/photos-debug" -Method POST -Form $form -ContentType "multipart/form-data"
    Write-Host "   Upload image large réussi!" -ForegroundColor Green
} catch {
    Write-Host "   Erreur upload image large: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "   Code statut: $statusCode" -ForegroundColor Red
    }
}

# Nettoyage
Remove-Item $testImagePath -ErrorAction SilentlyContinue
Remove-Item $largeImagePath -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "=== RECOMMANDATIONS ===" -ForegroundColor Green
Write-Host "1. Vérifiez les logs Laravel sur le serveur:" -ForegroundColor Yellow
Write-Host "   tail -f /var/www/votre-app/laravel-app/storage/logs/laravel.log" -ForegroundColor White
Write-Host ""
Write-Host "2. Vérifiez la configuration PHP sur le serveur:" -ForegroundColor Yellow
Write-Host "   php -i | grep -E '(upload_max_filesize|post_max_size)'" -ForegroundColor White
Write-Host ""
Write-Host "3. Si le debug fonctionne mais pas l'original:" -ForegroundColor Yellow
Write-Host "   → Problème dans le contrôleur principal" -ForegroundColor White
Write-Host ""
Write-Host "4. Si rien ne fonctionne:" -ForegroundColor Yellow
Write-Host "   → Problème de configuration serveur (PHP/Nginx)" -ForegroundColor White
Write-Host ""
Write-Host "5. Déployez les nouveaux fichiers sur le serveur:" -ForegroundColor Yellow
Write-Host "   - GuestUploadControllerDebug.php" -ForegroundColor White
Write-Host "   - routes/web.php avec la route debug" -ForegroundColor White
Write-Host ""
