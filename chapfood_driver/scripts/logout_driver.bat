@echo off
REM Script pour déconnecter le livreur actuellement connecté
REM Usage: scripts\logout_driver.bat

echo.
echo ========================================
echo   Script de deconnexion du livreur
echo ========================================
echo.

cd /d "%~dp0\.."
dart run scripts/logout_driver.dart

pause


