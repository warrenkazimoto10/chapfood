-- Activer RLS sur la table order_driver_assignments et créer les politiques nécessaires
ALTER TABLE public.order_driver_assignments ENABLE ROW LEVEL SECURITY;

-- Seuls les admins peuvent voir et gérer les assignations
CREATE POLICY "Admin can manage order driver assignments" 
ON public.order_driver_assignments 
FOR ALL 
USING (true);