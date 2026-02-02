# 🔧 Correction des erreurs de types Mapbox

## ❌ **Erreurs rencontrées :**

### **1. Erreur `num` → `double` :**
```
A value of type 'num' can't be assigned to a variable of type 'double'
```

### **2. Erreur `Map<String, Object>` → `String` :**
```
Error: The argument type 'Map<String, Object>' can't be assigned to the parameter type 'String?'
```

## ✅ **Solutions appliquées :**

### **1. Import de `dart:convert` :**
```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
// ...
```

### **2. Casting des coordonnées en `double` :**
```dart
// ❌ Avant
'lat': _customerPosition!.coordinates.lat,
'lng': _customerPosition!.coordinates.lng,

// ✅ Après
'lat': _customerPosition!.coordinates.lat.toDouble(),
'lng': _customerPosition!.coordinates.lng.toDouble(),
```

### **3. Utilisation de `jsonEncode()` pour les données GeoJSON :**
```dart
// ❌ Avant
data: {
  "type": "FeatureCollection",
  "features": [...]
}

// ✅ Après
data: jsonEncode({
  "type": "FeatureCollection",
  "features": [...]
})
```

## 🛠️ **Implémentation corrigée :**

### **1. Méthode `_addMarkersAndRoute()` :**
```dart
Future<void> _addMarkersAndRoute() async {
  if (mapboxMap == null || _driverPosition == null || _customerPosition == null) return;

  try {
    // Source GeoJSON avec jsonEncode
    await mapboxMap!.style.addSource(
      GeoJsonSource(
        id: "positions",
        data: jsonEncode({
          "type": "FeatureCollection",
          "features": [
            {
              "type": "Feature",
              "geometry": {
                "type": "Point",
                "coordinates": [
                  _driverPosition!.coordinates.lng.toDouble(), // ✅ .toDouble()
                  _driverPosition!.coordinates.lat.toDouble(), // ✅ .toDouble()
                ]
              },
              "properties": {"icon": "car"}
            },
            {
              "type": "Feature",
              "geometry": {
                "type": "Point",
                "coordinates": [
                  _customerPosition!.coordinates.lng.toDouble(), // ✅ .toDouble()
                  _customerPosition!.coordinates.lat.toDouble(), // ✅ .toDouble()
                ]
              },
              "properties": {"icon": "pin"}
            }
          ]
        }),
      ),
    );

    // Couche de symboles
    await mapboxMap!.style.addLayer(
      SymbolLayer(
        id: "positions-layer",
        sourceId: "positions",
        iconImage: "car", // Icône par défaut
        iconSize: 1.2,
      ),
    );

    // Route avec jsonEncode
    await mapboxMap!.style.addSource(
      GeoJsonSource(
        id: "route",
        data: jsonEncode({ // ✅ jsonEncode()
          "type": "Feature",
          "geometry": {
            "type": "LineString",
            "coordinates": [
              [-4.0363, 5.3563],
              [-4.0300, 5.3600],
              [-4.0250, 5.3650],
              [widget.customerLongitude.toDouble(), widget.customerLatitude.toDouble()] // ✅ .toDouble()
            ]
          }
        }),
      ),
    );

    await mapboxMap!.style.addLayer(
      LineLayer(
        id: "route-layer",
        sourceId: "route",
        lineColor: Colors.blue.value, // ✅ .value
        lineWidth: 4.0,
      ),
    );
  } catch (e) {
    print('Erreur lors de l\'ajout des marqueurs et route: $e');
  }
}
```

### **2. Méthode `_updateDriverMarker()` :**
```dart
Future<void> _updateDriverMarker() async {
  if (mapboxMap == null || _driverPosition == null || _customerPosition == null) return;

  try {
    await mapboxMap!.style.setStyleSourceProperty(
      "positions",
      "data",
      jsonEncode({ // ✅ jsonEncode()
        "type": "FeatureCollection",
        "features": [
          {
            "type": "Feature",
            "geometry": {
              "type": "Point",
              "coordinates": [
                _driverPosition!.coordinates.lng.toDouble(), // ✅ .toDouble()
                _driverPosition!.coordinates.lat.toDouble(), // ✅ .toDouble()
              ]
            },
            "properties": {"icon": "car"}
          },
          {
            "type": "Feature",
            "geometry": {
              "type": "Point",
              "coordinates": [
                _customerPosition!.coordinates.lng.toDouble(), // ✅ .toDouble()
                _customerPosition!.coordinates.lat.toDouble(), // ✅ .toDouble()
              ]
            },
            "properties": {"icon": "pin"}
          }
        ]
      }),
    );
  } catch (e) {
    print('Erreur lors de la mise à jour du marqueur du livreur: $e');
  }
}
```

### **3. Route avec coordonnées corrigées :**
```dart
_trackingService.setRoute([
  {'lat': 5.3563, 'lng': -4.0363},
  {'lat': 5.3600, 'lng': -4.0300},
  {'lat': 5.3650, 'lng': -4.0250},
  {
    'lat': _customerPosition!.coordinates.lat.toDouble(), // ✅ .toDouble()
    'lng': _customerPosition!.coordinates.lng.toDouble(), // ✅ .toDouble()
  },
]);
```

## 🎯 **Résultat :**

### **Avant :**
- ❌ **Erreur de compilation** `num` → `double`
- ❌ **Erreur de compilation** `Map` → `String`
- ❌ **Application ne démarre pas**

### **Après :**
- ✅ **Compilation réussie** sans erreurs
- ✅ **Types corrects** avec `.toDouble()` et `jsonEncode()`
- ✅ **Application démarre** correctement
- ✅ **Carte Mapbox** avec marqueurs fonctionnels

## 📝 **Règles à retenir :**

### **1. Coordonnées Mapbox :**
```dart
// ✅ Toujours utiliser .toDouble()
coordinates.lat.toDouble()
coordinates.lng.toDouble()
```

### **2. Données GeoJSON :**
```dart
// ✅ Toujours utiliser jsonEncode()
data: jsonEncode({
  "type": "Feature",
  "geometry": {...}
})
```

### **3. Couleurs Mapbox :**
```dart
// ✅ Utiliser .value pour les couleurs
lineColor: Colors.blue.value
```

**Toutes les erreurs de types Mapbox sont maintenant corrigées ! 🎯✨**
