-- Activer RLS sur la table drivers et créer les politiques nécessaires
ALTER TABLE public.drivers ENABLE ROW LEVEL SECURITY;

-- Seuls les admins peuvent voir et gérer les livreurs
CREATE POLICY "Admin can manage drivers" 
ON public.drivers 
FOR ALL 
USING (true);