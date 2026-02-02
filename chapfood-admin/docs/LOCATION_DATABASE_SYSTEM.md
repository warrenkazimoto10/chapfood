# Système de Base de Données des Locations - Grand-Bassam

## Vue d'ensemble

Système complet de géolocalisation pour Grand-Bassam avec base de données des quartiers, zones et points de repère, optimisé pour les livraisons et la recherche d'adresses.

## Base de Données

### Tables Principales

#### 1. **`delivery_locations`** - Quartiers et Zones
```sql
- id (UUID, PRIMARY KEY)
- name (TEXT) : Nom du quartier/zone
- district (TEXT) : District (Centre, Nord, Sud, Est, Ouest, Périphérie)
- zone_type (ENUM) : Type de zone
- latitude/longitude (REAL) : Coordonnées GPS précises
- postal_code (TEXT) : Code postal optionnel
- delivery_fee (REAL) : Frais de livraison en FCFA
- estimated_delivery_time (INTEGER) : Temps estimé en minutes
- is_active (BOOLEAN) : Zone active/inactive
- description (TEXT) : Description de la zone
```

#### 2. **`landmarks`** - Points de Repère
```sql
- id (UUID, PRIMARY KEY)
- name (TEXT) : Nom du point de repère
- landmark_type (ENUM) : Type de landmark
- address (TEXT) : Adresse détaillée
- latitude/longitude (REAL) : Coordonnées GPS
- delivery_location_id (UUID) : Référence vers delivery_locations
- is_active (BOOLEAN) : Landmark actif/inactif
- description (TEXT) : Description du landmark
```

#### 3. **`delivery_zones`** - Zones de Livraison
```sql
- id (UUID, PRIMARY KEY)
- name (TEXT) : Nom de la zone
- base_fee (REAL) : Frais de base en FCFA
- max_distance_km (REAL) : Distance maximale couverte
- estimated_time_minutes (INTEGER) : Temps estimé
- color_code (TEXT) : Couleur pour l'affichage
- is_active (BOOLEAN) : Zone active/inactive
```

#### 4. **`location_delivery_zones`** - Liaison
```sql
- location_id (UUID) : Référence vers delivery_locations
- zone_id (UUID) : Référence vers delivery_zones
- PRIMARY KEY (location_id, zone_id)
```

## Données de Grand-Bassam

### Districts et Zones

#### **Centre** (Frais : 0 FCFA, Temps : 10-15 min)
- **Quartier France** : Zone historique UNESCO
- **Quartier Impérial** : Zone résidentielle et administrative
- **Quartier Petit-Paris** : Zone résidentielle avec ancien phare
- **Marché Central** : Zone commerciale principale
- **Zone Hôtelière** : Hôtels et résidences touristiques
- **Zone Administrative** : Administrations publiques

#### **Nord** (Frais : 500 FCFA, Temps : 20-22 min)
- **Quartier Résidentiel Nord** : Zone résidentielle moderne
- **Cité des Fonctionnaires** : Résidences pour fonctionnaires
- **Zone HLM** : Habitations à loyer modéré
- **Nouveau Quartier Nord** : Extensions récentes
- **Cité Moderne** : Villas modernes

#### **Sud** (Frais : 500-800 FCFA, Temps : 18-25 min)
- **Quartier Résidentiel Sud** : Zone résidentielle
- **Cité Universitaire** : Zone étudiante
- **Village Artisanal** : Zone des artisans
- **Extension Sud** : Extensions résidentielles
- **Zone Résidentielle Moderne** : Résidences modernes

#### **Est** (Frais : 1000 FCFA, Temps : 25 min)
- **Quartier Industriel** : Zone industrielle et portuaire
- **Zone Portuaire** : Port de Grand-Bassam
- **Quartier des Pêcheurs** : Village de pêcheurs traditionnel

#### **Ouest** (Frais : 1000 FCFA, Temps : 30 min)
- **Quartier Ouest** : Zone résidentielle
- **Zone Agricole Ouest** : Zone agricole et résidentielle

#### **Périphérie** (Frais : 1500 FCFA, Temps : 35-45 min)
- **Village d'Assinie** : Village côtier à l'est
- **Village de Bonoua** : Village au nord
- **Village d'Adiaké** : Village à l'ouest

### Points de Repère Importants

