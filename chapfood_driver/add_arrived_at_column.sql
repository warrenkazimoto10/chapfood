-- Migration pour ajouter la colonne arrived_at dans order_driver_assignments
-- Cette colonne indique quand le livreur est arrivé au point de livraison

-- Ajouter la colonne arrived_at si elle n'existe pas
ALTER TABLE order_driver_assignments 
ADD COLUMN IF NOT EXISTS arrived_at TIMESTAMP NULL;

-- Créer un index pour améliorer les performances des requêtes
CREATE INDEX IF NOT EXISTS idx_order_driver_assignments_driver_active 
ON order_driver_assignments(driver_id, delivered_at) 
WHERE delivered_at IS NULL;

-- Commentaire pour documenter la colonne
COMMENT ON COLUMN order_driver_assignments.arrived_at IS 
'Timestamp indiquant quand le livreur est arrivé au point de livraison. NULL si pas encore arrivé.';


