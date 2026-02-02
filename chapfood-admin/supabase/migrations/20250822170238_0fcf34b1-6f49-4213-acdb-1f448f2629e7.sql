-- Activer RLS sur la table carts_old 
ALTER TABLE public.carts_old ENABLE ROW LEVEL SECURITY;

-- Politique restrictive - cette table semble être obsolète donc on limite l'accès
CREATE POLICY "Restrict access to carts_old" 
ON public.carts_old 
FOR ALL 
USING (false);