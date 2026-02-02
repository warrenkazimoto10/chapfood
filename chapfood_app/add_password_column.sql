-- Script pour ajouter la colonne password à la table users et s'assurer que l'ID est au format UUID
-- Exécuter ce script dans votre base de données Supabase

-- Vérifier si la colonne password existe déjà
DO $$ 
BEGIN
    -- Ajouter la colonne password si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND column_name = 'password'
    ) THEN
        ALTER TABLE users ADD COLUMN password TEXT;
        RAISE NOTICE 'Colonne password ajoutée à la table users';
    ELSE
        RAISE NOTICE 'La colonne password existe déjà dans la table users';
    END IF;
END $$;

-- S'assurer que la colonne ID accepte les UUID (si ce n'est pas déjà le cas)
DO $$
BEGIN
    -- Vérifier le type de la colonne ID
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND column_name = 'id'
        AND data_type = 'text'
    ) THEN
        RAISE NOTICE 'La colonne ID est déjà au format TEXT (compatible UUID)';
    ELSIF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND column_name = 'id'
        AND data_type = 'uuid'
    ) THEN
        RAISE NOTICE 'La colonne ID est déjà au format UUID';
    ELSE
        -- Modifier la colonne ID pour accepter les UUID
        ALTER TABLE users ALTER COLUMN id TYPE TEXT;
        RAISE NOTICE 'Colonne ID modifiée pour accepter les UUID (format TEXT)';
    END IF;
END $$;

-- Ajouter des contraintes si nécessaire
-- ALTER TABLE users ADD CONSTRAINT users_password_not_empty CHECK (password IS NOT NULL AND password != '');

-- Mettre à jour les utilisateurs existants avec un mot de passe par défaut (optionnel)
-- UPDATE users SET password = 'password123' WHERE password IS NULL;

-- Afficher la structure de la table users
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'users' 
ORDER BY ordinal_position;
