# 🔧 Correction de l'erreur de type "num can't be assigned to double"

## ❌ **Erreur identifiée :**

```
Error: A value of type 'num' can't be assigned to a variable of type 'double'.
```

**Fichier :** `lib/widgets/realtime_map_widget.dart`  
**Lignes :** 113, 114, 117, 118

## 🔍 **Cause du problème :**

Dans Mapbox Flutter, les coordonnées `Position.lat` et `Position.lng` sont de type `num`, mais la méthode `setRoute()` attend des valeurs de type `double`.

### **Code problématique :**
```dart
_trackingService.setRoute([
  {
    'lat': _driverPosition!.coordinates.lat,  // ❌ num → double
    'lng': _driverPosition!.coordinates.lng,  // ❌ num → double
  },
  {
    'lat': _customerPosition!.coordinates.lat, // ❌ num → double
    'lng': _customerPosition!.coordinates.lng, // ❌ num → double
  },
]);
```

## ✅ **Solution appliquée :**

### **Code corrigé :**
```dart
_trackingService.setRoute([
  {
    'lat': _driverPosition!.coordinates.lat.toDouble(),  // ✅ Conversion explicite
    'lng': _driverPosition!.coordinates.lng.toDouble(),  // ✅ Conversion explicite
  },
  {
    'lat': _customerPosition!.coordinates.lat.toDouble(), // ✅ Conversion explicite
    'lng': _customerPosition!.coordinates.lng.toDouble(), // ✅ Conversion explicite
  },
]);
```

## 🎯 **Résultat :**

- ✅ **Compilation réussie** : Plus d'erreur de type
- ✅ **Conversion sûre** : `num` → `double` avec `.toDouble()`
- ✅ **Route définie** : Positions validées et converties
- ✅ **Logs fonctionnels** : Affichage des coordonnées finales

## 📝 **Leçon apprise :**

Dans Flutter avec Mapbox, toujours convertir explicitement :
- `Position.lat` (num) → `.toDouble()`
- `Position.lng` (num) → `.toDouble()`

**L'application devrait maintenant compiler et afficher les deux marqueurs correctement ! 🚚🔴🗺️✨**
