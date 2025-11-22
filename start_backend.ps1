# Script simple de demarrage du backend
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "DEMARRAGE DU BACKEND API - SALAM" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Verifier Node.js
$nodeVersion = node --version 2>$null
if ($nodeVersion) {
    Write-Host "✓ Node.js $nodeVersion" -ForegroundColor Green
} else {
    Write-Host "✗ Node.js non installe!" -ForegroundColor Red
    Write-Host "  Telecharger: https://nodejs.org/`n" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "`nDemarrage du serveur API..." -ForegroundColor Yellow
Write-Host "URL: http://192.168.1.23:3000" -ForegroundColor White
Write-Host "Appuyez sur Ctrl+C pour arreter`n" -ForegroundColor Gray
Write-Host "========================================`n" -ForegroundColor Cyan

cd baol_api
node server.js
