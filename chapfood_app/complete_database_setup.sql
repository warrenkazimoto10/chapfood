-- Script SQL complet pour la gestion des statuts de commande
-- Flux: pending → accepted → ready_for_delivery → in_transit → delivered

-- Mise à jour de l'enum order_status pour inclure les nouveaux statuts
-- Créer l'enum order_status s'il n'existe pas déjà
DO $$ 
BEGIN
    -- Vérifier si l'enum existe déjà
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_status') THEN
        CREATE TYPE public.order_status AS ENUM (
            'pending',
            'accepted', 
            'ready_for_delivery',
            'in_transit',
            'delivered',
            'cancelled'
        );
    ELSE
        -- Si l'enum existe, ajouter les nouvelles valeurs s'ils n'existent pas
        IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'accepted' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'order_status')) THEN
            ALTER TYPE public.order_status ADD VALUE 'accepted';
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'ready_for_delivery' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'order_status')) THEN
            ALTER TYPE public.order_status ADD VALUE 'ready_for_delivery';
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'in_transit' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'order_status')) THEN
            ALTER TYPE public.order_status ADD VALUE 'in_transit';
        END IF;
    END IF;
END $$;

-- Mettre à jour la table orders pour utiliser le bon type de colonne
-- (Au cas où la colonne status n'utiliserait pas encore l'enum)
DO $$
BEGIN
    -- Vérifier si la colonne status existe et son type
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'orders' AND column_name = 'status') THEN
        
        -- Si la colonne n'utilise pas encore l'enum, la convertir
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'orders' 
                       AND column_name = 'status' 
                       AND udt_name = 'order_status') THEN
            
            -- Convertir la colonne vers l'enum
            ALTER TABLE public.orders 
            ALTER COLUMN status TYPE public.order_status 
            USING status::public.order_status;
        END IF;
    END IF;
END $$;

-- Mettre à jour la table order_tracking pour utiliser le bon type
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'order_tracking' AND column_name = 'status') THEN
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'order_tracking' 
                       AND column_name = 'status' 
                       AND udt_name = 'order_status') THEN
            
            ALTER TABLE public.order_tracking 
            ALTER COLUMN status TYPE public.order_status 
            USING status::public.order_status;
        END IF;
    END IF;
END $$;

-- Ajouter un commentaire explicatif
COMMENT ON TYPE public.order_status IS 'Statuts des commandes: pending → accepted → ready_for_delivery → in_transit → delivered';

-- Insérer des livreurs de test
INSERT INTO public.drivers (
  name, 
  phone, 
  email, 
  is_available, 
  is_active, 
  current_lat, 
  current_lng, 
  address, 
  vehicle_type, 
  vehicle_info, 
  delivery_zones, 
  max_delivery_distance, 
  rating, 
  total_deliveries
) VALUES
(
  'Jean Kouassi',
  '+225 07 77 39 33 56',
  'jean.kouassi@chapfood.com',
  true,
  true,
  5.206313,
  -3.741129,
  'Grand Bassam, Côte d''Ivoire',
  'moto',
  '{"brand": "Honda", "model": "CG 125", "color": "Rouge", "plate": "CI-123-AB"}',
  ARRAY['Grand Bassam', 'Abidjan', 'Bingerville'],
  15,
  4.5,
  127
),
(
  'Marie Traoré',
  '+225 07 88 44 55 66',
  'marie.traore@chapfood.com',
  true,
  true,
  5.207000,
  -3.742000,
  'Abidjan, Côte d''Ivoire',
  'car',
  '{"brand": "Toyota", "model": "Corolla", "color": "Blanc", "plate": "CI-456-CD"}',
  ARRAY['Abidjan', 'Cocody', 'Plateau'],
  20,
  4.8,
  89
),
(
  'Kouame N''Guessan',
  '+225 07 99 55 77 88',
  'kouame.nguessan@chapfood.com',
  false,
  true,
  5.208000,
  -3.743000,
  'Bingerville, Côte d''Ivoire',
  'bike',
  '{"brand": "Giant", "model": "Escape", "color": "Vert", "accessories": ["panier", "casque"]}',
  ARRAY['Bingerville', 'Grand Bassam'],
  8,
  4.2,
  45
)
ON CONFLICT (phone) DO NOTHING;

-- Exemple d'assignation de livreur à une commande existante
-- Remplace 25 par l'ID d'une commande existante dans ta base
INSERT INTO public.order_driver_assignments (
  order_id,
  driver_id,
  assigned_at
) VALUES (
  25,  -- ID de la commande
  (SELECT id FROM public.drivers WHERE phone = '+225 07 77 39 33 56' LIMIT 1),  -- ID du livreur Jean Kouassi
  NOW()
)
ON CONFLICT (order_id) DO NOTHING;

-- Mettre à jour le statut de la commande vers 'in_transit'
UPDATE public.orders 
SET status = 'in_transit', 
    updated_at = NOW()
WHERE id = 25;

-- Mettre à jour la position du livreur (simulation de mouvement)
UPDATE public.drivers 
SET current_lat = 5.206500,
    current_lng = -3.741200,
    updated_at = NOW()
WHERE phone = '+225 07 77 39 33 56';

-- Vérifier les données insérées
SELECT 
  o.id as order_id,
  o.status,
  o.customer_name,
  o.delivery_address,
  d.name as driver_name,
  d.phone as driver_phone,
  d.vehicle_type,
  d.rating,
  oda.assigned_at,
  oda.picked_up_at,
  oda.delivered_at
FROM public.orders o
LEFT JOIN public.order_driver_assignments oda ON o.id = oda.order_id
LEFT JOIN public.drivers d ON oda.driver_id = d.id
WHERE o.id = 25;


