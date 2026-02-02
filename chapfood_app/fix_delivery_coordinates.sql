-- Script pour corriger et vérifier les coordonnées de livraison
-- dans la table orders

-- 1. Vérifier la structure de la table orders
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'orders' 
AND column_name IN ('delivery_lat', 'delivery_lng', 'delivery_address')
ORDER BY ordinal_position;

-- 2. Vérifier les données actuelles des commandes
SELECT 
    id,
    delivery_type,
    delivery_address,
    delivery_lat,
    delivery_lng,
    status
FROM orders 
WHERE delivery_type = 'delivery'
ORDER BY created_at DESC
LIMIT 10;

-- 3. Mettre à jour les coordonnées manquantes avec des coordonnées d'Abidjan
UPDATE orders 
SET 
    delivery_lat = 5.3600,
    delivery_lng = -4.0083
WHERE delivery_type = 'delivery' 
AND (delivery_lat IS NULL OR delivery_lng IS NULL);

-- 4. Vérifier que toutes les commandes de livraison ont des coordonnées
SELECT 
    COUNT(*) as total_delivery_orders,
    COUNT(delivery_lat) as orders_with_lat,
    COUNT(delivery_lng) as orders_with_lng,
    COUNT(CASE WHEN delivery_lat IS NOT NULL AND delivery_lng IS NOT NULL THEN 1 END) as orders_with_both_coords
FROM orders 
WHERE delivery_type = 'delivery';

-- 5. Exemple de commande avec coordonnées complètes
SELECT 
    o.id,
    o.customer_name,
    o.delivery_address,
    o.delivery_lat,
    o.delivery_lng,
    o.status,
    d.name as driver_name,
    d.current_lat as driver_lat,
    d.current_lng as driver_lng
FROM orders o
LEFT JOIN order_driver_assignments oda ON o.id = oda.order_id
LEFT JOIN drivers d ON oda.driver_id = d.id
WHERE o.delivery_type = 'delivery'
AND o.delivery_lat IS NOT NULL 
AND o.delivery_lng IS NOT NULL
LIMIT 5;

-- 6. Ajouter des coordonnées de test si nécessaire
INSERT INTO orders (
    user_id,
    customer_phone,
    customer_name,
    delivery_type,
    delivery_address,
    delivery_lat,
    delivery_lng,
    payment_method,
    subtotal,
    total_amount,
    status,
    created_at
) VALUES (
    'test-user-id',
    '+225 07 77 39 33 56',
    'Client Test',
    'delivery',
    'Abidjan, Côte d''Ivoire',
    5.3600,
    -4.0083,
    'cash',
    5000.0,
    5500.0,
    'in_transit',
    NOW()
) ON CONFLICT DO NOTHING;

-- 7. Assigner un livreur à la commande de test
INSERT INTO order_driver_assignments (order_id, driver_id, assigned_at)
SELECT 
    o.id,
    d.id,
    NOW()
FROM orders o
CROSS JOIN drivers d
WHERE o.customer_name = 'Client Test'
AND d.name = 'Jean Kouassi'
ON CONFLICT (order_id) DO NOTHING;

-- 8. Vérification finale
SELECT 
    'Coordonnées de livraison' as info,
    delivery_lat,
    delivery_lng,
    delivery_address
FROM orders 
WHERE delivery_type = 'delivery'
AND delivery_lat IS NOT NULL 
AND delivery_lng IS NOT NULL
LIMIT 3;
