# Estimation du Temps de Livraison

## Vue d'ensemble

Le système calcule automatiquement l'heure prévue de livraison basée sur la distance entre le livreur assigné et le client. Cette estimation n'est affichée que lorsqu'un livreur est assigné à la commande.

## Fonctionnalités

### 1. Calcul de Distance
- Utilise la formule de Haversine pour calculer la distance réelle entre deux points GPS
- Prend en compte la courbure de la Terre pour une précision maximale
- Distance exprimée en kilomètres

### 2. Estimation du Temps
L'estimation prend en compte :
- **Vitesse moyenne en ville** : 25 km/h
- **Temps de préparation** : 10 minutes
- **Temps de livraison sur place** : 5 minutes

### 3. Affichage Conditionnel
- La colonne "Heure prévue" s'affiche uniquement si :
  - Un livreur est assigné à la commande
  - Le livreur a une position GPS valide
  - L'adresse de livraison a des coordonnées GPS valides

## Interface Utilisateur

### Dans la Table des Commandes
```
Heure prévue
14:30
(25 min)
```

- **Ligne principale** : Heure d'arrivée estimée
- **Ligne secondaire** : Durée estimée de livraison

### États d'Affichage
- **"Non assigné"** : Aucun livreur assigné
- **Heure calculée** : Estimation basée sur la distance réelle

## Fichiers Modifiés

### 1. `src/utils/deliveryEstimation.ts`
Nouveau fichier contenant les fonctions utilitaires :
- `calculateDistance()` : Calcul de distance entre deux points
- `estimateDeliveryTime()` : Estimation du temps de livraison
- `formatEstimatedTime()` : Formatage du temps estimé
- `getEstimatedArrivalTime()` : Calcul de l'heure d'arrivée

### 2. `src/pages/admin/AdminReservations.tsx`
Modifications apportées :
- Import des fonctions d'estimation
- Extension de l'interface `Order` pour inclure les données du livreur
- Modification de `fetchOrders()` pour récupérer les informations du livreur
- Nouvelles fonctions `getEstimatedDeliveryTime()` et `getEstimatedDeliveryDuration()`
- Mise à jour de l'affichage de la colonne "Heure prévue"

## Base de Données

### Tables Utilisées
- `orders` : Commandes avec coordonnées de livraison
- `drivers` : Livreurs avec position GPS actuelle
- `order_driver_assignments` : Assignations livreur-commande

### Champs Requis
- `orders.delivery_lat` et `orders.delivery_lng` : Coordonnées de livraison
- `drivers.current_lat` et `drivers.current_lng` : Position actuelle du livreur

## Algorithme de Calcul

```typescript
// 1. Calculer la distance
const distance = calculateDistance(driverLat, driverLng, deliveryLat, deliveryLng);

// 2. Estimer le temps total
const travelTime = (distance / 25) * 60; // Conversion en minutes
const totalTime = travelTime + 10 + 5; // + préparation + livraison

// 3. Calculer l'heure d'arrivée
const arrivalTime = new Date(now + totalTime * 60000);
```

## Avantages

1. **Précision** : Calcul basé sur la distance réelle, pas sur des estimations fixes
2. **Temps réel** : Mise à jour automatique selon la position du livreur
3. **Flexibilité** : S'adapte aux conditions de circulation urbaine
4. **Transparence** : Affichage clair de l'estimation pour l'admin

## Configuration

Les paramètres d'estimation peuvent être ajustés dans `src/utils/deliveryEstimation.ts` :
- Vitesse moyenne (actuellement 25 km/h)
- Temps de préparation (actuellement 10 min)
- Temps de livraison (actuellement 5 min)

## Limitations

1. Ne prend pas en compte les conditions de circulation en temps réel
2. Estimation basée sur une vitesse moyenne constante
3. Ne considère pas les embouteillages ou événements spéciaux
4. Requiert des coordonnées GPS valides pour fonctionner





