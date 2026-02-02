# Exemples de Code - Migration Google Maps → Mapbox

## Exemple 1: Ajouter un Marqueur Simple

### Google Maps (Ancien)
```dart
final marker = Marker(
  markerId: MarkerId('restaurant'),
  position: LatLng(5.226313, -3.768063),
  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
);

setState(() {
  _markers.add(marker);
});
```

### Mapbox (Nouveau)
```dart
// Créer l'image du marqueur
final markerImage = await MapboxDirectionalMarker.createSimpleMarkerImage(
  color: Colors.red,
  size: 40.0,
);

// Ajouter l'image au style
await _mapboxMap!.style.addStyleImage(
  'restaurant_marker',
  1.0,
  markerImage,
  false,
  [],
  [],
  null,
);

// Ajouter le marqueur
await _annotationHelper!.addOrUpdatePointAnnotation(
  id: 'restaurant',
  lat: 5.226313,
  lng: -3.768063,  // ⚠️ Attention: lng avant lat!
  iconImage: 'restaurant_marker',
  iconSize: 1.0,
);
```

## Exemple 2: Ajouter un Marqueur Directionnel

### Google Maps (Ancien)
```dart
final directionalIcon = await DirectionalMarker.createDirectionalMarker(
  color: Colors.blue,
  bearing: 45.0,
  showPopup: false,
);

final marker = Marker(
  markerId: MarkerId('driver'),
  position: LatLng(latitude, longitude),
  icon: directionalIcon,
  anchor: Offset(0.5, 0.5),
);

setState(() {
  _markers.add(marker);
});
```

### Mapbox (Nouveau)
```dart
final bearing = 45.0;

// Créer l'image directionnelle
final markerImage = await MapboxDirectionalMarker.createDirectionalMarkerImage(
  color: Colors.blue,
  bearing: bearing,
  showPopup: false,
);

// Générer un ID unique basé sur le bearing
final imageId = MapboxDirectionalMarker.generateMarkerId(
  color: Colors.blue,
  bearing: bearing,
  showPopup: false,
);

// Ajouter l'image au style
await _mapboxMap!.style.addStyleImage(
  imageId,
  1.0,
  markerImage,
  false,
  [],
  [],
  null,
);

// Ajouter le marqueur
await _annotationHelper!.addOrUpdatePointAnnotation(
  id: 'driver',
  lat: latitude,
  lng: longitude,
  iconImage: imageId,
  iconSize: 1.0,
);
```

## Exemple 3: Dessiner une Polyline (Route)

### Google Maps (Ancien)
```dart
final polyline = Polyline(
  polylineId: PolylineId('route'),
  points: routeCoordinates,  // List<LatLng>
  color: Color(0xFF3B82F6),
  width: 6,
  geodesic: true,
);

setState(() {
  _polylines.add(polyline);
});
```

### Mapbox (Nouveau)
```dart
// Convertir List<LatLng> en List<Position>
// ⚠️ ATTENTION: Ordre inversé!
final positions = routeCoordinates.map((latLng) => 
  Position(latLng.longitude, latLng.latitude)
).toList();

// Ajouter la polyline
await _annotationHelper!.addOrUpdatePolyline(
  id: 'route',
  coordinates: positions,
  lineColor: 0xFF3B82F6,
  lineWidth: 6.0,
);
```

## Exemple 4: Centrer la Caméra

### Google Maps (Ancien)
```dart
await _mapController!.animateCamera(
  CameraUpdate.newLatLngZoom(
    LatLng(latitude, longitude),
    15.0,
  ),
);
```

### Mapbox (Nouveau)
```dart
await _cameraHelper!.animateTo(
  lat: latitude,
  lng: longitude,
  zoom: 15.0,
);
```

## Exemple 5: Centrer sur une Route (Bounds)

### Google Maps (Ancien)
```dart
final bounds = LatLngBounds(
  southwest: LatLng(minLat, minLng),
  northeast: LatLng(maxLat, maxLng),
);

await _mapController!.animateCamera(
  CameraUpdate.newLatLngBounds(bounds, 50),
);
```

### Mapbox (Nouveau)
```dart
await _cameraHelper!.fitBounds(
  coordinates: positions,  // List<Position>
  padding: EdgeInsets.all(50),
);
```

## Exemple 6: Supprimer un Marqueur

### Google Maps (Ancien)
```dart
_markers.removeWhere((m) => m.markerId == MarkerId('driver'));
setState(() {});
```

### Mapbox (Nouveau)
```dart
await _annotationHelper!.removePointAnnotation('driver');
```

## Exemple 7: Supprimer une Polyline

### Google Maps (Ancien)
```dart
_polylines.removeWhere((p) => p.polylineId == PolylineId('route'));
setState(() {});
```

### Mapbox (Nouveau)
```dart
await _annotationHelper!.removePolyline('route');
```

## Exemple 8: Initialisation de la Carte

### Google Maps (Ancien)
```dart
GoogleMap(
  initialCameraPosition: CameraPosition(
    target: LatLng(5.3600, -4.0083),
    zoom: 15.0,
  ),
  markers: _markers,
  polylines: _polylines,
  onMapCreated: (GoogleMapController controller) {
    _mapController = controller;
  },
)
```

### Mapbox (Nouveau)
```dart
MapboxMapWidget(
  initialPosition: _currentPosition,
  onMapCreated: (MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _annotationHelper = MapboxAnnotationHelper(mapboxMap);
    _cameraHelper = MapboxCameraHelper(mapboxMap);
    await _annotationHelper!.initialize();
  },
  initialZoom: 15.0,
)
```

## Exemple 9: Conversion de Coordonnées

### De LatLng à Position
```dart
// Google Maps
final latLng = LatLng(5.226313, -3.768063);

// Mapbox - ⚠️ ORDRE INVERSÉ!
final position = Position(-3.768063, 5.226313);
// ou
final position = Position(latLng.longitude, latLng.latitude);
```

### De List<LatLng> à List<Position>
```dart
// Google Maps
List<LatLng> googleCoords = [...];

// Mapbox
List<Position> mapboxCoords = googleCoords.map((latLng) =>
  Position(latLng.longitude, latLng.latitude)
).toList();
```

## Exemple 10: Utilisation du Service de Routage

### Google Maps (Ancien)
```dart
final route = await GoogleMapsRoutingService.getRoute(
  startLat: startLat,
  startLng: startLng,
  endLat: endLat,
  endLng: endLng,
);

if (route != null) {
  // route.coordinates est List<LatLng>
  final polyline = Polyline(
    polylineId: PolylineId('route'),
    points: route.coordinates,
    color: Colors.blue,
    width: 5,
  );
}
```

### Mapbox (Nouveau)
```dart
final route = await MapboxRoutingService.getRoute(
  startLat: startLat,
  startLng: startLng,
  endLat: endLat,
  endLng: endLng,
);

if (route != null) {
  // route.coordinates est List<Position>
  await _annotationHelper!.addOrUpdatePolyline(
    id: 'route',
    coordinates: route.coordinates,
    lineColor: 0xFF3B82F6,
    lineWidth: 5.0,
  );
}
```

## Points Clés à Retenir

1. **Ordre des coordonnées:** `Position(longitude, latitude)` ≠ `LatLng(latitude, longitude)`
2. **Asynchrone:** Toutes les opérations Mapbox sont `async`
3. **Initialisation:** `await _annotationHelper!.initialize()` est obligatoire
4. **Images:** Les marqueurs nécessitent `addStyleImage()` avant utilisation
5. **Pas de setState:** Les annotations Mapbox se mettent à jour automatiquement

Bon courage! 🚀
