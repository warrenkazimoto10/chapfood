# Processus d'Assignation des Commandes aux Livreurs

## Vue d'ensemble

L'assignation d'une commande à un livreur suit un processus structuré impliquant plusieurs tables de la base de données et des règles métier spécifiques.

## Tables Impliquées

### 1. **Table `orders`** - Commandes
```sql
- id (INTEGER, PRIMARY KEY)
- status (order_status ENUM) : pending → accepted → ready_for_delivery → in_transit → delivered
- delivery_type (TEXT) : 'delivery' ou 'pickup'
- delivery_address (TEXT)
- delivery_lat, delivery_lng (REAL)
- user_id (UUID)
- subtotal, delivery_fee (REAL)
- created_at, updated_at (TIMESTAMP)
```

### 2. **Table `drivers`** - Livreurs
```sql
- id (INTEGER, PRIMARY KEY)
- name (TEXT)
- phone (TEXT)
- email (TEXT)
- is_active (BOOLEAN) : true/false
- is_available (BOOLEAN) : true/false
- current_lat, current_lng (REAL) : Position GPS actuelle
- created_at, updated_at (TIMESTAMP)
```

### 3. **Table `order_driver_assignments`** - Assignations
```sql
- id (UUID, PRIMARY KEY)
- order_id (INTEGER, FOREIGN KEY → orders.id)
- driver_id (INTEGER, FOREIGN KEY → drivers.id)
- assigned_at (TIMESTAMP) : Moment de l'assignation
- delivered_at (TIMESTAMP, NULL) : Moment de livraison (NULL si pas encore livré)
```

### 4. **Table `driver_notifications`** - Notifications Livreurs
```sql
- id (UUID, PRIMARY KEY)
- driver_id (INTEGER, FOREIGN KEY → drivers.id)
- order_id (INTEGER, FOREIGN KEY → orders.id)
- message (TEXT)
- type (TEXT) : 'order_assigned'
- read_at (TIMESTAMP, NULL)
- created_at (TIMESTAMP)
```

### 5. **Table `order_notifications`** - Notifications Clients
```sql
- id (UUID, PRIMARY KEY)
- order_id (INTEGER, FOREIGN KEY → orders.id)
- user_id (UUID, FOREIGN KEY → users.id)
- message (TEXT)
- type (TEXT) : 'status_update'
- sent_at (TIMESTAMP)
- read_at (TIMESTAMP, NULL)
```

## Flux d'Assignation

### Étape 1 : Commande Prête pour Livraison
```sql
-- La commande doit avoir le statut "ready_for_delivery"
UPDATE orders 
SET status = 'ready_for_delivery', ready_at = NOW()
WHERE id = [order_id];
```

### Étape 2 : Recherche des Livreurs Disponibles
```sql
-- Critères pour un livreur disponible :
SELECT d.* FROM drivers d
WHERE d.is_active = true 
  AND d.is_available = true
  AND NOT EXISTS (
    SELECT 1 FROM order_driver_assignments oda
    WHERE oda.driver_id = d.id 
      AND oda.delivered_at IS NULL
  );
```

**Critères de disponibilité :**
- ✅ `is_active = true` (livreur actif)
- ✅ `is_available = true` (disponible pour nouvelles commandes)
- ✅ Pas de livraison en cours (`delivered_at IS NULL` dans `order_driver_assignments`)

### Étape 3 : Assignation du Livreur
```sql
-- 1. Créer l'assignation
INSERT INTO order_driver_assignments (order_id, driver_id, assigned_at)
VALUES ([order_id], [driver_id], NOW());

-- 2. Mettre à jour le statut de la commande
UPDATE orders 
SET status = 'in_transit', updated_at = NOW()
WHERE id = [order_id];

-- 3. Notifier le livreur
INSERT INTO driver_notifications (driver_id, order_id, message, type)
VALUES ([driver_id], [order_id], 'Nouvelle livraison assignée', 'order_assigned');

-- 4. Notifier le client
INSERT INTO order_notifications (order_id, user_id, message, type)
VALUES ([order_id], [user_id], 'Votre commande est en cours de livraison', 'status_update');
```

