-- Script pour modifier la table orders pour accepter les IDs string
-- au lieu de UUID uniquement

-- 1. Vérifier la structure actuelle de la table orders
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'orders' AND column_name = 'user_id';

-- 2. Modifier la colonne user_id pour accepter VARCHAR au lieu d'UUID
ALTER TABLE orders 
ALTER COLUMN user_id TYPE VARCHAR(255);

-- 3. Supprimer la contrainte de clé étrangère si elle existe
ALTER TABLE orders 
DROP CONSTRAINT IF EXISTS orders_user_id_fkey;

-- 4. Ajouter un index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);

-- 5. Vérifier la nouvelle structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'orders' AND column_name = 'user_id';
