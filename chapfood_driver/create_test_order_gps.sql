-- Script pour créer une commande de test avec les vraies coordonnées GPS
-- Coordonnées fournies: 5.213580, -3.771710

-- 1. Insérer une commande de test avec les vraies coordonnées
INSERT INTO orders (
    customer_name,
    customer_phone,
    delivery_address,
    delivery_lat,
    delivery_lng,
    subtotal,
    total_amount,
    payment_method,
    status,
    created_at,
    updated_at,
    ready_at
) VALUES (
    'Test Customer GPS',
    '0707559999',
    'Adresse de test avec coordonnées GPS',
    5.213580,  -- Latitude fournie
    -3.771710, -- Longitude fournie
    15000,
    15000,
    'cash',
    'ready_for_delivery',
    NOW(),
    NOW(),
    NOW()
);

-- 2. Vérifier que la commande a été insérée avec les bonnes coordonnées
SELECT 
    id,
    customer_name,
    delivery_address,
    delivery_lat,
    delivery_lng,
    status,
    ready_at,
    created_at
FROM orders 
WHERE customer_name = 'Test Customer GPS'
ORDER BY created_at DESC;

-- 3. Vérifier toutes les commandes ready_for_delivery avec coordonnées
SELECT 
    id,
    customer_name,
    delivery_address,
    delivery_lat,
    delivery_lng,
    status
FROM orders 
WHERE status = 'ready_for_delivery'
  AND delivery_lat IS NOT NULL 
  AND delivery_lng IS NOT NULL
ORDER BY ready_at DESC;
