import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { useToast } from "@/hooks/use-toast";
import { supabase } from "@/integrations/supabase/client";
import { Plus, Edit, Package, FolderOpen } from "lucide-react";
import { useAdminAuth } from "@/hooks/useAdminAuth";

interface Category {
  id?: number;
  name: string;
  description: string;
  is_active: boolean;
  image_url?: string;
}

interface CategoryDialogProps {
  category?: Category;
  onSave: () => void;
  trigger?: React.ReactNode;
}

export function CategoryDialog({ category, onSave, trigger }: CategoryDialogProps) {
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState<Category>({
    name: "",
    description: "",
    is_active: true,
    image_url: ""
  });

  const { toast } = useToast();
  const { admin } = useAdminAuth();
  const canManage = !!admin && (admin.role === 'admin_general' || admin.role === 'cuisine');

  useEffect(() => {
    if (category) {
      setFormData({
        ...category,
        description: category.description || "",
        image_url: category.image_url || ""
      });
    } else {
      setFormData({
        name: "",
        description: "",
        is_active: true,
        image_url: ""
      });
    }
  }, [category, open]);

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
      const categoryData = {
        name: formData.name,
        description: formData.description || null,
        is_active: formData.is_active,
        image_url: formData.image_url || null
      };

      let result;
      if (category?.id) {
        result = await supabase
          .from('categories')
          .update(categoryData)
          .eq('id', category.id);
      } else {
        result = await supabase
          .from('categories')
          .insert([categoryData]);
      }

      if (result.error) throw result.error;

      toast({
        title: "Succès",
        description: category?.id ? "Catégorie modifiée avec succès" : "Catégorie ajoutée avec succès",
      });

      setOpen(false);
      onSave();
    } catch (error) {
      console.error('Error saving category:', error);
      toast({
        title: "Erreur",
        description: "Une erreur est survenue lors de l'enregistrement",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const defaultTrigger = (
    <Button>
      <Plus className="h-4 w-4 mr-2" />
      Ajouter une catégorie
    </Button>
  );

  const editTrigger = (
    <Button variant="outline" size="sm">
      <Edit className="h-4 w-4" />
    </Button>
  );

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        {trigger || (category?.id ? editTrigger : defaultTrigger)}
      </DialogTrigger>
      <DialogContent className="max-w-lg bg-gradient-to-br from-orange-50 via-red-50 to-yellow-50 border-orange-200">
        <DialogHeader className="border-b border-orange-200 pb-4">
          <DialogTitle className="flex items-center gap-3 text-orange-700">
            <div className="p-2 bg-gradient-to-r from-orange-500 to-red-500 rounded-lg">
              <Package className="h-5 w-5 text-white" />
            </div>
            <span className="text-2xl font-bold bg-gradient-to-r from-orange-600 to-red-600 bg-clip-text text-transparent">
              {category?.id ? "Modifier la catégorie" : "Ajouter une catégorie"}
            </span>
          </DialogTitle>
          <DialogDescription className="text-gray-600 text-lg">
            {category?.id ? "✏️ Modifiez les informations de la catégorie" : "➕ Ajoutez une nouvelle catégorie"}
          </DialogDescription>
        </DialogHeader>
        
        <form onSubmit={handleSubmit} className="space-y-6 p-6">
          <div className="space-y-2">
            <Label htmlFor="name" className="text-orange-700 font-medium">📝 Nom de la catégorie *</Label>
            <Input
              id="name"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              placeholder="Ex: Pizzas, Burgers..."
              className="border-orange-300 focus:border-orange-500"
              required
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="description" className="text-orange-700 font-medium">📄 Description</Label>
            <Textarea
              id="description"
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              placeholder="Description de la catégorie..."
              rows={3}
              className="border-orange-300 focus:border-orange-500"
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="image_url" className="text-orange-700 font-medium">🖼️ URL de l'image</Label>
            <Input
              id="image_url"
              value={formData.image_url}
              onChange={(e) => setFormData({ ...formData, image_url: e.target.value })}
              placeholder="https://example.com/image.jpg"
              className="border-orange-300 focus:border-orange-500"
            />
          </div>

          <div className="flex items-center space-x-3 p-3 bg-green-50 rounded-lg border border-green-200">
            <Switch
              id="is_active"
              checked={formData.is_active}
              onCheckedChange={(checked) => setFormData({ ...formData, is_active: checked })}
            />
            <Label htmlFor="is_active" className="text-green-700 font-medium">✅ Catégorie active</Label>
          </div>

          <div className="flex justify-end space-x-3 pt-4 border-t border-orange-200">
            <Button type="button" variant="outline" onClick={() => setOpen(false)} className="border-orange-300 text-orange-600 hover:bg-orange-50">
              ❌ Annuler
            </Button>
            <Button type="submit" disabled={loading || !canManage} className="bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 text-white">
              {loading ? "⏳ Enregistrement..." : (category?.id ? "✏️ Modifier" : "➕ Ajouter")}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}