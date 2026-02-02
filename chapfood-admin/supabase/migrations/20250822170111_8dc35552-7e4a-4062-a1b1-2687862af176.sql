-- Insérer directement un administrateur avec un mot de passe hashé simple
INSERT INTO public.admin_users (email, password_hash, role, full_name, is_active)
VALUES (
  'admin@chapfood.com',
  'admin123',  -- Pour simplifier, on utilise le mot de passe en clair temporairement
  'admin_general',
  'Administrateur ChapFood',
  true
)
ON CONFLICT (email) DO NOTHING;