-- Table pour les livreurs
CREATE TABLE public.drivers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(15) NOT NULL UNIQUE,
    photo_url VARCHAR(255),
    is_available BOOLEAN DEFAULT true,
    current_lat DECIMAL(10, 8),
    current_lng DECIMAL(11, 8),
    last_location_update TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour optimiser les requêtes
CREATE INDEX idx_drivers_available ON public.drivers (is_available);
CREATE INDEX idx_drivers_location ON public.drivers (current_lat, current_lng);

-- Trigger pour mettre à jour updated_at
CREATE TRIGGER update_drivers_updated_at
    BEFORE UPDATE ON public.drivers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Exemple de données de test
INSERT INTO public.drivers (name, phone, photo_url, is_available, current_lat, current_lng) VALUES
('Jean Kouassi', '+225 07 77 39 33 56', 'https://via.placeholder.com/150', true, 5.206313, -3.741129),
('Marie Traoré', '+225 07 88 44 55 66', 'https://via.placeholder.com/150', true, 5.207000, -3.742000),
('Kouame N\'Guessan', '+225 07 99 55 77 88', 'https://via.placeholder.com/150', false, 5.208000, -3.743000);

-- Mise à jour des statuts de commande existants
-- Remplacer les anciens statuts par les nouveaux
UPDATE public.orders 
SET status = CASE 
    WHEN status = 'preparing' THEN 'ready_for_delivery'
    WHEN status = 'ready' THEN 'in_transit'
    ELSE status
END
WHERE status IN ('preparing', 'ready');


