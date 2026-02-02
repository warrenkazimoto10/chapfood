-- Script simplifié pour créer une commande de test
-- Exécuter dans l'éditeur SQL de Supabase

-- 1. Insérer une commande de test
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
    'Test Customer',
    '0707559999',
    '123 Rue de la Paix, Abidjan',
    5.3599,
    -4.0083,
    15000,
    15000,
    'cash',
    'ready_for_delivery',
    NOW(),
    NOW(),
    NOW()
);

-- 2. Vérifier que la commande a été insérée
SELECT 
    id,
    customer_name,
    customer_phone,
    delivery_address,
    status,
    ready_at,
    created_at
FROM orders 
WHERE customer_name = 'Test Customer'
ORDER BY created_at DESC;

-- 3. Vérifier toutes les commandes ready_for_delivery
SELECT 
    id,
    customer_name,
    delivery_address,
    status,
    ready_at
FROM orders 
WHERE status = 'ready_for_delivery'
ORDER BY ready_at DESC;
