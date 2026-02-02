-- Script pour vérifier la commande ID 37 et le livreur ID 6

-- 1. Vérifier la commande ID 37
SELECT 
    o.id as commande_id,
    o.customer_name,
    o.customer_phone,
    o.delivery_type,
    o.delivery_address,
    o.delivery_lat,
    o.delivery_lng,
    o.status,
    o.created_at,
    o.total_amount
FROM orders o
WHERE o.id = 37;

-- 2. Vérifier le livreur ID 6
SELECT 
    d.id as livreur_id,
    d.name as nom_livreur,
    d.phone as telephone_livreur,
    d.current_lat,
    d.current_lng,
    d.is_available,
    d.address as adresse_livreur
FROM drivers d
WHERE d.id = 6;

-- 3. Vérifier l'assignation livreur-commande
SELECT 
    oda.order_id,
    oda.driver_id,
    oda.assigned_at,
    o.customer_name,
    o.delivery_address,
    o.delivery_lat as client_lat,
    o.delivery_lng as client_lng,
    d.name as nom_livreur,
    d.current_lat as livreur_lat,
    d.current_lng as livreur_lng
FROM order_driver_assignments oda
JOIN orders o ON oda.order_id = o.id
JOIN drivers d ON oda.driver_id = d.id
WHERE oda.order_id = 37 AND oda.driver_id = 6;

-- 4. Vérifier toutes les assignations pour la commande 37
SELECT 
    oda.order_id,
    oda.driver_id,
    oda.assigned_at,
    d.name as nom_livreur,
    d.current_lat,
    d.current_lng
FROM order_driver_assignments oda
JOIN drivers d ON oda.driver_id = d.id
WHERE oda.order_id = 37;

-- 5. Vérifier toutes les commandes du livreur ID 6
SELECT 
    oda.order_id,
    oda.assigned_at,
    o.customer_name,
    o.delivery_address,
    o.delivery_lat,
    o.delivery_lng,
    o.status
FROM order_driver_assignments oda
JOIN orders o ON oda.order_id = o.id
WHERE oda.driver_id = 6
ORDER BY oda.assigned_at DESC;

-- 6. Comparer les coordonnées (pour identifier le problème de superposition)
SELECT 
    'Commande 37' as type,
    o.delivery_lat as latitude,
    o.delivery_lng as longitude,
    o.delivery_address as description
FROM orders o
WHERE o.id = 37

UNION ALL

SELECT 
    'Livreur 6' as type,
    d.current_lat as latitude,
    d.current_lng as longitude,
    CONCAT('Livreur: ', d.name) as description
FROM drivers d
WHERE d.id = 6;

-- 7. Mettre à jour les coordonnées du client si nécessaire (décommentez si besoin)
-- UPDATE orders 
-- SET 
--     delivery_lat = 5.3600,  -- Abidjan Plateau
--     delivery_lng = -4.0083
-- WHERE id = 37 AND delivery_lat IS NULL;

-- 8. Mettre à jour les coordonnées du livreur si nécessaire (décommentez si besoin)
-- UPDATE drivers 
-- SET 
--     current_lat = 5.3563,  -- Treichville
--     current_lng = -4.0363
-- WHERE id = 6 AND current_lat IS NULL;

-- 9. Créer l'assignation si elle n'existe pas (décommentez si besoin)
-- INSERT INTO order_driver_assignments (order_id, driver_id, assigned_at)
-- VALUES (37, 6, NOW())
-- ON CONFLICT (order_id) DO UPDATE SET
--     driver_id = EXCLUDED.driver_id,
--     assigned_at = EXCLUDED.assigned_at;
