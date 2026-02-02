-- Script pour vérifier la structure des tables de notifications
-- Exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier la structure de la table driver_notifications
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'driver_notifications' 
ORDER BY ordinal_position;

-- 2. Vérifier la structure de la table order_notifications
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'order_notifications' 
ORDER BY ordinal_position;

-- 3. Vérifier la structure de la table orders
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'orders' 
ORDER BY ordinal_position;
