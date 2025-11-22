# Script de Génération des Assets - SALAM
# Ce script génère automatiquement les icônes et splash screens

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Génération des Assets pour SALAM" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier si Flutter est installé
Write-Host "[1/6] Vérification de Flutter..." -ForegroundColor Yellow
$flutterCheck = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterCheck) {
    Write-Host "❌ ERREUR: Flutter n'est pas installé ou pas dans le PATH!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Flutter détecté" -ForegroundColor Green
Write-Host ""

# Vérifier les fichiers requis
Write-Host "[2/6] Vérification des images sources..." -ForegroundColor Yellow
$requiredFiles = @(
    "assets/icons/app_icon.png",
    "assets/icons/foreground.png",
    "assets/icons/splash_logo.png"
)

$missingFiles = @()
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "  ✅ $file trouvé" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $file manquant" -ForegroundColor Red
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "⚠️  ATTENTION: Des fichiers sont manquants!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Vous devez créer ces images avant de continuer :" -ForegroundColor Yellow
    foreach ($file in $missingFiles) {
        Write-Host "  - $file" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "📖 Consultez PREPARATION_IMAGES.md pour les spécifications." -ForegroundColor Cyan
    Write-Host ""
    
    # Proposer une solution temporaire
    $useLogoTemp = Read-Host "Voulez-vous utiliser temporairement logo.jpg ? (O/N)"
    if ($useLogoTemp -eq "O" -or $useLogoTemp -eq "o") {
        Write-Host ""
        Write-Host "⚠️  Copie temporaire du logo existant..." -ForegroundColor Yellow
        
        foreach ($file in $missingFiles) {
            Copy-Item "assets/images/logo.jpg" $file -Force
            Write-Host "  ✅ Créé: $file" -ForegroundColor Green
        }
        
        Write-Host ""
        Write-Host "⚠️  IMPORTANT: Remplacez ces fichiers par de vraies images PNG avec transparence !" -ForegroundColor Yellow
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "❌ Génération annulée. Créez les images puis relancez ce script." -ForegroundColor Red
        exit 1
    }
}
Write-Host ""

# Nettoyer le projet
Write-Host "[3/6] Nettoyage du projet..." -ForegroundColor Yellow
flutter clean | Out-Null
Write-Host "✅ Nettoyage terminé" -ForegroundColor Green
Write-Host ""

# Installer les dépendances
Write-Host "[4/6] Installation des dépendances..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ ERREUR: L'installation des dépendances a échoué!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Dépendances installées" -ForegroundColor Green
Write-Host ""

# Générer les icônes
Write-Host "[5/6] Génération des icônes d'application..." -ForegroundColor Yellow
flutter pub run flutter_launcher_icons
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ ERREUR: La génération des icônes a échoué!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Icônes générées" -ForegroundColor Green
Write-Host ""

# Générer les splash screens
Write-Host "[6/6] Génération des splash screens..." -ForegroundColor Yellow
flutter pub run flutter_native_splash:create
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ ERREUR: La génération des splash screens a échoué!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Splash screens générés" -ForegroundColor Green
Write-Host ""

# Résumé
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ✨ Génération Terminée avec Succès !" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📱 Assets générés:" -ForegroundColor Yellow
Write-Host "  ✅ Icônes Android (toutes densités)" -ForegroundColor White
Write-Host "  ✅ Icônes iOS (toutes tailles)" -ForegroundColor White
Write-Host "  ✅ Icônes Web" -ForegroundColor White
Write-Host "  ✅ Splash screens Android" -ForegroundColor White
Write-Host "  ✅ Splash screens iOS" -ForegroundColor White
Write-Host "  ✅ Splash screens Android 12+" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Prochaines étapes:" -ForegroundColor Yellow
Write-Host "  1. Testez avec: flutter run" -ForegroundColor White
Write-Host "  2. Vérifiez les icônes sur l'appareil" -ForegroundColor White
Write-Host "  3. Si tout est OK, passez à la signature Android" -ForegroundColor White
Write-Host ""
Write-Host "📖 Documentation:" -ForegroundColor Cyan
Write-Host "  - GUIDE_ASSETS.md : Guide complet des assets" -ForegroundColor White
Write-Host "  - GUIDE_SIGNATURE_ANDROID.md : Prochaine étape" -ForegroundColor White
Write-Host ""
Write-Host "✅ Vous pouvez maintenant construire l'app!" -ForegroundColor Green
Write-Host ""
