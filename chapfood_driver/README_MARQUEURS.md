# 📍 Système de Marqueurs - ChapFood Livreur

## 🎯 Vue d'ensemble

Ce document explique le fonctionnement complet du système de marqueurs dans l'application ChapFood Livreur, permettant l'affichage simultané du marqueur du livreur (rouge) et du marqueur du client (jaune) sur la carte Mapbox.

## 🏗️ Architecture du système

### Variables principales
```dart
class _HomeScreenState extends State<HomeScreen> {
  MapboxMap? _mapboxMap;                    // Instance de la carte Mapbox
  PointAnnotationManager? _pointAnnotationManager; // Gestionnaire des annotations
  PointAnnotation? _clientMarker;          // Marqueur du client (jaune)
  PointAnnotation? _driverMarker;           // Marqueur du livreur (rouge)
  OrderModel? _currentOrder;               // Commande actuelle
  bool _isOnDelivery = false;              // Statut de livraison
}
```

## 🔄 Flux fonctionnel complet

### 1️⃣ Initialisation de la carte
```dart
onMapCreated: (MapboxMap mapboxMap) async {
  _mapboxMap = mapboxMap;
  _pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
  
  // Créer les images des marqueurs
  await _createCustomDriverMarker();
  await _createCustomClientMarker();
  
  // Ajouter le marqueur du livreur initial
  _updateMapLocation();
}
```

### 2️⃣ Création des images de marqueurs

#### Marqueur du livreur (rouge avec icône moto)
```dart
Future<void> _createCustomDriverMarker() async {
  final driverImage = await _createDriverMarkerImage();
  await _mapboxMap!.style.addStyleImage(
    "driver-marker", 
    1.0, 
    driverImage, 
    false, 
    [], 
    [], 
    null
  );
}

Future<MbxImage> _createDriverMarkerImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  
  // Cercle rouge avec effet 3D
  final center = const Offset(20, 20);
  final radius = 16.0;
  
  // Gradient radial pour effet 3D
  final gradient = RadialGradient(
    colors: [Colors.red.shade400, Colors.red.shade700],
    stops: const [0.0, 1.0],
  );
  
  final paint = Paint()..shader = gradient.createShader(
    Rect.fromCircle(center: center, radius: radius)
  );
  
  canvas.drawCircle(center, radius, paint);
  
  // Bordure blanche
  final borderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  canvas.drawCircle(center, radius, borderPaint);
  
  // Dessiner l'icône moto
  _drawMotoIcon3D(canvas, center);
  
  // Convertir en image
  final picture = recorder.endRecording();
  final image = await picture.toImage(40, 40);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  
  return MbxImage(
    width: 40,
    height: 40,
    data: byteData!.buffer.asUint8List(),
  );
}
```

#### Marqueur du client (jaune)
```dart
Future<void> _createCustomClientMarker() async {
  final clientImage = await _createClientMarkerImage();
  await _mapboxMap!.style.addStyleImage(
    "client-marker", 
    1.0, 
    clientImage, 
    false, 
    [], 
    [], 
    null
  );
}

Future<MbxImage> _createClientMarkerImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  
  // Cercle jaune
  final paint = Paint()..color = Colors.yellow;
  canvas.drawCircle(const Offset(20, 20), 15, paint);
  
  // Bordure blanche
  final borderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  canvas.drawCircle(const Offset(20, 20), 15, borderPaint);
  
  // Convertir en image
  final picture = recorder.endRecording();
  final image = await picture.toImage(40, 40);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  
  return MbxImage(
    width: 40,
    height: 40,
    data: byteData!.buffer.asUint8List(),
  );
}
```

### 3️⃣ Gestion des commandes

#### Acceptation d'une commande
```dart
void _acceptOrder(OrderModel order) async {
  if (_isOnDelivery) return; // Empêche double acceptation
  
  try {
    // Accepter la commande en base de données
    final success = await OrderService.acceptOrder(order.id, _currentDriver!.id);
    
    if (success) {
      setState(() {
        _currentOrder = order;
        _isOnDelivery = true;
        _isDriverAvailable = true;
        _availableOrders.clear();
      });
      
      // 🎯 AFFICHAGE DU MARQUEUR CLIENT
      _showDeliveryLocation(order.deliveryLat!, order.deliveryLng!);
    }
  } catch (e) {
    print('Erreur acceptation commande: $e');
  }
}
```

