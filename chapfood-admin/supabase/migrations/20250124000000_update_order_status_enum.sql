-- Mise à jour de l'enum order_status pour inclure les nouveaux statuts
-- Flux: pending → accepted → ready_for_delivery → in_transit → delivered

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

