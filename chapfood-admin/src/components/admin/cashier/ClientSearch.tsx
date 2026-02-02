import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';
import { 
  Search, 
  UserPlus, 
  Users, 
  Phone, 
  Mail, 
  MapPin,
  User,
  Plus
} from 'lucide-react';

interface Client {
  id: string;
  full_name: string;
  phone: string;
  email?: string;
  address?: string;
  is_active: boolean;
  created_at: string;
}

interface ClientSearchProps {
  onClientSelected: (client: Client) => void;
  onClientCreated: (client: Client) => void;
}

const ClientSearch: React.FC<ClientSearchProps> = ({ onClientSelected, onClientCreated }) => {
  const { toast } = useToast();
  const [searchTerm, setSearchTerm] = useState('');
  const [clients, setClients] = useState<Client[]>([]);
  const [loading, setLoading] = useState(false);
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [createLoading, setCreateLoading] = useState(false);
  
  // Formulaire de création
  const [formData, setFormData] = useState({
    full_name: '',
    phone: '',
    email: '',
    address: '',
    is_active: true
  });

  // Recherche de clients
  const searchClients = async () => {
    if (!searchTerm.trim()) {
      setClients([]);
      return;
    }

    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('users')
        .select('*')
        .or(`full_name.ilike.%${searchTerm}%,phone.ilike.%${searchTerm}%`)
        .eq('is_active', true)
        .limit(10);

      if (error) throw error;
      setClients(data || []);
    } catch (error) {
      console.error('Erreur lors de la recherche:', error);
      toast({
        title: "Erreur",
        description: "Impossible de rechercher les clients",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const timer = setTimeout(searchClients, 300);
    return () => clearTimeout(timer);
  }, [searchTerm]);

  const handleCreateClient = async () => {
    try {
      // Validation des champs obligatoires
      if (!formData.full_name.trim() || !formData.phone.trim()) {
        toast({
          title: "Erreur",
          description: "Le nom et le téléphone sont obligatoires",
          variant: "destructive",
        });
        return;
      }

      setCreateLoading(true);

      // Préparer les données pour l'insertion
      const userData: any = {
        id: crypto.randomUUID(),
        full_name: formData.full_name.trim(),
        phone: formData.phone.trim(),
        password: '123456789', // Mot de passe par défaut
        is_active: formData.is_active
      };

      // Ajouter les champs optionnels seulement s'ils ne sont pas vides
      if (formData.email.trim()) {
        userData.email = formData.email.trim();
      }
      if (formData.address.trim()) {
        userData.address = formData.address.trim();
      }

      const { data, error } = await supabase
        .from('users')
        .insert([userData])
        .select()
        .single();

      if (error) {
        console.error('Supabase error:', error);
        throw error;
      }

      toast({
        title: "Succès",
        description: `Client "${formData.full_name}" créé avec succès`,
      });

      onClientCreated(data);
      setIsCreateModalOpen(false);
      setFormData({
        full_name: '',
        email: '',
        phone: '',
        address: '',
        is_active: true
      });
    } catch (error: any) {
      console.error('Error creating user:', error);
      toast({
        title: "Erreur",
        description: error.message || "Impossible de créer le client",
        variant: "destructive",
      });
    } finally {
      setCreateLoading(false);
    }
  };

  const formatPhone = (phone: string) => {
    // Formater le numéro de téléphone pour l'affichage
    if (phone.startsWith('+225')) {
      return phone.replace('+225', '0');
    }
    return phone;
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <Card className="bg-white/90 backdrop-blur-sm border-orange-200 shadow-lg">
        <CardHeader className="bg-gradient-to-r from-orange-50 to-red-50 border-b border-orange-200">
          <CardTitle className="text-orange-700 flex items-center gap-2">
            <Search className="h-6 w-6" />
            Recherche Client
          </CardTitle>
        </CardHeader>
        <CardContent className="p-6">
          <div className="space-y-4">
            <div className="flex gap-4">
              <div className="flex-1">
                <Input
                  placeholder="Rechercher par nom ou téléphone..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="border-orange-300 focus:border-orange-500"
                />
              </div>
              <Dialog open={isCreateModalOpen} onOpenChange={setIsCreateModalOpen}>
                <DialogTrigger asChild>
                  <Button className="bg-gradient-to-r from-green-500 to-emerald-500 hover:from-green-600 hover:to-emerald-600 text-white">
                    <UserPlus className="h-4 w-4 mr-2" />
                    Nouveau Client
                  </Button>
                </DialogTrigger>
                <DialogContent className="bg-gradient-to-br from-orange-50 via-red-50 to-yellow-50 border-orange-200 max-w-md">
                  <DialogHeader className="border-b border-orange-200 pb-4">
                    <DialogTitle className="flex items-center gap-2 text-orange-700">
                      <UserPlus className="h-5 w-5" />
                      Créer un Nouveau Client
                    </DialogTitle>
                  </DialogHeader>
                  
                  <div className="space-y-4 py-4">
                    <div className="space-y-2">
                      <Label className="text-orange-700 font-medium">Nom Complet *</Label>
                      <Input
                        value={formData.full_name}
                        onChange={(e) => setFormData({ ...formData, full_name: e.target.value })}
                        placeholder="Nom complet du client"
                        className="border-orange-300 focus:border-orange-500"
                      />
                    </div>

                    <div className="space-y-2">
                      <Label className="text-orange-700 font-medium">Téléphone *</Label>
                      <Input
                        value={formData.phone}
                        onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                        placeholder="Numéro de téléphone"
                        className="border-orange-300 focus:border-orange-500"
                      />
                    </div>

                    <div className="space-y-2">
                      <Label className="text-orange-700 font-medium">Email</Label>
                      <Input
                        value={formData.email}
                        onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                        placeholder="Email (optionnel)"
                        type="email"
                        className="border-orange-300 focus:border-orange-500"
                      />
                    </div>

                    <div className="space-y-2">
                      <Label className="text-orange-700 font-medium">Adresse</Label>
                      <Input
                        value={formData.address}
                        onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                        placeholder="Adresse (optionnel)"
                        className="border-orange-300 focus:border-orange-500"
                      />
                    </div>

                    <div className="bg-green-50 border border-green-200 rounded-lg p-4">
                      <div className="flex items-center gap-2">
                        <Switch
                          checked={formData.is_active}
                          onCheckedChange={(checked) => setFormData({ ...formData, is_active: checked })}
                        />
                        <Label className="text-green-700 font-medium">Client actif</Label>
                      </div>
                    </div>

                    <div className="bg-orange-50 border border-orange-200 rounded-lg p-4">
                      <p className="text-sm text-orange-800">
                        <strong>Note :</strong> Le client recevra un mot de passe par défaut lors de sa première connexion.
                      </p>
                      <p className="text-xs text-orange-600 mt-1">
                        Il pourra changer ce mot de passe dans ses paramètres.
                      </p>
                    </div>
                  </div>

                  <div className="flex gap-3 pt-4 border-t border-orange-200">
                    <Button
                      variant="outline"
                      onClick={() => setIsCreateModalOpen(false)}
                      className="flex-1 border-orange-300 text-orange-600 hover:bg-orange-50"
                    >
                      Annuler
                    </Button>
                    <Button
                      onClick={handleCreateClient}
                      disabled={createLoading}
                      className="flex-1 bg-gradient-to-r from-green-500 to-emerald-500 hover:from-green-600 hover:to-emerald-600 text-white"
                    >
                      {createLoading ? "Création..." : "Créer Client"}
                    </Button>
                  </div>
                </DialogContent>
              </Dialog>
            </div>

            {loading && (
              <div className="text-center py-4">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-orange-500 mx-auto"></div>
                <p className="text-gray-600 mt-2">Recherche en cours...</p>
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Résultats de recherche */}
      {searchTerm && (
        <Card className="bg-white/90 backdrop-blur-sm border-orange-200 shadow-lg">
          <CardHeader className="bg-gradient-to-r from-orange-50 to-red-50 border-b border-orange-200">
            <CardTitle className="text-orange-700 flex items-center gap-2">
              <Users className="h-5 w-5" />
              Résultats ({clients.length})
            </CardTitle>
          </CardHeader>
          <CardContent className="p-6">
            {clients.length === 0 && !loading ? (
              <div className="text-center py-8">
                <Users className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <p className="text-gray-600 mb-4">Aucun client trouvé</p>
                <p className="text-sm text-gray-500">
                  Essayez avec un autre terme de recherche ou créez un nouveau client
                </p>
              </div>
            ) : (
              <div className="space-y-3">
                {clients.map((client) => (
                  <div
                    key={client.id}
                    className="flex items-center justify-between p-4 bg-white rounded-lg border border-orange-200 hover:bg-orange-50 transition-colors cursor-pointer"
                    onClick={() => onClientSelected(client)}
                  >
                    <div className="flex items-center gap-4">
                      <Avatar className="h-12 w-12">
                        <AvatarFallback className="bg-gradient-to-r from-orange-500 to-red-500 text-white font-bold">
                          {client.full_name.split(' ').map(n => n[0]).join('').slice(0, 2)}
                        </AvatarFallback>
                      </Avatar>
                      <div>
                        <h3 className="font-semibold text-gray-800">{client.full_name}</h3>
                        <div className="flex items-center gap-4 text-sm text-gray-600">
                          <div className="flex items-center gap-1">
                            <Phone className="h-4 w-4" />
                            {formatPhone(client.phone)}
                          </div>
                          {client.email && (
                            <div className="flex items-center gap-1">
                              <Mail className="h-4 w-4" />
                              {client.email}
                            </div>
                          )}
                        </div>
                        {client.address && (
                          <div className="flex items-center gap-1 text-sm text-gray-600 mt-1">
                            <MapPin className="h-4 w-4" />
                            {client.address}
                          </div>
                        )}
                      </div>
                    </div>
                    <div className="text-right">
                      <Badge className={client.is_active ? "bg-green-100 text-green-800" : "bg-red-100 text-red-800"}>
                        {client.is_active ? "Actif" : "Inactif"}
                      </Badge>
                      <p className="text-xs text-gray-500 mt-1">
                        Inscrit le {new Date(client.created_at).toLocaleDateString('fr-FR')}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {/* Instructions */}
      {!searchTerm && (
        <Card className="bg-white/90 backdrop-blur-sm border-orange-200 shadow-lg">
          <CardContent className="p-6">
            <div className="text-center">
              <Search className="h-16 w-16 text-orange-400 mx-auto mb-4" />
              <h3 className="text-xl font-semibold text-gray-800 mb-2">
                Rechercher un Client
              </h3>
              <p className="text-gray-600 mb-4">
                Commencez par taper le nom ou le numéro de téléphone du client
              </p>
              <div className="bg-orange-50 border border-orange-200 rounded-lg p-4 max-w-md mx-auto">
                <p className="text-sm text-orange-800">
                  <strong>💡 Astuce :</strong> Si le client n'existe pas, vous pouvez le créer directement depuis cette page.
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
};

export default ClientSearch;



