import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';
import { Settings, DollarSign, Lock } from 'lucide-react';

interface CashierSettingsProps {
  isOpen: boolean;
  onClose: () => void;
}

const CashierSettings: React.FC<CashierSettingsProps> = ({ isOpen, onClose }) => {
  const { toast } = useToast();
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [settings, setSettings] = useState({
    default_delivery_fee: '2000',
    default_password: '123456789'
  });

  useEffect(() => {
    if (isOpen) {
      loadSettings();
    }
  }, [isOpen]);

  const loadSettings = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('cashier_settings')
        .select('*');

      if (error) throw error;

      const settingsMap: { [key: string]: string } = {};
      data?.forEach(setting => {
        settingsMap[setting.setting_key] = setting.setting_value;
      });

      setSettings({
        default_delivery_fee: settingsMap['default_delivery_fee'] || '2000',
        default_password: settingsMap['default_password'] || '123456789'
      });
    } catch (error) {
      console.error('Erreur lors du chargement des paramètres:', error);
      toast({
        title: "Erreur",
        description: "Impossible de charger les paramètres",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const saveSettings = async () => {
    try {
      setSaving(true);

      // Mettre à jour chaque paramètre
      for (const [key, value] of Object.entries(settings)) {
        const { error } = await supabase
          .from('cashier_settings')
          .upsert({
            setting_key: key,
            setting_value: value
          }, {
            onConflict: 'setting_key'
          });

        if (error) throw error;
      }

      toast({
        title: "Paramètres sauvegardés",
        description: "Les paramètres ont été mis à jour avec succès",
      });

      onClose();
    } catch (error) {
      console.error('Erreur lors de la sauvegarde:', error);
      toast({
        title: "Erreur",
        description: "Impossible de sauvegarder les paramètres",
        variant: "destructive",
      });
    } finally {
      setSaving(false);
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-2xl">
        <DialogHeader>
          <DialogTitle className="text-orange-700 flex items-center gap-2">
            <Settings className="h-6 w-6" />
            Paramètres de la Caisse
          </DialogTitle>
          <DialogDescription>
            Configurez les paramètres par défaut du système de caisse
          </DialogDescription>
        </DialogHeader>

        {loading ? (
          <div className="text-center py-12">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-orange-500 mx-auto"></div>
            <p className="text-gray-600 mt-4">Chargement des paramètres...</p>
          </div>
        ) : (
          <div className="space-y-6">
            <Card className="bg-gradient-to-br from-orange-50 to-red-50 border-orange-200">
              <CardHeader>
                <CardTitle className="text-orange-700 flex items-center gap-2">
                  <DollarSign className="h-5 w-5" />
                  Frais de Livraison
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-2">
                <Label htmlFor="delivery_fee" className="text-orange-700 font-medium">
                  Frais de livraison par défaut (FCFA)
                </Label>
                <Input
                  id="delivery_fee"
                  type="number"
                  value={settings.default_delivery_fee}
                  onChange={(e) => setSettings({ ...settings, default_delivery_fee: e.target.value })}
                  className="border-orange-300"
                  min={0}
                />
                <p className="text-xs text-gray-600">
                  Montant des frais de livraison pour les commandes à livrer
                </p>
              </CardContent>
            </Card>

            <Card className="bg-gradient-to-br from-blue-50 to-cyan-50 border-blue-200">
              <CardHeader>
                <CardTitle className="text-blue-700 flex items-center gap-2">
                  <Lock className="h-5 w-5" />
                  Nouveaux Clients
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-2">
                <Label htmlFor="default_password" className="text-blue-700 font-medium">
                  Mot de passe par défaut
                </Label>
                <Input
                  id="default_password"
                  type="text"
                  value={settings.default_password}
                  onChange={(e) => setSettings({ ...settings, default_password: e.target.value })}
                  className="border-blue-300"
                />
                <p className="text-xs text-gray-600">
                  Mot de passe attribué aux nouveaux clients créés via la caisse
                </p>
              </CardContent>
            </Card>

            <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
              <p className="text-sm text-yellow-800">
                <strong>Note :</strong> Ces paramètres s'appliquent immédiatement aux nouvelles commandes.
              </p>
            </div>

            <div className="flex gap-3 pt-4 border-t">
              <Button
                variant="outline"
                onClick={onClose}
                className="flex-1 border-orange-300 text-orange-600 hover:bg-orange-50"
              >
                Annuler
              </Button>
              <Button
                onClick={saveSettings}
                disabled={saving}
                className="flex-1 bg-gradient-to-r from-green-500 to-emerald-500 hover:from-green-600 hover:to-emerald-600 text-white"
              >
                {saving ? "Sauvegarde..." : "Sauvegarder"}
              </Button>
            </div>
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
};

export default CashierSettings;

