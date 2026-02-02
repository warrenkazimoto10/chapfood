-- Script de test pour le système de codes de livraison
-- Exécuter ce script dans Supabase SQL Editor

-- 1. Supprimer l'ancienne commande de test
DELETE FROM orders WHERE id = 26;

-- 2. Créer une nouvelle commande avec un code de livraison
INSERT INTO orders (
  id,
  user_id,
  customer_name,
  customer_phone,
  delivery_address,
  delivery_lat,
  delivery_lng,
  total_amount,
  status,
  delivery_code,
  delivery_code_generated_at,
  delivery_code_expires_at,
  created_at,
  updated_at
) VALUES (
  26,
  1,
  'Client Test Code',
  '+2250707559999',
  'Quartier France, Grand-Bassam',
  5.213580,  -- Latitude proche
  -3.771710, -- Longitude proche
  15000.0,
  'in_transit',
  '123456',  -- Code de test
  NOW(),
  NOW() + INTERVAL '15 minutes', -- Expire dans 15 minutes
  NOW(),
  NOW()
);

-- 3. Créer l'assignation du livreur
INSERT INTO order_driver_assignments (
  order_id,
  driver_id,
  assigned_at
) VALUES (
  26,
  1,  -- ID du livreur connecté
  NOW()
);

-- 4. Vérifier la commande créée
SELECT 
  o.id,
  o.customer_name,
  o.delivery_address,
  o.delivery_lat,
  o.delivery_lng,
  o.status,
  o.delivery_code,
  o.delivery_code_generated_at,
  o.delivery_code_expires_at,
  o.delivery_confirmed_at,
  oda.driver_id,
  oda.assigned_at
FROM orders o
LEFT JOIN order_driver_assignments oda ON o.id = oda.order_id
WHERE o.id = 26;

-- 5. Tester la fonction de validation
SELECT validate_delivery_code(26, '123456') as is_valid;

-- 6. Tester la fonction de confirmation
SELECT confirm_delivery(26, '123456', 'driver_1') as is_confirmed;

-- 7. Vérifier le statut après confirmation
SELECT 
  id,
  customer_name,
  status,
  delivery_confirmed_at,
  delivery_confirmed_by
FROM orders 
WHERE id = 26;

