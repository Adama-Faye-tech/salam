# Script de demarrage de l'application Flutter
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "DEMARRAGE DE L'APPLICATION FLUTTER" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Verifier Flutter
try {
    $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
    Write-Host "✓ Flutter detecte" -ForegroundColor Green
} catch {
    Write-Host "✗ Flutter non installe!" -ForegroundColor Red
    Write-Host "  Telecharger: https://flutter.dev/`n" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "`nChoisissez la plateforme:" -ForegroundColor Cyan
Write-Host "  1. Chrome (Web - Recommande)" -ForegroundColor White
Write-Host "  2. Windows (Desktop)" -ForegroundColor White
Write-Host "  3. Android (Emulateur)" -ForegroundColor White
Write-Host "  4. Lister tous les appareils" -ForegroundColor Gray

$choice = Read-Host "`nEntrez votre choix (1-4)"

Write-Host "`n========================================" -ForegroundColor Cyan

switch ($choice) {
    "1" {
        Write-Host "Lancement sur Chrome...`n" -ForegroundColor Yellow
        flutter run -d chrome
    }
    "2" {
        Write-Host "Lancement sur Windows...`n" -ForegroundColor Yellow
        flutter run -d windows
    }
    "3" {
        Write-Host "Lancement sur Android...`n" -ForegroundColor Yellow
        flutter devices
        Write-Host "`nLancement..." -ForegroundColor Yellow
        flutter run
    }
    "4" {
        Write-Host "Appareils disponibles:`n" -ForegroundColor Yellow
        flutter devices
        Write-Host "`n"
        $deviceId = Read-Host "Entrez l'ID de l'appareil"
        Write-Host "`nLancement sur $deviceId...`n" -ForegroundColor Yellow
        flutter run -d $deviceId
    }
    default {
        Write-Host "Lancement par defaut sur Chrome...`n" -ForegroundColor Yellow
        flutter run -d chrome
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Application lancee!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan
