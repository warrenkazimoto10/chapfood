# Système de Gestion de Caisse - Commandes Manuelles

## Vue d'ensemble

Système de caisse moderne pour gérer les commandes manuelles (WhatsApp, téléphone, etc.) avec une interface visuelle similaire à une caisse enregistreuse de restaurant ou supermarché.

## Fonctionnalités Principales

### 1. **Gestion des Clients**
- **Recherche de clients existants** par nom, téléphone, email
- **Création de nouveaux clients** avec informations complètes
- **Mot de passe par défaut** : `123456789` pour tous les nouveaux clients
- **Informations client** : nom, téléphone, email, adresse par défaut

### 2. **Interface de Commande Manuelle**
- **Sélection de plats** depuis le menu disponible
- **Gestion des garnitures** et suppléments
- **Calcul automatique des prix** avec taxes et frais
- **Interface tactile** optimisée pour tablettes

### 3. **Types de Commande**
- **Livraison** : Sélection GPS obligatoire, frais de livraison
- **À emporter** : Pas de frais de livraison, pas de GPS requis

### 4. **Sélection de Position (Livraison)**
- **Carte interactive** pour sélectionner l'adresse de livraison
- **Recherche d'adresse** avec autocomplétion
- **Coordonnées GPS** automatiques
- **Calcul de distance** et estimation des frais

### 5. **Tableau de Bord de Caisse**
- **Interface moderne** style caisse enregistreuse
- **Navigation intuitive** avec boutons larges
- **Historique des commandes** du jour
- **Statistiques en temps réel**

## Structure de l'Interface

### Écran Principal - Dashboard Caisse
```
┌─────────────────────────────────────────────────────────┐
│  🏪 CHAPFOOD - CAISSE ENREGISTREUSE                    │
├─────────────────────────────────────────────────────────┤
│  [🔍 RECHERCHER CLIENT] [➕ NOUVEAU CLIENT]             │
│                                                         │
│  👤 CLIENT: [Nom du client ou "Nouveau client"]        │
│  📱 TÉLÉPHONE: [Numéro de téléphone]                   │
├─────────────────────────────────────────────────────────┤
│  📋 MENU DISPONIBLE                                     │
│  ┌─────────┬─────────┬─────────┬─────────┐              │
│  │ 🍕 PIZZA│ 🍔 BURGER│ 🍜 SOUP │ 🥗 SALAD│              │
│  │         │         │         │         │              │
│  │ 15,990 FCFA  │ 12,500 FCFA  │  8,990 FCFA  │ 11,990 FCFA  │              │
│  └─────────┴─────────┴─────────┴─────────┘              │
│                                                         │
│  🛒 PANIER (3 articles) - Total: 47,480 FCFA                │
│  ┌─────────────────────────────────────────────────────┐ │
│  │ 2x Pizza Margherita + Extra fromage       31,980 FCFA   │ │
│  │ 1x Burger Classic + Frites                15,500 FCFA   │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                         │
│  [🚚 LIVRAISON] [📦 À EMPORTER] [💳 FINALISER]         │
└─────────────────────────────────────────────────────────┘
```

### Interface de Sélection GPS (Livraison)
```
┌─────────────────────────────────────────────────────────┐
│  📍 SÉLECTION ADRESSE DE LIVRAISON                     │
├─────────────────────────────────────────────────────────┤
│  🔍 Rechercher une adresse...                          │
│  ┌─────────────────────────────────────────────────────┐ │
│  │ 📍 123 Rue de la Paix, Bassam, Côte d'Ivoire       │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                         │
│  🗺️  CARTE INTERACTIVE                                  │
│  ┌─────────────────────────────────────────────────────┐ │
│  │                                                     │ │
│  │              [📍 MARQUEUR]                          │ │
│  │                                                     │ │
│  │                                                     │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                         │
│  📏 Distance: 2.5 km - ⏱️ Temps: 8 min                 │
│  💰 Frais de livraison: 3,000 FCFA                          │
│                                                         │
│  [✅ CONFIRMER ADRESSE] [❌ ANNULER]                    │
└─────────────────────────────────────────────────────────┘
```

