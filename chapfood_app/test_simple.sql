-- TEST SIMPLE - Vérifier que le système fonctionne

-- 1. Vérifier l'état actuel du livreur
SELECT 
    'État actuel' as status,
    id,
    name,
    current_lat,
    current_lng,
    last_location_update,
    is_available
FROM drivers 
WHERE id = 6;

-- 2. Mettre à jour manuellement la position (simulation GPS)
UPDATE drivers 
SET 
    current_lat = 5.21116357 + (RANDOM() - 0.5) * 0.001,
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
    EXTRACT(EPOCH FROM (NOW() - last_location_update)) as seconds_ago
FROM drivers 
WHERE id = 6;

-- 4. Vérifier la cohérence avec la commande
SELECT 
    'Cohérence commande-livreur' as status,
    o.id as commande_id,
    o.customer_name,
    d.name as nom_livreur,
    d.current_lat as livreur_lat,
    d.current_lng as livreur_lng,
    d.last_location_update,
    CASE 
        WHEN d.last_location_update > NOW() - INTERVAL '10 seconds' THEN '✅ Récent'
        WHEN d.last_location_update > NOW() - INTERVAL '1 minute' THEN '⚠️ Ancien'
        ELSE '❌ Très ancien'
    END as statut_position
FROM orders o
LEFT JOIN order_driver_assignments oda ON o.id = oda.order_id
LEFT JOIN drivers d ON oda.driver_id = d.id
WHERE o.id = 37;




