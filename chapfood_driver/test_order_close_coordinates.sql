-- Test avec des coordonnées proches de Grand-Bassam
-- Position livreur actuelle: 5.2054724, -3.7414368
-- Position client proche: 5.213580, -3.771710

-- Supprimer l'ancienne commande de test
DELETE FROM orders WHERE id = 26;

-- Créer une nouvelle commande avec des coordonnées proches
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
  created_at,
  updated_at
) VALUES (
  26,
  1,
  'Client Test Proche',
  '+2250707559999',
  'Quartier France, Grand-Bassam',
  5.213580,  -- Latitude proche
  -3.771710, -- Longitude proche
  15000.0,
  'ready_for_delivery',
  NOW(),
  NOW()
);

-- Vérifier la commande créée
SELECT 
  id,
  customer_name,
  delivery_address,
  delivery_lat,
  delivery_lng,
  status,
  created_at
FROM orders 
WHERE id = 26;



