# Étapes Finales de Migration

J'ai automatisé 80% de la migration. Voici les 20% restants à faire manuellement pour chaque écran.

## 1. home_screen.dart

### A. Chargement des Icônes (_loadMarkerIcons)
Remplacer le code commenté par:
```dart
_driverMarkerIcon = await MapboxDirectionalMarker.createSimpleMarkerImage(color: Colors.blue, size: 40);
await _mapboxMap!.style.addStyleImage('driver_icon', 1.0, _driverMarkerIcon!, false, [], [], null);

_clientMarkerIcon = await MapboxDirectionalMarker.createSimpleMarkerImage(color: Colors.yellow, size: 40);
await _mapboxMap!.style.addStyleImage('client_icon', 1.0, _clientMarkerIcon!, false, [], [], null);
```

### B. Mise à jour du Livreur (_updateMapLocation)
Remplacer la logique `_markers` par:
```dart
await _annotationHelper!.addOrUpdatePointAnnotation(
  id: 'driver',
  lat: _currentPosition!.latitude,
  lng: _currentPosition!.longitude,
  iconImage: 'driver_icon', // Assurez-vous d'avoir ajouté l'image au style
);
```

### C. Ajout Marqueur Client (_addClientMarker)
Remplacer la logique `_markers` par:
```dart
await _annotationHelper!.addOrUpdatePointAnnotation(
  id: 'client',
  lat: lat,
  lng: lng,
  iconImage: 'client_icon',
);
```

### D. Dessiner Route (_drawRoute)
Remplacer la logique `_polylines` par:
```dart
await _annotationHelper!.addOrUpdatePolyline(
  id: 'route',
  coordinates: coordinates, // List<Position>
  lineColor: AppColors.primaryRed.value,
  lineWidth: 5.0,
);
```

## 2. real_data_home_screen.dart & active_delivery_screen.dart

Suivre exactement le même modèle que `home_screen.dart`.

## ⚠️ Rappel Important : Coordonnées

Mapbox utilise `Position(longitude, latitude)`.
Google Maps utilise `LatLng(latitude, longitude)`.

**L'ordre est inversé !** Soyez vigilants lors de la conversion.

## Vérification

Une fois ces modifications faites, lancez:
```bash
flutter run
```
Si vous avez des erreurs, consultez `CODE_EXAMPLES.md` pour voir comment implémenter chaque fonctionnalité.
