import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Textarea } from '@/components/ui/textarea';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';
import { 
  ShoppingCart, 
  Plus, 
  Minus, 
  Package, 
  MapPin,
  ChefHat,
  Trash2,
  Edit,
  Search,
  Filter
} from 'lucide-react';

interface MenuItem {
  id: number;
  name: string;
  price: number;
  description?: string;
  image_url?: string;
  is_available: boolean;
  category_id: number;
}

interface Category {
  id: number;
  name: string;
}

interface Supplement {
  id: number;
  name: string;
  price: number;
  type: 'extra' | 'garniture';
  is_available: boolean;
  is_obligatory: boolean;
}

interface CartItem {
  id: string;
  menu_item: MenuItem;
  quantity: number;
  selected_extras: Supplement[];
  selected_garnitures: Supplement[];
  total_price: number;
  special_instructions?: string;
}

interface Client {
  id: string;
  full_name: string;
  phone: string;
  email?: string;
  address?: string;
}

interface OrderBuilderProps {
  client: Client;
  cart: CartItem[];
  setCart: React.Dispatch<React.SetStateAction<CartItem[]>>;
  orderType: 'delivery' | 'pickup';
  setOrderType: React.Dispatch<React.SetStateAction<'delivery' | 'pickup'>>;
  onComplete: () => void;
}

