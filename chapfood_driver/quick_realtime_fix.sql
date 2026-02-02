-- Script de correction rapide pour Supabase Realtime
-- Exécuter ces commandes dans l'ordre dans l'éditeur SQL de Supabase

-- 1. Vérifier l'état actuel
SELECT 
    pubname,
    puballtables,
    pubinsert,
    pubupdate,
    pubdelete
FROM pg_publication 
WHERE pubname = 'supabase_realtime';

-- 2. Vérifier les tables dans la publication
SELECT 
    schemaname,
    tablename
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime'
ORDER BY tablename;

-- 3. CORRECTION: Donner les permissions de réplication
ALTER ROLE supabase_realtime_admin REPLICATION;

-- 4. Si la publication n'existe pas, la créer
-- (Décommentez seulement si la requête #1 ne retourne rien)
-- CREATE PUBLICATION supabase_realtime FOR ALL TABLES;

-- 5. Si vous voulez forcer la reconfiguration complète:
-- (ATTENTION: Cela supprimera toutes les configurations Realtime existantes)
-- DROP PUBLICATION IF EXISTS supabase_realtime;
-- CREATE PUBLICATION supabase_realtime FOR ALL TABLES;

-- 6. Vérifier que tout fonctionne
SELECT 
    p.pubname,
    pt.tablename,
    pt.attnames
FROM pg_publication p
LEFT JOIN pg_publication_tables pt ON p.pubname = pt.pubname
WHERE p.pubname = 'supabase_realtime'
ORDER BY pt.tablename;
