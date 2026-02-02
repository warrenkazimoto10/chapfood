import { useState, useEffect, useRef } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Switch } from "@/components/ui/switch";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { useToast } from "@/hooks/use-toast";
import { supabase } from "@/integrations/supabase/client";
import { Plus, Edit, Utensils, Package, DollarSign, Upload, Image as ImageIcon, X } from "lucide-react";
import { useAdminAuth } from "@/hooks/useAdminAuth";
interface Category {
  id: number;
  name: string;
}

interface MenuItem {
  id?: number;
  name: string;
  description: string;
  price: number;
  category_id: number | null;
  is_available: boolean;
  is_popular: boolean;
  has_extra: boolean;
  has_garniture: boolean;
  image_url?: string;
}

interface MenuItemDialogProps {
  item?: MenuItem;
  categories: Category[];
  onSave: () => void;
  trigger?: React.ReactNode;
}

export function MenuItemDialog({ item, categories, onSave, trigger }: MenuItemDialogProps) {
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [formData, setFormData] = useState<MenuItem>({
    name: "",
    description: "",
    price: 0,
    category_id: null,
    is_available: true,
    is_popular: false,
    has_extra: false,
    has_garniture: false,
    image_url: ""
  });

  const { toast } = useToast();
  const { admin } = useAdminAuth();
  const canManage = !!admin && (admin.role === 'admin_general' || admin.role === 'cuisine');

  useEffect(() => {
    if (item) {
      setFormData({
        ...item,
        description: item.description || "",
        image_url: item.image_url || ""
      });
      if (item.image_url) {
        setPreviewUrl(item.image_url);
      }
    } else {
      setFormData({
        name: "",
        description: "",
        price: 0,
        category_id: null,
        is_available: true,
        is_popular: false,
        has_extra: false,
        has_garniture: false,
        image_url: ""
      });
      setPreviewUrl(null);
    }
    setSelectedFile(null);
  }, [item, open]);

  const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      // Vérifier le type de fichier
      if (!file.type.startsWith('image/')) {
        toast({
          title: "Erreur",
          description: "Veuillez sélectionner un fichier image",
          variant: "destructive",
        });
        return;
      }

      // Vérifier la taille (max 5MB)
      if (file.size > 5 * 1024 * 1024) {
        toast({
          title: "Erreur",
          description: "L'image ne doit pas dépasser 5MB",
          variant: "destructive",
        });
        return;
      }

      setSelectedFile(file);
      
      // Créer une URL de prévisualisation
      const url = URL.createObjectURL(file);
      setPreviewUrl(url);
    }
  };

  const uploadImage = async (file: File): Promise<string | null> => {
    try {
      setUploading(true);
      
      // Créer un nom de fichier unique
      const fileExt = file.name.split('.').pop();
      const fileName = `${Date.now()}-${Math.random().toString(36).substring(2)}.${fileExt}`;
      
      // Upload vers Supabase Storage
      const { data, error } = await supabase.storage
        .from('menu-images')
        .upload(fileName, file);

      if (error) {
        throw error;
      }

      // Récupérer l'URL publique
      const { data: { publicUrl } } = supabase.storage
        .from('menu-images')
        .getPublicUrl(fileName);

      return publicUrl;
    } catch (error) {
      console.error('Erreur lors de l\'upload:', error);
      toast({
        title: "Erreur",
        description: "Impossible d'uploader l'image",
        variant: "destructive",
      });
      return null;
    } finally {
      setUploading(false);
    }
  };

  const removeImage = () => {
    setSelectedFile(null);
    setPreviewUrl(null);
    setFormData({ ...formData, image_url: "" });
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
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
      const menuItemData = {
        name: formData.name,
        description: formData.description || null,
        price: formData.price,
        category_id: formData.category_id,
        is_available: formData.is_available,
        is_popular: formData.is_popular,
        has_extra: formData.has_extra,
        has_garniture: formData.has_garniture,
        image_url: formData.image_url || null
      };

      let result;
      if (item?.id) {
        result = await supabase
          .from('menu_items')
          .update(menuItemData)
          .eq('id', item.id);
      } else {
        result = await supabase
          .from('menu_items')
          .insert([menuItemData]);
      }

      if (result.error) throw result.error;

      toast({
        title: "Succès",
        description: item?.id ? "Article modifié avec succès" : "Article ajouté avec succès",
      });

      setOpen(false);
      onSave();
    } catch (error) {
      console.error('Error saving menu item:', error);
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
      Ajouter un article
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
        {trigger || (item?.id ? editTrigger : defaultTrigger)}
      </DialogTrigger>
      <DialogContent className="max-w-2xl bg-gradient-to-br from-orange-50 via-red-50 to-yellow-50 border-orange-200">
        <DialogHeader className="border-b border-orange-200 pb-4">
          <DialogTitle className="flex items-center gap-3 text-orange-700">
            <div className="p-2 bg-gradient-to-r from-orange-500 to-red-500 rounded-lg">
              <Utensils className="h-5 w-5 text-white" />
            </div>
            <span className="text-2xl font-bold bg-gradient-to-r from-orange-600 to-red-600 bg-clip-text text-transparent">
              {item?.id ? "Modifier l'article" : "Ajouter un article"}
            </span>
          </DialogTitle>
          <DialogDescription className="text-gray-600 text-lg">
            {item?.id ? "✏️ Modifiez les informations de l'article" : "➕ Ajoutez un nouvel article au menu"}
          </DialogDescription>
        </DialogHeader>
        
        <form onSubmit={handleSubmit} className="space-y-6 p-6">
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="name" className="text-orange-700 font-medium">📝 Nom de l'article *</Label>
              <Input
                id="name"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                placeholder="Ex: Pizza Margherita"
                className="border-orange-300 focus:border-orange-500"
                required
              />
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="price" className="text-orange-700 font-medium">💰 Prix (FCFA) *</Label>
              <Input
                id="price"
                type="number"
                step="0.01"
                min="0"
                value={formData.price}
                onChange={(e) => setFormData({ ...formData, price: parseFloat(e.target.value) || 0 })}
                placeholder="12.50"
                className="border-orange-300 focus:border-orange-500"
                required
              />
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="description" className="text-orange-700 font-medium">📄 Description</Label>
            <Textarea
              id="description"
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              placeholder="Description de l'article..."
              rows={3}
              className="border-orange-300 focus:border-orange-500"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="category" className="text-orange-700 font-medium">📦 Catégorie</Label>
              <Select 
                value={formData.category_id?.toString() || "none"} 
                onValueChange={(value) => setFormData({ ...formData, category_id: value === "none" ? null : parseInt(value) })}
              >
                <SelectTrigger className="border-orange-300 focus:border-orange-500">
                  <SelectValue placeholder="Sélectionner une catégorie" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="none">Aucune catégorie</SelectItem>
                  {categories.map((category) => (
                    <SelectItem key={category.id} value={category.id.toString()}>
                      {category.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label className="text-orange-700 font-medium">🖼️ Image de l'article</Label>
              
              {/* Zone de téléchargement */}
              <div className="border-2 border-dashed border-orange-300 rounded-lg p-4 text-center hover:border-orange-400 transition-colors">
                <input
                  ref={fileInputRef}
                  type="file"
                  accept="image/*"
                  onChange={handleFileSelect}
                  className="hidden"
                />
                
                {previewUrl ? (
                  <div className="space-y-3">
                    <div className="relative inline-block">
                      <img
                        src={previewUrl}
                        alt="Aperçu"
                        className="w-32 h-32 object-cover rounded-lg border border-orange-200"
                      />
                      <Button
                        type="button"
                        size="sm"
                        variant="destructive"
                        className="absolute -top-2 -right-2 h-6 w-6 rounded-full p-0"
                        onClick={removeImage}
                      >
                        <X className="h-3 w-3" />
                      </Button>
                    </div>
                    <p className="text-sm text-gray-600">
                      {selectedFile ? selectedFile.name : "Image actuelle"}
                    </p>
                  </div>
                ) : (
                  <div className="space-y-3">
                    <ImageIcon className="h-12 w-12 text-orange-400 mx-auto" />
                    <div>
                      <Button
                        type="button"
                        variant="outline"
                        onClick={() => fileInputRef.current?.click()}
                        className="border-orange-300 text-orange-600 hover:bg-orange-50"
                      >
                        <Upload className="h-4 w-4 mr-2" />
                        Choisir une image
                      </Button>
                      <p className="text-xs text-gray-500 mt-2">
                        PNG, JPG jusqu'à 5MB
                      </p>
                    </div>
                  </div>
                )}
              </div>
              
              {/* Champ URL (optionnel) */}
              <div className="mt-3">
                <Label htmlFor="image_url" className="text-orange-700 font-medium text-sm">Ou URL de l'image</Label>
                <Input
                  id="image_url"
                  value={formData.image_url}
                  onChange={(e) => setFormData({ ...formData, image_url: e.target.value })}
                  placeholder="https://example.com/image.jpg"
                  className="border-orange-300 focus:border-orange-500"
                />
              </div>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-6">
            <div className="space-y-4">
              <div className="flex items-center space-x-3 p-3 bg-green-50 rounded-lg border border-green-200">
                <Switch
                  id="is_available"
                  checked={formData.is_available}
                  onCheckedChange={(checked) => setFormData({ ...formData, is_available: checked })}
                />
                <Label htmlFor="is_available" className="text-green-700 font-medium">✅ Article disponible</Label>
              </div>

              <div className="flex items-center space-x-3 p-3 bg-yellow-50 rounded-lg border border-yellow-200">
                <Switch
                  id="is_popular"
                  checked={formData.is_popular}
                  onCheckedChange={(checked) => setFormData({ ...formData, is_popular: checked })}
                />
                <Label htmlFor="is_popular" className="text-yellow-700 font-medium">⭐ Article populaire</Label>
              </div>
            </div>

            <div className="space-y-4">
              <div className="flex items-center space-x-3 p-3 bg-purple-50 rounded-lg border border-purple-200">
                <Switch
                  id="has_extra"
                  checked={formData.has_extra}
                  onCheckedChange={(checked) => setFormData({ ...formData, has_extra: checked })}
                />
                <Label htmlFor="has_extra" className="text-purple-700 font-medium">🍯 Suppléments disponibles</Label>
              </div>

              <div className="flex items-center space-x-3 p-3 bg-blue-50 rounded-lg border border-blue-200">
                <Switch
                  id="has_garniture"
                  checked={formData.has_garniture}
                  onCheckedChange={(checked) => setFormData({ ...formData, has_garniture: checked })}
                />
                <Label htmlFor="has_garniture" className="text-blue-700 font-medium">🥗 Garnitures disponibles</Label>
              </div>
            </div>
          </div>

          <div className="flex justify-end space-x-3 pt-4 border-t border-orange-200">
            <Button type="button" variant="outline" onClick={() => setOpen(false)} className="border-orange-300 text-orange-600 hover:bg-orange-50">
              ❌ Annuler
            </Button>
            <Button type="submit" disabled={loading || uploading || !canManage} className="bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 text-white">
              {loading ? "⏳ Enregistrement..." : uploading ? "📤 Upload en cours..." : (item?.id ? "✏️ Modifier" : "➕ Ajouter")}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}