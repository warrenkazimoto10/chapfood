-- Migration pour ajouter la colonne created_via à la table orders
-- Exécuter ce script dans Supabase SQL Editor

-- 1. Ajouter la colonne created_via à la table orders
ALTER TABLE orders 
ADD COLUMN created_via VARCHAR(50) DEFAULT 'app';

-- 2. Mettre à jour les enregistrements existants
UPDATE orders 
SET created_via = 'app' 
WHERE created_via IS NULL;

-- 3. Ajouter une contrainte pour valider les valeurs
ALTER TABLE orders 
ADD CONSTRAINT check_created_via_values 
CHECK (created_via IN ('app', 'cashier', 'whatsapp', 'phone'));

-- 4. Ajouter un commentaire pour la documentation
COMMENT ON COLUMN orders.created_via IS 'Source de création de la commande: app (application mobile), cashier (système de caisse), whatsapp, phone';

-- 5. Créer un index pour optimiser les recherches (optionnel)
CREATE INDEX idx_orders_created_via ON orders(created_via);

-- 6. Exemples de valeurs possibles:
-- 'app' - Commande créée via l'application mobile
-- 'cashier' - Commande créée via le système de caisse
-- 'whatsapp' - Commande créée via WhatsApp
-- 'phone' - Commande créée par téléphone
