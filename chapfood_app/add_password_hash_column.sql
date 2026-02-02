-- Script pour ajouter la colonne password_hash à la table users
-- Exécuter ce script dans Supabase SQL Editor

-- Vérifier si la colonne password_hash existe déjà et l'ajouter si nécessaire
DO $$ 
BEGIN
    -- Ajouter la colonne password_hash si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public'
        AND table_name = 'users' 
        AND column_name = 'password_hash'
    ) THEN
        ALTER TABLE public.users ADD COLUMN password_hash TEXT;
        RAISE NOTICE '✅ Colonne password_hash ajoutée à la table users';
    ELSE
        RAISE NOTICE 'ℹ️ La colonne password_hash existe déjà dans la table users';
    END IF;
END $$;

-- Afficher la structure de la table users pour vérification
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_schema = 'public'
AND table_name = 'users' 
ORDER BY ordinal_position;
