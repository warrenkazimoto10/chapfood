-- Script pour créer une commande de test ready_for_delivery
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

-- 3. Vérifier toutes les colonnes disponibles dans driver_notifications
SELECT * FROM driver_notifications LIMIT 1;

-- 4. Vérifier toutes les colonnes disponibles dans order_notifications  
SELECT * FROM order_notifications LIMIT 1;

-- 4. Nettoyer les commandes de test (à exécuter après les tests)
-- DELETE FROM orders WHERE customer_name = 'Test Customer';
