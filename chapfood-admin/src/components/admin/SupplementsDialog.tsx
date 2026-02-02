import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Switch } from "@/components/ui/switch";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { useToast } from "@/hooks/use-toast";
import { supabase } from "@/integrations/supabase/client";
import { Plus, Edit, Trash2, Settings, Cog, Wrench } from "lucide-react";
import { useAdminAuth } from "@/hooks/useAdminAuth";

interface Supplement {
  id: number;
  name: string;
  type: string;
  price: number;
  is_available: boolean;
  is_obligatory: boolean;
  created_at: string;
}

interface SupplementsDialogProps {
  trigger?: React.ReactNode;
}

export function SupplementsDialog({ trigger }: SupplementsDialogProps) {
  const [open, setOpen] = useState(false);
  const [supplements, setSupplements] = useState<Supplement[]>([]);
  const [loading, setLoading] = useState(false);
  const [editingSupplementId, setEditingSupplementId] = useState<number | null>(null);
  const [formData, setFormData] = useState({
    name: "",
    type: "extra",
    price: 0,
    is_available: true,
    is_obligatory: false
  });

  const { toast } = useToast();
  const { admin } = useAdminAuth();
  const canManage = !!admin && (admin.role === 'admin_general' || admin.role === 'cuisine');

  useEffect(() => {
    if (open) {
      fetchSupplements();
    }
  }, [open]);

  const fetchSupplements = async () => {
    try {
      const { data, error } = await supabase
        .from('supplements')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      setSupplements(data || []);
    } catch (error) {
      console.error('Error fetching supplements:', error);
      toast({
        title: "Erreur",
        description: "Impossible de charger les suppléments",
        variant: "destructive",
      });
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    if (!canManage) {
      toast({
        title: "Accès refusé",
        description: "Vous n'avez pas l'autorisation d'effectuer cette action.",
        variant: "destructive",
      });
      setLoading(false);
      return;
    }

    try {
      const supplementData = {
        name: formData.name,
        type: formData.type,
        price: formData.price,
        is_available: formData.is_available,
        is_obligatory: formData.is_obligatory
      };

      let result;
      if (editingSupplementId) {
        result = await supabase
          .from('supplements')
          .update(supplementData)
          .eq('id', editingSupplementId);
      } else {
        result = await supabase
          .from('supplements')
          .insert([supplementData]);
      }

      if (result.error) throw result.error;

      toast({
        title: "Succès",
        description: editingSupplementId ? "Supplément modifié avec succès" : "Supplément ajouté avec succès",
      });

      // Reset form
      setFormData({
        name: "",
        type: "extra",
        price: 0,
        is_available: true,
        is_obligatory: false
      });
      setEditingSupplementId(null);
      
      // Refresh list
      fetchSupplements();
    } catch (error) {
      console.error('Error saving supplement:', error);
      toast({
        title: "Erreur",
        description: "Une erreur est survenue lors de l'enregistrement",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const handleEdit = (supplement: Supplement) => {
    setFormData({
      name: supplement.name,
      type: supplement.type,
      price: Number(supplement.price),
      is_available: supplement.is_available,
      is_obligatory: supplement.is_obligatory
    });
    setEditingSupplementId(supplement.id);
  };

  const handleDelete = async (id: number) => {
    if (!canManage) {
      toast({
        title: "Accès refusé",
        description: "Vous n'avez pas l'autorisation d'effectuer cette action.",
        variant: "destructive",
      });
      return;
    }

    if (!confirm("Êtes-vous sûr de vouloir supprimer ce supplément ?")) return;

    try {
      const { error } = await supabase
        .from('supplements')
        .delete()
        .eq('id', id);

      if (error) throw error;

      toast({
        title: "Succès",
        description: "Supplément supprimé avec succès",
      });

      fetchSupplements();
    } catch (error) {
      console.error('Error deleting supplement:', error);
      toast({
        title: "Erreur",
        description: "Impossible de supprimer le supplément",
        variant: "destructive",
      });
    }
  };

  const cancelEdit = () => {
    setFormData({
      name: "",
      type: "extra",
      price: 0,
      is_available: true,
      is_obligatory: false
    });
    setEditingSupplementId(null);
  };

  const defaultTrigger = (
    <Button variant="outline">
      <Settings className="h-4 w-4 mr-2" />
      Gérer les suppléments
    </Button>
  );

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        {trigger || defaultTrigger}
      </DialogTrigger>
      <DialogContent className="max-w-6xl max-h-[90vh] overflow-hidden bg-gradient-to-br from-orange-50 via-red-50 to-yellow-50 border-orange-200">
        <DialogHeader className="border-b border-orange-200 pb-4">
          <DialogTitle className="flex items-center gap-3 text-orange-700">
            <div className="p-2 bg-gradient-to-r from-orange-500 to-red-500 rounded-lg">
              <Settings className="h-5 w-5 text-white" />
            </div>
            <span className="text-2xl font-bold bg-gradient-to-r from-orange-600 to-red-600 bg-clip-text text-transparent">
              Gestion des Suppléments
            </span>
          </DialogTitle>
          <DialogDescription className="text-gray-600 text-lg">
            ⚙️ Gérez les suppléments et garnitures de votre menu
          </DialogDescription>
        </DialogHeader>
        
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 overflow-auto p-6">
          {/* Form */}
          <div className="space-y-4">
            <h3 className="text-lg font-semibold text-orange-700 flex items-center gap-2">
              <Cog className="h-5 w-5" />
              {editingSupplementId ? "✏️ Modifier le supplément" : "➕ Ajouter un supplément"}
            </h3>
            
            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="sup_name" className="text-orange-700 font-medium">📝 Nom du supplément *</Label>
                <Input
                  id="sup_name"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  placeholder="Ex: Fromage supplémentaire"
                  className="border-orange-300 focus:border-orange-500"
                  required
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="sup_type" className="text-orange-700 font-medium">📦 Type</Label>
                <Select 
                  value={formData.type} 
                  onValueChange={(value) => setFormData({ ...formData, type: value })}
                >
                  <SelectTrigger className="border-orange-300 focus:border-orange-500">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="extra">🍯 Supplément</SelectItem>
                    <SelectItem value="garniture">🥗 Garniture</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label htmlFor="sup_price" className="text-orange-700 font-medium">💰 Prix (FCFA)</Label>
                <Input
                  id="sup_price"
                  type="number"
                  step="0.01"
                  min="0"
                  value={formData.price}
                  onChange={(e) => setFormData({ ...formData, price: parseFloat(e.target.value) || 0 })}
                  placeholder="1.50"
                  className="border-orange-300 focus:border-orange-500"
                />
              </div>

              <div className="space-y-3">
                <div className="flex items-center space-x-3 p-3 bg-green-50 rounded-lg border border-green-200">
                  <Switch
                    id="sup_available"
                    checked={formData.is_available}
                    onCheckedChange={(checked) => setFormData({ ...formData, is_available: checked })}
                  />
                  <Label htmlFor="sup_available" className="text-green-700 font-medium">✅ Disponible</Label>
                </div>

                <div className="flex items-center space-x-3 p-3 bg-yellow-50 rounded-lg border border-yellow-200">
                  <Switch
                    id="sup_obligatory"
                    checked={formData.is_obligatory}
                    onCheckedChange={(checked) => setFormData({ ...formData, is_obligatory: checked })}
                  />
                  <Label htmlFor="sup_obligatory" className="text-yellow-700 font-medium">⚠️ Obligatoire</Label>
                </div>
              </div>

              <div className="flex space-x-3 pt-4 border-t border-orange-200">
                {editingSupplementId && (
                  <Button type="button" variant="outline" onClick={cancelEdit} className="border-orange-300 text-orange-600 hover:bg-orange-50">
                    ❌ Annuler
                  </Button>
                )}
                <Button type="submit" disabled={loading || !canManage} className="flex-1 bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 text-white">
                  {loading ? "⏳ Enregistrement..." : (editingSupplementId ? "✏️ Modifier" : "➕ Ajouter")}
                </Button>
              </div>
            </form>
          </div>

          {/* List */}
          <div className="space-y-4">
            <h3 className="text-lg font-semibold text-orange-700 flex items-center gap-2">
              <Wrench className="h-5 w-5" />
              📋 Suppléments existants
            </h3>
            
            <div className="border border-orange-200 rounded-lg overflow-auto max-h-96 bg-white/90">
              <Table>
                <TableHeader>
                  <TableRow className="bg-orange-50 hover:bg-orange-50">
                    <TableHead className="text-orange-700 font-semibold">📝 Nom</TableHead>
                    <TableHead className="text-orange-700 font-semibold">📦 Type</TableHead>
                    <TableHead className="text-orange-700 font-semibold">💰 Prix</TableHead>
                    <TableHead className="text-orange-700 font-semibold">📊 Statut</TableHead>
                    <TableHead className="text-orange-700 font-semibold">⚙️ Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {supplements.map((supplement) => (
                    <TableRow key={supplement.id} className="hover:bg-orange-50/50 transition-colors">
                      <TableCell className="font-semibold text-orange-800">
                        {supplement.name}
                      </TableCell>
                      <TableCell>
                        <Badge className={supplement.type === 'extra' ? "bg-purple-100 text-purple-800 border-purple-200" : "bg-blue-100 text-blue-800 border-blue-200"}>
                          {supplement.type === 'extra' ? '🍯 Supplément' : '🥗 Garniture'}
                        </Badge>
                      </TableCell>
                      <TableCell className="font-bold text-green-600">
                        {Number(supplement.price).toLocaleString()} FCFA
                      </TableCell>
                      <TableCell>
                        <div className="flex flex-col space-y-1">
                          <Badge className={supplement.is_available ? "bg-green-100 text-green-800 border-green-200" : "bg-red-100 text-red-800 border-red-200"} variant="secondary">
                            {supplement.is_available ? "✅ Disponible" : "❌ Indisponible"}
                          </Badge>
                          {supplement.is_obligatory && (
                            <Badge className="bg-yellow-100 text-yellow-800 border-yellow-200">
                              ⚠️ Obligatoire
                            </Badge>
                          )}
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="flex space-x-2">
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => handleEdit(supplement)}
                            disabled={!canManage}
                            className="border-orange-300 text-orange-600 hover:bg-orange-50"
                          >
                            <Edit className="h-3 w-3" />
                          </Button>
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => handleDelete(supplement.id)}
                            disabled={!canManage}
                          >
                            <Trash2 className="h-3 w-3" />
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))}
                  {supplements.length === 0 && (
                    <TableRow>
                      <TableCell colSpan={5} className="text-center py-8">
                        Aucun supplément trouvé
                      </TableCell>
                    </TableRow>
                  )}
                </TableBody>
              </Table>
            </div>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}