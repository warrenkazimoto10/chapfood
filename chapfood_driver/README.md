# ChapFood Driver - Application Flutter

Application mobile pour les livreurs de ChapFood, permettant la gestion des livraisons et le suivi en temps réel.

## 🚀 Fonctionnalités

- **Écran de démarrage** avec le design ChapFood
- **Authentification** des livreurs
- **Carte Mapbox** en plein écran pour le suivi GPS
- **Gestion des commandes** assignées
- **Notifications** en temps réel
- **Suivi de position** automatique
- **Interface moderne** et intuitive

## 📱 Captures d'écran

L'application comprend :
- Splash screen avec le logo ChapFood et le design gradient
- Page de connexion pour les livreurs
- Page d'accueil avec carte Mapbox et gestion des commandes

## 🛠️ Installation

### Prérequis

- Flutter SDK (version 3.9.2 ou supérieure)
- Dart SDK
- Android Studio / VS Code
- Compte Supabase
- Compte Mapbox

### Configuration

1. **Cloner le projet**
```bash
git clone <repository-url>
cd chapfood_driver
```

2. **Installer les dépendances**
```bash
flutter pub get
```

3. **Configurer Supabase**
   - Créer un projet Supabase
   - Récupérer l'URL et la clé anonyme
   - Mettre à jour `lib/main.dart` :
   ```dart
   const String supabaseUrl = 'VOTRE_URL_SUPABASE';
   const String supabaseAnonKey = 'VOTRE_CLE_SUPABASE';
   ```

4. **Configurer Mapbox**
   - Créer un compte Mapbox
   - Générer un token d'accès
   - Mettre à jour `lib/main.dart` :
   ```dart
   const String mapboxAccessToken = 'VOTRE_TOKEN_MAPBOX';
   ```

5. **Configurer les permissions Android**
   - Ajouter dans `android/app/src/main/AndroidManifest.xml` :
   ```xml
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
   <uses-permission android:name="android.permission.INTERNET" />
   ```

6. **Configurer les permissions iOS**
   - Ajouter dans `ios/Runner/Info.plist` :
   ```xml
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>Cette application a besoin de votre position pour le suivi des livraisons</string>
   <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
   <string>Cette application a besoin de votre position pour le suivi des livraisons</string>
   ```

## 🏃‍♂️ Exécution

```bash
flutter run
```

## 📁 Structure du projet

```
lib/
├── constants/          # Configuration de l'application
├── models/            # Modèles de données
├── screens/           # Écrans de l'application
├── services/          # Services (Supabase, localisation, etc.)
├── widgets/          # Widgets personnalisés
└── main.dart         # Point d'entrée de l'application
```

## 🗄️ Base de données

L'application utilise Supabase avec les tables suivantes :
- `drivers` - Informations des livreurs
- `orders` - Commandes
- `order_driver_assignments` - Assignations livreur-commande
- `driver_notifications` - Notifications des livreurs

## 🔧 Services

- **SupabaseService** : Gestion des données Supabase
- **LocationService** : Gestion de la localisation GPS
- **SessionService** : Gestion de la session utilisateur
- **DeliveryTrackingService** : Suivi des livraisons

## 🎨 Design

L'application suit le design ChapFood avec :
- Couleurs principales : Rouge (#E94560) et Or (#FFD700)
- Gradient de fond : Bleu foncé vers rouge
- Interface moderne et intuitive

## 📱 Écrans

1. **SplashScreen** : Écran de démarrage avec animation
2. **LoginScreen** : Connexion des livreurs
3. **HomeScreen** : Carte Mapbox et gestion des commandes

## 🔐 Authentification

L'authentification se fait via :
- Numéro de téléphone
- Mot de passe
- Session persistante avec SharedPreferences

## 🗺️ Cartes

Utilisation de Mapbox pour :
- Affichage de la position du livreur
- Suivi GPS en temps réel
- Navigation vers les adresses de livraison

## 📊 Fonctionnalités principales

- **Suivi de position** : Mise à jour automatique de la position
- **Gestion des commandes** : Affichage et gestion des commandes assignées
- **Notifications** : Notifications en temps réel
- **Statut de disponibilité** : Toggle pour indiquer la disponibilité
- **Déconnexion** : Gestion de la session

## 🚨 Dépannage

### Problèmes courants

1. **Erreur de localisation**
   - Vérifier les permissions
   - Activer la localisation sur l'appareil

2. **Erreur de connexion Supabase**
   - Vérifier l'URL et la clé
   - Vérifier la connexion internet

3. **Erreur Mapbox**
   - Vérifier le token d'accès
   - Vérifier la configuration des permissions

## 📝 Notes de développement

- L'application est optimisée pour Android et iOS
- Utilisation de Provider pour la gestion d'état
- Architecture modulaire et maintenable
- Code documenté en français

## 🤝 Contribution

Pour contribuer au projet :
1. Fork le repository
2. Créer une branche feature
3. Commiter les changements
4. Pousser vers la branche
5. Créer une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus de détails.

## 📞 Support

Pour toute question ou problème :
- Email : support@chapfood.com
- Téléphone : +225 XX XX XX XX XX

---

**ChapFood Driver** - Livraisons intelligentes à Grand Bassam 🚚🍽️