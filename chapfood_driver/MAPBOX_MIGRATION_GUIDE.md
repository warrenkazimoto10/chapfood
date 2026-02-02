# Guide de Migration - dashboard_screen.dart vers Mapbox

## État Actuel

✅ **Déjà fait:**
- Imports Mapbox ajoutés (lignes 5, 17-19)
- Variables d'état adaptées (lignes 44-49)
- Méthode `_updateDriverMarkerOnMap()` migrée (lignes 449-495)

## Étapes de Migration Restantes

### Étape 1: Remplacer le Widget GoogleMap (lignes 780-797)

**Ancien code (GoogleMap):**
```dart
Widget _buildMapView() {
  return GoogleMap(
    mapType: MapType.normal,
    initialCameraPosition: CameraPosition(
      target: LatLng(
        _currentPosition?.latitude ?? 5.3600,
        _currentPosition?.longitude ?? -4.0083,
      ),
      zoom: 15.0,
    ),
    markers: _markers,
    onMapCreated: _onMapCreated,
    myLocationEnabled: false,
    myLocationButtonEnabled: false,
  );
}
```

**Nouveau code (Mapbox):**
```dart
Widget _buildMapView() {
  return MapboxMapWidget(
    initialPosition: _currentPosition,
    onMapCreated: _onMapCreated,
    initialZoom: 15.0,
  );
}
```

### Étape 2: Migrer _onMapCreated (lignes 799-829)

**Changements clés:**
- `GoogleMapController controller` → `MapboxMap mapboxMap`
- Initialiser `_annotationHelper` et `_cameraHelper`
- Appeler `await _annotationHelper!.initialize()`

**Nouveau code:**
```dart
Future<void> _onMapCreated(MapboxMap mapboxMap) async {
  _mapboxMap = mapboxMap;
  _annotationHelper = MapboxAnnotationHelper(mapboxMap);
  _cameraHelper = MapboxCameraHelper(mapboxMap);
  await _annotationHelper!.initialize();
  
  // Le reste du code reste identique
}
```

### Étape 3: Supprimer _createDirectionalMarker (lignes 831-840)

Cette méthode n'est plus nécessaire. **Supprimer complètement.**

### Étape 4: Migrer _centerMapOnDriverPosition (lignes 842-897)

**Changements clés:**
- `_mapController` → `_cameraHelper`
- `_mapController!.animateCamera(CameraUpdate.newLatLngZoom(...))` → `_cameraHelper!.animateTo(lat: ..., lng: ..., zoom: ...)`

**Nouveau code:**
```dart
Future<void> _centerMapOnDriverPosition() async {
  if (_currentPosition == null) {
    final position = await DriverLocationService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() { _currentPosition = position; });
    } else {
      print('Position non disponible');
      return;
    }
  }

  if (_cameraHelper == null || _currentPosition == null) {
    return;
  }

  try {
    await _cameraHelper!.animateTo(
      lat: _currentPosition!.latitude,
      lng: _currentPosition!.longitude,
      zoom: 15.0,
    );
    
    // Le reste (feedback visuel) reste identique
  } catch (e) {
    print('Erreur: $e');
  }
}
```

## Points d'Attention Critiques

⚠️ **ORDRE DES COORDONNÉES INVERSÉ:**
- Google Maps: `LatLng(latitude, longitude)`
- Mapbox: `Position(longitude, latitude)`

## Commandes de Test

```bash
cd c:/Users/ThinkPad/chapfood/chapfood_driver
flutter pub get
flutter run
```

## Résumé des Remplacements

| Ancien | Nouveau |
|--------|---------|
| `GoogleMapController` | `MapboxMap` |
| `_mapController` | `_mapboxMap` ou `_cameraHelper` |
| `Set<Marker> _markers` | Supprimé (géré par `_annotationHelper`) |
| `animateCamera(CameraUpdate.newLatLngZoom(...))` | `_cameraHelper.animateTo(lat:, lng:, zoom:)` |
| `LatLng(lat, lng)` | `Position(lng, lat)` |

Bonne migration! 🚀
