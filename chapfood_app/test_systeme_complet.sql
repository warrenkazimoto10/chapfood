-- TEST COMPLET DU SYSTÈME DE LIVRAISON
-- Vérification que le livreur met à jour sa position automatiquement

-- 1. Vérifier l'état initial du livreur
SELECT 
    'État initial' as status,
    id,
    name,
    current_lat,
    current_lng,
    last_location_update,
    is_available,
    updated_at
FROM drivers 
WHERE id = 6;

-- 2. Simuler une mise à jour de position (comme le ferait l'app livreur)
UPDATE drivers 
SET 
    current_lat = 5.21116357 + (RANDOM() - 0.5) * 0.001,  -- Variation de ~100m
    current_lng = -3.73560203 + (RANDOM() - 0.5) * 0.001,
    last_location_update = NOW(),
    updated_at = NOW()
WHERE id = 6;

-- 3. Vérifier la mise à jour
SELECT 
    'Après mise à jour' as status,
    id,
    name,
    current_lat,
    current_lng,
    last_location_update,
    is_available,
    updated_at
FROM drivers 
WHERE id = 6;

-- 4. Vérifier la cohérence avec la commande
SELECT 
    'Cohérence commande-livreur' as status,
    o.id as commande_id,
    o.customer_name,
    o.delivery_lat as client_lat,
    o.delivery_lng as client_lng,
    d.id as livreur_id,
    d.name as nom_livreur,
    d.current_lat as livreur_lat,
    d.current_lng as livreur_lng,
    d.last_location_update,
    d.is_available,
    -- Calculer la distance approximative
    ROUND(
        6371000 * ACOS(
            COS(RADIANS(o.delivery_lat)) * 
            COS(RADIANS(d.current_lat)) * 
            COS(RADIANS(d.current_lng) - RADIANS(o.delivery_lng)) + 
            SIN(RADIANS(o.delivery_lat)) * 
            SIN(RADIANS(d.current_lat))
        )
    ) as distance_meters
FROM orders o
LEFT JOIN order_driver_assignments oda ON o.id = oda.order_id
LEFT JOIN drivers d ON oda.driver_id = d.id
WHERE o.id = 37;

-- 5. Vérifier la publication en temps réel
SELECT 
    'Publication temps réel' as status,
    schemaname,
    tablename
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime' 
AND tablename = 'drivers';

-- 6. Test de plusieurs mises à jour rapides (simulation du mouvement)
DO $$
DECLARE
    i INTEGER;
    base_lat DOUBLE PRECISION := 5.21116357;
    base_lng DOUBLE PRECISION := -3.73560203;
    step_lat DOUBLE PRECISION;
    step_lng DOUBLE PRECISION;
BEGIN
    FOR i IN 1..5 LOOP
        -- Simuler un mouvement vers le client
        step_lat := (5.21340780 - base_lat) / 5.0;  -- Vers le client
        step_lng := (-3.77163830 - base_lng) / 5.0;
        
        base_lat := base_lat + step_lat;
        base_lng := base_lng + step_lng;
        
        UPDATE drivers 
        SET 
            current_lat = base_lat,
            current_lng = base_lng,
            last_location_update = NOW(),
            updated_at = NOW()
        WHERE id = 6;
        
        RAISE NOTICE 'Position %: %, %', i, base_lat, base_lng;
        
        -- Attendre 2 secondes entre chaque mise à jour
        PERFORM pg_sleep(2);
    END LOOP;
END $$;

-- 7. Vérifier la position finale
SELECT 
    'Position finale' as status,
    id,
    name,
    current_lat,
    current_lng,
    last_location_update,
    -- Distance finale vers le client
    ROUND(
        6371000 * ACOS(
            COS(RADIANS(5.21340780)) * 
            COS(RADIANS(current_lat)) * 
            COS(RADIANS(current_lng) - RADIANS(-3.77163830)) + 
            SIN(RADIANS(5.21340780)) * 
            SIN(RADIANS(current_lat))
        )
    ) as distance_finale_meters
FROM drivers 
WHERE id = 6;
