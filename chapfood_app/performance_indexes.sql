-- ============================================================================
-- Indexes de Performance - ChapFood
-- ============================================================================
-- Ce script crée des indexes pour améliorer les performances des requêtes
-- fréquentes sur les tables principales
-- ============================================================================

-- ============================================================================
-- 1. INDEX SUR LA TABLE USERS
-- ============================================================================

-- Index pour recherche par email (login)
CREATE INDEX IF NOT EXISTS idx_users_email 
ON users(email) 
WHERE is_active = true;

-- Index pour recherche par téléphone (login alternatif)
CREATE INDEX IF NOT EXISTS idx_users_phone 
ON users(phone) 
WHERE is_active = true AND phone IS NOT NULL;

-- Index pour utilisateurs actifs
CREATE INDEX IF NOT EXISTS idx_users_active 
ON users(is_active, created_at DESC);

RAISE NOTICE 'Indexes users créés';

-- ============================================================================
-- 2. INDEX SUR LA TABLE DRIVERS
-- ============================================================================

-- Index pour drivers disponibles (recherche assignation)
CREATE INDEX IF NOT EXISTS idx_drivers_available 
ON drivers(is_available, current_lat, current_lng) 
WHERE is_available = true;

-- Index pour dernière mise à jour localisation
CREATE INDEX IF NOT EXISTS idx_drivers_location_update 
ON drivers(last_location_update DESC) 
WHERE is_available = true;

-- Index pour recherche par email (login)
CREATE INDEX IF NOT EXISTS idx_drivers_email 
ON drivers(email) 
WHERE is_active = true;

-- Index pour recherche par téléphone
CREATE INDEX IF NOT EXISTS idx_drivers_phone 
ON drivers(phone) 
WHERE is_active = true;

-- Index spatial pour localisation (si PostGIS activé)
-- CREATE INDEX IF NOT EXISTS idx_drivers_location_geo 
-- ON drivers USING GIST (ST_MakePoint(current_lng, current_lat));

RAISE NOTICE 'Indexes drivers créés';

-- ============================================================================
-- 3. INDEX SUR LA TABLE ORDERS
-- ============================================================================

-- Index principal: commandes par utilisateur (historique)
CREATE INDEX IF NOT EXISTS idx_orders_user_id 
ON orders(user_id, created_at DESC);

-- Index pour commandes driver (livraisons actives)
CREATE INDEX IF NOT EXISTS idx_orders_driver_id 
ON orders(driver_id, status, created_at DESC) 
WHERE driver_id IS NOT NULL;

-- Index pour statut + date (dashboard, statistiques)
CREATE INDEX IF NOT EXISTS idx_orders_status_date 
ON orders(status, created_at DESC);

-- Index pour commandes en attente (drivers cherchent)
CREATE INDEX IF NOT EXISTS idx_orders_pending 
ON orders(status, created_at) 
WHERE status = 'ready_for_delivery';

-- Index pour recherche par téléphone client (support)
CREATE INDEX IF NOT EXISTS idx_orders_customer_phone 
ON orders(customer_phone, created_at DESC);

-- Index pour montant total (statistiques revenus)
CREATE INDEX IF NOT EXISTS idx_orders_total_amount 
ON orders(total_amount, created_at) 
WHERE status IN ('delivered', 'completed');

-- Index composite pour suivi temps réel
CREATE INDEX IF NOT EXISTS idx_orders_tracking 
ON orders(id, driver_id, status, delivery_lat, delivery_lng) 
WHERE status IN ('in_transit', 'accepted');

RAISE NOTICE 'Indexes orders créés';

-- ============================================================================
-- 4. INDEX SUR LA TABLE ORDER_ITEMS
-- ============================================================================

-- Index principal: items par commande
CREATE INDEX IF NOT EXISTS idx_order_items_order_id 
ON order_items(order_id, created_at);

-- Index pour statistiques par plat
CREATE INDEX IF NOT EXISTS idx_order_items_menu_item 
ON order_items(menu_item_id, created_at DESC);

-- Index pour montant total items (vérification cohérence)
CREATE INDEX IF NOT EXISTS idx_order_items_total 
ON order_items(order_id, total_price);

RAISE NOTICE 'Indexes order_items créés';

-- ============================================================================
-- 5. INDEX SUR LA TABLE ORDER_DRIVER_ASSIGNMENTS
-- ============================================================================

-- Index pour assignations par driver (historique)
CREATE INDEX IF NOT EXISTS idx_assignments_driver 
ON order_driver_assignments(driver_id, assigned_at DESC);

