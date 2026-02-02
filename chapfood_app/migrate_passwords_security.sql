-- ============================================================================
-- Migration Sécurité: Hachage des Mots de Passe
-- ============================================================================
-- Ce script migre les mots de passe en clair vers des mots de passe hachés
-- ATTENTION: À exécuter une seule fois en production
-- ============================================================================

-- 1. Ajouter la colonne password_hash si elle n'existe pas
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users'
    AND column_name = 'password_hash'
  ) THEN
    ALTER TABLE users ADD COLUMN password_hash VARCHAR(255);
    RAISE NOTICE 'Colonne password_hash ajoutée à la table users';
  ELSE
    RAISE NOTICE 'Colonne password_hash existe déjà';
  END IF;
END $$;

-- 2. Pour la table drivers
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'drivers'
    AND column_name = 'password_hash'
  ) THEN
    ALTER TABLE drivers ADD COLUMN password_hash VARCHAR(255);
    RAISE NOTICE 'Colonne password_hash ajoutée à la table drivers';
  ELSE
    RAISE NOTICE 'Colonne password_hash existe déjà';
  END IF;
END $$;

-- 3. Créer une fonction PostgreSQL pour hacher les mots de passe
-- NOTE: En production, utiliser une vraie fonction de hachage (pgcrypto)
CREATE OR REPLACE FUNCTION hash_password(password TEXT, salt TEXT)
RETURNS TEXT AS $$
BEGIN
  -- Utilisation de pgcrypto pour un vrai hachage
  -- Nécessite l'extension pgcrypto
  RETURN salt || ':' || encode(digest(password || salt, 'sha256'), 'hex');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Activer l'extension pgcrypto si pas déjà fait
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 5. Fonction pour générer un salt aléatoire
CREATE OR REPLACE FUNCTION generate_salt()
RETURNS TEXT AS $$
BEGIN
  RETURN encode(gen_random_bytes(8), 'hex');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Migrer les mots de passe existants (ATTENTION: ne pas exécuter plusieurs fois)
-- Pour la table users
DO $$
DECLARE
  user_record RECORD;
  new_salt TEXT;
  new_hash TEXT;
BEGIN
  FOR user_record IN 
    SELECT id, password 
    FROM users 
    WHERE password IS NOT NULL 
    AND (password_hash IS NULL OR password_hash = '')
  LOOP
    new_salt := generate_salt();
    new_hash := hash_password(user_record.password, new_salt);
    
    UPDATE users 
    SET password_hash = new_hash
    WHERE id = user_record.id;
    
    RAISE NOTICE 'Mot de passe migré pour user ID: %', user_record.id;
  END LOOP;
END $$;

-- 7. Migrer les mots de passe pour les drivers
DO $$
DECLARE
  driver_record RECORD;
  new_salt TEXT;
  new_hash TEXT;
BEGIN
  FOR driver_record IN 
    SELECT id, password 
    FROM drivers 
    WHERE password IS NOT NULL 
    AND (password_hash IS NULL OR password_hash = '')
  LOOP
    new_salt := generate_salt();
    new_hash := hash_password(driver_record.password, new_salt);
    
    UPDATE drivers 
    SET password_hash = new_hash
    WHERE id = driver_record.id;
    
    RAISE NOTICE 'Mot de passe migré pour driver ID: %', driver_record.id;
  END LOOP;
END $$;

-- 8. Après migration et tests, supprimer la colonne password (ATTENTION: sauvegarde avant!)
-- NE PAS EXÉCUTER IMMÉDIATEMENT - Attendre validation complète
/*
ALTER TABLE users DROP COLUMN IF EXISTS password;
ALTER TABLE drivers DROP COLUMN IF EXISTS password;
*/

-- 9. Créer une fonction RPC pour vérifier un mot de passe
CREATE OR REPLACE FUNCTION verify_password(
  input_password TEXT,
  stored_hash TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  salt TEXT;
  expected_hash TEXT;
BEGIN
  -- Extraire le salt du hash stocké
  salt := split_part(stored_hash, ':', 1);
  
  -- Recalculer le hash avec le mot de passe fourni
  expected_hash := hash_password(input_password, salt);
  
  -- Comparer les hashs
  RETURN expected_hash = stored_hash;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Vérifier la migration
SELECT 
  'users' as table_name,
  COUNT(*) as total,
  COUNT(*) FILTER (WHERE password_hash IS NOT NULL) as migrated,
  COUNT(*) FILTER (WHERE password IS NOT NULL) as with_plaintext
FROM users

UNION ALL

SELECT 
  'drivers' as table_name,
  COUNT(*) as total,
  COUNT(*) FILTER (WHERE password_hash IS NOT NULL) as migrated,
  COUNT(*) FILTER (WHERE password IS NOT NULL) as with_plaintext
FROM drivers;

-- ============================================================================
-- Résumé:
-- - Colonnes password_hash ajoutées
-- - Fonctions hash_password, generate_salt, verify_password créées
-- - Mots de passe existants migrés
-- - Colonnes password à supprimer après validation complète
-- ============================================================================


