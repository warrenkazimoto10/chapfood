# Guide de Dépannage - Suivi des Livraisons

## Erreurs courantes et solutions

### 1. Erreur "column orders.assigned_at does not exist"

**Problème :** L'erreur indique que la colonne `assigned_at` n'existe pas dans la table `orders`.

**Cause :** La requête tentait d'accéder à `assigned_at` dans la table `orders`, mais cette colonne se trouve dans `order_driver_assignments`.

**Solution :** ✅ **CORRIGÉ** - La requête a été mise à jour pour utiliser la bonne structure de données.

```sql
-- ❌ Incorrect (ancien)
SELECT assigned_at FROM orders

-- ✅ Correct (nouveau)
SELECT order_driver_assignments.assigned_at FROM orders
JOIN order_driver_assignments ON orders.id = order_driver_assignments.order_id
```

### 2. Erreur de jointure avec `!inner`

**Problème :** L'utilisation de `!inner` dans les requêtes Supabase peut causer des erreurs si les relations ne sont pas correctement configurées.

**Solution :** ✅ **CORRIGÉ** - Utilisation de jointures normales au lieu de `!inner`.

```javascript
// ❌ Incorrect (ancien)
order_driver_assignments!inner(driver_id, assigned_at, ...)

// ✅ Correct (nouveau)
order_driver_assignments(driver_id, assigned_at, ...)
```

### 3. Aucune livraison affichée

**Causes possibles :**
- Aucune commande avec le statut `in_transit` ou `ready_for_delivery`
- Problème de permissions dans la base de données
- Erreur dans la requête de données

**Solutions :**
1. Vérifier qu'il existe des commandes avec les bons statuts
2. Vérifier les politiques RLS de Supabase
3. Tester la requête directement dans l'interface Supabase

### 4. Livreurs non affichés dans la liste

**Causes possibles :**
- Tous les livreurs sont marqués comme `is_active = false` ou `is_available = false`
- Problème dans la logique de filtrage des livreurs occupés
- Erreur dans la requête de jointure

**Solutions :**
1. Vérifier les données des livreurs dans la table `drivers`
2. Vérifier la logique de filtrage dans `AvailableDriversCard`
3. Tester manuellement les requêtes

### 5. Actualisation automatique ne fonctionne pas

**Causes possibles :**
- Problème avec l'intervalle JavaScript
- Erreur dans la fonction `fetchDeliveries`
- Problème de permissions

**Solutions :**
1. Vérifier la console pour les erreurs JavaScript
2. Tester l'actualisation manuelle
3. Vérifier les logs de la base de données

## Vérifications de base

### 1. Structure de la base de données
Assurez-vous que les tables suivantes existent avec les bonnes colonnes :

```sql
-- Table orders
CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  customer_name TEXT,
  customer_phone TEXT NOT NULL,
  delivery_address TEXT,
  status order_status,
  -- autres colonnes...
);

-- Table drivers
CREATE TABLE drivers (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  is_active BOOLEAN,
  is_available BOOLEAN,
  -- autres colonnes...
);

-- Table order_driver_assignments
CREATE TABLE order_driver_assignments (
  id SERIAL PRIMARY KEY,
  order_id INTEGER REFERENCES orders(id),
  driver_id INTEGER REFERENCES drivers(id),
  assigned_at TIMESTAMP,
  picked_up_at TIMESTAMP,
  delivered_at TIMESTAMP
);
```

### 2. Permissions RLS
Vérifiez que les politiques RLS permettent aux admins d'accéder aux données :

```sql
-- Exemple de politique pour les orders
CREATE POLICY "Admins can view all orders" 
ON orders FOR SELECT 
USING (true);

-- Exemple de politique pour les drivers
CREATE POLICY "Admins can view all drivers" 
ON drivers FOR SELECT 
USING (true);
```

### 3. Données de test
Pour tester l'application, créez des données de test :

```sql
-- Créer un livreur de test
INSERT INTO drivers (name, phone, is_active, is_available) 
VALUES ('Livreur Test', '0123456789', true, true);

-- Créer une commande de test
INSERT INTO orders (customer_name, customer_phone, delivery_address, status, total_amount) 
VALUES ('Client Test', '0987654321', 'Adresse Test', 'ready_for_delivery', 25.50);
```

## Logs utiles

### Console du navigateur
- Ouvrez les outils de développement (F12)
- Allez dans l'onglet "Console"
- Recherchez les erreurs JavaScript

### Logs Supabase
- Connectez-vous à votre dashboard Supabase
- Allez dans "Logs" > "API"
- Recherchez les erreurs 400, 500, etc.

### Logs de l'application
- Vérifiez les messages dans la console
- Utilisez `console.log()` pour déboguer
- Vérifiez les états React avec les DevTools

## Commandes de débogage

### Tester la connexion à la base
```javascript
// Dans la console du navigateur
const { data, error } = await supabase.from('orders').select('*').limit(1);
console.log('Orders:', data, 'Error:', error);
```

### Tester les livreurs
```javascript
const { data, error } = await supabase.from('drivers').select('*');
console.log('Drivers:', data, 'Error:', error);
```

### Tester les assignations
```javascript
const { data, error } = await supabase.from('order_driver_assignments').select('*');
console.log('Assignments:', data, 'Error:', error);
```

## Support

Si vous rencontrez d'autres problèmes :
1. Vérifiez d'abord ce guide
2. Consultez la documentation Supabase
3. Vérifiez les logs d'erreur
4. Testez avec des données de test simples

