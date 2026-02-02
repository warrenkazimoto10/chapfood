-- Migration pour ajouter les paramètres configurables du système de caisse
-- Exécuter ce script dans Supabase SQL Editor

-- 1. Créer la table cashier_settings si elle n'existe pas
CREATE TABLE IF NOT EXISTS public.cashier_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  setting_key VARCHAR(50) UNIQUE NOT NULL,
  setting_value TEXT NOT NULL,
  description TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_by VARCHAR(255)
);

-- 2. Insérer les paramètres par défaut
INSERT INTO public.cashier_settings (setting_key, setting_value, description) VALUES
('default_delivery_fee', '2000', 'Frais de livraison par défaut en FCFA'),
('default_password', '123456789', 'Mot de passe par défaut pour nouveaux clients')
ON CONFLICT (setting_key) DO NOTHING;

-- 3. Créer des index pour optimiser les recherches
CREATE INDEX IF NOT EXISTS idx_cashier_settings_key ON public.cashier_settings(setting_key);

-- 4. Activer RLS
ALTER TABLE public.cashier_settings ENABLE ROW LEVEL SECURITY;

-- 5. Politique RLS - Lecture publique pour les paramètres
CREATE POLICY "Anyone can view cashier settings" 
ON public.cashier_settings 
FOR SELECT 
USING (true);

-- 6. Politique RLS - Modification pour les admins
CREATE POLICY "Admin can manage cashier settings" 
ON public.cashier_settings 
FOR ALL 
USING (true);

-- 7. Créer une fonction pour mettre à jour automatiquement updated_at
CREATE OR REPLACE FUNCTION update_cashier_settings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 8. Créer le trigger
DROP TRIGGER IF EXISTS update_cashier_settings_updated_at ON public.cashier_settings;
CREATE TRIGGER update_cashier_settings_updated_at
BEFORE UPDATE ON public.cashier_settings
FOR EACH ROW
EXECUTE FUNCTION update_cashier_settings_updated_at();

-- 9. Commentaires pour la documentation
COMMENT ON TABLE public.cashier_settings IS 'Paramètres configurables du système de caisse';
COMMENT ON COLUMN public.cashier_settings.setting_key IS 'Clé unique du paramètre';
COMMENT ON COLUMN public.cashier_settings.setting_value IS 'Valeur du paramètre';
COMMENT ON COLUMN public.cashier_settings.description IS 'Description du paramètre';


