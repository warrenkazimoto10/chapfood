-- Désactiver les règles RLS sur les tables de catégories et d'articles du menu
-- Permettre aux administrateurs et au personnel de cuisine de gérer librement ces tables

-- Désactiver RLS sur la table categories
ALTER TABLE public.categories DISABLE ROW LEVEL SECURITY;

-- Désactiver RLS sur la table menu_items
ALTER TABLE public.menu_items DISABLE ROW LEVEL SECURITY;

-- Désactiver RLS sur la table supplements (garnitures et autres)
ALTER TABLE public.supplements DISABLE ROW LEVEL SECURITY;

-- Désactiver RLS sur la table menu_item_supplements (relation entre articles et garnitures)
ALTER TABLE public.menu_item_supplements DISABLE ROW LEVEL SECURITY;

-- Créer une fonction pour vérifier le rôle de l'utilisateur admin
CREATE OR REPLACE FUNCTION public.is_admin_user(user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.admin_users 
    WHERE id = user_id 
    AND is_active = true 
    AND role IN ('admin_general', 'cuisine')
  );
END;
$$;

-- Créer une fonction pour vérifier si l'utilisateur peut gérer le stock
CREATE OR REPLACE FUNCTION public.can_manage_stock(user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN public.is_admin_user(user_id);
END;
$$;

-- Commentaire sur la sécurité
COMMENT ON FUNCTION public.is_admin_user(UUID) IS 'Vérifie si un utilisateur a un rôle admin ou cuisine';
COMMENT ON FUNCTION public.can_manage_stock(UUID) IS 'Vérifie si un utilisateur peut gérer le stock (catégories, articles, garnitures)';