#### **Hôtels**
- Hotel Etoile du Sud (Quartier France)
- Hotel Ivoire (Zone Hôtelière)
- Hotel Les Cocotiers (Quartier Petit-Paris)

#### **Restaurants**
- Restaurant Le Phare (Quartier Petit-Paris)
- Restaurant Le Colonial (Quartier France)
- Maquis Chez Tonton (Marché Central)

#### **Banques**
- Banque Atlantique (Zone Administrative)
- SGBCI (Avenue de la République)
- Banque Populaire (Rue du Commerce)

#### **Écoles**
- École Primaire Publique (Rue des Écoles)
- Lycée Moderne (Quartier Impérial)
- École Privée Les Palmiers (Zone Résidentielle Sud)

#### **Lieux de Culte**
- Église Notre-Dame (Quartier France)
- Mosquée Centrale (Quartier Impérial)
- Temple Protestant (Rue du Commerce)

## Fonctions de Base de Données

### 1. **`calculate_distance_km`**
```sql
-- Calcule la distance entre deux points GPS en kilomètres
SELECT calculate_distance_km(5.2091, -3.7386, 5.2150, -3.7400);
-- Résultat: 0.7 km
```

### 2. **`find_nearest_locations`**
```sql
-- Trouve les locations les plus proches d'un point
SELECT * FROM find_nearest_locations(5.2091, -3.7386, 5, 10);
-- Retourne les 10 locations les plus proches dans un rayon de 5km
```

### 3. **`get_delivery_fee`**
```sql
-- Calcule les frais de livraison pour une position
SELECT * FROM get_delivery_fee(5.2091, -3.7386);
-- Retourne la zone, les frais, le temps et la distance
```

## Services TypeScript

### `LocationService`

#### **Recherche**
```typescript
// Recherche par nom avec autocomplétion
const locations = await locationService.searchLocations('France', 10);

// Recherche par district
const centreLocations = await locationService.getLocationsByDistrict('Centre');

// Recherche par type de zone
const residential = await locationService.getLocationsByType('zone_residentielle');

// Recherche intelligente combinée
const results = await locationService.smartSearch('hotel', 15);
```

#### **Géolocalisation**
```typescript
// Trouver les locations proches
const nearest = await locationService.findNearestLocations(5.2091, -3.7386, 5, 10);

// Calculer les frais de livraison
const fee = await locationService.getDeliveryFee(5.2091, -3.7386);

// Calculer la distance entre deux points
const distance = locationService.calculateDistance(lat1, lon1, lat2, lon2);
```

#### **Validation**
```typescript
// Valider des coordonnées GPS
const isValid = locationService.isValidGPSCoordinates(5.2091, -3.7386);

// Formater une adresse
const address = locationService.formatAddress(location, landmark);
```

## Composants React

### 1. **`LocationSearch`** - Recherche avec Autocomplétion

#### Fonctionnalités
- **Recherche en temps réel** avec debounce (300ms)
- **Autocomplétion** des quartiers et landmarks
- **Navigation clavier** (flèches, Entrée, Échap)
- **Icônes contextuelles** selon le type de location
- **Informations détaillées** (frais, temps, distance)
- **Groupement intelligent** (quartiers vs landmarks)

#### Interface
```typescript
<LocationSearch
  onLocationSelected={(location) => {
    // location: { name, address, latitude, longitude, delivery_fee, estimated_time }
  }}
  selectedLocation={currentLocation}
  className="w-full"
/>
```

### 2. **`DeliveryLocationPicker`** - Sélection GPS avec Carte

#### Fonctionnalités
- **Carte interactive** Mapbox intégrée
- **Recherche d'adresse** avec autocomplétion
- **Sélection par clic** sur la carte
- **Marqueur draggable** pour ajustement précis
- **Calcul automatique** des frais et temps
- **Validation GPS** (zone de livraison)
- **Interface responsive** pour tablettes

#### Interface
```typescript
<DeliveryLocationPicker
  onLocationConfirmed={(location) => {
    // location: { name, address, latitude, longitude, delivery_fee, estimated_time }
  }}
  onCancel={() => {}}
  className="w-full"
/>
```

## Types de Zones

