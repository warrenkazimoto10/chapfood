-- SCRIPT ULTRA-SIMPLE - Correction définitive

-- 1. Ajouter la colonne manquante
ALTER TABLE drivers ADD COLUMN IF NOT EXISTS last_location_update TIMESTAMP WITH TIME ZONE;

-- 2. Mettre à jour les enregistrements existants
UPDATE drivers 
SET last_location_update = updated_at 
WHERE last_location_update IS NULL;

-- 3. Test de mise à jour de position
UPDATE drivers 
SET 
    current_lat = 5.3563,
    current_lng = -4.0363,
    last_location_update = NOW(),
    updated_at = NOW()
WHERE id = 1;

-- 4. Vérifier que ça fonctionne
SELECT 
    id,
    name,
    current_lat,
    current_lng,
    last_location_update,
    updated_at
FROM drivers 
WHERE id = 1;

-- 5. Vérifier la publication en temps réel (version simple)
SELECT 
    schemaname,
    tablename
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime' 
AND tablename = 'drivers';

-- 6. Test final de cohérence
SELECT 
    o.id as commande_id,
    o.customer_name,
    o.delivery_lat as client_lat,
    o.delivery_lng as client_lng,
    d.id as livreur_id,
    d.name as nom_livreur,
    d.current_lat as livreur_lat,
    d.current_lng as livreur_lng,
    d.last_location_update
FROM orders o
LEFT JOIN order_driver_assignments oda ON o.id = oda.order_id
LEFT JOIN drivers d ON oda.driver_id = d.id
WHERE o.id = 37;
