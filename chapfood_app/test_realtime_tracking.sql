-- Script de test pour vérifier la cohérence entre les applications
-- Ce script simule le mouvement du livreur pour tester le suivi en temps réel

-- 1. Vérifier l'état actuel de la commande 37 et son livreur
SELECT 
    'État actuel' as status,
    o.id as commande_id,
    o.customer_name,
    o.delivery_address,
    o.delivery_lat as client_lat,
    o.delivery_lng as client_lng,
    d.id as livreur_id,
    d.name as nom_livreur,
    d.current_lat as livreur_lat,
    d.current_lng as livreur_lng,
    oda.assigned_at
FROM orders o
LEFT JOIN order_driver_assignments oda ON o.id = oda.order_id
LEFT JOIN drivers d ON oda.driver_id = d.id
WHERE o.id = 37;

-- 2. Simuler le mouvement du livreur vers le client
-- Position 1: Départ du restaurant (position actuelle)
UPDATE drivers 
SET 
    current_lat = 5.3563,  -- Position restaurant
    current_lng = -4.0363,
    last_location_update = NOW(),
    updated_at = NOW()
WHERE id = (SELECT driver_id FROM order_driver_assignments WHERE order_id = 37);

-- Attendre 5 secondes puis mettre à jour
-- Position 2: En route vers le client
UPDATE drivers 
SET 
    current_lat = 5.3600,  -- Position intermédiaire
    current_lng = -4.0300,
    last_location_update = NOW(),
    updated_at = NOW()
WHERE id = (SELECT driver_id FROM order_driver_assignments WHERE order_id = 37);

-- Position 3: Plus proche du client
UPDATE drivers 
SET 
    current_lat = 5.3650,  -- Position plus proche
    current_lng = -4.0250,
    last_location_update = NOW(),
    updated_at = NOW()
WHERE id = (SELECT driver_id FROM order_driver_assignments WHERE order_id = 37);

-- Position 4: Arrivé chez le client
UPDATE drivers 
SET 
    current_lat = 5.3700,  -- Position client
    current_lng = -4.0200,
    last_location_update = NOW(),
    updated_at = NOW()
WHERE id = (SELECT driver_id FROM order_driver_assignments WHERE order_id = 37);

-- 3. Vérifier les positions après mise à jour
SELECT 
    'Après simulation' as status,
    o.id as commande_id,
    o.customer_name,
    o.delivery_lat as client_lat,
    o.delivery_lng as client_lng,
    d.id as livreur_id,
    d.name as nom_livreur,
    d.current_lat as livreur_lat,
    d.current_lng as livreur_lng,
    d.last_location_update,
    ST_Distance(
        ST_GeogFromText(CONCAT('POINT(', d.current_lng, ' ', d.current_lat, ')')),
        ST_GeogFromText(CONCAT('POINT(', o.delivery_lng, ' ', o.delivery_lat, ')'))
    ) as distance_meters
FROM orders o
LEFT JOIN order_driver_assignments oda ON o.id = oda.order_id
LEFT JOIN drivers d ON oda.driver_id = d.id
WHERE o.id = 37;

-- 4. Script pour tester le suivi en temps réel
-- Exécuter ce script toutes les 5 secondes pour simuler le mouvement
/*
DO $$
DECLARE
    driver_id INTEGER;
    current_lat DECIMAL(10,8);
    current_lng DECIMAL(11,8);
    target_lat DECIMAL(10,8);
    target_lng DECIMAL(11,8);
    step_lat DECIMAL(10,8);
    step_lng DECIMAL(11,8);
BEGIN
    -- Récupérer l'ID du livreur et les positions
    SELECT 
        oda.driver_id,
        d.current_lat,
        d.current_lng,
        o.delivery_lat,
        o.delivery_lng
    INTO driver_id, current_lat, current_lng, target_lat, target_lng
    FROM order_driver_assignments oda
    JOIN drivers d ON oda.driver_id = d.id
    JOIN orders o ON oda.order_id = o.id
    WHERE oda.order_id = 37;
    
    -- Calculer le pas de mouvement (1% de la distance)
    step_lat := (target_lat - current_lat) * 0.01;
    step_lng := (target_lng - current_lng) * 0.01;
    
    -- Mettre à jour la position
    UPDATE drivers 
    SET 
        current_lat = current_lat + step_lat,
        current_lng = current_lng + step_lng,
        last_location_update = NOW(),
        updated_at = NOW()
    WHERE id = driver_id;
    
    RAISE NOTICE 'Position mise à jour: %, %', current_lat + step_lat, current_lng + step_lng;
END $$;
*/

-- 5. Vérifier la publication en temps réel
SELECT 
    schemaname,
    tablename,
    hasinserts,
    hasupdates,
    hasdeletes,
    hastruncates
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime' 
AND tablename = 'drivers';

-- 6. Activer la publication en temps réel si nécessaire
-- ALTER PUBLICATION supabase_realtime ADD TABLE drivers;
