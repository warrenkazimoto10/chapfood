-- Script pour corriger l'ID utilisateur existant
-- Remplace l'ancien ID personnalisé par un UUID valide

-- 1. Mettre à jour l'ID de l'utilisateur existant
UPDATE users 
SET id = '550e8400-e29b-41d4-a716-446655440000'::uuid
WHERE id = 'user_1758578078690_6783';

-- 2. Vérifier que la mise à jour a fonctionné
SELECT id, email, full_name, phone 
FROM users 
WHERE email = 'angedesirecamara@gmail.com';

-- 3. Si vous avez des commandes existantes avec l'ancien ID, les mettre à jour aussi
-- UPDATE orders 
-- SET user_id = '550e8400-e29b-41d4-a716-446655440000'::uuid
-- WHERE user_id = 'user_1758578078690_6783';
