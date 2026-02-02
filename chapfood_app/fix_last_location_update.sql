-- Script de correction pour la colonne last_location_update
-- Ce script corrige l'erreur "column last_location_update does not exist"

-- 1. Vérifier la structure actuelle de la table drivers
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'drivers' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Ajouter la colonne last_location_update si elle n'existe pas
DO $$
BEGIN
    -- Vérifier si la colonne existe déjà
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'drivers' 
        AND column_name = 'last_location_update'
        AND table_schema = 'public'
    ) THEN
        -- Ajouter la colonne
        ALTER TABLE public.drivers 
        ADD COLUMN last_location_update TIMESTAMP WITH TIME ZONE;
        
        RAISE NOTICE 'Colonne last_location_update ajoutée à la table drivers';
    ELSE
        RAISE NOTICE 'Colonne last_location_update existe déjà';
    END IF;
END $$;

-- 3. Mettre à jour la colonne pour les enregistrements existants
UPDATE public.drivers 
SET last_location_update = updated_at 
WHERE last_location_update IS NULL;

-- 4. Vérifier la structure après modification
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'drivers' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 5. Tester la mise à jour de position
UPDATE public.drivers 
SET 
    current_lat = 5.3563,
    current_lng = -4.0363,
    last_location_update = NOW(),
    updated_at = NOW()
WHERE id = 1;

-- 6. Vérifier la mise à jour
SELECT 
    id,
    name,
    current_lat,
    current_lng,
    last_location_update,
    updated_at
FROM public.drivers 
WHERE id = 1;

-- 7. Script de test pour le suivi en temps réel
-- Ce script simule le mouvement d'un livreur
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
        
        -- Calculer la distance
        distance := ST_Distance(
            ST_GeogFromText(CONCAT('POINT(', current_lng, ' ', current_lat, ')')),
            ST_GeogFromText(CONCAT('POINT(', target_lng, ' ', target_lat, ')'))
        );
        
        -- Si la distance est > 100m, faire un pas vers le client
        IF distance > 100 THEN
            -- Calculer le pas de mouvement (1% de la distance)
            step_lat := (target_lat - current_lat) * 0.01;
            step_lng := (target_lng - current_lng) * 0.01;
            
            -- Mettre à jour la position
            UPDATE drivers 
            SET 
                current_lat = current_lat + step_lat,
                current_lng = current_lng + step_lng,
                last_location_update = NOW(),
                updated_at = NOW()
            WHERE id = driver_id;
            
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

-- 8. Vérifier la publication en temps réel
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

-- 9. Activer la publication en temps réel si nécessaire
-- ALTER PUBLICATION supabase_realtime ADD TABLE drivers;

-- 10. Test final de cohérence
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
    ST_Distance(
        ST_GeogFromText(CONCAT('POINT(', d.current_lng, ' ', d.current_lat, ')')),
        ST_GeogFromText(CONCAT('POINT(', o.delivery_lng, ' ', o.delivery_lat, ')'))
    ) as distance_meters
FROM orders o
LEFT JOIN order_driver_assignments oda ON o.id = oda.order_id
LEFT JOIN drivers d ON oda.driver_id = d.id
WHERE o.id = 37;
