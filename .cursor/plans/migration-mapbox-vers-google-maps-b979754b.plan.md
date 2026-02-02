---
name: Amélioration suivi livraison style Uber/Glovo/Yango
overview: ""
todos: []
---

# Amélioration suivi livraison style Uber/Glovo/Yango

## Objectifs

1. Remplacer les lignes rectilignes par des routes réelles utilisant Google Directions API
2. Créer un design professionnel style Uber/Glovo avec animations fluides
3. Synchroniser le suivi en temps réel entre app client et app livreur
4. Améliorer l'UI/UX avec des cards modernes, animations et indicateurs de progression

## Problèmes identifiés

- Les polylines sont rectilignes au lieu de suivre les routes réelles
- Le design actuel n'est pas assez professionnel
- Le suivi n'est pas parfaitement synchronisé entre client et livreur
- Manque d'animations et de feedback visuel

## Fichiers à modifier

### 1. `chapfood_driver/lib/services/google_maps_routing_service.dart`

- Améliorer `getRoute()` pour utiliser `alternatives=true` et obtenir plusieurs options
- Ajouter un paramètre pour forcer un recalcul avec plus de points intermédiaires
- Utiliser `overview_polyline` avec `overview=full` pour obtenir tous les points de la route
- Ajouter une méthode `getDetailedRoute()` qui retourne une route avec plus de détails

### 2. `chapfood_driver/lib/screens/active_delivery_screen.dart`

- Améliorer `_drawRouteToRestaurant()` et `_drawRouteToClient()` pour utiliser des routes détaillées
- Ajouter une mise à jour automatique de la route toutes les 30 secondes ou quand le livreur s'écarte
- Améliorer le design avec :
- Card de statut en haut avec progression animée
- Card d'informations livreur/client en bas
- Animations de transition entre les étapes
- Indicateur de distance et ETA en temps réel
- Ajouter un mode navigation avec instructions vocales (optionnel)

### 3. `chapfood_app/lib/widgets/realtime_map_widget.dart`

- Migrer de Mapbox vers Google Maps (remplacer `mapbox_maps_flutter` par `google_maps_flutter`)
- Améliorer le calcul de route pour utiliser Google Directions API
- Créer un design style Uber avec :
- Header avec photo et nom du livreur
- Card d'informations en bas avec ETA, distance, statut
- Animation de la route qui se dessine progressivement
- Marqueur livreur animé qui suit la route
- Indicateur de progression de livraison
- Synchroniser avec le livreur via Supabase Realtime

### 4. Créer `chapfood_driver/lib/widgets/delivery/route_progress_card.dart` (nouveau)

- Widget pour afficher la progression de la livraison
- Barre de progression animée
- Distance restante et ETA
- Étape actuelle (vers restaurant / vers client)

### 5. Créer `chapfood_app/lib/widgets/delivery/driver_info_card.dart` (nouveau)

- Widget pour afficher les infos du livreur (style Uber)
- Photo, nom, note, véhicule
- Bouton d'appel
- Statut en temps réel

### 6. Créer `chapfood_driver/lib/widgets/delivery/navigation_card.dart` (nouveau)

- Widget pour afficher les instructions de navigation
- Prochaine instruction (tourner à gauche, droite, etc.)
- Distance jusqu'à la prochaine instruction
- Design moderne avec icônes

### 7. Améliorer `chapfood_driver/lib/services/google_maps_routing_service.dart`

- Ajouter support pour `waypoints` pour routes complexes
- Ajouter support pour `optimize:true` pour optimiser l'ordre des waypoints
- Ajouter méthode `getRouteWithSteps()` pour obtenir les instructions détaillées
- Améliorer le décodage de polyline pour obtenir plus de points intermédiaires

### 8. Créer `chapfood_driver/lib/services/route_optimization_service.dart` (nouveau)

- Service pour optimiser les routes
- Recalcul automatique si le livreur s'écarte de la route
- Mise à jour de la route en temps réel

### 9. Améliorer la synchronisation temps réel

- Utiliser Supabase Realtime pour synchroniser la position du livreur
- Mettre à jour la route côté client quand le livreur change de direction
- Animer le marqueur livreur de manière fluide

### 10. Design improvements

- Cards avec ombres et bordures arrondies
- Animations de transition fluides
- Couleurs cohérentes (bleu pour livreur, vert pour client, orange pour restaurant)
- Typographie moderne et lisible
- Indicateurs visuels clairs (icônes, badges, progress bars)

## Détails techniques

### Routes réelles (pas rectilignes)

- Utiliser `overview_polyline` avec `overview=full` dans Google Directions API
- Décoder la polyline avec `flutter_polyline_points` pour obtenir tous les points
- Dessiner la polyline avec `Polyline` de `google_maps_flutter` avec `geodesic: true`
- Mettre à jour la route périodiquement (toutes les 30 secondes ou quand le livreur s'écarte)

### Design style Uber/Glovo

- Header avec gradient et informations livreur
- Card en bas avec informations de livraison
- Animations de transition entre les étapes
- Marqueurs personnalisés avec animations
- Indicateurs de progression visuels

### Synchronisation temps réel

- Utiliser Supabase Realtime pour écouter les changements de position du livreur
- Mettre à jour la carte côté client en temps réel
- Recalculer la route si nécessaire