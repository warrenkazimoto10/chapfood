# Suivi en Temps Réel avec Mapbox

## Vue d'ensemble

La fonctionnalité de suivi en temps réel permet aux administrateurs de visualiser la position exacte des livreurs sur une carte interactive Mapbox, en temps réel et en plein écran.

## Fonctionnalités

### 🗺️ Carte interactive Mapbox
- **Visualisation en temps réel** : Position actuelle du livreur et point de livraison
- **Marqueurs personnalisés** : Icônes distinctes pour le livreur (camion bleu) et la livraison (pin vert)
- **Popups informatifs** : Détails du livreur et du point de livraison au clic
- **Calcul de distance** : Distance en kilomètres entre le livreur et la livraison

### 📱 Interface optimisée
- **Mode plein écran** : Affichage optimisé pour surveillance continue
- **Panneau d'informations** : Détails complets de la commande et du livreur
- **Contrôles intuitifs** : Boutons d'actualisation, plein écran et fermeture
- **Design responsive** : Adaptation à tous les types d'écrans

### ⚡ Temps réel
- **Actualisation automatique** : Position mise à jour en continu
- **Timestamp de dernière position** : Horodatage de la dernière localisation
- **Indicateur de statut** : Distance et temps estimé de livraison

## Utilisation

### Accéder au suivi en temps réel
1. Allez dans "Suivi des Livraisons" (`/admin/live-tracking`)
2. Trouvez une commande avec un livreur assigné et des coordonnées GPS
3. Cliquez sur le bouton "Suivi en temps réel" (icône carte) sur la carte de la commande
4. La carte s'ouvre en mode overlay avec la position du livreur et du point de livraison

### Navigation sur la carte
- **Zoom** : Utilisez la molette de la souris ou les boutons +/-
- **Déplacement** : Cliquez et glissez pour déplacer la vue
- **Marqueurs** : Cliquez sur les marqueurs pour voir les informations détaillées
- **Plein écran** : Cliquez sur l'icône plein écran pour un affichage optimisé

### Informations affichées

#### Panneau du livreur
- **Nom et photo** : Identité du livreur avec initiales
- **Contact** : Numéro de téléphone
- **Position** : Coordonnées GPS actuelles
- **Dernière mise à jour** : Timestamp de la dernière position

#### Panneau de la commande
- **Informations client** : Nom, téléphone, adresse
- **Détails de livraison** : Heure prévue, montant total
- **Statut** : Badge de statut de la livraison

#### Calculs automatiques
- **Distance** : Distance en kilomètres entre livreur et livraison
- **Temps estimé** : Estimation basée sur la distance et vitesse moyenne

## Configuration technique

### Clé API Mapbox
La clé API Mapbox est configurée dans le composant :
```typescript
const MAPBOX_TOKEN = 'pk.eyJ1IjoiYW5nZXdhcnJlbjEyMiIsImEiOiJjbWN0MGY2eTEwMDNhMmpzamF0OHc5YWt2In0.IY84028ftDyxRM8j_1AaHA';
```

### Prérequis
- **Coordonnées GPS** : Le livreur doit avoir des coordonnées `current_lat` et `current_lng`
- **Adresse de livraison** : La commande doit avoir des coordonnées `delivery_lat` et `delivery_lng`
- **Livreur assigné** : Un livreur doit être assigné à la commande

### Données nécessaires
```sql
-- Table drivers
current_lat DECIMAL(10,8)
current_lng DECIMAL(11,8)

-- Table orders  
delivery_lat DECIMAL(10,8)
delivery_lng DECIMAL(11,8)
```

## Interface utilisateur

### Bouton de suivi
- **Condition d'affichage** : Seulement si un livreur est assigné ET a des coordonnées GPS
- **Design** : Bouton bleu avec icône de carte
- **Texte** : "Suivi en temps réel"

### Carte en overlay
- **Position** : Overlay en plein écran par-dessus l'interface
- **Header** : Titre, timestamp et boutons de contrôle
- **Carte** : Zone principale avec la carte Mapbox
- **Panneau latéral** : Informations détaillées (sauf en mode plein écran)

### Contrôles
- **Actualiser** : Force la mise à jour des positions
- **Plein écran** : Passe en mode plein écran optimisé
- **Fermer** : Retour à la vue principale

## Optimisations

### Performance
- **Rendu optimisé** : Utilisation de `react-map-gl` pour de meilleures performances
- **Marqueurs légers** : Icônes SVG personnalisées
- **Calculs efficaces** : Formule de Haversine pour la distance

### UX/UI
- **Design cohérent** : Style uniforme avec le reste de l'application
- **Animations fluides** : Transitions et animations CSS
- **Responsive** : Adaptation mobile et desktop

### Sécurité
- **Token sécurisé** : Clé API Mapbox intégrée côté client (publique)
- **Validation des données** : Vérification des coordonnées avant affichage
- **Gestion d'erreurs** : Fallbacks en cas de problème de chargement

## Cas d'usage

### Surveillance opérationnelle
- **Salle de contrôle** : Affichage permanent sur écrans dédiés
- **Suivi de performance** : Surveillance des temps de livraison
- **Optimisation des routes** : Visualisation des déplacements

### Support client
- **Informations précises** : Position exacte du livreur
- **Temps d'arrivée** : Estimation basée sur la distance
- **Communication** : Coordonnées pour contacter le livreur

### Gestion d'équipe
- **Répartition des tâches** : Vue d'ensemble des livraisons actives
- **Supervision** : Surveillance des livreurs en temps réel
- **Planification** : Optimisation des assignations futures

## Développement futur

### Fonctionnalités avancées
- **Itinéraires** : Affichage du trajet prévu du livreur
- **Trafic en temps réel** : Intégration des données de trafic
- **Notifications** : Alertes automatiques pour les retards
- **Historique** : Archive des trajets de livraison

### Intégrations
- **GPS mobile** : Suivi automatique via l'application livreur
- **API de trafic** : Données de circulation en temps réel
- **Notifications push** : Alertes instantanées
- **Analytics** : Métriques de performance des livraisons

## Dépannage

### Problèmes courants
1. **Carte ne se charge pas** : Vérifier la clé API Mapbox
2. **Marqueurs manquants** : Vérifier les coordonnées GPS
3. **Performance lente** : Réduire la fréquence d'actualisation
4. **Erreurs de géolocalisation** : Vérifier la validité des coordonnées

### Vérifications
- Clé API Mapbox valide et active
- Coordonnées GPS dans le bon format (décimal)
- Connexion internet stable
- Navigateur compatible (Chrome, Firefox, Safari, Edge)






