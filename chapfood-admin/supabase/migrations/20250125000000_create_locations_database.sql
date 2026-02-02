-- Création de la base de données des quartiers et zones de Grand-Bassam
-- Système de géolocalisation pour optimiser les livraisons

-- Table des zones/quartiers de Grand-Bassam
CREATE TABLE public.delivery_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  district TEXT NOT NULL,
  zone_type TEXT NOT NULL CHECK (zone_type IN ('quartier', 'zone_commerciale', 'zone_residentielle', 'zone_industrielle', 'village', 'lieu_public')),
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  postal_code TEXT,
  delivery_fee REAL DEFAULT 0,
  estimated_delivery_time INTEGER DEFAULT 15, -- en minutes
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

-- Table des points de repère (landmarks) importants
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

-- Index pour les landmarks
CREATE INDEX idx_landmarks_coordinates ON public.landmarks (latitude, longitude);
CREATE INDEX idx_landmarks_type ON public.landmarks (landmark_type);
CREATE INDEX idx_landmarks_location ON public.landmarks (delivery_location_id);

-- Table des zones de livraison (pour calcul des frais)
CREATE TABLE public.delivery_zones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  base_fee REAL NOT NULL DEFAULT 0,
  max_distance_km REAL DEFAULT 5,
  estimated_time_minutes INTEGER DEFAULT 20,
  color_code TEXT DEFAULT '#3B82F6', -- couleur pour l'affichage sur carte
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table de liaison entre locations et zones de livraison
CREATE TABLE public.location_delivery_zones (
  location_id UUID REFERENCES public.delivery_locations(id) ON DELETE CASCADE,
  zone_id UUID REFERENCES public.delivery_zones(id) ON DELETE CASCADE,
  PRIMARY KEY (location_id, zone_id)
);

-- Activer RLS
ALTER TABLE public.delivery_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.landmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.location_delivery_zones ENABLE ROW LEVEL SECURITY;

-- Politiques RLS - Lecture publique pour les locations
CREATE POLICY "Anyone can view delivery locations" 
ON public.delivery_locations 
FOR SELECT 
USING (true);

CREATE POLICY "Anyone can view landmarks" 
ON public.landmarks 
FOR SELECT 
USING (true);

CREATE POLICY "Anyone can view delivery zones" 
ON public.delivery_zones 
FOR SELECT 
USING (true);

CREATE POLICY "Anyone can view location zones" 
ON public.location_delivery_zones 
FOR SELECT 
USING (true);

-- Politiques pour les admins (gestion complète)
CREATE POLICY "Admin can manage delivery locations" 
ON public.delivery_locations 
FOR ALL 
USING (true);

CREATE POLICY "Admin can manage landmarks" 
ON public.landmarks 
FOR ALL 
USING (true);

CREATE POLICY "Admin can manage delivery zones" 
ON public.delivery_zones 
FOR ALL 
USING (true);

CREATE POLICY "Admin can manage location zones" 
ON public.location_delivery_zones 
FOR ALL 
USING (true);

-- Triggers pour updated_at
CREATE TRIGGER update_delivery_locations_updated_at
BEFORE UPDATE ON public.delivery_locations
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_landmarks_updated_at
BEFORE UPDATE ON public.landmarks
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_delivery_zones_updated_at
BEFORE UPDATE ON public.delivery_zones
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Fonction pour calculer la distance entre deux points GPS
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

-- Fonction pour trouver les locations les plus proches
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

-- Fonction pour obtenir les frais de livraison selon la zone
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
  RETURN QUERY
  SELECT 
    dz.name,
    dz.base_fee,
    dz.estimated_time_minutes,
    calculate_distance_km(target_lat, target_lon, dl.latitude, dl.longitude) as distance_km
  FROM public.delivery_locations dl
  JOIN public.location_delivery_zones ldz ON dl.id = ldz.location_id
  JOIN public.delivery_zones dz ON ldz.zone_id = dz.id
  WHERE dl.is_active = true 
    AND dz.is_active = true
    AND calculate_distance_km(target_lat, target_lon, dl.latitude, dl.longitude) <= dz.max_distance_km
  ORDER BY distance_km
  LIMIT 1;
END;
$$;

-- Activer realtime pour les locations
ALTER PUBLICATION supabase_realtime ADD TABLE public.delivery_locations;
ALTER PUBLICATION supabase_realtime ADD TABLE public.landmarks;
ALTER PUBLICATION supabase_realtime ADD TABLE public.delivery_zones;