## Architecture Technique

### 1. **Nouveaux Composants**
- `CashierDashboard.tsx` - Tableau de bord principal
- `ClientSearch.tsx` - Recherche/création de clients
- `ManualOrderInterface.tsx` - Interface de commande
- `MenuSelection.tsx` - Sélection des plats
- `GarnishSelection.tsx` - Gestion des garnitures
- `DeliveryLocationPicker.tsx` - Sélection GPS
- `OrderSummary.tsx` - Récapitulatif et finalisation

### 2. **Pages Principales**
- `src/pages/admin/Cashier.tsx` - Page principale de caisse
- `src/pages/admin/CashierOrders.tsx` - Historique des commandes

### 3. **Services**
- `src/services/cashierService.ts` - Logique métier de caisse
- `src/services/clientService.ts` - Gestion des clients
- `src/utils/orderCalculator.ts` - Calculs de prix

## Base de Données

### Nouvelles Tables/Colonnes

#### Table `users` (Extension)
```sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS created_by_admin BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS default_password BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN DEFAULT false;
```

#### Table `manual_orders` (Nouvelle)
```sql
CREATE TABLE manual_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES users(id),
  client_name TEXT NOT NULL,
  client_phone TEXT NOT NULL,
  order_items JSONB NOT NULL,
  delivery_type TEXT CHECK (delivery_type IN ('delivery', 'pickup')),
  delivery_address TEXT,
  delivery_lat REAL,
  delivery_lng REAL,
  subtotal REAL NOT NULL,
  delivery_fee REAL DEFAULT 0,
  total REAL NOT NULL,
  status order_status DEFAULT 'pending',
  created_by_admin UUID REFERENCES admin_users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Table `cashier_sessions` (Nouvelle)
```sql
CREATE TABLE cashier_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID REFERENCES admin_users(id),
  started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  ended_at TIMESTAMP WITH TIME ZONE,
  total_orders INTEGER DEFAULT 0,
  total_revenue REAL DEFAULT 0,
  is_active BOOLEAN DEFAULT true
);
```

## Flux de Travail

### 1. **Ouverture de Session Caisse**
```typescript
const startCashierSession = async () => {
  const session = await supabase
    .from('cashier_sessions')
    .insert({
      admin_id: currentAdmin.id,
      started_at: new Date().toISOString()
    });
};
```

### 2. **Recherche/Création Client**
```typescript
const findOrCreateClient = async (phone: string, name?: string) => {
  // Rechercher client existant
  let client = await supabase
    .from('users')
    .select('*')
    .eq('phone', phone)
    .single();

  // Créer si inexistant
  if (!client) {
    client = await supabase
      .from('users')
      .insert({
        phone,
        name: name || 'Client WhatsApp',
        password_hash: await hashPassword('123456789'),
        created_by_admin: true,
        default_password: true
      });
  }

  return client;
};
```

### 3. **Création Commande Manuelle**
```typescript
const createManualOrder = async (orderData: ManualOrderData) => {
  const order = await supabase
    .from('manual_orders')
    .insert({
      client_id: orderData.clientId,
      client_name: orderData.clientName,
      client_phone: orderData.clientPhone,
      order_items: orderData.items,
      delivery_type: orderData.deliveryType,
      delivery_address: orderData.deliveryAddress,
      delivery_lat: orderData.deliveryLat,
      delivery_lng: orderData.deliveryLng,
      subtotal: orderData.subtotal,
      delivery_fee: orderData.deliveryFee,
      total: orderData.total,
      created_by_admin: currentAdmin.id
    });

  // Intégrer avec le système existant
  await integrateWithExistingOrderSystem(order);
};
```

## Interface Utilisateur

### Design Style Caisse Enregistreuse

#### Couleurs et Thème
- **Fond principal** : Blanc/gris clair
- **Boutons** : Couleurs vives (vert, bleu, orange, rouge)
- **Textes** : Noir sur fond clair
- **Bordures** : Épaisses et contrastées
- **Icônes** : Grandes et claires

#### Typographie
- **Titres** : Police large et bold
- **Prix** : Police monospace pour alignement
- **Boutons** : Police moyenne, facile à lire

#### Layout Responsive
- **Desktop** : Interface large avec sidebar
- **Tablette** : Interface tactile optimisée
- **Mobile** : Mode compact avec navigation

### Composants Visuels

#### Boutons de Menu
```typescript
<Button 
  className="w-48 h-32 text-lg font-bold bg-green-500 hover:bg-green-600 text-white border-4 border-green-700"
