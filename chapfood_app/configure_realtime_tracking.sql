-- ============================================================================
-- Configuration Supabase Realtime pour le Suivi en Temps Réel
-- ============================================================================
-- Ce script configure les publications Realtime pour synchroniser 
-- les positions des livreurs entre l'app driver et l'app cliente
-- ============================================================================

-- 1. Vérifier les publications existantes
SELECT * FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime'
ORDER BY schemaname, tablename;

-- 2. Ajouter la table drivers à la publication Realtime
-- (Ignore l'erreur si déjà ajoutée)
DO $$
BEGIN
  -- Vérifier si la table est déjà dans la publication
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
    AND tablename = 'drivers'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE drivers;
    RAISE NOTICE 'Table drivers ajoutée à la publication Realtime';
  ELSE
    RAISE NOTICE 'Table drivers déjà dans la publication Realtime';
  END IF;
END $$;

-- 3. Vérifier les colonnes qui seront publiées
SELECT 
  schemaname,
  tablename,
  attname as column_name,
  atttypid::regtype as data_type
FROM pg_publication_tables pt
JOIN pg_attribute pa ON pa.attrelid = (pt.schemaname||'.'||pt.tablename)::regclass
WHERE pubname = 'supabase_realtime'
  AND tablename = 'drivers'
  AND attnum > 0
  AND NOT attisdropped
ORDER BY attnum;

-- 4. Vérifier les politiques RLS pour les lectures (nécessaire pour Realtime)
SELECT 
  schemaname,
  tablename,
  policyname,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'drivers'
ORDER BY policyname;

-- 5. S'assurer que RLS est activé
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;

-- 6. Créer une politique permettant aux clients de lire les positions des livreurs
-- (Seulement si elle n'existe pas déjà)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'drivers' 
    AND policyname = 'Allow clients to read driver positions'
  ) THEN
    CREATE POLICY "Allow clients to read driver positions"
    ON drivers
    FOR SELECT
    USING (true);
    RAISE NOTICE 'Politique de lecture créée pour les clients';
  ELSE
    RAISE NOTICE 'Politique de lecture existe déjà';
  END IF;
END $$;

-- 7. Vérifier que les colonnes essentielles existent
DO $$
BEGIN
  -- Vérifier current_lat
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'drivers' 
    AND column_name = 'current_lat'
  ) THEN
    RAISE EXCEPTION 'Colonne current_lat manquante dans la table drivers';
  END IF;

  -- Vérifier current_lng
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'drivers' 
    AND column_name = 'current_lng'
  ) THEN
    RAISE EXCEPTION 'Colonne current_lng manquante dans la table drivers';
  END IF;

  -- Vérifier last_location_update
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'drivers' 
    AND column_name = 'last_location_update'
  ) THEN
    ALTER TABLE drivers ADD COLUMN last_location_update TIMESTAMP WITH TIME ZONE;
    RAISE NOTICE 'Colonne last_location_update ajoutée';
  END IF;

  RAISE NOTICE 'Toutes les colonnes nécessaires sont présentes';
END $$;

-- 8. Créer un index pour améliorer les performances des requêtes Realtime
CREATE INDEX IF NOT EXISTS idx_drivers_location_update 
ON drivers(last_location_update DESC);

CREATE INDEX IF NOT EXISTS idx_drivers_available 
ON drivers(is_available) 
WHERE is_available = true;

-- 9. Afficher un résumé de la configuration
SELECT 
  'Configuration Realtime' as status,
  COUNT(*) FILTER (WHERE tablename = 'drivers') as drivers_in_publication,
  COUNT(*) FILTER (WHERE tablename = 'drivers' AND cmd = 'SELECT') as read_policies
FROM (
  SELECT tablename FROM pg_publication_tables WHERE pubname = 'supabase_realtime'
) pt
FULL OUTER JOIN (
  SELECT tablename, cmd FROM pg_policies WHERE tablename = 'drivers'
) pp ON pt.tablename = pp.tablename;

-- 10. Test: Afficher les livreurs avec leur dernière position
SELECT 
  id,
  name,
  current_lat,
  current_lng,
  last_location_update,
  is_available,
  CASE 
    WHEN last_location_update IS NULL THEN 'Jamais mis à jour'
    WHEN last_location_update > NOW() - INTERVAL '1 minute' THEN 'Actif'
    WHEN last_location_update > NOW() - INTERVAL '10 minutes' THEN 'Récent'
    ELSE 'Inactif'
  END as status
FROM drivers
ORDER BY last_location_update DESC NULLS LAST
LIMIT 10;

-- ============================================================================
-- INSTRUCTIONS D'UTILISATION
-- ============================================================================
-- 1. Exécuter ce script dans l'éditeur SQL de Supabase
-- 2. Vérifier qu'aucune erreur n'est retournée
-- 3. Vérifier dans les logs que la table drivers est dans la publication
-- 4. Tester l'app cliente pour vérifier que le Realtime fonctionne
--
-- Pour déboguer:
-- - Vérifier les logs Realtime dans le dashboard Supabase
-- - Vérifier que les positions sont mises à jour dans la table drivers
-- - Utiliser les outils de développement du navigateur pour voir les WebSocket
-- ============================================================================