#### Affichage de la position de livraison
```dart
void _showDeliveryLocation(double lat, double lng) {
  print('🎯 Affichage position livraison: $lat, $lng');
  
  // Centrer la carte sur la position client
  _mapboxMap!.flyTo(
    CameraOptions(
      center: Point(coordinates: Position(lng, lat)),
      zoom: 15.0,
    ),
    MapAnimationOptions(duration: 1000),
  );
  
  // Ajouter le marqueur client
  _addClientMarker(lat, lng);
}
```

### 4️⃣ Ajout du marqueur client sur la carte
```dart
void _addClientMarker(double lat, double lng) async {
  if (_pointAnnotationManager == null || _mapboxMap == null) return;

  try {
    // Supprimer l'ancien marqueur client s'il existe
    if (_clientMarker != null) {
      await _pointAnnotationManager!.delete(_clientMarker!);
    }

    // Créer l'image du marqueur
    await _createCustomClientMarker();

    // Créer le PointAnnotation sur la carte
    _clientMarker = await _pointAnnotationManager!.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: Position(lng, lat)),
        iconImage: "client-marker",
        iconSize: 1.0,
        iconAnchor: IconAnchor.BOTTOM,
      ),
    );
    
    print('✅ Marqueur client ajouté à la carte');
  } catch (e) {
    print('❌ Erreur ajout marqueur client: $e');
  }
}
```

### 5️⃣ Mise à jour de la position du livreur

#### ⚠️ CORRECTION MAJEURE : Suppression sélective
```dart
void _updateMapLocation() async {
  if (_mapboxMap != null && _currentPosition != null && _pointAnnotationManager != null) {
    try {
      // Centrer la carte sur la position du livreur
      _mapboxMap!.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(_currentPosition!.longitude, _currentPosition!.latitude)),
          zoom: 15.0,
        ),
        MapAnimationOptions(duration: 1000),
      );

      // ✅ SUPPRIMER SEULEMENT LE MARQUEUR DU LIVREUR
      if (_driverMarker != null) {
        await _pointAnnotationManager!.delete(_driverMarker!);
      }

      // Créer le nouveau marqueur du livreur
      _driverMarker = await _pointAnnotationManager!.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(_currentPosition!.longitude, _currentPosition!.latitude)),
          iconImage: "driver-marker",
          iconSize: 1.0,
          iconAnchor: IconAnchor.BOTTOM,
        ),
      );

      print('📍 Marker livreur mis à jour');
    } catch (e) {
      print('Erreur mise à jour carte: $e');
    }
  }
}
```

**❌ AVANT (problématique) :**
```dart
_pointAnnotationManager!.deleteAll(); // Supprimait TOUS les marqueurs
```

**✅ APRÈS (corrigé) :**
```dart
if (_driverMarker != null) {
  await _pointAnnotationManager!.delete(_driverMarker!); // Supprime SEULEMENT le marqueur du livreur
}
```

### 6️⃣ Finalisation de la livraison
```dart
void _completeDelivery() async {
  try {
    // Marquer la livraison comme terminée en base de données
    await OrderService.completeDelivery(_currentOrder!.id);
    
    setState(() {
      _currentOrder = null;
      _isOnDelivery = false;
      _isDriverAvailable = true;
    });
    
    // 🎯 SUPPRIMER LE MARQUEUR CLIENT
    if (_clientMarker != null && _pointAnnotationManager != null) {
      await _pointAnnotationManager!.delete(_clientMarker!);
      _clientMarker = null;
    }
    
    // Remettre le marqueur du livreur
    _updateMapLocation();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Livraison terminée !'),
        backgroundColor: AppColors.successColor,
      ),
    );
  } catch (e) {
    print('Erreur finalisation livraison: $e');
  }
}
```