const OrderBuilder: React.FC<OrderBuilderProps> = ({
  client,
  cart,
  setCart,
  orderType,
  setOrderType,
  onComplete
}) => {
  const { toast } = useToast();
  const [menuItems, setMenuItems] = useState<MenuItem[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [supplements, setSupplements] = useState<Supplement[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedItem, setSelectedItem] = useState<MenuItem | null>(null);
  const [isItemModalOpen, setIsItemModalOpen] = useState(false);
  const [quantity, setQuantity] = useState(1);
  const [selectedExtras, setSelectedExtras] = useState<Supplement[]>([]);
  const [selectedGarnitures, setSelectedGarnitures] = useState<Supplement[]>([]);
  const [specialInstructions, setSpecialInstructions] = useState('');

  // Charger les données
  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      setLoading(true);
      
      // Charger les catégories
      const { data: categoriesData, error: categoriesError } = await supabase
        .from('categories')
        .select('*')
        .eq('is_active', true)
        .order('name');

      if (categoriesError) throw categoriesError;

      // Charger les articles du menu
      const { data: menuData, error: menuError } = await supabase
        .from('menu_items')
        .select('*')
        .eq('is_available', true)
        .order('name');

      if (menuError) throw menuError;

      // Charger les suppléments
      const { data: supplementsData, error: supplementsError } = await supabase
        .from('supplements')
        .select('*')
        .eq('is_available', true)
        .order('name');

      if (supplementsError) throw supplementsError;

      setCategories(categoriesData || []);
      setMenuItems(menuData || []);
      setSupplements(supplementsData || []);
    } catch (error) {
      console.error('Erreur lors du chargement des données:', error);
      toast({
        title: "Erreur",
        description: "Impossible de charger les données du menu",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const getCategoryName = (categoryId: number) => {
    const category = categories.find(c => c.id === categoryId);
    return category?.name || 'Non catégorisé';
  };

  const filteredItems = menuItems.filter(item => {
    const matchesCategory = selectedCategory === 'all' || item.category_id.toString() === selectedCategory;
    const matchesSearch = item.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         item.description?.toLowerCase().includes(searchTerm.toLowerCase());
    return matchesCategory && matchesSearch;
  });

  const openItemModal = (item: MenuItem) => {
    setSelectedItem(item);
    setQuantity(1);
    setSelectedExtras([]);
    setSelectedGarnitures([]);
    setSpecialInstructions('');
    setIsItemModalOpen(true);
  };

  const addToCart = () => {
    if (!selectedItem) return;

    const extras = selectedExtras;
    const garnitures = selectedGarnitures;
    
    // Calculer le prix total
    const extrasPrice = extras.reduce((sum, extra) => sum + extra.price, 0);
    const garnituresPrice = garnitures.reduce((sum, garniture) => sum + garniture.price, 0);
    const totalPrice = (selectedItem.price + extrasPrice + garnituresPrice) * quantity;

    const cartItem: CartItem = {
      id: `${selectedItem.id}-${Date.now()}`,
      menu_item: selectedItem,
      quantity,
      selected_extras: extras,
      selected_garnitures: garnitures,
      total_price: totalPrice,
      special_instructions: specialInstructions.trim() || undefined
    };

    setCart(prev => [...prev, cartItem]);
    setIsItemModalOpen(false);
    
    toast({
      title: "Article ajouté",
      description: `${selectedItem.name} ajouté au panier`,
    });
  };

  const updateCartItemQuantity = (itemId: string, newQuantity: number) => {
    if (newQuantity <= 0) {
      removeFromCart(itemId);
      return;
    }

    setCart(prev => prev.map(item => {
      if (item.id === itemId) {
        const basePrice = item.menu_item.price + 
                         item.selected_extras.reduce((sum, extra) => sum + extra.price, 0) +
                         item.selected_garnitures.reduce((sum, garniture) => sum + garniture.price, 0);
        return {
          ...item,
          quantity: newQuantity,
          total_price: basePrice * newQuantity
        };
      }
      return item;
    }));
  };

  const removeFromCart = (itemId: string) => {
    setCart(prev => prev.filter(item => item.id !== itemId));
    toast({
      title: "Article supprimé",
      description: "Article retiré du panier",
    });
  };

  const getTotalPrice = () => {
    return cart.reduce((sum, item) => sum + item.total_price, 0);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-orange-500"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <Card className="bg-white/90 backdrop-blur-sm border-orange-200 shadow-lg">
        <CardHeader className="bg-gradient-to-r from-orange-50 to-red-50 border-b border-orange-200">
          <CardTitle className="text-orange-700 flex items-center gap-2">
            <ShoppingCart className="h-6 w-6" />
            Construction de la Commande
          </CardTitle>
        </CardHeader>
        <CardContent className="p-6">
          <div className="flex items-center justify-between mb-6">
            <div>
              <p className="text-gray-600">Client: <span className="font-semibold">{client.full_name}</span></p>
              <p className="text-sm text-gray-500">{client.phone}</p>
            </div>
            
            {/* Type de commande */}
            <div className="flex gap-4">
              <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                <div className="flex items-center gap-2">
                  <Switch
                    checked={orderType === 'delivery'}
                    onCheckedChange={(checked) => setOrderType(checked ? 'delivery' : 'pickup')}
                  />
                  <div>
                    <Label className="text-blue-700 font-medium">
                      {orderType === 'delivery' ? (
                        <div className="flex items-center gap-2">
                          <MapPin className="h-4 w-4" />
                          Livraison
                        </div>
                      ) : (
                        <div className="flex items-center gap-2">
                          <Package className="h-4 w-4" />
                          À emporter
                        </div>
                      )}
                    </Label>
                    <p className="text-xs text-blue-600">
                      {orderType === 'delivery' ? 'Commande à livrer' : 'Commande à récupérer'}
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Recherche */}
          <div className="mb-6">
            <Input
              placeholder="Rechercher un article..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="border-orange-300 focus:border-orange-500"
            />
          </div>
        </CardContent>
      </Card>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Menu */}
        <div className="lg:col-span-2">
          <Card className="bg-white/90 backdrop-blur-sm border-orange-200 shadow-lg">
            <CardHeader className="bg-gradient-to-r from-orange-50 to-red-50 border-b border-orange-200">
              <CardTitle className="text-orange-700 flex items-center gap-2">
                <ChefHat className="h-5 w-5" />
                Menu ({filteredItems.length} articles)
              </CardTitle>
            </CardHeader>
            <CardContent className="p-6">
              <Tabs value={selectedCategory} onValueChange={setSelectedCategory} className="w-full">
                <TabsList className="inline-flex w-full bg-orange-100 p-1 overflow-x-auto">
                  <TabsTrigger 
                    value="all" 
                    className="data-[state=active]:bg-white data-[state=active]:text-orange-600 data-[state=active]:shadow-sm whitespace-nowrap"
                  >
                    Tous ({menuItems.length})
                  </TabsTrigger>
                  {categories.map(category => {
                    const categoryItems = menuItems.filter(item => item.category_id === category.id);
                    return (
                      <TabsTrigger 
                        key={category.id} 
                        value={category.id.toString()}
                        className="data-[state=active]:bg-white data-[state=active]:text-orange-600 data-[state=active]:shadow-sm whitespace-nowrap"
                      >
                        {category.name} ({categoryItems.length})
                      </TabsTrigger>
                    );
                  })}
                </TabsList>
                
                <TabsContent value="all" className="mt-6">
                  {filteredItems.length === 0 ? (
                    <div className="text-center py-8">
                      <Search className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                      <p className="text-gray-600">Aucun article trouvé</p>
                      <p className="text-sm text-gray-500">Essayez avec d'autres critères de recherche</p>
                    </div>
                  ) : (
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      {filteredItems.map((item) => (
                        <div
                          key={item.id}
                          className="p-4 bg-white rounded-lg border border-orange-200 hover:bg-orange-50 transition-colors cursor-pointer"
                          onClick={() => openItemModal(item)}
                        >
                          <div className="flex items-start gap-3">
                            <div className="w-16 h-16 bg-gray-100 rounded-lg flex items-center justify-center">
                              {item.image_url ? (
                                <img
                                  src={item.image_url}
                                  alt={item.name}
                                  className="w-16 h-16 object-cover rounded-lg"
                                />
                              ) : (
                                <ChefHat className="h-8 w-8 text-gray-400" />
                              )}
                            </div>
                            <div className="flex-1">
                              <h3 className="font-semibold text-gray-800">{item.name}</h3>
                              <p className="text-sm text-gray-600 line-clamp-2">{item.description}</p>
                              <div className="flex items-center justify-between mt-2">
                                <Badge className="bg-orange-100 text-orange-800">
                                  {getCategoryName(item.category_id)}
                                </Badge>
                                <span className="font-bold text-green-600">
                                  {item.price.toLocaleString()} FCFA
                                </span>
                              </div>
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </TabsContent>
                
                {categories.map(category => {
                  const categoryItems = filteredItems.filter(item => item.category_id === category.id);
                  return (
                    <TabsContent key={category.id} value={category.id.toString()} className="mt-6">
                      {categoryItems.length === 0 ? (
                        <div className="text-center py-8">
                          <Search className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                          <p className="text-gray-600">Aucun article trouvé dans cette catégorie</p>
                          <p className="text-sm text-gray-500">Essayez avec d'autres critères de recherche</p>
                        </div>
                      ) : (
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                          {categoryItems.map((item) => (
                            <div
                              key={item.id}
                              className="p-4 bg-white rounded-lg border border-orange-200 hover:bg-orange-50 transition-colors cursor-pointer"
                              onClick={() => openItemModal(item)}
                            >
                              <div className="flex items-start gap-3">
                                <div className="w-16 h-16 bg-gray-100 rounded-lg flex items-center justify-center">
                                  {item.image_url ? (
                                    <img
                                      src={item.image_url}
                                      alt={item.name}
                                      className="w-16 h-16 object-cover rounded-lg"
                                    />
                                  ) : (
                                    <ChefHat className="h-8 w-8 text-gray-400" />
                                  )}
                                </div>
                                <div className="flex-1">
                                  <h3 className="font-semibold text-gray-800">{item.name}</h3>
                                  <p className="text-sm text-gray-600 line-clamp-2">{item.description}</p>
                                  <div className="flex items-center justify-between mt-2">
                                    <Badge className="bg-orange-100 text-orange-800">
                                      {getCategoryName(item.category_id)}
                                    </Badge>
                                    <span className="font-bold text-green-600">
                                      {item.price.toLocaleString()} FCFA
                                    </span>
                                  </div>
                                </div>
                              </div>
                            </div>
                          ))}
                        </div>
                      )}
                    </TabsContent>
                  );
                })}
              </Tabs>
            </CardContent>
          </Card>
        </div>

        {/* Panier */}
        <div>
          <Card className="bg-white/90 backdrop-blur-sm border-orange-200 shadow-lg">
            <CardHeader className="bg-gradient-to-r from-orange-50 to-red-50 border-b border-orange-200">
              <CardTitle className="text-orange-700 flex items-center gap-2">
                <ShoppingCart className="h-5 w-5" />
                Panier ({cart.length})
              </CardTitle>
            </CardHeader>
            <CardContent className="p-6">
              {cart.length === 0 ? (
                <div className="text-center py-8">
                  <ShoppingCart className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                  <p className="text-gray-600">Panier vide</p>
                  <p className="text-sm text-gray-500">Ajoutez des articles pour commencer</p>
                </div>
              ) : (
                <div className="space-y-4">
                  {cart.map((item) => (
                    <div key={item.id} className="p-3 bg-white rounded-lg border border-orange-200 hover:border-orange-300 transition-colors">
                      <div className="flex items-start justify-between mb-2">
                        <div className="flex-1">
                          <h4 className="font-semibold text-gray-800">{item.menu_item.name}</h4>
                          <div className="flex items-center gap-2 mt-2">
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => updateCartItemQuantity(item.id, item.quantity - 1)}
                              className="h-7 w-7 p-0 border-orange-300"
                            >
                              <Minus className="h-3 w-3" />
                            </Button>
                            <span className="text-sm font-semibold text-gray-700 min-w-[2rem] text-center">
                              {item.quantity}
                            </span>
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => updateCartItemQuantity(item.id, item.quantity + 1)}
                              className="h-7 w-7 p-0 border-orange-300"
                            >
                              <Plus className="h-3 w-3" />
                            </Button>
                          </div>
                        </div>
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => {
                            if (confirm(`Supprimer "${item.menu_item.name}" du panier?`)) {
                              removeFromCart(item.id);
                            }
                          }}
                          className="text-red-500 hover:text-red-700 hover:bg-red-50"
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                      
                      {item.selected_extras.length > 0 && (
                        <div className="mb-2">
                          <p className="text-xs font-medium text-purple-700 mb-1">Suppléments:</p>
                          {item.selected_extras.map((extra) => (
                            <p key={extra.id} className="text-xs text-purple-600">
                              + {extra.name} ({extra.price.toLocaleString()} FCFA)
                            </p>
                          ))}
                        </div>
                      )}
                      
                      {item.selected_garnitures.length > 0 && (
                        <div className="mb-2">
                          <p className="text-xs font-medium text-green-700 mb-1">Garnitures:</p>
                          {item.selected_garnitures.map((garniture) => (
                            <p key={garniture.id} className="text-xs text-green-600">
                              + {garniture.name} ({garniture.price.toLocaleString()} FCFA)
                            </p>
                          ))}
                        </div>
                      )}
                      
                      {item.special_instructions && (
                        <p className="text-xs text-blue-600 italic mb-2">
                          Note: {item.special_instructions}
                        </p>
                      )}
                      
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => updateCartItemQuantity(item.id, item.quantity - 1)}
                            className="h-6 w-6 p-0"
                          >
                            <Minus className="h-3 w-3" />
                          </Button>
                          <span className="text-sm font-medium">{item.quantity}</span>
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => updateCartItemQuantity(item.id, item.quantity + 1)}
                            className="h-6 w-6 p-0"
                          >
                            <Plus className="h-3 w-3" />
                          </Button>
                        </div>
                        <span className="font-bold text-green-600">
                          {item.total_price.toLocaleString()} FCFA
                        </span>
                      </div>
                    </div>
                  ))}
                  
                  <div className="border-t border-orange-200 pt-4">
                    <div className="flex justify-between items-center font-bold text-lg">
                      <span>Total:</span>
                      <span className="text-green-600">{getTotalPrice().toLocaleString()} FCFA</span>
                    </div>
                  </div>
                  
                  <Button
                    onClick={onComplete}
                    disabled={cart.length === 0}
                    className="w-full bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 text-white"
                  >
                    Continuer la Commande
                  </Button>
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Modal d'ajout d'article */}
      <Dialog open={isItemModalOpen} onOpenChange={setIsItemModalOpen}>
        <DialogContent className="bg-gradient-to-br from-orange-50 via-red-50 to-yellow-50 border-orange-200 max-w-4xl w-[90vw] max-h-[90vh] overflow-y-auto">
          <DialogHeader className="border-b border-orange-200 pb-4">
            <DialogTitle className="flex items-center gap-2 text-orange-700">
              <ChefHat className="h-5 w-5" />
              {selectedItem?.name}
            </DialogTitle>
          </DialogHeader>
          
          {selectedItem && (
            <div className="space-y-6 py-4">
              {/* Informations de base */}
              <div className="flex gap-4">
                <div className="w-24 h-24 bg-gray-100 rounded-lg flex items-center justify-center">
                  {selectedItem.image_url ? (
                    <img
                      src={selectedItem.image_url}
                      alt={selectedItem.name}
                      className="w-24 h-24 object-cover rounded-lg"
                    />
                  ) : (
                    <ChefHat className="h-12 w-12 text-gray-400" />
                  )}
                </div>
                <div className="flex-1">
                  <h3 className="text-xl font-semibold text-gray-800">{selectedItem.name}</h3>
                  <p className="text-gray-600">{selectedItem.description}</p>
                  <div className="flex items-center gap-2 mt-2">
                    <Badge className="bg-orange-100 text-orange-800">
                      {getCategoryName(selectedItem.category_id)}
                    </Badge>
                    <span className="text-2xl font-bold text-green-600">
                      {selectedItem.price.toLocaleString()} FCFA
                    </span>
                  </div>
                </div>
              </div>

              {/* Suppléments */}
              <div className="space-y-4">
                <h4 className="font-semibold text-purple-700">Suppléments (optionnels)</h4>
                <div className="grid grid-cols-1 gap-2">
                  {supplements.filter(s => s.type === 'extra').map((supplement) => (
                    <div key={supplement.id} className="flex items-center justify-between p-3 bg-purple-50 rounded-lg border border-purple-200">
                      <div className="flex items-center gap-3">
                        <Switch
                          checked={selectedExtras.some(e => e.id === supplement.id)}
                          onCheckedChange={(checked) => {
                            if (checked) {
                              setSelectedExtras([...selectedExtras, supplement]);
                            } else {
                              setSelectedExtras(selectedExtras.filter(e => e.id !== supplement.id));
                            }
                          }}
                        />
                        <div>
                          <p className="font-medium text-purple-800">{supplement.name}</p>
                          <p className="text-sm text-purple-600">+{supplement.price.toLocaleString()} FCFA</p>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Garnitures */}
              <div className="space-y-4">
                <h4 className="font-semibold text-green-700">Garnitures</h4>
                <div className="grid grid-cols-1 gap-2">
                  {supplements.filter(s => s.type === 'garniture').map((supplement) => (
                    <div key={supplement.id} className="flex items-center justify-between p-3 bg-green-50 rounded-lg border border-green-200">
                      <div className="flex items-center gap-3">
                        <Switch
                          checked={selectedGarnitures.some(g => g.id === supplement.id)}
                          onCheckedChange={(checked) => {
                            if (checked) {
                              setSelectedGarnitures([...selectedGarnitures, supplement]);
                            } else {
                              setSelectedGarnitures(selectedGarnitures.filter(g => g.id !== supplement.id));
                            }
                          }}
                        />
                        <div>
                          <p className="font-medium text-green-800">{supplement.name}</p>
                          <p className="text-sm text-green-600">+{supplement.price.toLocaleString()} FCFA</p>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Quantité */}
              <div className="space-y-2">
                <Label className="text-orange-700 font-medium">Quantité</Label>
                <div className="flex items-center gap-4">
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setQuantity(Math.max(1, quantity - 1))}
                    className="h-10 w-10"
                  >
                    <Minus className="h-4 w-4" />
                  </Button>
                  <span className="text-xl font-bold w-12 text-center">{quantity}</span>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setQuantity(quantity + 1)}
                    className="h-10 w-10"
                  >
                    <Plus className="h-4 w-4" />
                  </Button>
                </div>
              </div>

              {/* Instructions spéciales */}
              <div className="space-y-2">
                <Label className="text-orange-700 font-medium">Instructions spéciales</Label>
                <Textarea
                  value={specialInstructions}
                  onChange={(e) => setSpecialInstructions(e.target.value)}
                  placeholder="Ex: Sans oignons, bien cuit..."
                  className="border-orange-300 focus:border-orange-500"
                />
              </div>

              {/* Prix total */}
              <div className="bg-green-50 border border-green-200 rounded-lg p-4">
                <div className="flex justify-between items-center">
                  <span className="font-semibold text-green-800">Prix total:</span>
                  <span className="text-2xl font-bold text-green-600">
                    {((selectedItem.price + 
                       selectedExtras.reduce((sum, e) => sum + e.price, 0) +
                       selectedGarnitures.reduce((sum, g) => sum + g.price, 0)) * quantity).toLocaleString()} FCFA
                  </span>
                </div>
              </div>
            </div>
          )}

          <div className="flex gap-3 pt-4 border-t border-orange-200">
            <Button
              variant="outline"
              onClick={() => setIsItemModalOpen(false)}
              className="flex-1 border-orange-300 text-orange-600 hover:bg-orange-50"
            >
              Annuler
            </Button>
            <Button
              onClick={addToCart}
              className="flex-1 bg-gradient-to-r from-green-500 to-emerald-500 hover:from-green-600 hover:to-emerald-600 text-white"
            >
              Ajouter au Panier
            </Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default OrderBuilder;
