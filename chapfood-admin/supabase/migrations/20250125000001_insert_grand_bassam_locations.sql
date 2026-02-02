-- Insertion des données des quartiers et zones de Grand-Bassam
-- Coordonnées GPS précises pour optimiser les livraisons

-- Zones de livraison de base
INSERT INTO public.delivery_zones (id, name, base_fee, max_distance_km, estimated_time_minutes, color_code) VALUES
('11111111-1111-1111-1111-111111111111', 'Centre Ville', 0, 3, 15, '#22C55E'),
('22222222-2222-2222-2222-222222222222', 'Zone Proche', 500, 5, 20, '#3B82F6'),
('33333333-3333-3333-3333-333333333333', 'Zone Moyenne', 1000, 8, 30, '#F59E0B'),
('44444444-4444-4444-4444-444444444444', 'Zone Éloignée', 1500, 12, 45, '#EF4444');

-- Quartiers principaux de Grand-Bassam
INSERT INTO public.delivery_locations (name, district, zone_type, latitude, longitude, delivery_fee, estimated_delivery_time, description) VALUES

-- QUARTIER FRANCE (Centre historique UNESCO)
('Quartier France', 'Centre', 'quartier', 5.2091, -3.7386, 0, 10, 'Quartier historique classé UNESCO avec maisons coloniales'),
('Place de la Liberté', 'Centre', 'lieu_public', 5.2095, -3.7388, 0, 10, 'Place principale du quartier France'),
('Rue du Commerce', 'Centre', 'quartier', 5.2089, -3.7384, 0, 10, 'Rue commerçante du centre historique'),
('Avenue 6', 'Centre', 'quartier', 5.2093, -3.7390, 0, 10, 'Avenue principale du quartier France'),

-- QUARTIER IMPÉRIAL
('Quartier Impérial', 'Centre', 'quartier', 5.2075, -3.7402, 0, 12, 'Quartier résidentiel et administratif'),
('Rue des Écoles', 'Centre', 'quartier', 5.2078, -3.7405, 0, 12, 'Zone scolaire et résidentielle'),
('Avenue de la République', 'Centre', 'quartier', 5.2072, -3.7400, 0, 12, 'Avenue principale du quartier Impérial'),

-- QUARTIER PETIT-PARIS
('Quartier Petit-Paris', 'Centre', 'quartier', 5.2110, -3.7350, 0, 15, 'Quartier résidentiel avec ancien phare'),
('Rue du Phare', 'Centre', 'quartier', 5.2113, -3.7353, 0, 15, 'Rue menant à l''ancien phare'),
('Zone Résidentielle Petit-Paris', 'Centre', 'zone_residentielle', 5.2107, -3.7347, 0, 15, 'Zone résidentielle calme'),

-- QUARTIER COMMERCIAL
('Marché Central', 'Centre', 'zone_commerciale', 5.2080, -3.7420, 0, 8, 'Grand marché central de Grand-Bassam'),
('Rue du Marché', 'Centre', 'quartier', 5.2083, -3.7423, 0, 8, 'Rue commerçante près du marché'),
('Zone Artisanale', 'Centre', 'zone_commerciale', 5.2077, -3.7417, 0, 8, 'Zone des artisans et commerçants'),

-- QUARTIERS RÉSIDENTIELS
('Quartier Résidentiel Nord', 'Nord', 'zone_residentielle', 5.2150, -3.7400, 500, 20, 'Zone résidentielle au nord de la ville'),
('Cité des Fonctionnaires', 'Nord', 'zone_residentielle', 5.2160, -3.7410, 500, 20, 'Cité résidentielle pour fonctionnaires'),
('Zone HLM', 'Nord', 'zone_residentielle', 5.2140, -3.7390, 500, 20, 'Zone d''habitations à loyer modéré'),

('Quartier Résidentiel Sud', 'Sud', 'zone_residentielle', 5.2020, -3.7350, 500, 18, 'Zone résidentielle au sud de la ville'),
('Cité Universitaire', 'Sud', 'zone_residentielle', 5.2010, -3.7340, 500, 18, 'Zone résidentielle étudiante'),
('Village Artisanal', 'Sud', 'zone_residentielle', 5.2030, -3.7360, 500, 18, 'Village des artisans'),

-- QUARTIERS PÉRIPHÉRIQUES
('Quartier Industriel', 'Est', 'zone_industrielle', 5.2100, -3.7200, 1000, 25, 'Zone industrielle et portuaire'),
('Zone Portuaire', 'Est', 'zone_industrielle', 5.2090, -3.7180, 1000, 25, 'Zone du port de Grand-Bassam'),
('Quartier des Pêcheurs', 'Est', 'quartier', 5.2110, -3.7220, 1000, 25, 'Village de pêcheurs traditionnel'),

('Quartier Ouest', 'Ouest', 'zone_residentielle', 5.2080, -3.7600, 1000, 30, 'Zone résidentielle à l''ouest'),
('Zone Agricole Ouest', 'Ouest', 'zone_residentielle', 5.2060, -3.7620, 1000, 30, 'Zone agricole et résidentielle'),