### Étape 4 : Livraison Terminée
```sql
-- 1. Marquer la livraison comme terminée
UPDATE order_driver_assignments 
SET delivered_at = NOW()
WHERE order_id = [order_id] AND driver_id = [driver_id];

-- 2. Mettre à jour le statut de la commande
UPDATE orders 
SET status = 'delivered', actual_delivery_time = NOW()
WHERE id = [order_id];
```

## Règles Métier

### 1. **Assignation Obligatoire pour "in_transit"**
- ❌ Impossible de passer en `in_transit` sans livreur assigné
- ✅ Le statut `in_transit` nécessite une entrée dans `order_driver_assignments`

### 2. **Un Livreur = Une Commande Active**
- Un livreur ne peut avoir qu'une seule livraison en cours à la fois
- Vérification via `delivered_at IS NULL` dans `order_driver_assignments`

### 3. **Types de Commandes**
- **`delivery`** : Nécessite un livreur assigné
- **`pickup`** : Pas de livreur nécessaire (à emporter)

### 4. **Notifications Automatiques**
- Livreur notifié lors de l'assignation
- Client notifié du changement de statut
- Notifications en temps réel via Supabase Realtime

## Code d'Implémentation

### Fonction d'Assignation
```typescript
const assignDriverToOrder = async (driverId: number, driverName: string) => {
  try {
    // 1. Créer l'assignation
    const { error: assignError } = await supabase
      .from('order_driver_assignments')
      .insert({
        order_id: orderId,
        driver_id: driverId,
        assigned_at: new Date().toISOString()
      });

    if (assignError) throw assignError;

    // 2. Mettre à jour le statut
    const { error: statusError } = await supabase
      .from('orders')
      .update({
        status: 'in_transit',
        updated_at: new Date().toISOString()
      })
      .eq('id', orderId);

    if (statusError) throw statusError;

    // 3. Notifier le livreur
    await supabase
      .from('driver_notifications')
      .insert({
        driver_id: driverId,
        order_id: orderId,
        message: `Nouvelle livraison assignée - Commande #${orderId}`,
        type: 'order_assigned'
      });

    // 4. Notifier le client
    await supabase
      .from('order_notifications')
      .insert({
        order_id: orderId,
        message: `Votre commande est en cours de livraison. Livreur: ${driverName}`,
        type: 'status_update'
      });

  } catch (error) {
    console.error('Erreur lors de l\'assignation:', error);
  }
};
```

### Vérification des Livreurs Disponibles
```typescript
const fetchAvailableDrivers = async () => {
  const { data: drivers, error } = await supabase
    .from('drivers')
    .select('*')
    .eq('is_active', true)
    .eq('is_available', true);

  // Filtrer les livreurs avec livraison en cours
  const availableDrivers = drivers?.filter(driver => {
    // Vérifier s'il n'a pas de livraison en cours
    return !driver.order_driver_assignments?.some(
      assignment => assignment.delivered_at === null
    );
  });

  return availableDrivers;
};
```

## Interface Utilisateur

### Modal de Détail de Commande
1. **Statut "ready_for_delivery"** → Affiche la carte des livreurs disponibles
2. **Sélection du livreur** → Assignation automatique + changement de statut
3. **Statut "in_transit"** → Affichage du livreur assigné
4. **Statut "delivered"** → Marquer la livraison comme terminée

### Carte des Livreurs Disponibles
- Liste des livreurs actifs et disponibles
- Informations : nom, téléphone, position GPS
- Bouton "Assigner" pour chaque livreur
- Filtrage automatique des livreurs occupés

## Sécurité et Contrôles

### Row Level Security (RLS)
```sql
-- Seuls les admins peuvent gérer les assignations
CREATE POLICY "Admin can manage order driver assignments" 
ON public.order_driver_assignments 
FOR ALL 
USING (true);
```

### Validation des Données
- Vérification de l'existence du livreur
- Vérification de la disponibilité
- Contrôle des statuts de commande
- Gestion des erreurs transactionnelles

## Avantages du Système

### 1. **Traçabilité Complète**
- Historique des assignations
- Timestamps précis
- Notifications automatiques

### 2. **Gestion des Conflits**
- Un livreur = une livraison active
- Vérifications de disponibilité
- Statuts cohérents

### 3. **Interface Intuitive**
- Assignation en un clic
- Affichage temps réel
- Notifications automatiques

### 4. **Scalabilité**
- Support de multiples livreurs
- Gestion des pics d'activité
- Historique des performances




