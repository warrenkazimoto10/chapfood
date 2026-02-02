-- CORRECTION URGENTE - Exécuter ce script immédiatement

-- 1. Ajouter la colonne manquante
ALTER TABLE drivers ADD COLUMN IF NOT EXISTS last_location_update TIMESTAMP WITH TIME ZONE;

-- 2. Mettre à jour les enregistrements existants
UPDATE drivers 
SET last_location_update = updated_at 
WHERE last_location_update IS NULL;

-- 3. Test de mise à jour de position
UPDATE drivers 
SET 
    current_lat = 5.3563,
    current_lng = -4.0363,
    last_location_update = NOW(),
    updated_at = NOW()
WHERE id = 1;

-- 4. Vérifier que ça fonctionne
SELECT 
    id,
    name,
    current_lat,
    current_lng,
    last_location_update,
    updated_at
FROM drivers 
WHERE id = 1;




