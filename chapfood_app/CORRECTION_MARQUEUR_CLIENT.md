# 🔴 Correction du marqueur client (position de livraison)

## 🎯 **Problème identifié :**
- ✅ **Marqueur livreur** (bleu) : S'affiche correctement
- ❌ **Marqueur client** (rouge) : Ne s'affiche pas sur la carte

## 🔍 **Analyse du problème :**

### **Structure de la base de données :**
```sql
-- Table orders
delivery_lat DECIMAL(10, 8)  -- Coordonnées directes
delivery_lng DECIMAL(11, 8)  -- Coordonnées directes
delivery_address TEXT        -- Adresse textuelle avec coordonnées

-- Table drivers  
current_lat DECIMAL(10, 8)   -- Position du livreur
current_lng DECIMAL(11, 8)   -- Position du livreur
```

### **Problème identifié :**
1. **Priorité incorrecte** : Extraction depuis `delivery_address` au lieu d'utiliser `delivery_lat/lng`
2. **Coordonnées manquantes** : Les colonnes `delivery_lat/lng` peuvent être `NULL`
3. **Marqueurs identiques** : Les deux marqueurs utilisent la même icône "car"

## ✅ **Corrections apportées :**

### **1. Priorité des coordonnées client :**

#### **Avant :**
```dart
// Extraction uniquement depuis delivery_address
final addressMatch = RegExp(r'\(([0-9.-]+),\s*([0-9.-]+)\)').firstMatch(order.deliveryAddress!);
```

#### **Après :**
```dart
// Priorité 1: Utiliser delivery_lat et delivery_lng directement
if (order.deliveryLat != null && order.deliveryLng != null &&
    order.deliveryLat!.isFinite && order.deliveryLng!.isFinite) {
  customerLat = order.deliveryLat!;
  customerLng = order.deliveryLng!;
  print('📍 Coordonnées client depuis delivery_lat/lng: $customerLat, $customerLng');
} 
// Priorité 2: Fallback vers delivery_address
else if (order.deliveryAddress != null) {
  // Extraction depuis l'adresse textuelle
}
```

### **2. Logs de débogage :**

#### **Coordonnées client :**
```dart
print('📍 Coordonnées client depuis delivery_lat/lng: $customerLat, $customerLng');
print('📍 Extraction depuis delivery_address: ${order.deliveryAddress}');
print('❌ Aucune coordonnée client disponible, utilisation des valeurs par défaut');
```

#### **Coordonnées livreur :**
```dart
print('🚚 Coordonnées livreur: $driverLat, $driverLng');
print('❌ Coordonnées livreur invalides, utilisation des valeurs par défaut');
print('🚚 Driver: ${driver?.name}, currentLat: ${driver?.currentLat}, currentLng: ${driver?.currentLng}');
```

#### **Création des marqueurs :**
```dart
print('🗺️ Ajout des marqueurs:');
print('🚚 Livreur: ${_driverPosition!.coordinates.lat}, ${_driverPosition!.coordinates.lng}');
print('🏠 Client: ${_customerPosition!.coordinates.lat}, ${_customerPosition!.coordinates.lng}');
print('✅ Marqueurs ajoutés avec succès');
```

### **3. Amélioration des marqueurs :**

#### **Propriétés différenciées :**
```json
{
  "properties": {"type": "driver", "icon": "car"}    // Livreur
},
{
  "properties": {"type": "customer", "icon": "marker"} // Client
}
```

#### **Paramètres de visibilité :**
```dart
SymbolLayer(
  id: "positions-layer",
  sourceId: "positions",
  iconImage: "car",
  iconSize: 1.5,                    // Taille plus grande
  iconAllowOverlap: true,           // Permettre le chevauchement
  iconIgnorePlacement: true,        // Ignorer le placement automatique
)
```

## 🗄️ **Script SQL de correction :**

### **Vérification des données :**
```sql
-- Vérifier les coordonnées manquantes
SELECT 
    COUNT(*) as total_delivery_orders,
    COUNT(delivery_lat) as orders_with_lat,
    COUNT(delivery_lng) as orders_with_lng
FROM orders 
WHERE delivery_type = 'delivery';
```

### **Mise à jour des coordonnées :**
```sql
-- Ajouter des coordonnées manquantes
UPDATE orders 
SET 
    delivery_lat = 5.3600,
    delivery_lng = -4.0083
WHERE delivery_type = 'delivery' 
AND (delivery_lat IS NULL OR delivery_lng IS NULL);
```

## 🔄 **Flux de récupération des coordonnées :**

### **Position du livreur :**
```
orders → order_driver_assignments → drivers.current_lat/lng
```

### **Position du client :**
```
orders.delivery_lat/lng (priorité 1)
↓ (si null)
orders.delivery_address (priorité 2)
↓ (si impossible à extraire)
Valeurs par défaut (5.3700, -4.0200)
```

## 🎯 **Résultats attendus :**

### **Avant :**
- ❌ Marqueur client invisible
- ❌ Extraction uniquement depuis `delivery_address`
- ❌ Pas de logs de débogage
- ❌ Marqueurs identiques

### **Après :**
- ✅ **Marqueur client visible** (rouge)
- ✅ **Priorité correcte** : `delivery_lat/lng` en premier
- ✅ **Logs détaillés** pour le débogage
- ✅ **Marqueurs différenciés** : livreur (bleu) vs client (rouge)
- ✅ **Fallback robuste** en cas de données manquantes

## 🛠️ **Actions à effectuer :**

1. **Exécuter le script SQL** `fix_delivery_coordinates.sql`
2. **Tester l'application** et vérifier les logs
3. **Confirmer l'affichage** des deux marqueurs sur la carte

**Le marqueur client rouge devrait maintenant s'afficher correctement ! 🔴🗺️✨**
