-- Script pour résoudre l'erreur Supabase Realtime
-- Erreur: "relation 'orders' is already member of publication 'supabase_realtime'"

-- Script pour résoudre l'erreur Supabase Realtime
-- Erreur: "relation 'orders' is already member of publication 'supabase_realtime'"

-- 1. Vérifier l'état actuel des publications
SELECT 
    p.pubname as publication_name,
    pt.schemaname,
    pt.tablename,
    pt.attnames
FROM pg_publication p
LEFT JOIN pg_publication_tables pt ON p.pubname = pt.pubname
WHERE p.pubname = 'supabase_realtime'
ORDER BY pt.tablename;

-- 2. Si la table orders est déjà dans la publication, c'est normal
-- L'erreur peut venir d'une tentative de double ajout

-- 3. Pour résoudre le problème, vous pouvez:
-- Option A: Supprimer et re-ajouter la table (ATTENTION!)
-- ALTER PUBLICATION supabase_realtime DROP TABLE orders;
-- ALTER PUBLICATION supabase_realtime ADD TABLE orders;

-- Option B: Vérifier que la table orders a les bonnes colonnes pour Realtime
-- Les colonnes suivantes sont nécessaires:
-- - id (primary key)
-- - created_at (timestamp)
-- - updated_at (timestamp)

-- 4. Vérifier la structure de la table orders
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'orders' 
ORDER BY ordinal_position;

-- 5. Vérifier les contraintes de la table orders
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'orders';

-- 6. Si vous voulez forcer la reconfiguration Realtime:
-- DROP PUBLICATION IF EXISTS supabase_realtime;
-- CREATE PUBLICATION supabase_realtime FOR ALL TABLES;

-- 7. Alternative: Ajouter seulement les tables nécessaires
-- CREATE PUBLICATION supabase_realtime FOR TABLE orders, drivers, order_driver_assignments;

-- 8. Vérifier les permissions Realtime
SELECT 
    r.rolname,
    r.rolsuper,
    r.rolcreaterole,
    r.rolcreatedb,
    r.rolreplication
FROM pg_roles r
WHERE r.rolname LIKE '%realtime%' OR r.rolname LIKE '%supabase%';

-- 9. CORRECTION: Donner les permissions de réplication au rôle realtime
-- ALTER ROLE supabase_realtime_admin REPLICATION;

-- 10. Vérifier que la publication existe et fonctionne
SELECT 
    pubname,
    puballtables,
    pubinsert,
    pubupdate,
    pubdelete,
    pubtruncate
FROM pg_publication 
WHERE pubname = 'supabase_realtime';

-- 11. Si la publication n'existe pas, la créer
-- CREATE PUBLICATION supabase_realtime FOR ALL TABLES;

-- 12. Alternative: Créer une publication spécifique pour les tables nécessaires
-- DROP PUBLICATION IF EXISTS supabase_realtime;
-- CREATE PUBLICATION supabase_realtime FOR TABLE orders, drivers, order_driver_assignments;
