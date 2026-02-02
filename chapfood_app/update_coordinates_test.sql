-- Script SQL pour tester la route avec des coordonnées différentes

-- Mettre à jour la commande 37 avec de nouvelles coordonnées client
UPDATE orders 
SET 
    delivery_lat = 5.3600,  -- Abidjan Plateau (centre ville)
    delivery_lng = -4.0083,
    delivery_address = 'Abidjan Plateau - Avenue Franchetti (5.3600, -4.0083)'
WHERE id = 37;

-- Mettre à jour le livreur ID 6 avec de nouvelles coordonnées différentes
UPDATE drivers 
SET 
    current_lat = 5.2900,  -- Treichville (sud d'Abidjan)
    current_lng = -4.0081,
    last_location_update = NOW()
WHERE id = 6;

-- Vérifier les nouvelles coordonnées
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
    CONCAT('Livreur: ', d.name, ' - ', d.address) as description
FROM drivers d
WHERE d.id = 6;

-- Calculer la distance approximative entre les points
SELECT 
    ST_Distance(
        ST_GeogFromText('POINT(-4.0083 5.3600)'),  -- Client Plateau
        ST_GeogFromText('POINT(-4.0081 5.2900)')   -- Livreur Treichville
    ) as distance_meters,
    ROUND(ST_Distance(
        ST_GeogFromText('POINT(-4.0083 5.3600)'),
        ST_GeogFromText('POINT(-4.0081 5.2900)')
    ) / 1000, 2) as distance_km;

-- Voir toutes les assignations pour la commande 37
SELECT 
    oda.order_id,
    oda.driver_id,
    oda.assigned_at,
    d.name as nom_livreur,
    d.current_lat as livreur_lat,
    d.current_lng as livreur_lng,
    o.delivery_lat as client_lat,
    o.delivery_lng as client_lng,
    ST_Distance(
        ST_GeogFromText(CONCAT('POINT(', d.current_lng, ' ', d.current_lat, ')')),
        ST_GeogFromText(CONCAT('POINT(', o.delivery_lng, ' ', o.delivery_lat, ')'))
    ) as distance_directe_mtres
FROM order_driver_assignments oda
JOIN drivers d ON oda.driver_id = d.id
JOIN orders o ON oda.order_id = o.id
WHERE oda.order_id = 37;