### Zone Types
- **`quartier`** : Quartier résidentiel ou commercial
- **`zone_commerciale`** : Zone commerciale et marchés
- **`zone_residentielle`** : Zone résidentielle pure
- **`zone_industrielle`** : Zone industrielle et portuaire
- **`village`** : Village ou zone rurale
- **`lieu_public`** : Lieux publics et espaces communs

### Landmark Types
- **`hotel`** : Hôtels et hébergements
- **`restaurant`** : Restaurants et maquis
- **`banque`** : Banques et institutions financières
- **`pharmacie`** : Pharmacies et santé
- **`hopital`** : Hôpitaux et centres de santé
- **`ecole`** : Écoles et établissements éducatifs
- **`eglise`** : Églises et lieux de culte chrétiens
- **`mosquee`** : Mosquées et lieux de culte musulmans
- **`marche`** : Marchés et commerces
- **`station_service`** : Stations-service et carburants
- **`bureau`** : Bureaux et administrations
- **`autre`** : Autres points de repère

## Tarification par Zone

### Zones de Livraison
1. **Centre Ville** (0 FCFA, 15 min, 3km max)
   - Quartier France, Impérial, Petit-Paris
   - Marché Central, Zone Hôtelière
   - Zone Administrative

2. **Zone Proche** (500 FCFA, 20 min, 5km max)
   - Quartiers résidentiels Nord/Sud
   - Extensions récentes
   - Cités et HLM

3. **Zone Moyenne** (1000 FCFA, 30 min, 8km max)
   - Quartier Industriel
   - Zone Portuaire
   - Quartier des Pêcheurs

4. **Zone Éloignée** (1500 FCFA, 45 min, 12km max)
   - Villages périphériques
   - Assinie, Bonoua, Adiaké
   - Zones rurales

## Intégration avec le Système de Caisse

### Flux de Sélection d'Adresse
1. **Recherche** : L'utilisateur tape une adresse
2. **Autocomplétion** : Suggestions en temps réel
3. **Sélection** : Choix dans la liste ou clic sur carte
4. **Validation** : Vérification GPS et calcul des frais
5. **Confirmation** : Enregistrement avec coordonnées précises

### Avantages
- **Précision** : Coordonnées GPS exactes
- **Rapidité** : Recherche instantanée
- **Fiabilité** : Base de données locale
- **Flexibilité** : Mise à jour facile des zones
- **Traçabilité** : Historique des livraisons par zone

## Maintenance et Mise à Jour

### Ajout de Nouvelles Zones
```sql
-- Ajouter un nouveau quartier
INSERT INTO delivery_locations (name, district, zone_type, latitude, longitude, delivery_fee, estimated_delivery_time)
VALUES ('Nouveau Quartier', 'Nord', 'quartier', 5.2200, -3.7500, 500, 20);

-- Lier à une zone de livraison
INSERT INTO location_delivery_zones (location_id, zone_id)
VALUES (location_uuid, '22222222-2222-2222-2222-222222222222');
```

### Ajout de Landmarks
```sql
-- Ajouter un nouveau point de repère
INSERT INTO landmarks (name, landmark_type, address, latitude, longitude, delivery_location_id)
VALUES ('Nouveau Restaurant', 'restaurant', '123 Rue Nouvelle', 5.2091, -3.7386, location_uuid);
```

### Mise à Jour des Tarifs
```sql
-- Modifier les frais d'une zone
UPDATE delivery_zones 
SET base_fee = 750, estimated_time_minutes = 25
WHERE name = 'Zone Proche';
```

## Statistiques et Analytics

### Métriques Disponibles
- **Nombre total de locations** par district
- **Nombre de landmarks** par type
- **Zones les plus demandées**
- **Distances moyennes de livraison**
- **Temps de livraison moyens**
- **Répartition des frais par zone**

### Requêtes d'Analyse
```sql
-- Statistiques par district
SELECT district, COUNT(*) as locations_count, AVG(delivery_fee) as avg_fee
FROM delivery_locations 
WHERE is_active = true 
GROUP BY district;

-- Landmarks par type
SELECT landmark_type, COUNT(*) as count
FROM landmarks 
WHERE is_active = true 
GROUP BY landmark_type;
```

Ce système de géolocalisation offre une base solide pour optimiser les livraisons et améliorer l'expérience utilisateur dans Grand-Bassam ! 🗺️✨📍




