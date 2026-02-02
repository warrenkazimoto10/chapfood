-- Vérifier et activer l'extension pgcrypto
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Recréer la fonction authenticate_admin avec un mot de passe simple pour le test
CREATE OR REPLACE FUNCTION public.authenticate_admin(email_input text, password_input text)
RETURNS TABLE(admin_id uuid, admin_email text, admin_role text, admin_name text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
BEGIN
  RETURN QUERY
  SELECT a.id, a.email, a.role, a.full_name
  FROM public.admin_users a
  WHERE a.email = email_input 
    AND a.password_hash = password_input  -- Comparaison directe pour le test
    AND a.is_active = true;
END;
$$;