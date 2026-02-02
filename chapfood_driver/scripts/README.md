# Scripts de gestion

## Script de déconnexion du livreur

### Description
Ce script permet de déconnecter le livreur actuellement connecté en :
1. Mettant à jour son statut dans la base de données (is_active: false, is_available: false)
2. Déconnectant la session Supabase Auth
3. Nettoyant les données de session locale (SharedPreferences)
4. Réinitialisant la position GPS

### Utilisation

#### Windows
```bash
scripts\logout_driver.bat
```

#### Linux/Mac
```bash
chmod +x scripts/logout_driver.sh
./scripts/logout_driver.sh
```

#### Directement avec Dart
```bash
cd chapfood_driver
dart run scripts/logout_driver.dart
```

### Prérequis
- Dart SDK installé
- Les dépendances Flutter installées (`flutter pub get`)
- Un livreur actuellement connecté dans l'application

### Notes
- Le script lit les données de session depuis SharedPreferences
- Si aucun livreur n'est connecté, le script se termine sans erreur
- Le script peut être exécuté même si l'application est fermée


