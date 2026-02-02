-- Script de diagnostic pour Supabase Realtime
-- Ce script vous aide à diagnostiquer les problèmes de publication Realtime

-- 1. Vérifier les publications existantes
SELECT * FROM pg_publication;

-- 2. Vérifier les tables dans la publication supabase_realtime
SELECT schemaname, tablename 
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime';

-- 3. Vérifier si la table orders existe
SELECT table_name, table_schema 
FROM information_schema.tables 
WHERE table_name = 'orders';

-- 4. Vérifier les colonnes de la table orders
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'orders' 
ORDER BY ordinal_position;

-- 5. Si vous voulez supprimer la table de la publication (ATTENTION!)
-- ALTER PUBLICATION supabase_realtime DROP TABLE orders;

-- 6. Si vous voulez ajouter la table à la publication (si elle n'y est pas)
-- ALTER PUBLICATION supabase_realtime ADD TABLE orders;

-- 7. Vérifier les permissions Realtime
SELECT * FROM pg_roles WHERE rolname LIKE '%realtime%';
