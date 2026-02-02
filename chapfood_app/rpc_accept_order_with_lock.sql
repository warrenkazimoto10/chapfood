-- ============================================================================
-- RPC: Acceptation Commande avec Verrou Pessimiste
-- ============================================================================
-- Cette fonction évite la double-assignation d'une commande par plusieurs drivers
-- Utilise SELECT FOR UPDATE NOWAIT pour verrou pessimiste
-- ============================================================================

CREATE OR REPLACE FUNCTION accept_order_atomically(
  p_order_id INT,
  p_driver_id INT
)
RETURNS JSON AS $$
DECLARE
  v_order_status TEXT;
  v_current_driver_id INT;
  v_customer_lat DECIMAL;
  v_customer_lng DECIMAL;
  v_driver_lat DECIMAL;
  v_driver_lng DECIMAL;
  v_result JSON;
BEGIN
  -- Vérifier que le driver existe et est disponible
  SELECT current_lat, current_lng, is_available
  INTO v_driver_lat, v_driver_lng
  FROM drivers
  WHERE id = p_driver_id;
  
  IF NOT FOUND THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Driver introuvable',
      'code', 'DRIVER_NOT_FOUND'
    );
  END IF;
  
  -- Verrou pessimiste sur la commande (NOWAIT = échec immédiat si déjà verrouillée)
  BEGIN
    SELECT status, driver_id, delivery_lat, delivery_lng
    INTO v_order_status, v_current_driver_id, v_customer_lat, v_customer_lng
    FROM orders
    WHERE id = p_order_id
    FOR UPDATE NOWAIT;
  EXCEPTION
    WHEN lock_not_available THEN
      -- Un autre driver est en train d'accepter cette commande
      RETURN json_build_object(
        'success', false,
        'error', 'Cette commande est en cours d''acceptation par un autre livreur',
        'code', 'LOCK_NOT_AVAILABLE'
      );
  END;
  
  -- Vérifier que la commande n'a pas été trouvée
  IF v_order_status IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Commande introuvable',
      'code', 'ORDER_NOT_FOUND'
    );
  END IF;
  
  -- Vérifier le statut de la commande
  IF v_order_status != 'ready_for_delivery' THEN
    IF v_order_status = 'in_transit' AND v_current_driver_id = p_driver_id THEN
      -- Le driver a déjà accepté cette commande
      RETURN json_build_object(
        'success', true,
        'already_accepted', true,
        'message', 'Vous avez déjà accepté cette commande'
      );
    ELSE
      RETURN json_build_object(
        'success', false,
        'error', 'Cette commande n''est plus disponible (statut: ' || v_order_status || ')',
        'code', 'INVALID_STATUS',
        'current_status', v_order_status
      );
    END IF;
  END IF;
  
  -- Mettre à jour la commande
  UPDATE orders
  SET 
    status = 'in_transit',
    driver_id = p_driver_id,
    accepted_at = NOW(),
    updated_at = NOW()
  WHERE id = p_order_id;
  
  RAISE NOTICE 'Commande % acceptée par driver %', p_order_id, p_driver_id;
  
  -- Créer l'assignation dans order_driver_assignments
  INSERT INTO order_driver_assignments (
    order_id,
    driver_id,
    assigned_at,
    status,
    pickup_lat,
    pickup_lng,
    delivery_lat,
    delivery_lng
  )
  VALUES (
    p_order_id,
    p_driver_id,
    NOW(),
    'active',
    v_driver_lat,
    v_driver_lng,
    v_customer_lat,
    v_customer_lng
  )
  ON CONFLICT (order_id, driver_id) 
  DO UPDATE SET
    assigned_at = NOW(),
    status = 'active';
  
  -- Mettre à jour la disponibilité du driver
  UPDATE drivers
  SET 
    is_available = false,
    updated_at = NOW()
  WHERE id = p_driver_id;
  
  -- Construire le résultat avec toutes les infos utiles
  SELECT json_build_object(
    'success', true,
    'order_id', o.id,
    'customer_name', o.customer_name,
    'customer_phone', o.customer_phone,
    'delivery_address', o.delivery_address,
    'delivery_lat', o.delivery_lat,
    'delivery_lng', o.delivery_lng,
    'total_amount', o.total_amount,
    'delivery_fee', o.delivery_fee,
    'payment_method', o.payment_method,
    'accepted_at', o.accepted_at,
    'items', (
      SELECT json_agg(
        json_build_object(
          'item_name', oi.item_name,
          'quantity', oi.quantity,
          'total_price', oi.total_price
        )
      )
      FROM order_items oi
      WHERE oi.order_id = o.id
    )
  )
  INTO v_result
  FROM orders o
  WHERE o.id = p_order_id;
  
  RETURN v_result;
  
EXCEPTION
  WHEN OTHERS THEN
    -- Log l'erreur
    RAISE WARNING 'Erreur acceptation commande %: %', p_order_id, SQLERRM;
    
    RETURN json_build_object(
      'success', false,
      'error', 'Erreur serveur: ' || SQLERRM,
      'code', 'INTERNAL_ERROR'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- RPC: Libérer une commande (annulation/échec)
-- ============================================================================

CREATE OR REPLACE FUNCTION release_order(
  p_order_id INT,
  p_driver_id INT,
  p_reason TEXT DEFAULT 'cancelled'
)
RETURNS JSON AS $$
BEGIN
  -- Vérifier que c'est bien le bon driver
  IF NOT EXISTS (
    SELECT 1 FROM orders
    WHERE id = p_order_id
    AND driver_id = p_driver_id
    AND status IN ('in_transit', 'accepted')
  ) THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Vous ne pouvez pas libérer cette commande'
    );
  END IF;
  
  -- Remettre la commande en attente
  UPDATE orders
  SET 
    status = 'ready_for_delivery',
    driver_id = NULL,
    accepted_at = NULL,
    updated_at = NOW()
  WHERE id = p_order_id;
  
  -- Mettre à jour l'assignation
  UPDATE order_driver_assignments
  SET 
    status = 'cancelled',
    cancelled_at = NOW(),
    cancellation_reason = p_reason
  WHERE order_id = p_order_id
    AND driver_id = p_driver_id;
  
  -- Rendre le driver disponible
  UPDATE drivers
  SET 
    is_available = true,
    updated_at = NOW()
  WHERE id = p_driver_id;
  
  RETURN json_build_object(
    'success', true,
    'message', 'Commande libérée avec succès'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- Grant permissions
-- ============================================================================
GRANT EXECUTE ON FUNCTION accept_order_atomically TO authenticated;
GRANT EXECUTE ON FUNCTION release_order TO authenticated;

-- ============================================================================
-- Test de la fonction
-- ============================================================================
/*
-- Test acceptation normale
SELECT accept_order_atomically(
  p_order_id := 1,
  p_driver_id := 6
);

-- Test double-acceptation (devrait échouer avec LOCK_NOT_AVAILABLE)
-- Exécuter dans 2 fenêtres SQL simultanément:
BEGIN;
SELECT accept_order_atomically(1, 6);
-- Attendre quelques secondes avant COMMIT
COMMIT;

-- Test libération
SELECT release_order(
  p_order_id := 1,
  p_driver_id := 6,
  p_reason := 'Driver unavailable'
);
*/


