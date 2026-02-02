-- ============================================================================
-- Script de Monitoring en Temps Réel - ChapFood
-- ============================================================================
-- Ce script permet de surveiller les mises à jour des positions des livreurs
-- en temps réel pour vérifier que le système fonctionne correctement.
-- ============================================================================

-- 1. Surveiller les mises à jour en continu (à exécuter dans un terminal SQL)
-- Exécutez cette requête plusieurs fois de suite pour voir les changements
SELECT 
  id,
  name,
  current_lat,
  current_lng,
  last_location_update,
  is_available,
  CASE 
    WHEN last_location_update > NOW() - INTERVAL '10 seconds' THEN '🟢 Actif (< 10s)'
    WHEN last_location_update > NOW() - INTERVAL '1 minute' THEN '🟡 Récent (< 1min)'
    WHEN last_location_update > NOW() - INTERVAL '5 minutes' THEN '🟠 Ancien (< 5min)'
    WHEN last_location_update IS NULL THEN '⚪ Jamais mis à jour'
    ELSE '🔴 Inactif (> 5min)'
  END as status,
  EXTRACT(EPOCH FROM (NOW() - last_location_update)) as secondes_depuis_maj
FROM drivers
WHERE is_available = true OR last_location_update > NOW() - INTERVAL '10 minutes'
ORDER BY last_location_update DESC NULLS LAST;

-- ============================================================================

-- 2. Afficher l'historique des 10 dernières secondes
-- (Nécessite une table d'audit - optionnel)
-- Pour créer la table d'audit, exécutez d'abord create_driver_audit_table.sql

-- ============================================================================

-- 3. Compter les mises à jour par minute (dernier 10 minutes)
WITH updates_per_minute AS (
  SELECT 
    id,
    name,
    DATE_TRUNC('minute', last_location_update) as minute,
    last_location_update
  FROM drivers
  WHERE last_location_update > NOW() - INTERVAL '10 minutes'
)
SELECT 
  minute,
  COUNT(*) as nb_updates,
  STRING_AGG(name, ', ') as drivers_updated
FROM updates_per_minute
GROUP BY minute
ORDER BY minute DESC;

-- ============================================================================

-- 4. Vérifier les livreurs assignés aux commandes en cours
SELECT 
  o.id as order_id,
  o.status as order_status,
  d.id as driver_id,
  d.name as driver_name,
  d.current_lat,
  d.current_lng,
  d.last_location_update,
  EXTRACT(EPOCH FROM (NOW() - d.last_location_update)) as secondes_depuis_maj,
  CASE 
    WHEN d.last_location_update > NOW() - INTERVAL '10 seconds' THEN '✅ Temps réel actif'
    WHEN d.last_location_update > NOW() - INTERVAL '1 minute' THEN '⚠️ Légèrement retardé'
    ELSE '❌ Pas à jour'
  END as realtime_status
FROM orders o
JOIN order_driver_assignments oda ON o.id = oda.order_id
JOIN drivers d ON oda.driver_id = d.id
WHERE o.status IN ('in_transit', 'ready_for_delivery', 'accepted')
ORDER BY d.last_location_update DESC;

-- ============================================================================

-- 5. Détecter les anomalies (positions qui ne bougent plus)
SELECT 
  id,
  name,
  current_lat,
  current_lng,
  last_location_update,
  EXTRACT(EPOCH FROM (NOW() - last_location_update))/60 as minutes_sans_maj,
  is_available
FROM drivers
WHERE 
  is_available = true 
  AND last_location_update < NOW() - INTERVAL '2 minutes'
  AND last_location_update > NOW() - INTERVAL '1 hour'
ORDER BY last_location_update ASC;

-- ============================================================================

-- 6. Statistiques globales du système
SELECT 
  COUNT(*) as total_drivers,
  COUNT(*) FILTER (WHERE is_available = true) as drivers_disponibles,
  COUNT(*) FILTER (WHERE last_location_update > NOW() - INTERVAL '10 seconds') as actifs_10s,
  COUNT(*) FILTER (WHERE last_location_update > NOW() - INTERVAL '1 minute') as actifs_1min,
  COUNT(*) FILTER (WHERE last_location_update > NOW() - INTERVAL '5 minutes') as actifs_5min,
  COUNT(*) FILTER (WHERE last_location_update IS NULL) as jamais_mis_a_jour,
  ROUND(AVG(EXTRACT(EPOCH FROM (NOW() - last_location_update)))::numeric, 2) as latence_moyenne_sec
FROM drivers;

-- ============================================================================

-- 7. Vérifier la configuration Realtime
SELECT 
  'Realtime Configuration' as info,
  EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'drivers'
  ) as drivers_dans_publication,
  EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'drivers' AND cmd = 'SELECT'
  ) as politique_lecture_existe,
  pg_size_pretty(pg_total_relation_size('drivers')) as taille_table;

-- ============================================================================

-- 8. Tester une mise à jour manuelle (pour debug)
-- Décommentez et modifiez l'ID pour tester
/*
UPDATE drivers 
SET 
  current_lat = 5.3563 + (random() * 0.01),
  current_lng = -4.0363 + (random() * 0.01),
  last_location_update = NOW()
WHERE id = 1; -- Remplacer 1 par l'ID du driver à tester

-- Vérifiez immédiatement dans l'app cliente si la position est mise à jour
*/

-- ============================================================================
-- UTILISATION
-- ============================================================================
-- 
-- Pour surveiller en temps réel:
-- 1. Ouvrir deux fenêtres SQL dans Supabase
-- 2. Dans la première, exécuter la requête 1 toutes les 5 secondes
-- 3. Dans la seconde, exécuter la requête 4 pour voir les commandes actives
-- 4. Observer les changements de last_location_update
-- 
-- Pour tester le système:
-- 1. Lancer l'app driver avec un livreur
-- 2. Accepter une commande
-- 3. Observer dans la requête 1 que last_location_update se met à jour
-- 4. Ouvrir l'app cliente et suivre la commande
-- 5. Observer dans les logs que "Connexion Realtime établie"
-- 6. Vérifier que le marqueur bouge en temps réel
-- 
-- ============================================================================