-- VILLAGES PÉRIPHÉRIQUES
('Village d''Assinie', 'Périphérie', 'village', 5.1800, -3.8000, 1500, 45, 'Village côtier à l''est'),
('Village de Bonoua', 'Périphérie', 'village', 5.2700, -3.6000, 1500, 40, 'Village au nord de Grand-Bassam'),
('Village d''Adiaké', 'Périphérie', 'village', 5.2200, -3.7800, 1500, 35, 'Village à l''ouest'),

-- ZONES SPÉCIALISÉES
('Zone Hôtelière', 'Centre', 'zone_commerciale', 5.2050, -3.7300, 0, 12, 'Zone des hôtels et résidences touristiques'),
('Plage de Grand-Bassam', 'Centre', 'lieu_public', 5.2040, -3.7290, 0, 15, 'Plage principale de la ville'),
('Zone Administrative', 'Centre', 'zone_commerciale', 5.2070, -3.7430, 0, 10, 'Zone des administrations publiques'),

-- QUARTIERS NOUVELLES EXTENSIONS
('Nouveau Quartier Nord', 'Nord', 'quartier', 5.2200, -3.7450, 500, 22, 'Extension résidentielle récente'),
('Cité Moderne', 'Nord', 'zone_residentielle', 5.2220, -3.7470, 500, 22, 'Cité moderne avec villas'),
('Zone d''Activité Nord', 'Nord', 'zone_commerciale', 5.2180, -3.7430, 500, 20, 'Zone d''activités commerciales'),

('Extension Sud', 'Sud', 'quartier', 5.1950, -3.7400, 800, 25, 'Extension résidentielle au sud'),
('Zone Résidentielle Moderne', 'Sud', 'zone_residentielle', 5.1930, -3.7380, 800, 25, 'Zone résidentielle moderne'),
('Quartier des Employés', 'Sud', 'zone_residentielle', 5.1970, -3.7420, 800, 25, 'Quartier des employés et cadres');

-- Liaison des locations avec les zones de livraison
INSERT INTO public.location_delivery_zones (location_id, zone_id) 
SELECT dl.id, '11111111-1111-1111-1111-111111111111' -- Centre Ville
FROM public.delivery_locations dl 
WHERE dl.district = 'Centre' AND dl.delivery_fee = 0;

INSERT INTO public.location_delivery_zones (location_id, zone_id) 
SELECT dl.id, '22222222-2222-2222-2222-222222222222' -- Zone Proche
FROM public.delivery_locations dl 
WHERE dl.delivery_fee = 500;

INSERT INTO public.location_delivery_zones (location_id, zone_id) 
SELECT dl.id, '33333333-3333-3333-3333-333333333333' -- Zone Moyenne
FROM public.delivery_locations dl 
WHERE dl.delivery_fee = 1000;

INSERT INTO public.location_delivery_zones (location_id, zone_id) 
SELECT dl.id, '44444444-4444-4444-4444-444444444444' -- Zone Éloignée
FROM public.delivery_locations dl 
WHERE dl.delivery_fee = 1500;

-- Points de repère importants (landmarks)
INSERT INTO public.landmarks (name, landmark_type, address, latitude, longitude, delivery_location_id, description) VALUES

-- HÔTELS
('Hotel Etoile du Sud', 'hotel', 'Quartier France', 5.2095, -3.7385, 
 (SELECT id FROM delivery_locations WHERE name = 'Quartier France' LIMIT 1),
 'Hôtel 3 étoiles dans le centre historique'),
('Hotel Ivoire', 'hotel', 'Zone Hôtelière', 5.2052, -3.7302,
 (SELECT id FROM delivery_locations WHERE name = 'Zone Hôtelière' LIMIT 1),
 'Hôtel de luxe face à la plage'),
('Hotel Les Cocotiers', 'hotel', 'Quartier Petit-Paris', 5.2112, -3.7352,
 (SELECT id FROM delivery_locations WHERE name = 'Quartier Petit-Paris' LIMIT 1),
 'Hôtel familial avec piscine'),

-- RESTAURANTS
('Restaurant Le Phare', 'restaurant', 'Quartier Petit-Paris', 5.2111, -3.7351,
 (SELECT id FROM delivery_locations WHERE name = 'Quartier Petit-Paris' LIMIT 1),
 'Restaurant avec vue sur mer'),
('Restaurant Le Colonial', 'restaurant', 'Quartier France', 5.2093, -3.7387,
 (SELECT id FROM delivery_locations WHERE name = 'Quartier France' LIMIT 1),
 'Restaurant dans maison coloniale'),
('Maquis Chez Tonton', 'restaurant', 'Marché Central', 5.2082, -3.7422,
 (SELECT id FROM delivery_locations WHERE name = 'Marché Central' LIMIT 1),
 'Maquis populaire près du marché'),

-- BANQUES
('Banque Atlantique', 'banque', 'Zone Administrative', 5.2072, -3.7432,
 (SELECT id FROM delivery_locations WHERE name = 'Zone Administrative' LIMIT 1),
 'Agence bancaire principale'),