## 🎨 Interface utilisateur

### Panneau de livraison compact
```dart
Widget _buildCompactStatusPanel() {
  return Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        // Icône de livraison
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.local_shipping,
            color: AppColors.primaryRed,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        
        // Informations de livraison
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Livraison en cours',
                style: AppTextStyles.foodItemTitle.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Commande #${_currentOrder?.id}',
                style: AppTextStyles.foodItemDescription,
              ),
            ],
          ),
        ),
        
        // Bouton pour afficher/masquer les détails
        IconButton(
          onPressed: () {
            setState(() {
              _isDeliveryCardVisible = !_isDeliveryCardVisible;
            });
          },
          icon: Icon(
            _isDeliveryCardVisible 
              ? Icons.keyboard_arrow_up 
              : Icons.keyboard_arrow_down,
            color: AppColors.primaryRed,
          ),
          tooltip: _isDeliveryCardVisible 
            ? 'Masquer les détails' 
            : 'Afficher les détails',
        ),
      ],
    ),
  );
}
```

### Panneau de livraison détaillé
```dart
Widget _buildDeliveryPanel() {
  if (!_isDeliveryCardVisible) return const SizedBox.shrink();
  
  return DeliveryPanel(
    order: _currentOrder!,
    onCompleteDelivery: _completeDelivery,
  );
}
```

## 🔧 Configuration technique

### Dépendances requises
```yaml
dependencies:
  mapbox_maps_flutter: ^2.10.0
  geolocator: ^14.0.0
  permission_handler: ^11.3.0
```

### Permissions Android
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

### Configuration Mapbox
```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configuration Mapbox
  MapboxOptions.setAccessToken("pk.eyJ1IjoiYW5nZXdhcnJlbjEyMiIsImEiOiJjbWN0MGY2eTEwMDNhMmpzamF0OHc5YWt2In0.IY84028ftDyxRM8j_1AaHA");
  
  runApp(const MyApp());
}
```

## 🐛 Dépannage

### Problèmes courants

#### 1. Marqueur client invisible
**Cause :** `deleteAll()` supprime tous les marqueurs
**Solution :** Utiliser des références séparées et suppression sélective

#### 2. Erreur de compilation avec `await`
**Cause :** Méthode non déclarée `async`
**Solution :** Ajouter `async` à la signature de la méthode

#### 3. Marqueurs qui disparaissent
**Cause :** Conflit entre les mises à jour de position
**Solution :** Gérer les références `_clientMarker` et `_driverMarker` indépendamment

### Logs de débogage
```dart
print('🎯 Affichage position livraison: $lat, $lng');
print('✅ Marqueur client ajouté à la carte');
print('📍 Marker livreur mis à jour');
print('❌ Erreur ajout marqueur client: $e');
```

## 📊 États du système

### États possibles
1. **Libre** : Seul le marqueur du livreur est visible
2. **En livraison** : Marqueur du livreur + marqueur du client visibles
3. **Livraison terminée** : Retour à l'état libre

### Transitions
```
Libre → Acceptation commande → En livraison → Finalisation → Libre
```

## 🎯 Points clés à retenir

1. **Références séparées** : `_clientMarker` et `_driverMarker` sont indépendants
2. **Suppression sélective** : Ne jamais utiliser `deleteAll()` pendant une livraison
3. **Persistance** : Le marqueur client survit aux mises à jour de position
4. **Nettoyage** : Suppression automatique à la fin de la livraison
5. **Gestion d'erreurs** : Try-catch autour de toutes les opérations Mapbox

## 🚀 Améliorations futures

- [ ] Animation des marqueurs lors des transitions
- [ ] Marqueurs personnalisés selon le type de véhicule
- [ ] Indicateurs de direction pour le livreur
- [ ] Marqueurs pour les points de collecte multiples
- [ ] Optimisation des performances pour de nombreux marqueurs

---

**Version :** 1.0  
**Dernière mise à jour :** Décembre 2024  
**Auteur :** Équipe ChapFood Livreur