>
  <div className="text-center">
    <div className="text-2xl">🍕</div>
    <div>PIZZA</div>
    <div className="text-sm">15,990 FCFA</div>
  </div>
</Button>
```

#### Panier de Commande
```typescript
<Card className="bg-yellow-50 border-4 border-yellow-300">
  <CardHeader>
    <CardTitle className="text-xl font-bold text-center">
      🛒 PANIER ({itemCount} articles)
    </CardTitle>
  </CardHeader>
  <CardContent>
    <div className="space-y-2">
      {items.map(item => (
        <div key={item.id} className="flex justify-between items-center p-2 bg-white rounded border">
          <span className="font-medium">{item.name}</span>
          <span className="font-mono">{item.price.toLocaleString()} FCFA</span>
        </div>
      ))}
    </div>
    <div className="mt-4 p-3 bg-green-100 rounded border-2 border-green-500">
      <div className="text-center">
        <div className="text-lg font-bold">TOTAL: {total.toLocaleString()} FCFA</div>
      </div>
    </div>
  </CardContent>
</Card>
```

## Intégration avec le Système Existant

### 1. **Synchronisation des Commandes**
- Les commandes manuelles sont intégrées dans le système de commandes existant
- Même flux de statuts : pending → accepted → ready_for_delivery → in_transit → delivered
- Même système d'assignation de livreurs

### 2. **Gestion des Stocks**
- Décrémentation automatique des stocks
- Vérification de disponibilité en temps réel
- Alertes si stock insuffisant

### 3. **Notifications**
- Notifications client via WhatsApp/SMS
- Notifications livreur pour les livraisons
- Notifications admin pour les commandes manuelles

## Sécurité et Permissions

### Rôles Admin
- **admin_general** : Accès complet à la caisse
- **cuisine** : Accès limité (lecture des commandes)

### Validation des Données
- Vérification des prix
- Validation des coordonnées GPS
- Contrôle des stocks disponibles
- Vérification des informations client

## Tests et Validation

### Tests Fonctionnels
1. **Création de client** avec mot de passe par défaut
2. **Sélection de plats** et calcul des prix
3. **Gestion des garnitures** et suppléments
4. **Sélection GPS** pour livraisons
5. **Finalisation de commande** et intégration

### Tests d'Interface
1. **Responsive design** sur différentes tailles d'écran
2. **Interface tactile** sur tablettes
3. **Performance** avec de nombreux plats
4. **Accessibilité** pour les utilisateurs

## Métriques et Analytics

### Tableau de Bord Admin
- **Commandes du jour** par type (manuelles vs app)
- **Revenus** générés par la caisse
- **Clients créés** via commandes manuelles
- **Performance** des livreurs pour livraisons manuelles

### Rapports
- **Rapport quotidien** des ventes caisse
- **Rapport mensuel** des commandes manuelles
- **Analyse des clients** WhatsApp vs app

## Déploiement et Maintenance

### Configuration
- Variables d'environnement pour API de géolocalisation
- Configuration des frais de livraison
- Paramètres de mot de passe par défaut

### Monitoring
- Logs des sessions de caisse
- Suivi des erreurs de géolocalisation
- Monitoring des performances

Ce système de caisse moderne permettra de gérer efficacement les commandes WhatsApp tout en maintenant la cohérence avec le système existant ! 🏪✨💳

