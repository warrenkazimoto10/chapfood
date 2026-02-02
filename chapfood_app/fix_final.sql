-- CORRECTION FINALE - Script simple sans ambiguïté

-- 1. Ajouter la colonne manquante
ALTER TABLE drivers ADD COLUMN IF NOT EXISTS last_location_update TIMESTAMP WITH TIME ZONE;

-- 2. Mettre à jour les enregistrements existants
UPDATE drivers 
SET last_location_update = updated_at 
WHERE last_location_update IS NULL;

-- 3. Test simple de mise à jour de position
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

-- 5. Test de simulation de mouvement (sans ambiguïté)
DO $$
DECLARE
    driver_id INTEGER;
    target_lat DECIMAL(10,8);
    target_lng DECIMAL(11,8);
BEGIN
    -- Récupérer l'ID du livreur assigné à la commande 37
    SELECT oda.driver_id INTO driver_id
    FROM order_driver_assignments oda
    WHERE oda.order_id = 37;
    
    IF driver_id IS NOT NULL THEN
        -- Récupérer la position du client (commande 37)
        SELECT o.delivery_lat, o.delivery_lng INTO target_lat, target_lng
        FROM orders o
        WHERE o.id = 37;
        
        -- Mettre à jour la position du livreur vers le client
        UPDATE drivers 
        SET 
            current_lat = target_lat,
            current_lng = target_lng,
            last_location_update = NOW(),
            updated_at = NOW()
        WHERE drivers.id = driver_id;
        
        RAISE NOTICE 'Position livreur mise à jour vers client: %, %', target_lat, target_lng;
    ELSE
        RAISE NOTICE 'Aucun livreur assigné à la commande 37';
    END IF;
END $$;

-- 6. Vérifier la publication en temps réel
SELECT 
    schemaname,
    tablename
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime' 
AND tablename = 'drivers';

-- 7. Test final de cohérence
SELECT 
    'État final' as status,
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
