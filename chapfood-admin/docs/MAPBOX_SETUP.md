# Configuration Mapbox - Guide d'installation

## Prérequis

### 1. Compte Mapbox
- Créez un compte sur [mapbox.com](https://www.mapbox.com/)
- Obtenez votre clé API publique (Access Token)
- Configurez les restrictions de domaine si nécessaire

### 2. Installation des dépendances
```bash
npm install mapbox-gl react-map-gl
```

### 3. Configuration de la clé API
La clé API Mapbox est configurée dans `src/config/mapbox.ts` :

```typescript
export const MAPBOX_CONFIG = {
  ACCESS_TOKEN: 'pk.eyJ1IjoiYW5nZXdhcnJlbjEyMiIsImEiOiJjbWN0MGY2eTEwMDNhMmpzamF0OHc5YWt2In0.IY84028ftDyxRM8j_1AaHA',
  // ... autres configurations
};
```

## Structure des fichiers

```
src/
├── components/admin/
│   ├── LiveDeliveryMap.tsx      # Composant principal de la carte
│   └── LiveDeliveryTracking.tsx # Page de suivi des livraisons
├── config/
│   └── mapbox.ts                # Configuration Mapbox
└── types/
    └── mapbox.d.ts              # Types TypeScript pour react-map-gl
```

## Fonctionnalités implémentées

### ✅ Composants créés
1. **LiveDeliveryMap** - Carte interactive avec suivi en temps réel
2. **Bouton de suivi** - Ajouté sur chaque carte de commande
3. **Configuration centralisée** - Gestion des styles et tokens
4. **Types TypeScript** - Définitions pour react-map-gl

### ✅ Fonctionnalités
- **Carte interactive** avec Mapbox GL JS
- **Marqueurs personnalisés** pour livreur et livraison
- **Popups informatifs** avec détails
- **Mode plein écran** optimisé
- **Calcul de distance** entre livreur et livraison
- **Interface responsive** adaptée mobile/desktop

## Utilisation

### 1. Accès à la fonctionnalité
1. Allez dans `/admin/live-tracking`
2. Trouvez une commande avec un livreur assigné
3. Cliquez sur "Suivi en temps réel"

### 2. Navigation sur la carte
- **Zoom** : Molette de la souris
- **Déplacement** : Clic et glisser
- **Marqueurs** : Clic pour voir les détails
- **Plein écran** : Bouton en haut à droite

### 3. Informations affichées
- Position du livreur (marqueur bleu)
- Point de livraison (marqueur vert)
- Distance calculée automatiquement
- Détails du livreur et de la commande

## Configuration avancée

### Styles de carte
Modifiez le style dans `src/config/mapbox.ts` :

```typescript
MAP_STYLES: {
  STREETS: 'mapbox://styles/mapbox/streets-v12',
  OUTDOORS: 'mapbox://styles/mapbox/outdoors-v12',
  LIGHT: 'mapbox://styles/mapbox/light-v11',
  DARK: 'mapbox://styles/mapbox/dark-v11',
  SATELLITE: 'mapbox://styles/mapbox/satellite-v9'
}
```

### Marqueurs personnalisés
Personnalisez l'apparence des marqueurs :

```typescript
MARKERS: {
  DRIVER: {
    color: '#2563eb', // Couleur du livreur
    size: 48          // Taille en pixels
  },
  DELIVERY: {
    color: '#16a34a', // Couleur de la livraison
    size: 48
  }
}
```

## Données nécessaires

### Table `drivers`
```sql
current_lat DECIMAL(10,8) NOT NULL,
current_lng DECIMAL(11,8) NOT NULL
```

### Table `orders`
```sql
delivery_lat DECIMAL(10,8),
delivery_lng DECIMAL(11,8)
```

## Dépannage

### Problèmes courants

1. **Carte ne se charge pas**
   - Vérifiez la clé API Mapbox
   - Vérifiez la connexion internet
   - Vérifiez les restrictions de domaine

2. **Marqueurs manquants**
   - Vérifiez les coordonnées GPS dans la base de données
   - Vérifiez que les données sont valides (latitude: -90 à 90, longitude: -180 à 180)

3. **Erreurs TypeScript**
   - Vérifiez que `react-map-gl` est installé
   - Vérifiez les types dans `src/types/mapbox.d.ts`

4. **Performance lente**
   - Réduisez la fréquence d'actualisation
   - Limitez le nombre de marqueurs affichés
   - Utilisez des styles de carte plus légers

### Logs utiles
```javascript
// Dans la console du navigateur
console.log('Mapbox token:', MAPBOX_CONFIG.ACCESS_TOKEN);
console.log('Driver location:', driverLocation);
console.log('Delivery location:', deliveryLocation);
```

## Sécurité

### Clé API Mapbox
- La clé API est **publique** et peut être exposée côté client
- Configurez les restrictions de domaine dans votre compte Mapbox
- Surveillez l'utilisation via le dashboard Mapbox

### Données sensibles
- Les coordonnées GPS sont considérées comme sensibles
- Respectez le RGPD pour le stockage des positions
- Implémentez des politiques de rétention des données

## Coûts

### Mapbox
- **Gratuit** : 50,000 requêtes/mois
- **Payant** : $0.50 pour 1,000 requêtes supplémentaires
- **Monitoring** : Surveillez l'usage via le dashboard

### Optimisations
- Cachez les tiles de carte
- Limitez les actualisations automatiques
- Utilisez des styles de carte légers

## Support

### Documentation
- [Mapbox GL JS](https://docs.mapbox.com/mapbox-gl-js/)
- [React Map GL](https://visgl.github.io/react-map-gl/)
- [Mapbox Styles](https://docs.mapbox.com/api/maps/styles/)

### Communauté
- [Mapbox Community](https://community.mapbox.com/)
- [GitHub Issues](https://github.com/visgl/react-map-gl/issues)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/mapbox-gl-js)






