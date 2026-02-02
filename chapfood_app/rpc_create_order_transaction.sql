-- ============================================================================
-- RPC: Création Commande avec Transaction Atomique
-- ============================================================================
-- Cette fonction crée une commande et ses items dans une transaction unique
-- Evite les commandes orphelines si l'insertion des items échoue
-- ============================================================================

CREATE OR REPLACE FUNCTION create_order_with_items(
  p_user_id TEXT,
  p_customer_name TEXT,
  p_customer_phone TEXT,
  p_delivery_type TEXT,
  p_delivery_address TEXT DEFAULT NULL,
  p_delivery_lat DECIMAL DEFAULT NULL,
  p_delivery_lng DECIMAL DEFAULT NULL,
  p_payment_method TEXT,
  p_subtotal DECIMAL,
  p_delivery_fee DECIMAL,
  p_total_amount DECIMAL,
  p_items JSONB
)
RETURNS JSON AS $$
DECLARE
  v_order_id INT;
  v_item JSONB;
  v_result JSON;
BEGIN
  -- Validation des paramètres
  IF p_customer_name IS NULL OR p_customer_phone IS NULL THEN
    RAISE EXCEPTION 'Nom et téléphone client obligatoires';
  END IF;
  
  IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'La commande doit contenir au moins un article';
  END IF;
  
  -- Insérer la commande
  INSERT INTO orders (
    user_id,
    customer_name,
    customer_phone,
    delivery_type,
    delivery_address,
    delivery_lat,
    delivery_lng,
    payment_method,
    subtotal,
    delivery_fee,
    total_amount,
    status,
    created_at,
    updated_at
  )
  VALUES (
    p_user_id,
    p_customer_name,
    p_customer_phone,
    p_delivery_type,
    p_delivery_address,
    p_delivery_lat,
    p_delivery_lng,
    p_payment_method,
    p_subtotal,
    p_delivery_fee,
    p_total_amount,
    'pending',
    NOW(),
    NOW()
  )
  RETURNING id INTO v_order_id;
  
  RAISE NOTICE 'Commande créée avec ID: %', v_order_id;
  
  -- Insérer les items (dans la même transaction)
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    INSERT INTO order_items (
      order_id,
      menu_item_id,
      item_name,
      item_price,
      quantity,
      total_price,
      selected_garnitures,
      selected_extras,
      instructions,
      created_at
    )
    VALUES (
      v_order_id,
      (v_item->>'menu_item_id')::INT,
      v_item->>'item_name',
      (v_item->>'item_price')::DECIMAL,
      (v_item->>'quantity')::INT,
      (v_item->>'total_price')::DECIMAL,
      COALESCE((v_item->'selected_garnitures')::TEXT[], ARRAY[]::TEXT[]),
      COALESCE((v_item->'selected_extras')::TEXT[], ARRAY[]::TEXT[]),
      COALESCE(v_item->>'instructions', ''),
      NOW()
    );
    
    RAISE NOTICE 'Item ajouté: % x %', v_item->>'item_name', v_item->>'quantity';
  END LOOP;
  
  -- Récupérer la commande complète avec les items
  SELECT json_build_object(
    'id', o.id,
    'user_id', o.user_id,
    'customer_name', o.customer_name,
    'customer_phone', o.customer_phone,
    'delivery_type', o.delivery_type,
    'delivery_address', o.delivery_address,
    'delivery_lat', o.delivery_lat,
    'delivery_lng', o.delivery_lng,
    'payment_method', o.payment_method,
    'subtotal', o.subtotal,
    'delivery_fee', o.delivery_fee,
    'total_amount', o.total_amount,
    'status', o.status,
    'created_at', o.created_at,
    'items', (
      SELECT json_agg(
        json_build_object(
          'id', oi.id,
          'menu_item_id', oi.menu_item_id,
          'item_name', oi.item_name,
          'item_price', oi.item_price,
          'quantity', oi.quantity,
          'total_price', oi.total_price,
          'selected_garnitures', oi.selected_garnitures,
          'selected_extras', oi.selected_extras,
          'instructions', oi.instructions
        )
      )
      FROM order_items oi
      WHERE oi.order_id = o.id
    )
  )
  INTO v_result
  FROM orders o
  WHERE o.id = v_order_id;
  
  RETURN v_result;
  
EXCEPTION
  WHEN OTHERS THEN
    -- En cas d'erreur, rollback automatique de toute la transaction
    RAISE EXCEPTION 'Erreur création commande: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- Grant permissions
-- ============================================================================
GRANT EXECUTE ON FUNCTION create_order_with_items TO authenticated;
GRANT EXECUTE ON FUNCTION create_order_with_items TO anon;

-- ============================================================================
-- Test de la fonction
-- ============================================================================
/*
SELECT create_order_with_items(
  p_user_id := 'user-uuid-here',
  p_customer_name := 'Test Client',
  p_customer_phone := '+225 07 12 34 56 78',
  p_delivery_type := 'home_delivery',
  p_delivery_address := '123 Rue Test, Abidjan',
  p_delivery_lat := 5.3599,
  p_delivery_lng := -4.0083,
  p_payment_method := 'cash',
  p_subtotal := 15000.00,
  p_delivery_fee := 1500.00,
  p_total_amount := 16500.00,
  p_items := '[
    {
      "menu_item_id": 1,
      "item_name": "Poulet Braisé",
      "item_price": 5000,
      "quantity": 2,
      "total_price": 10000,
      "selected_garnitures": ["Attiéké", "Tomates"],
      "selected_extras": [],
      "instructions": "Bien pimenté"
    },
    {
      "menu_item_id": 2,
      "item_name": "Alloco",
      "item_price": 2500,
      "quantity": 2,
      "total_price": 5000,
      "selected_garnitures": [],
      "selected_extras": ["Sauce piquante"],
      "instructions": ""
    }
  ]'::JSONB
);
*/