('SGBCI', 'banque', 'Avenue de la République', 5.2074, -3.7402,
 (SELECT id FROM delivery_locations WHERE name = 'Avenue de la République' LIMIT 1),
 'Agence Société Générale'),
('Banque Populaire', 'banque', 'Rue du Commerce', 5.2091, -3.7386,
 (SELECT id FROM delivery_locations WHERE name = 'Rue du Commerce' LIMIT 1),
 'Agence Banque Populaire'),

-- PHARMACIES
('Pharmacie du Centre', 'pharmacie', 'Quartier France', 5.2090, -3.7388,
 (SELECT id FROM delivery_locations WHERE name = 'Quartier France' LIMIT 1),
 'Pharmacie principale du centre'),
('Pharmacie de la Plage', 'pharmacie', 'Zone Hôtelière', 5.2048, -3.7298,
 (SELECT id FROM delivery_locations WHERE name = 'Zone Hôtelière' LIMIT 1),
 'Pharmacie près de la plage'),
('Pharmacie du Marché', 'pharmacie', 'Marché Central', 5.2084, -3.7424,
 (SELECT id FROM delivery_locations WHERE name = 'Marché Central' LIMIT 1),
 'Pharmacie près du marché'),

-- ÉCOLES
('École Primaire Publique', 'ecole', 'Rue des Écoles', 5.2080, -3.7407,
 (SELECT id FROM delivery_locations WHERE name = 'Rue des Écoles' LIMIT 1),
 'École primaire publique principale'),
('Lycée Moderne', 'ecole', 'Quartier Impérial', 5.2076, -3.7404,
 (SELECT id FROM delivery_locations WHERE name = 'Quartier Impérial' LIMIT 1),
 'Lycée d''enseignement secondaire'),
('École Privée Les Palmiers', 'ecole', 'Zone Résidentielle Sud', 5.2022, -3.7352,
 (SELECT id FROM delivery_locations WHERE name = 'Quartier Résidentiel Sud' LIMIT 1),
 'École privée primaire et secondaire'),

-- LIEUX DE CULTE
('Église Notre-Dame', 'eglise', 'Quartier France', 5.2092, -3.7389,
 (SELECT id FROM delivery_locations WHERE name = 'Quartier France' LIMIT 1),
 'Église catholique historique'),
('Mosquée Centrale', 'mosquee', 'Quartier Impérial', 5.2073, -3.7401,
 (SELECT id FROM delivery_locations WHERE name = 'Quartier Impérial' LIMIT 1),
 'Mosquée principale de la ville'),
('Temple Protestant', 'eglise', 'Rue du Commerce', 5.2088, -3.7385,
 (SELECT id FROM delivery_locations WHERE name = 'Rue du Commerce' LIMIT 1),
 'Temple protestant'),

-- STATIONS SERVICE
('Station Total', 'station_service', 'Avenue de la République', 5.2071, -3.7399,
 (SELECT id FROM delivery_locations WHERE name = 'Avenue de la République' LIMIT 1),
 'Station-service Total'),
('Station Shell', 'station_service', 'Zone Portuaire', 5.2092, -3.7182,
 (SELECT id FROM delivery_locations WHERE name = 'Zone Portuaire' LIMIT 1),
 'Station-service Shell'),
('Station Petro-Ivoire', 'station_service', 'Quartier Industriel', 5.2102, -3.7202,
 (SELECT id FROM delivery_locations WHERE name = 'Quartier Industriel' LIMIT 1),
 'Station-service Petro-Ivoire'),

-- BUREAUX
('Mairie de Grand-Bassam', 'bureau', 'Zone Administrative', 5.2071, -3.7431,
 (SELECT id FROM delivery_locations WHERE name = 'Zone Administrative' LIMIT 1),
 'Hôtel de ville'),
('Préfecture', 'bureau', 'Zone Administrative', 5.2073, -3.7433,
 (SELECT id FROM delivery_locations WHERE name = 'Zone Administrative' LIMIT 1),
 'Préfecture du département'),
('Poste Centrale', 'bureau', 'Quartier France', 5.2094, -3.7388,
 (SELECT id FROM delivery_locations WHERE name = 'Quartier France' LIMIT 1),
 'Bureau de poste principal');

-- Commentaires pour documentation
COMMENT ON TABLE public.delivery_locations IS 'Base de données des quartiers et zones de Grand-Bassam avec coordonnées GPS';
COMMENT ON TABLE public.landmarks IS 'Points de repère importants pour faciliter les livraisons';
COMMENT ON TABLE public.delivery_zones IS 'Zones de livraison avec tarifs et temps estimés';
COMMENT ON FUNCTION calculate_distance_km IS 'Calcule la distance entre deux points GPS en kilomètres';
COMMENT ON FUNCTION find_nearest_locations IS 'Trouve les locations les plus proches d''un point GPS';
COMMENT ON FUNCTION get_delivery_fee IS 'Calcule les frais de livraison selon la zone';




