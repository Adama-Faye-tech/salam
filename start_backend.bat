@echo off
echo ========================================
echo DEMARRAGE DU BACKEND API - SALAM
echo ========================================
echo.

cd baol_api

echo Verification de Node.js...
node --version >nul 2>&1
if errorlevel 1 (
    echo [ERREUR] Node.js n'est pas installe!
    echo Telechargez depuis: https://nodejs.org/
    pause
    exit /b 1
)

echo [OK] Node.js detecte
echo.

echo Demarrage du serveur API sur http://192.168.1.23:3000
echo.
echo Appuyez sur Ctrl+C pour arreter le serveur
echo ========================================
echo.

node server.js

pause
