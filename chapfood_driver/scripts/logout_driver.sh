#!/bin/bash
# Script pour déconnecter le livreur actuellement connecté
# Usage: ./scripts/logout_driver.sh

echo ""
echo "========================================"
echo "  Script de déconnexion du livreur"
echo "========================================"
echo ""

cd "$(dirname "$0")/.."
dart run scripts/logout_driver.dart


