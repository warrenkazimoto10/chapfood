-- Script de correction URGENTE pour les erreurs
-- 1. Ajouter la colonne manquante
-- 2. Corriger les fonctions PostGIS

-- 1. Ajouter la colonne last_location_update si elle n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'drivers' 
        AND column_name = 'last_location_update'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.drivers 
        ADD COLUMN last_location_update TIMESTAMP WITH TIME ZONE;
        
        RAISE NOTICE 'Colonne last_location_update ajoutée';
    ELSE
        RAISE NOTICE 'Colonne last_location_update existe déjà';
    END IF;
END $$;

-- 2. Mettre à jour la colonne pour les enregistrements existants
UPDATE public.drivers 
SET last_location_update = updated_at 
WHERE last_location_update IS NULL;

-- 3. Vérifier la structure de la table
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'drivers' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 4. Test simple de mise à jour de position (sans PostGIS)
UPDATE public.drivers 
SET 
    current_lat = 5.3563,
    current_lng = -4.0363,
    last_location_update = NOW(),
    updated_at = NOW()
WHERE id = 1;

-- 5. Vérifier la mise à jour
SELECT 
    id,
    name,
    current_lat,
    current_lng,
    last_location_update,
    updated_at
FROM public.drivers 
WHERE id = 1;

-- 6. Script de test pour le suivi en temps réel (SANS PostGIS)
-- Utilise une fonction de distance simple au lieu de PostGIS
DO $$
DECLARE
    driver_id INTEGER;
    current_lat DECIMAL(10,8);
    current_lng DECIMAL(11,8);
    target_lat DECIMAL(10,8);
    target_lng DECIMAL(11,8);
    step_lat DECIMAL(10,8);
    step_lng DECIMAL(11,8);
    distance DECIMAL;
BEGIN
    -- Récupérer l'ID du livreur assigné à la commande 37
    SELECT oda.driver_id INTO driver_id
    FROM order_driver_assignments oda
    WHERE oda.order_id = 37;
    
    IF driver_id IS NOT NULL THEN
        -- Récupérer la position actuelle du livreur
        SELECT d.current_lat, d.current_lng INTO current_lat, current_lng
        FROM drivers d
        WHERE d.id = driver_id;
        
        -- Récupérer la position du client (commande 37)
        SELECT o.delivery_lat, o.delivery_lng INTO target_lat, target_lng
        FROM orders o
        WHERE o.id = 37;
        
        -- Calculer la distance simple (formule de Haversine simplifiée)
        distance := SQRT(
            POWER((target_lat - current_lat) * 111000, 2) + 
            POWER((target_lng - current_lng) * 111000 * COS(RADIANS(current_lat)), 2)
        );
        
        -- Si la distance est > 100m, faire un pas vers le client
        IF distance > 100 THEN
            -- Calculer le pas de mouvement (1% de la distance)
            step_lat := (target_lat - current_lat) * 0.01;
            step_lng := (target_lng - current_lng) * 0.01;
            
            -- Mettre à jour la position
            UPDATE drivers 
            SET 
                current_lat = drivers.current_lat + step_lat,
                current_lng = drivers.current_lng + step_lng,
                last_location_update = NOW(),
                updated_at = NOW()
            WHERE drivers.id = driver_id;
            
            RAISE NOTICE 'Position mise à jour: %, % (distance: %m)', 
                current_lat + step_lat, 
                current_lng + step_lng, 
                ROUND(distance);
        ELSE
            RAISE NOTICE 'Livreur arrivé à destination (distance: %m)', ROUND(distance);
        END IF;
    ELSE
        RAISE NOTICE 'Aucun livreur assigné à la commande 37';
    END IF;
END $$;

-- 7. Vérifier la publication en temps réel
SELECT 
    schemaname,
    tablename,
    hasinserts,
    hasupdates,
    hasdeletes,
    hastruncates
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime' 
AND tablename = 'drivers';

-- 8. Test final de cohérence (SANS PostGIS)
SELECT 
    'État final' as status,
    o.id as commande_id,
    o.customer_name,
    o.delivery_lat as client_lat,
    o.delivery_lng as client_lng,
    d.id as livreur_id,
    d.name as nom_livreur,
    d.current_lat as livreur_lat,
    d.current_lng as livreur_lng,
    d.last_location_update,
    -- Distance simple sans PostGIS
    ROUND(SQRT(
        POWER((o.delivery_lat - d.current_lat) * 111000, 2) + 
        POWER((o.delivery_lng - d.current_lng) * 111000 * COS(RADIANS(d.current_lat)), 2)
    )) as distance_meters
FROM orders o
LEFT JOIN order_driver_assignments oda ON o.id = oda.order_id
LEFT JOIN drivers d ON oda.driver_id = d.id
WHERE o.id = 37;
