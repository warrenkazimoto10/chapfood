# Configuration Google Maps API pour Directions API

## ⚠️ Problème actuel

L'erreur `REQUEST_DENIED` dans les logs indique :
```
This IP, site or mobile application is not authorized to use this API key.
Request received from IP address 160.154.150.196, with empty referer
```

**Cause** : La clé API Android est restreinte aux applications Android uniquement, mais Directions API est appelée via HTTP depuis l'app Flutter, ce qui nécessite une clé API serveur ou une clé sans restrictions IP.

## ✅ Solution : Créer une clé API serveur pour Directions API

### Option 1 : Créer une nouvelle clé API serveur (RECOMMANDÉ)

### Étape 1 : Créer une nouvelle clé API dans Google Cloud Console

1. Allez sur [Google Cloud Console](https://console.cloud.google.com/)
2. Sélectionnez votre projet
3. Menu ☰ → **APIs et services** → **Identifiants**
4. Cliquez sur **+ CRÉER DES IDENTIFIANTS** → **Clé API**
5. Nommez-la : `Directions API Server Key`

### Étape 2 : Configurer les restrictions

1. Cliquez sur la clé créée pour l'éditer
2. **Restrictions d'application** :
   - Sélectionnez **Aucune restriction** (pour Directions API)
   - OU **Restreindre la clé** → **APIs** → Sélectionnez uniquement :
     - ✅ Directions API
     - ✅ Maps SDK for Android (si nécessaire)
     - ✅ Maps SDK for iOS (si nécessaire)
     - ✅ Maps JavaScript API (si nécessaire)

3. **Restrictions d'API** :
   - Sélectionnez **Restreindre la clé**
   - Cochez uniquement **Directions API**

4. **Restrictions d'adresses IP** (optionnel, pour plus de sécurité) :
   - Laissez vide pour autoriser depuis n'importe quelle IP
   - OU ajoutez les IPs de vos serveurs si vous utilisez un proxy

5. Cliquez sur **Enregistrer**

### Étape 3 : Utiliser la nouvelle clé dans l'app

Remplacez la clé dans `chapfood_driver/lib/services/google_maps_routing_service.dart` :

```dart
static const String _apiKey = 'VOTRE_NOUVELLE_CLE_SERVEUR';
```

Et dans `chapfood_app/lib/services/google_maps_routing_service.dart` :

```dart
static const String _apiKey = 'VOTRE_NOUVELLE_CLE_SERVEUR';
```

## Option 2 : Modifier la clé Android existante (SOLUTION RAPIDE)

Si vous avez déjà ajouté Directions API dans les restrictions d'API mais obtenez toujours REQUEST_DENIED, le problème vient des **Restrictions d'application**.

### ⚠️ Problème courant

Même si Directions API est activée, si la clé est restreinte à **"Applications Android"**, les appels HTTP depuis Flutter sont bloqués.

### ✅ Solution : Modifier les restrictions d'application

1. Allez sur [Google Cloud Console](https://console.cloud.google.com/)
2. Menu ☰ → **APIs et services** → **Identifiants**
3. Cliquez sur votre clé Android : `AIzaSyCVdrU9NVG_OgPGTFe7rCbNBBW5RjcR7Bw`
4. Vérifiez **Restrictions d'API** :
   - Doit être sur **Restreindre la clé**
   - Doit avoir **Directions API** coché ✅
   - Doit avoir **Maps SDK for Android** coché ✅
5. **IMPORTANT** : Modifiez **Restrictions d'application** :
   - Changez de **Applications Android** à **Aucune restriction**
   - ⚠️ C'est cette étape qui résout le problème REQUEST_DENIED
6. Cliquez sur **Enregistrer**
7. Attendez 1-2 minutes pour que les changements se propagent

### 🔍 Pourquoi cette modification est nécessaire ?

- **Applications Android** : Restreint la clé aux apps Android uniquement (via le package name et SHA-1)
- **Aucune restriction** : Permet les appels HTTP depuis n'importe où (nécessaire pour Directions API depuis Flutter)

**⚠️ Note de sécurité** : Cette approche expose la clé dans le code, mais c'est acceptable pour Directions API car vous pouvez limiter les quotas dans Google Cloud Console.

## Vérification

Après configuration, testez l'app. Vous devriez voir dans les logs :
- `✅ Itinéraire calculé: Xm, Xmin`
- `🔍 Points décodés depuis steps: X points` (avec X > 50)

Au lieu de :
- `❌ Erreur API Google Maps: REQUEST_DENIED`