-- Index pour assignations par commande
CREATE INDEX IF NOT EXISTS idx_assignments_order 
ON order_driver_assignments(order_id, status);

-- Index pour assignations actives
CREATE INDEX IF NOT EXISTS idx_assignments_active 
ON order_driver_assignments(driver_id, status, assigned_at DESC) 
WHERE status = 'active';

RAISE NOTICE 'Indexes order_driver_assignments créés';

-- ============================================================================
-- 6. INDEX SUR LA TABLE MENU_ITEMS
-- ============================================================================

-- Index pour plats par catégorie
CREATE INDEX IF NOT EXISTS idx_menu_items_category 
ON menu_items(category_id, created_at) 
WHERE is_available = true;

-- Index pour recherche par nom (autocomplete)
CREATE INDEX IF NOT EXISTS idx_menu_items_name 
ON menu_items USING GIN (to_tsvector('french', name)) 
WHERE is_available = true;

-- Index pour prix (filtres, tris)
CREATE INDEX IF NOT EXISTS idx_menu_items_price 
ON menu_items(price, is_available);

RAISE NOTICE 'Indexes menu_items créés';

-- ============================================================================
-- 7. INDEX SUR LA TABLE CATEGORIES
-- ============================================================================

-- Index pour catégories actives triées
CREATE INDEX IF NOT EXISTS idx_categories_active 
ON categories(is_active, created_at) 
WHERE is_active = true;

RAISE NOTICE 'Indexes categories créés';

-- ============================================================================
-- 8. STATISTIQUES DE PERFORMANCE (Analyse)
-- ============================================================================

-- Analyser les tables pour mise à jour statistiques
ANALYZE users;
ANALYZE drivers;
ANALYZE orders;
ANALYZE order_items;
ANALYZE order_driver_assignments;
ANALYZE menu_items;
ANALYZE categories;

RAISE NOTICE 'Statistiques mises à jour';

-- ============================================================================
-- 9. VÉRIFICATION DES INDEXES
-- ============================================================================

-- Afficher tous les indexes créés
SELECT
  schemaname,
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('users', 'drivers', 'orders', 'order_items', 
                    'order_driver_assignments', 'menu_items', 'categories')
ORDER BY tablename, indexname;

-- ============================================================================
-- 10. TAILLE DES INDEXES (Monitoring)
-- ============================================================================

SELECT
  tablename,
  indexname,
  pg_size_pretty(pg_relation_size(indexname::regclass)) as index_size
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('users', 'drivers', 'orders', 'order_items')
ORDER BY pg_relation_size(indexname::regclass) DESC;

-- ============================================================================
-- 11. REQUÊTES OPTIMISÉES EXEMPLES
-- ============================================================================

/*
-- AVANT (Slow Scan)
EXPLAIN ANALYZE
SELECT * FROM orders WHERE user_id = 'user-uuid';
-- Seq Scan: 500ms pour 10,000 lignes

-- APRÈS (Index Scan avec idx_orders_user_id)
EXPLAIN ANALYZE
SELECT * FROM orders WHERE user_id = 'user-uuid' ORDER BY created_at DESC;
-- Index Scan: 5ms pour 10,000 lignes

-- GAIN: 100x plus rapide
*/

-- ============================================================================
-- 12. MAINTENANCE DES INDEXES
-- ============================================================================

-- Commande à exécuter périodiquement (ex: chaque semaine)
-- REINDEX DATABASE chapfood;

-- Ou par table spécifique:
-- REINDEX TABLE orders;

-- Vacuum pour nettoyer espace mort
-- VACUUM ANALYZE orders;

-- ============================================================================
-- NOTES
-- ============================================================================

/*
BONNES PRATIQUES:
1. Ne créez des indexes que sur les colonnes fréquemment utilisées en WHERE/JOIN
2. Les indexes ralentissent les INSERT/UPDATE (compromis acceptable)
3. Surveillez la taille des indexes (pas > 50% de la table)
4. ANALYZE après création d'index pour mettre à jour statistiques
5. Utilisez EXPLAIN ANALYZE pour vérifier utilisation des indexes

MONITORING:
- Logs Supabase → Performance Insights
- pg_stat_user_indexes pour usage réel
- pg_stat_user_tables pour stats tables

QUAND SUPPRIMER UN INDEX:
- Si jamais utilisé (vérifier pg_stat_user_indexes)
- Si ralentit trop les écritures
- Si duplique un autre index
*/


