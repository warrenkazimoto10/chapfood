# Configuration Supabase pour ChapFood

## 🔧 Configuration requise

### 1. Obtenir votre clé API Supabase

1. Allez sur [supabase.com](https://supabase.com)
2. Connectez-vous à votre projet `chapfood`
3. Allez dans **Settings** > **API**
4. Copiez votre **anon public key**

### 2. Mettre à jour la configuration

Ouvrez le fichier `lib/config/supabase_config.dart` et remplacez :

```dart
static const String supabaseAnonKey = 'VOTRE_CLE_ANON_ICI';
```

### 3. Permissions Android (pour la géolocalisation)

Ajoutez dans `android/app/src/main/AndroidManifest.xml` :

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

### 4. Permissions iOS (pour la géolocalisation)

Ajoutez dans `ios/Runner/Info.plist` :

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Cette app a besoin de votre localisation pour la livraison</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Cette app a besoin de votre localisation pour la livraison</string>
```

## 🗄️ Structure de base de données

Votre base de données Supabase contient déjà :

- ✅ **users** - Utilisateurs
- ✅ **categories** - Catégories de plats
- ✅ **menu_items** - Plats du menu
- ✅ **supplements** - Suppléments (garnitures, extras)
- ✅ **orders** - Commandes
- ✅ **order_items** - Articles de commande
- ✅ **carts** - Paniers
- ✅ **drivers** - Livreurs

## 🚀 Fonctionnalités implémentées

### ✅ Authentification
- Connexion par email
- Connexion par téléphone
- Inscription
- Gestion des profils utilisateur

### ✅ Menu
- Affichage des catégories
- Filtrage par catégorie
- Liste des plats avec images
- Prix et descriptions

### ✅ Services
- Restaurant (disponible)
- TruckFood (en développement)
- Supermarché (bientôt)

## 🔄 Prochaines étapes

1. **Panier** - Ajouter/supprimer des articles
2. **Commandes** - Créer et suivre les commandes
3. **Géolocalisation** - Suivi des livreurs
4. **Notifications** - Mises à jour en temps réel
5. **Paiement** - Intégration mobile money

## 🐛 Dépannage

### Erreur de connexion
- Vérifiez votre clé API Supabase
- Vérifiez votre connexion internet
- Vérifiez que votre projet Supabase est actif

### Erreur de géolocalisation
- Vérifiez les permissions Android/iOS
- Testez sur un appareil physique (pas l'émulateur)

### Erreur de build
```bash
flutter clean
flutter pub get
flutter run
```

## 📱 Test de l'application

1. Lancez l'application
2. Passez l'onboarding
3. Connectez-vous (créez un compte si nécessaire)
4. Accédez au menu restaurant
5. Parcourez les catégories et plats

## 🔗 Liens utiles

- [Documentation Supabase Flutter](https://supabase.com/docs/guides/getting-started/flutter)
- [Documentation Geolocator](https://pub.dev/packages/geolocator)
- [Documentation Google Maps](https://pub.dev/packages/google_maps_flutter)
