-- Migration pour s'assurer que les tables de localisation existent
-- et que les fonctions RPC sont disponibles

-- Vérifier si les tables existent, sinon les créer
DO $$
BEGIN
    -- Créer la table delivery_locations si elle n'existe pas
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'delivery_locations') THEN
        CREATE TABLE public.delivery_locations (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          name TEXT NOT NULL,
          district TEXT NOT NULL,
          zone_type TEXT NOT NULL CHECK (zone_type IN ('quartier', 'zone_commerciale', 'zone_residentielle', 'zone_industrielle', 'village', 'lieu_public')),
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          postal_code TEXT,
          delivery_fee REAL DEFAULT 0,
          estimated_delivery_time INTEGER DEFAULT 15,
          is_active BOOLEAN DEFAULT true,
          description TEXT,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        -- Index pour les recherches géographiques
        CREATE INDEX idx_delivery_locations_coordinates ON public.delivery_locations (latitude, longitude);
        CREATE INDEX idx_delivery_locations_name ON public.delivery_locations (name);
        CREATE INDEX idx_delivery_locations_district ON public.delivery_locations (district);
        CREATE INDEX idx_delivery_locations_zone_type ON public.delivery_locations (zone_type);
    END IF;

    -- Créer la table delivery_zones si elle n'existe pas
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'delivery_zones') THEN
        CREATE TABLE public.delivery_zones (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          name TEXT NOT NULL,
          base_fee REAL NOT NULL DEFAULT 0,
          max_distance_km REAL DEFAULT 5,
          estimated_time_minutes INTEGER DEFAULT 20,
          color_code TEXT DEFAULT '#3B82F6',
          is_active BOOLEAN DEFAULT true,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
    END IF;

    -- Créer la table landmarks si elle n'existe pas
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'landmarks') THEN
        CREATE TABLE public.landmarks (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          name TEXT NOT NULL,
          landmark_type TEXT NOT NULL CHECK (landmark_type IN ('restaurant', 'hotel', 'banque', 'pharmacie', 'hopital', 'ecole', 'eglise', 'mosquee', 'marche', 'station_service', 'bureau', 'autre')),
          address TEXT,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          delivery_location_id UUID REFERENCES public.delivery_locations(id),
          is_active BOOLEAN DEFAULT true,
          description TEXT,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
        
        CREATE INDEX idx_landmarks_coordinates ON public.landmarks (latitude, longitude);
        CREATE INDEX idx_landmarks_type ON public.landmarks (landmark_type);
        CREATE INDEX idx_landmarks_location ON public.landmarks (delivery_location_id);
    END IF;
END $$;

-- S'assurer que la fonction calculate_distance_km existe
CREATE OR REPLACE FUNCTION calculate_distance_km(
  lat1 REAL, lon1 REAL, 
  lat2 REAL, lon2 REAL
)
RETURNS REAL
LANGUAGE plpgsql
AS $$
DECLARE
  earth_radius REAL := 6371; -- Rayon de la Terre en km
  dlat REAL;
  dlon REAL;
  a REAL;
  c REAL;
BEGIN
  dlat := radians(lat2 - lat1);
  dlon := radians(lon2 - lon1);
  
  a := sin(dlat/2) * sin(dlat/2) + 
       cos(radians(lat1)) * cos(radians(lat2)) * 
       sin(dlon/2) * sin(dlon/2);
  
  c := 2 * atan2(sqrt(a), sqrt(1-a));
  
  RETURN earth_radius * c;
END;
$$;

-- S'assurer que la fonction find_nearest_locations existe
CREATE OR REPLACE FUNCTION find_nearest_locations(
  target_lat REAL,
  target_lon REAL,
  max_distance_km REAL DEFAULT 10,
  limit_count INTEGER DEFAULT 10
)
RETURNS TABLE(
  location_id UUID,
  location_name TEXT,
  district TEXT,
  distance_km REAL,
  delivery_fee REAL,
  estimated_time INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    dl.id,
    dl.name,
    dl.district,
    calculate_distance_km(target_lat, target_lon, dl.latitude, dl.longitude) as distance_km,
    dl.delivery_fee,
    dl.estimated_delivery_time
  FROM public.delivery_locations dl
  WHERE dl.is_active = true
    AND calculate_distance_km(target_lat, target_lon, dl.latitude, dl.longitude) <= max_distance_km
  ORDER BY distance_km
  LIMIT limit_count;
END;
$$;

-- S'assurer que la fonction get_delivery_fee existe
CREATE OR REPLACE FUNCTION get_delivery_fee(
  target_lat REAL,
  target_lon REAL
)
RETURNS TABLE(
  zone_name TEXT,
  delivery_fee REAL,
  estimated_time INTEGER,
  distance_km REAL
)
LANGUAGE plpgsql
AS $$
BEGIN
  -- Si aucune zone spécifique n'est trouvée, retourner une zone par défaut
  IF NOT EXISTS (SELECT 1 FROM public.delivery_zones WHERE is_active = true) THEN
    RETURN QUERY SELECT 
      'Grand-Bassam'::TEXT,
      1000::REAL,
      25::INTEGER,
      0::REAL;
    RETURN;
  END IF;
  
  -- Trouver la zone de livraison appropriée
  RETURN QUERY
  SELECT 
    dz.name,
    dz.base_fee,
    dz.estimated_time_minutes,
    COALESCE(
      (SELECT MIN(calculate_distance_km(target_lat, target_lon, dl.latitude, dl.longitude))
       FROM public.delivery_locations dl 
       WHERE dl.is_active = true), 
      0
    ) as distance_km
  FROM public.delivery_zones dz
  WHERE dz.is_active = true
  ORDER BY dz.base_fee
  LIMIT 1;
END;
$$;

-- Insérer des données de base si les tables sont vides
DO $$
BEGIN
    -- Insérer une zone de livraison par défaut si aucune n'existe
    IF NOT EXISTS (SELECT 1 FROM public.delivery_zones) THEN
        INSERT INTO public.delivery_zones (name, base_fee, max_distance_km, estimated_time_minutes, color_code) 
        VALUES ('Grand-Bassam Centre', 1000, 10, 25, '#3B82F6');
    END IF;

    -- Insérer quelques locations de base pour Grand-Bassam si aucune n'existe
    IF NOT EXISTS (SELECT 1 FROM public.delivery_locations) THEN
        INSERT INTO public.delivery_locations (name, district, zone_type, latitude, longitude, delivery_fee, estimated_delivery_time) VALUES
        ('Centre-ville', 'Grand-Bassam', 'zone_commerciale', 5.2091, -3.7386, 1000, 25),
        ('Quartier France', 'Grand-Bassam', 'quartier', 5.2150, -3.7400, 1200, 30),
        ('Plage', 'Grand-Bassam', 'lieu_public', 5.2000, -3.7350, 1500, 35),
        ('Zone Industrielle', 'Grand-Bassam', 'zone_industrielle', 5.2200, -3.7500, 2000, 40);
    END IF;
END $$;

-- Activer RLS si ce n'est pas déjà fait
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'delivery_locations') THEN
        ALTER TABLE public.delivery_locations ENABLE ROW LEVEL SECURITY;
        CREATE POLICY "Anyone can view delivery locations" 
        ON public.delivery_locations 
        FOR SELECT 
        USING (true);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'delivery_zones') THEN
        ALTER TABLE public.delivery_zones ENABLE ROW LEVEL SECURITY;
        CREATE POLICY "Anyone can view delivery zones" 
        ON public.delivery_zones 
        FOR SELECT 
        USING (true);
    END IF;
END $$;



