import { useState, useEffect } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from "@/components/ui/alert-dialog";
import { Search, Plus, Package, Utensils, Edit, Trash2, ArrowLeft, TrendingUp, Users, DollarSign, Filter, Download } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { Link } from "react-router-dom";
import { MenuItemDialog } from "@/components/admin/MenuItemDialog";
import { CategoryDialog } from "@/components/admin/CategoryDialog";
import { SupplementsDialog } from "@/components/admin/SupplementsDialog";
import { useToast } from "@/hooks/use-toast";
import { useAdminAuth } from "@/hooks/useAdminAuth";
import { useStockPermissions } from "@/hooks/useStockPermissions";

interface MenuItem {
  id: number;
  name: string;
  description: string | null;
  price: number;
  category_id: number | null;
  is_available: boolean;
  is_popular: boolean;
  has_extra: boolean;
  has_garniture: boolean;
  image_url: string | null;
  created_at: string;
}

interface Category {
  id: number;
  name: string;
  description: string | null;
  is_active: boolean;
  image_url: string | null;
  created_at: string;
}

const AdminStock = () => {
  const [menuItems, setMenuItems] = useState<MenuItem[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [searchTerm, setSearchTerm] = useState("");
  const [loading, setLoading] = useState(true);
  const { toast } = useToast();
  const { admin } = useAdminAuth();
  const permissions = useStockPermissions();

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      const [menuItemsResponse, categoriesResponse] = await Promise.all([
        supabase.from('menu_items').select('*').order('created_at', { ascending: false }),
        supabase.from('categories').select('*').order('created_at', { ascending: false })
      ]);

      if (menuItemsResponse.error) throw menuItemsResponse.error;
      if (categoriesResponse.error) throw categoriesResponse.error;

      setMenuItems(menuItemsResponse.data || []);
      setCategories(categoriesResponse.data || []);
    } catch (error) {
      console.error('Error fetching data:', error);
    } finally {
      setLoading(false);
    }
  };

  const filteredMenuItems = menuItems.filter(item =>
    item.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    item.description?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const filteredCategories = categories.filter(category =>
    category.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    category.description?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const getCategoryName = (categoryId: number | null) => {
    if (!categoryId) return "Non catégorisé";
    const category = categories.find(c => c.id === categoryId);
    return category?.name || "Catégorie inconnue";
  };

  const handleDeleteMenuItem = async (id: number) => {
    if (!permissions.canDelete) {
      toast({ title: "Accès refusé", description: "Action non autorisée", variant: "destructive" });
      return;
    }
    try {
      const { error } = await supabase
        .from('menu_items')
        .delete()
        .eq('id', id);

      if (error) throw error;

      toast({
        title: "Succès",
        description: "Article supprimé avec succès",
      });

      fetchData();
    } catch (error) {
      console.error('Error deleting menu item:', error);
      toast({
        title: "Erreur",
        description: "Impossible de supprimer l'article",
        variant: "destructive",
      });
    }
  };

  const handleDeleteCategory = async (id: number) => {
    if (!permissions.canDelete) {
      toast({ title: "Accès refusé", description: "Action non autorisée", variant: "destructive" });
      return;
    }
    try {
      const { error } = await supabase
        .from('categories')
        .delete()
        .eq('id', id);

      if (error) throw error;

      toast({
        title: "Succès",
        description: "Catégorie supprimée avec succès",
      });

      fetchData();
    } catch (error) {
      console.error('Error deleting category:', error);
      toast({
        title: "Erreur",
        description: "Impossible de supprimer la catégorie",
        variant: "destructive",
      });
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-orange-50 via-red-50 to-yellow-50">
      {/* Header */}
      <div className="bg-white/90 backdrop-blur-sm border-b border-orange-200 sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <Link to="/admin" className="flex items-center gap-2 text-orange-600 hover:text-orange-700 transition-colors">
                <ArrowLeft className="h-5 w-5" />
                <span className="font-medium">Retour</span>
              </Link>
              <div className="h-8 w-px bg-orange-200"></div>
              <div>
                <h1 className="text-3xl font-bold bg-gradient-to-r from-orange-600 to-red-600 bg-clip-text text-transparent flex items-center gap-3">
                  <div className="p-2 bg-gradient-to-r from-orange-500 to-red-500 rounded-lg">
                    <Package className="h-8 w-8 text-white" />
                  </div>
                  Gestion du Stock & Menu
                </h1>
                <p className="text-gray-600 mt-1">
                  📦 Gérez votre menu et vos catégories d'articles
                </p>
              </div>
            </div>
            
            <div className="flex items-center gap-3">
              <Button variant="outline" className="border-orange-300 text-orange-600 hover:bg-orange-50">
                <Filter className="h-4 w-4 mr-2" />
                Filtrer
              </Button>
              <Button variant="outline" className="border-green-300 text-green-600 hover:bg-green-50">
                <Download className="h-4 w-4 mr-2" />
                Exporter
              </Button>
              {permissions.canCreate && <SupplementsDialog />}
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-6 py-6">
        <div className="space-y-6">

          <Tabs defaultValue="menu" className="space-y-6">
            <TabsList className="bg-white/90 border-orange-200">
              <TabsTrigger value="menu" className="flex items-center space-x-2 data-[state=active]:bg-orange-100 data-[state=active]:text-orange-700">
                <Utensils className="h-4 w-4" />
                <span>🍽️ Articles du Menu</span>
              </TabsTrigger>
              <TabsTrigger value="categories" className="flex items-center space-x-2 data-[state=active]:bg-orange-100 data-[state=active]:text-orange-700">
                <Package className="h-4 w-4" />
                <span>📦 Catégories</span>
              </TabsTrigger>
            </TabsList>

            <TabsContent value="menu" className="space-y-6">
              {/* Stats Cards */}
              <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
                <Card className="bg-white/90 backdrop-blur-sm border-orange-200 shadow-lg hover:shadow-xl transition-shadow">
                  <CardContent className="p-6">
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="text-sm font-medium text-orange-600">📦 Total Articles</p>
                        <p className="text-3xl font-bold text-orange-800 mt-1">{menuItems.length}</p>
                      </div>
                      <div className="p-3 bg-gradient-to-r from-orange-400 to-red-400 rounded-full">
                        <Package className="h-6 w-6 text-white" />
                      </div>
                    </div>
                  </CardContent>
                </Card>
                
                <Card className="bg-white/90 backdrop-blur-sm border-green-200 shadow-lg hover:shadow-xl transition-shadow">
                  <CardContent className="p-6">
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="text-sm font-medium text-green-600">✅ Disponibles</p>
                        <p className="text-3xl font-bold text-green-800 mt-1">
                          {menuItems.filter(item => item.is_available).length}
                        </p>
                      </div>
                      <div className="p-3 bg-gradient-to-r from-green-400 to-emerald-500 rounded-full">
                        <TrendingUp className="h-6 w-6 text-white" />
                      </div>
                    </div>
                  </CardContent>
                </Card>
                
                <Card className="bg-white/90 backdrop-blur-sm border-yellow-200 shadow-lg hover:shadow-xl transition-shadow">
                  <CardContent className="p-6">
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="text-sm font-medium text-yellow-600">⭐ Populaires</p>
                        <p className="text-3xl font-bold text-yellow-800 mt-1">
                          {menuItems.filter(item => item.is_popular).length}
                        </p>
                      </div>
                      <div className="p-3 bg-gradient-to-r from-yellow-400 to-orange-400 rounded-full">
                        <Users className="h-6 w-6 text-white" />
                      </div>
                    </div>
                  </CardContent>
                </Card>
                
                <Card className="bg-white/90 backdrop-blur-sm border-red-200 shadow-lg hover:shadow-xl transition-shadow">
                  <CardContent className="p-6">
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="text-sm font-medium text-red-600">❌ Indisponibles</p>
                        <p className="text-3xl font-bold text-red-800 mt-1">
                          {menuItems.filter(item => !item.is_available).length}
                        </p>
                      </div>
                      <div className="p-3 bg-gradient-to-r from-red-400 to-pink-500 rounded-full">
                        <Package className="h-6 w-6 text-white" />
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </div>

              {/* Table des Articles */}
              <Card className="bg-white/90 backdrop-blur-sm border-orange-200 shadow-lg">
                <CardHeader className="bg-gradient-to-r from-orange-50 to-red-50 border-b border-orange-200">
                  <div className="flex items-center justify-between">
                    <div>
                      <CardTitle className="text-xl flex items-center gap-2 text-orange-700">
                        <Utensils className="h-5 w-5" />
                        🍽️ Articles du Menu
                      </CardTitle>
                      <CardDescription className="text-orange-600">
                        {filteredMenuItems.length} article(s) trouvé(s)
                      </CardDescription>
                    </div>
                    <div className="flex items-center space-x-3">
                      <div className="relative">
                        <Search className="absolute left-3 top-2.5 h-4 w-4 text-orange-400" />
                        <Input
                          placeholder="Rechercher un article..."
                          value={searchTerm}
                          onChange={(e) => setSearchTerm(e.target.value)}
                          className="pl-10 w-64 border-orange-300 focus:border-orange-500"
                        />
                      </div>
                      {permissions.canCreate && (
                        <MenuItemDialog 
                          categories={categories} 
                          onSave={fetchData}
                        />
                      )}
                    </div>
                  </div>
                </CardHeader>
                <CardContent className="p-6">
                  {loading ? (
                    <div className="text-center py-12">
                      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-orange-500 mx-auto"></div>
                      <p className="text-orange-600 mt-2">Chargement des articles...</p>
                    </div>
                  ) : (
                    <Table>
                      <TableHeader>
                        <TableRow className="bg-orange-50 hover:bg-orange-50">
                          <TableHead className="text-orange-700 font-semibold">📝 Nom</TableHead>
                          <TableHead className="text-orange-700 font-semibold">📄 Description</TableHead>
                          <TableHead className="text-orange-700 font-semibold">📦 Catégorie</TableHead>
                          <TableHead className="text-orange-700 font-semibold">💰 Prix</TableHead>
                          <TableHead className="text-orange-700 font-semibold">📊 Statut</TableHead>
                          <TableHead className="text-orange-700 font-semibold">⭐ Popularité</TableHead>
                          <TableHead className="text-orange-700 font-semibold">⚙️ Actions</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {filteredMenuItems.map((item) => (
                          <TableRow key={item.id} className="hover:bg-orange-50/50 transition-colors">
                            <TableCell className="font-semibold text-orange-800">
                              {item.name}
                            </TableCell>
                            <TableCell className="max-w-xs truncate text-gray-600">
                              {item.description || "Pas de description"}
                            </TableCell>
                            <TableCell>
                              <Badge className="bg-orange-100 text-orange-800 border-orange-200">
                                {getCategoryName(item.category_id)}
                              </Badge>
                            </TableCell>
                            <TableCell className="font-bold text-green-600">
                              {Number(item.price).toLocaleString()} FCFA
                            </TableCell>
                            <TableCell>
                              <Badge className={item.is_available ? "bg-green-100 text-green-800 border-green-200" : "bg-red-100 text-red-800 border-red-200"}>
                                {item.is_available ? "✅ Disponible" : "❌ Indisponible"}
                              </Badge>
                            </TableCell>
                            <TableCell>
                              {item.is_popular && (
                                <Badge className="bg-yellow-100 text-yellow-800 border-yellow-200">
                                  ⭐ Populaire
                                </Badge>
                              )}
                            </TableCell>
                                <TableCell>
                                  <div className="flex space-x-1">
                                    {permissions.canEdit ? (
                                      <>
                                        <MenuItemDialog 
                                          item={item}
                                          categories={categories}
                                          onSave={fetchData}
                                          trigger={
                                            <Button variant="outline" size="sm">
                                              <Edit className="h-4 w-4" />
                                            </Button>
                                          }
                                        />
                                        <AlertDialog>
                                          <AlertDialogTrigger asChild>
                                            <Button variant="outline" size="sm">
                                              <Trash2 className="h-4 w-4" />
                                            </Button>
                                          </AlertDialogTrigger>
                                          <AlertDialogContent>
                                            <AlertDialogHeader>
                                              <AlertDialogTitle>Supprimer l'article</AlertDialogTitle>
                                              <AlertDialogDescription>
                                                Êtes-vous sûr de vouloir supprimer "{item.name}" ? Cette action est irréversible.
                                              </AlertDialogDescription>
                                            </AlertDialogHeader>
                                            <AlertDialogFooter>
                                              <AlertDialogCancel>Annuler</AlertDialogCancel>
                                              <AlertDialogAction onClick={() => handleDeleteMenuItem(item.id)}>
                                                Supprimer
                                              </AlertDialogAction>
                                            </AlertDialogFooter>
                                          </AlertDialogContent>
                                        </AlertDialog>
                                      </>
                                    ) : (
                                      <span className="text-muted-foreground">-</span>
                                    )}
                                  </div>
                                </TableCell>
                              </TableRow>
                            ))}
                            {filteredMenuItems.length === 0 && (
                              <TableRow>
                                <TableCell colSpan={7} className="text-center py-8">
                                  Aucun article trouvé
                                </TableCell>
                              </TableRow>
                            )}
                          </TableBody>
                        </Table>
                      )}
                    </CardContent>
                  </Card>
                </TabsContent>

                <TabsContent value="categories" className="space-y-6">
                  <Card>
                    <CardHeader>
                      <div className="flex items-center justify-between">
                        <div>
                          <CardTitle>Catégories</CardTitle>
                          <CardDescription>
                            {filteredCategories.length} catégorie(s) trouvée(s)
                          </CardDescription>
                        </div>
                        <div className="flex items-center space-x-2">
                          <div className="relative">
                            <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
                            <Input
                              placeholder="Rechercher une catégorie..."
                              value={searchTerm}
                              onChange={(e) => setSearchTerm(e.target.value)}
                              className="pl-8 w-64"
                            />
                          </div>
                          {permissions.canCreate && <CategoryDialog onSave={fetchData} />}
                        </div>
                      </div>
                    </CardHeader>
                    <CardContent>
                      {loading ? (
                        <div className="text-center py-8">Chargement...</div>
                      ) : (
                        <Table>
                          <TableHeader>
                            <TableRow>
                              <TableHead>Nom</TableHead>
                              <TableHead>Description</TableHead>
                              <TableHead>Statut</TableHead>
                              <TableHead>Créée le</TableHead>
                              <TableHead>Actions</TableHead>
                            </TableRow>
                          </TableHeader>
                          <TableBody>
                            {filteredCategories.map((category) => (
                              <TableRow key={category.id}>
                                <TableCell className="font-medium">
                                  {category.name}
                                </TableCell>
                                <TableCell className="max-w-xs truncate">
                                  {category.description || "Pas de description"}
                                </TableCell>
                                <TableCell>
                                  <Badge variant={category.is_active ? "default" : "secondary"}>
                                    {category.is_active ? "Active" : "Inactive"}
                                  </Badge>
                                </TableCell>
                                <TableCell>
                                  {new Date(category.created_at).toLocaleDateString('fr-FR')}
                                </TableCell>
                                <TableCell>
                                  <div className="flex space-x-1">
                                    {permissions.canEdit ? (
                                      <>
                                        <CategoryDialog 
                                          category={category}
                                          onSave={fetchData}
                                          trigger={
                                            <Button variant="outline" size="sm">
                                              <Edit className="h-4 w-4" />
                                            </Button>
                                          }
                                        />
                                        <AlertDialog>
                                          <AlertDialogTrigger asChild>
                                            <Button variant="outline" size="sm">
                                              <Trash2 className="h-4 w-4" />
                                            </Button>
                                          </AlertDialogTrigger>
                                          <AlertDialogContent>
                                            <AlertDialogHeader>
                                              <AlertDialogTitle>Supprimer la catégorie</AlertDialogTitle>
                                              <AlertDialogDescription>
                                                Êtes-vous sûr de vouloir supprimer "{category.name}" ? Cette action est irréversible.
                                              </AlertDialogDescription>
                                            </AlertDialogHeader>
                                            <AlertDialogFooter>
                                              <AlertDialogCancel>Annuler</AlertDialogCancel>
                                              <AlertDialogAction onClick={() => handleDeleteCategory(category.id)}>
                                                Supprimer
                                              </AlertDialogAction>
                                            </AlertDialogFooter>
                                          </AlertDialogContent>
                                        </AlertDialog>
                                      </>
                                    ) : (
                                      <span className="text-muted-foreground">-</span>
                                    )}
                                  </div>
                                </TableCell>
                              </TableRow>
                            ))}
                            {filteredCategories.length === 0 && (
                              <TableRow>
                                <TableCell colSpan={5} className="text-center py-8">
                                  Aucune catégorie trouvée
                                </TableCell>
                              </TableRow>
                            )}
                          </TableBody>
                        </Table>
                      )}
                    </CardContent>
                  </Card>
            </TabsContent>
          </Tabs>
        </div>
      </div>
    </div>
  );
};

export default AdminStock;