import { useState, useEffect } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { useToast } from "@/hooks/use-toast";
import { 
  Search, 
  Eye, 
  Mail, 
  Phone, 
  Users, 
  UserPlus, 
  Filter,
  Download,
  ArrowLeft,
  Calendar,
  MapPin,
  TrendingUp,
  Edit,
  Trash2,
  Plus,
  X,
  Package,
  DollarSign,
  ShoppingCart,
  Clock,
  BarChart3
} from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { Link } from "react-router-dom";

interface User {
  id: string;
  full_name: string | null;
  email: string | null;
  phone: string | null;
  address: string | null;
  is_active: boolean;
  created_at: string;
}

interface ClientOrder {
  id: number;
  status: string;
  total_amount: number;
  created_at: string;
  delivery_type: string;
  order_items: Array<{
    item_name: string;
    quantity: number;
    menu_items?: {
      name: string;
      image_url: string | null;
    } | null;
  }>;
}

interface ClientStats {
  total_orders: number;
  total_spent: number;
  average_order_value: number;
  last_order_date: string | null;
  favorite_items: Array<{ name: string; quantity: number }>;
}

const AdminClients = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [searchTerm, setSearchTerm] = useState("");
  const [loading, setLoading] = useState(true);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [isViewModalOpen, setIsViewModalOpen] = useState(false);
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
  const { toast } = useToast();

  // États pour les statistiques du client
  const [clientOrders, setClientOrders] = useState<ClientOrder[]>([]);
  const [clientStats, setClientStats] = useState<ClientStats>({
    total_orders: 0,
    total_spent: 0,
    average_order_value: 0,
    last_order_date: null,
    favorite_items: []
  });
  const [loadingClientData, setLoadingClientData] = useState(false);

  // États pour le formulaire de création/édition
  const [formData, setFormData] = useState({
    full_name: '',
    email: '',
    phone: '',
    address: '',
    is_active: true
  });

  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    try {
      const { data, error } = await supabase
        .from('users')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      setUsers(data || []);
    } catch (error) {
      console.error('Error fetching users:', error);
      toast({
        title: "Erreur",
        description: "Impossible de charger les clients",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const handleViewUser = async (user: User) => {
    setSelectedUser(user);
    setIsViewModalOpen(true);
    await fetchClientData(user.id);
  };

  const fetchClientData = async (userId: string) => {
    try {
      setLoadingClientData(true);
      
      // Récupérer les commandes du client
      const { data: ordersData, error: ordersError } = await supabase
        .from('orders')
        .select(`
          id,
          status,
          total_amount,
          created_at,
          delivery_type,
          order_items (
            item_name,
            quantity,
            menu_items (
              name,
              image_url
            )
          )
        `)
        .eq('user_id', userId)
        .order('created_at', { ascending: false });

      if (ordersError) throw ordersError;

      const orders = ordersData || [];
      setClientOrders(orders as ClientOrder[]);

      // Calculer les statistiques
      const totalOrders = orders.length;
      const totalSpent = orders.reduce((sum, order) => sum + (order.total_amount || 0), 0);
      const averageOrderValue = totalOrders > 0 ? totalSpent / totalOrders : 0;
      const lastOrderDate = orders.length > 0 ? orders[0].created_at : null;

      // Calculer les plats favoris
      const itemCounts: { [key: string]: number } = {};
      orders.forEach(order => {
        (order.order_items as any[]).forEach(item => {
          const itemName = item.menu_items?.name || item.item_name;
          itemCounts[itemName] = (itemCounts[itemName] || 0) + item.quantity;
        });
      });

      const favoriteItems = Object.entries(itemCounts)
        .map(([name, quantity]) => ({ name, quantity }))
        .sort((a, b) => b.quantity - a.quantity)
        .slice(0, 5);

      setClientStats({
        total_orders: totalOrders,
        total_spent: totalSpent,
        average_order_value: averageOrderValue,
        last_order_date: lastOrderDate,
        favorite_items: favoriteItems
      });
    } catch (error) {
      console.error('Erreur lors du chargement des données du client:', error);
      toast({
        title: "Erreur",
        description: "Impossible de charger les statistiques du client",
        variant: "destructive",
      });
    } finally {
      setLoadingClientData(false);
    }
  };

  const formatPrice = (price: number) => {
    return `${price.toLocaleString('fr-FR')} FCFA`;
  };

  const handleEditUser = (user: User) => {
    setSelectedUser(user);
    setFormData({
      full_name: user.full_name || '',
      email: user.email || '',
      phone: user.phone || '',
      address: user.address || '',
      is_active: user.is_active
    });
    setIsEditModalOpen(true);
  };

  const handleDeleteUser = (user: User) => {
    setSelectedUser(user);
    setIsDeleteModalOpen(true);
  };

  const handleCreateUser = async () => {
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

      // Préparer les données pour l'insertion
      const userData: any = {
        id: crypto.randomUUID(), // Générer un UUID pour l'ID
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
        .select();

      if (error) {
        console.error('Supabase error:', error);
        throw error;
      }

      toast({
        title: "Succès",
        description: `Client "${formData.full_name}" créé avec succès`,
      });

      setIsCreateModalOpen(false);
      setFormData({
        full_name: '',
        email: '',
        phone: '',
        address: '',
        is_active: true
      });
      fetchUsers();
    } catch (error: any) {
      console.error('Error creating user:', error);
      toast({
        title: "Erreur",
        description: error.message || "Impossible de créer le client",
        variant: "destructive",
      });
    }
  };

  const handleUpdateUser = async () => {
    if (!selectedUser) return;

    try {
      const { error } = await supabase
        .from('users')
        .update({
          full_name: formData.full_name,
          email: formData.email,
          phone: formData.phone,
          address: formData.address,
          is_active: formData.is_active
        })
        .eq('id', selectedUser.id);

      if (error) throw error;

      toast({
        title: "Succès",
        description: "Client modifié avec succès",
      });

      setIsEditModalOpen(false);
      setSelectedUser(null);
      fetchUsers();
    } catch (error) {
      console.error('Error updating user:', error);
      toast({
        title: "Erreur",
        description: "Impossible de modifier le client",
        variant: "destructive",
      });
    }
  };

  const handleConfirmDelete = async () => {
    if (!selectedUser) return;

    try {
      const { error } = await supabase
        .from('users')
        .update({ is_active: false })
        .eq('id', selectedUser.id);

      if (error) throw error;

      toast({
        title: "Succès",
        description: "Client désactivé avec succès",
      });

      setIsDeleteModalOpen(false);
      setSelectedUser(null);
      fetchUsers();
    } catch (error) {
      console.error('Error deleting user:', error);
      toast({
        title: "Erreur",
        description: "Impossible de désactiver le client",
        variant: "destructive",
      });
    }
  };

  const filteredUsers = users.filter(user =>
    user.full_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    user.email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    user.phone?.includes(searchTerm)
  );

  const activeUsers = users.filter(user => user.is_active).length;
  const newUsersToday = users.filter(user => {
    const today = new Date().toISOString().split('T')[0];
    return user.created_at.startsWith(today);
  }).length;

  return (
    <div className="min-h-screen bg-gradient-to-br from-orange-50 via-red-50 to-yellow-50">
      {/* Header */}
      <div className="bg-white/90 backdrop-blur-sm border-b border-orange-200 sticky top-0 z-50">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <Button variant="ghost" asChild className="text-gray-600 hover:text-orange-600">
                <Link to="/admin">
                  <ArrowLeft className="h-4 w-4 mr-2" />
                  Retour
                </Link>
              </Button>
              <div>
                <h1 className="text-2xl font-bold bg-gradient-to-r from-orange-600 to-red-600 bg-clip-text text-transparent">
                  Gestion des Clients
                </h1>
                <p className="text-sm text-gray-600">
                  Gérez votre base client et leurs informations
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="container mx-auto px-4 py-8">
        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <Card className="bg-white/90 backdrop-blur-sm border-orange-200 hover:shadow-lg transition-shadow">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Total Clients</p>
                  <p className="text-3xl font-bold text-orange-600">{users.length}</p>
                  <p className="text-xs text-green-600 flex items-center gap-1">
                    <TrendingUp className="h-3 w-3" />
                    +{newUsersToday} aujourd'hui
                  </p>
                </div>
                <div className="h-12 w-12 bg-orange-100 rounded-full flex items-center justify-center">
                  <Users className="h-6 w-6 text-orange-600" />
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="bg-white/90 backdrop-blur-sm border-green-200 hover:shadow-lg transition-shadow">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Clients Actifs</p>
                  <p className="text-3xl font-bold text-green-600">{activeUsers}</p>
                  <p className="text-xs text-green-600">
                    {users.length > 0 ? Math.round((activeUsers / users.length) * 100) : 0}% du total
                  </p>
                </div>
                <div className="h-12 w-12 bg-green-100 rounded-full flex items-center justify-center">
                  <UserPlus className="h-6 w-6 text-green-600" />
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="bg-white/90 backdrop-blur-sm border-blue-200 hover:shadow-lg transition-shadow">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Nouveaux Aujourd'hui</p>
                  <p className="text-3xl font-bold text-blue-600">{newUsersToday}</p>
                  <p className="text-xs text-blue-600 flex items-center gap-1">
                    <Calendar className="h-3 w-3" />
                    Inscriptions récentes
                  </p>
                </div>
                <div className="h-12 w-12 bg-blue-100 rounded-full flex items-center justify-center">
                  <Calendar className="h-6 w-6 text-blue-600" />
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Main Content */}
        <Card className="bg-white/90 backdrop-blur-sm border-orange-200 shadow-lg">
          <CardHeader>
            <div className="flex items-center justify-between">
              <div>
                <CardTitle className="flex items-center gap-2 text-orange-600">
                  <Users className="h-5 w-5" />
                  Liste des Clients
                </CardTitle>
                <CardDescription>
                  {filteredUsers.length} client(s) trouvé(s) sur {users.length} total
                </CardDescription>
              </div>
              <div className="flex items-center space-x-3">
                <div className="relative">
                  <Search className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
                  <Input
                    placeholder="Rechercher un client..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="pl-10 w-64 border-gray-300 focus:border-orange-500 focus:ring-orange-500"
                  />
                </div>
                <Button variant="outline" className="border-orange-300 text-orange-600 hover:bg-orange-50">
                  <Filter className="h-4 w-4 mr-2" />
                  Filtrer
                </Button>
                <Button variant="outline" className="border-green-300 text-green-600 hover:bg-green-50">
                  <Download className="h-4 w-4 mr-2" />
                  Exporter
                </Button>
                <Button 
                  onClick={() => setIsCreateModalOpen(true)}
                  className="bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 text-white"
                >
                  <Plus className="h-4 w-4 mr-2" />
                  Nouveau Client
                </Button>
              </div>
            </div>
          </CardHeader>
          <CardContent>
            {loading ? (
              <div className="text-center py-12">
                <div className="animate-spin rounded-full h-12 w-12 border-4 border-orange-200 border-t-orange-600 mx-auto mb-4"></div>
                <p className="text-gray-600">Chargement des clients...</p>
              </div>
            ) : (
              <div className="rounded-lg border border-gray-200 overflow-hidden">
                <Table>
                  <TableHeader className="bg-orange-50">
                    <TableRow>
                      <TableHead className="text-orange-700 font-semibold">Nom Complet</TableHead>
                      <TableHead className="text-orange-700 font-semibold">Email</TableHead>
                      <TableHead className="text-orange-700 font-semibold">Téléphone</TableHead>
                      <TableHead className="text-orange-700 font-semibold">Adresse</TableHead>
                      <TableHead className="text-orange-700 font-semibold">Statut</TableHead>
                      <TableHead className="text-orange-700 font-semibold">Inscrit le</TableHead>
                      <TableHead className="text-orange-700 font-semibold">Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {filteredUsers.map((user) => (
                      <TableRow key={user.id} className="hover:bg-orange-50/50 transition-colors">
                        <TableCell className="font-medium">
                          <div className="flex items-center gap-2">
                            <div className="h-8 w-8 bg-gradient-to-br from-orange-100 to-red-100 rounded-full flex items-center justify-center">
                              <Users className="h-4 w-4 text-orange-600" />
                            </div>
                            <span className="font-medium text-gray-800">
                              {user.full_name || "Non renseigné"}
                            </span>
                          </div>
                        </TableCell>
                        <TableCell>
                          <div className="flex items-center space-x-2">
                            <Mail className="h-4 w-4 text-orange-500" />
                            <span className="text-gray-700">{user.email || "Non renseigné"}</span>
                          </div>
                        </TableCell>
                        <TableCell>
                          <div className="flex items-center space-x-2">
                            <Phone className="h-4 w-4 text-green-500" />
                            <span className="text-gray-700">{user.phone || "Non renseigné"}</span>
                          </div>
                        </TableCell>
                        <TableCell>
                          <div className="flex items-center space-x-2">
                            <MapPin className="h-4 w-4 text-blue-500" />
                            <span className="text-gray-700">{user.address || "Non renseignée"}</span>
                          </div>
                        </TableCell>
                        <TableCell>
                          <Badge 
                            className={user.is_active 
                              ? "bg-green-100 text-green-800 border-green-200" 
                              : "bg-red-100 text-red-800 border-red-200"
                            }
                          >
                            {user.is_active ? "Actif" : "Inactif"}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          <div className="flex items-center space-x-2">
                            <Calendar className="h-4 w-4 text-gray-400" />
                            <span className="text-gray-600">
                              {new Date(user.created_at).toLocaleDateString('fr-FR')}
                            </span>
                          </div>
                        </TableCell>
                        <TableCell>
                          <div className="flex items-center gap-2">
                            <Button 
                              variant="outline" 
                              size="sm" 
                              className="border-orange-300 text-orange-600 hover:bg-orange-50"
                              onClick={() => handleViewUser(user)}
                            >
                              <Eye className="h-4 w-4" />
                            </Button>
                            <Button 
                              variant="outline" 
                              size="sm" 
                              className="border-blue-300 text-blue-600 hover:bg-blue-50"
                              onClick={() => handleEditUser(user)}
                            >
                              <Edit className="h-4 w-4" />
                            </Button>
                            <Button 
                              variant="outline" 
                              size="sm" 
                              className="border-red-300 text-red-600 hover:bg-red-50"
                              onClick={() => handleDeleteUser(user)}
                            >
                              <Trash2 className="h-4 w-4" />
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))}
                    {filteredUsers.length === 0 && (
                      <TableRow>
                        <TableCell colSpan={7} className="text-center py-12">
                          <div className="flex flex-col items-center gap-4">
                            <div className="h-16 w-16 bg-gray-100 rounded-full flex items-center justify-center">
                              <Users className="h-8 w-8 text-gray-400" />
                            </div>
                            <div>
                              <h3 className="text-lg font-medium text-gray-600">Aucun client trouvé</h3>
                              <p className="text-sm text-gray-500">
                                {searchTerm ? "Essayez avec d'autres mots-clés" : "Aucun client enregistré pour le moment"}
                              </p>
                            </div>
                          </div>
                        </TableCell>
                      </TableRow>
                    )}
                  </TableBody>
                </Table>
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Modal de visualisation du client */}
      <Dialog open={isViewModalOpen} onOpenChange={setIsViewModalOpen}>
        <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2 text-orange-600">
              <Eye className="h-5 w-5" />
              Détails du Client
            </DialogTitle>
            <DialogDescription>
              Informations complètes et statistiques du client
            </DialogDescription>
          </DialogHeader>
          {selectedUser && (
            <Tabs defaultValue="info" className="w-full">
              <TabsList className="grid w-full grid-cols-3">
                <TabsTrigger value="info">
                  <UserPlus className="h-4 w-4 mr-2" />
                  Informations
                </TabsTrigger>
                <TabsTrigger value="stats">
                  <BarChart3 className="h-4 w-4 mr-2" />
                  Statistiques
                </TabsTrigger>
                <TabsTrigger value="orders">
                  <ShoppingCart className="h-4 w-4 mr-2" />
                  Commandes
                </TabsTrigger>
              </TabsList>

              <TabsContent value="info" className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="space-y-4">
                    <div>
                      <Label className="text-sm font-medium text-gray-600">Nom Complet</Label>
                      <p className="text-lg font-semibold text-gray-800">
                        {selectedUser.full_name || "Non renseigné"}
                      </p>
                    </div>
                    <div>
                      <Label className="text-sm font-medium text-gray-600">Email</Label>
                      <p className="text-gray-800 flex items-center gap-2">
                        <Mail className="h-4 w-4 text-orange-500" />
                        {selectedUser.email || "Non renseigné"}
                      </p>
                    </div>
                    <div>
                      <Label className="text-sm font-medium text-gray-600">Téléphone</Label>
                      <p className="text-gray-800 flex items-center gap-2">
                        <Phone className="h-4 w-4 text-green-500" />
                        {selectedUser.phone || "Non renseigné"}
                      </p>
                    </div>
                  </div>
                  <div className="space-y-4">
                    <div>
                      <Label className="text-sm font-medium text-gray-600">Adresse</Label>
                      <p className="text-gray-800 flex items-center gap-2">
                        <MapPin className="h-4 w-4 text-blue-500" />
                        {selectedUser.address || "Non renseignée"}
                      </p>
                    </div>
                    <div>
                      <Label className="text-sm font-medium text-gray-600">Statut</Label>
                      <div className="mt-1">
                        <Badge 
                          className={selectedUser.is_active 
                            ? "bg-green-100 text-green-800 border-green-200" 
                            : "bg-red-100 text-red-800 border-red-200"
                          }
                        >
                          {selectedUser.is_active ? "Actif" : "Inactif"}
                        </Badge>
                      </div>
                    </div>
                    <div>
                      <Label className="text-sm font-medium text-gray-600">Date d'inscription</Label>
                      <p className="text-gray-800 flex items-center gap-2">
                        <Calendar className="h-4 w-4 text-gray-400" />
                        {new Date(selectedUser.created_at).toLocaleDateString('fr-FR', {
                          year: 'numeric',
                          month: 'long',
                          day: 'numeric',
                          hour: '2-digit',
                          minute: '2-digit'
                        })}
                      </p>
                    </div>
                  </div>
                </div>
              </TabsContent>

              <TabsContent value="stats" className="space-y-6">
                {loadingClientData ? (
                  <div className="flex items-center justify-center py-12">
                    <div className="text-center">
                      <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-orange-600 mb-4"></div>
                      <p className="text-sm text-gray-600">Chargement des statistiques...</p>
                    </div>
                  </div>
                ) : (
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <Card className="bg-gradient-to-br from-orange-50 to-red-50 border-orange-200">
                      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                        <CardTitle className="text-sm font-medium text-gray-600">
                          Total des Commandes
                        </CardTitle>
                        <Package className="h-4 w-4 text-orange-600" />
                      </CardHeader>
                      <CardContent>
                        <div className="text-3xl font-bold text-orange-600">
                          {clientStats.total_orders}
                        </div>
                      </CardContent>
                    </Card>

                    <Card className="bg-gradient-to-br from-green-50 to-emerald-50 border-green-200">
                      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                        <CardTitle className="text-sm font-medium text-gray-600">
                          Montant Total Dépensé
                        </CardTitle>
                        <DollarSign className="h-4 w-4 text-green-600" />
                      </CardHeader>
                      <CardContent>
                        <div className="text-2xl font-bold text-green-600">
                          {formatPrice(clientStats.total_spent)}
                        </div>
                      </CardContent>
                    </Card>

                    <Card className="bg-gradient-to-br from-blue-50 to-cyan-50 border-blue-200">
                      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                        <CardTitle className="text-sm font-medium text-gray-600">
                          Commande Moyenne
                        </CardTitle>
                        <TrendingUp className="h-4 w-4 text-blue-600" />
                      </CardHeader>
                      <CardContent>
                        <div className="text-2xl font-bold text-blue-600">
                          {formatPrice(clientStats.average_order_value)}
                        </div>
                      </CardContent>
                    </Card>

                    <Card className="bg-gradient-to-br from-purple-50 to-pink-50 border-purple-200">
                      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                        <CardTitle className="text-sm font-medium text-gray-600">
                          Dernière Commande
                        </CardTitle>
                        <Clock className="h-4 w-4 text-purple-600" />
                      </CardHeader>
                      <CardContent>
                        <div className="text-sm font-bold text-purple-600">
                          {clientStats.last_order_date 
                            ? new Date(clientStats.last_order_date).toLocaleDateString('fr-FR', {
                                year: 'numeric',
                                month: 'long',
                                day: 'numeric'
                              })
                            : 'Aucune commande'
                          }
                        </div>
                      </CardContent>
                    </Card>
                  </div>
                )}

                {clientStats.favorite_items.length > 0 && (
                  <Card>
                    <CardHeader>
                      <CardTitle className="text-lg font-semibold">Plats Favoris</CardTitle>
                    </CardHeader>
                    <CardContent>
                      <div className="space-y-3">
                        {clientStats.favorite_items.map((item, index) => (
                          <div key={index} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                            <div className="flex items-center gap-3">
                              <div className="flex items-center justify-center w-8 h-8 bg-orange-100 text-orange-600 rounded-full font-bold">
                                {index + 1}
                              </div>
                              <span className="font-medium">{item.name}</span>
                            </div>
                            <Badge className="bg-orange-100 text-orange-800">
                              {item.quantity} {item.quantity > 1 ? 'fois' : 'fois'}
                            </Badge>
                          </div>
                        ))}
                      </div>
                    </CardContent>
                  </Card>
                )}
              </TabsContent>

              <TabsContent value="orders" className="space-y-6">
                {loadingClientData ? (
                  <div className="flex items-center justify-center py-12">
                    <div className="text-center">
                      <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-orange-600 mb-4"></div>
                      <p className="text-sm text-gray-600">Chargement des commandes...</p>
                    </div>
                  </div>
                ) : clientOrders.length === 0 ? (
                  <div className="text-center py-12">
                    <Package className="h-16 w-16 text-gray-300 mx-auto mb-4" />
                    <h3 className="text-lg font-medium text-gray-600 mb-2">Aucune commande</h3>
                    <p className="text-sm text-gray-500">Ce client n'a pas encore passé de commande</p>
                  </div>
                ) : (
                  <div className="space-y-4">
                    {clientOrders.map((order) => (
                      <Card key={order.id} className="border-l-4 border-l-orange-500">
                        <CardHeader>
                          <div className="flex items-center justify-between">
                            <CardTitle className="text-lg">Commande #{order.id}</CardTitle>
                            <Badge className={`${
                              order.status === 'delivered' ? 'bg-green-100 text-green-800' :
                              order.status === 'pending' ? 'bg-yellow-100 text-yellow-800' :
                              order.status === 'preparing' ? 'bg-blue-100 text-blue-800' :
                              'bg-gray-100 text-gray-800'
                            }`}>
                              {order.status}
                            </Badge>
                          </div>
                          <div className="flex items-center gap-4 text-sm text-gray-600">
                            <span className="flex items-center gap-1">
                              <Calendar className="h-4 w-4" />
                              {new Date(order.created_at).toLocaleDateString('fr-FR')}
                            </span>
                            <span className="flex items-center gap-1">
                              <Package className="h-4 w-4" />
                              {order.delivery_type === 'delivery' ? 'Livraison' : 'À emporter'}
                            </span>
                            <span className="flex items-center gap-1 font-bold text-orange-600">
                              <DollarSign className="h-4 w-4" />
                              {formatPrice(order.total_amount)}
                            </span>
                          </div>
                        </CardHeader>
                        <CardContent>
                          <div className="space-y-2">
                            {order.order_items.map((item, idx) => (
                              <div key={idx} className="flex items-center justify-between p-2 bg-gray-50 rounded">
                                <div className="flex items-center gap-3">
                                  {item.menu_items?.image_url && (
                                    <img 
                                      src={item.menu_items.image_url} 
                                      alt={item.menu_items.name}
                                      className="w-10 h-10 rounded object-cover"
                                    />
                                  )}
                                  <span className="font-medium">{item.menu_items?.name || item.item_name}</span>
                                </div>
                                <Badge variant="outline" className="ml-auto">
                                  x{item.quantity}
                                </Badge>
                              </div>
                            ))}
                          </div>
                        </CardContent>
                      </Card>
                    ))}
                  </div>
                )}
              </TabsContent>
            </Tabs>
          )}
          <div className="flex justify-end gap-3 pt-4 border-t mt-4">
            <Button 
              variant="outline" 
              onClick={() => setIsViewModalOpen(false)}
            >
              Fermer
            </Button>
            <Button 
              onClick={() => {
                setIsViewModalOpen(false);
                handleEditUser(selectedUser);
              }}
              className="bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 text-white"
            >
              <Edit className="h-4 w-4 mr-2" />
              Modifier
            </Button>
          </div>
        </DialogContent>
      </Dialog>

      {/* Modal de création de client */}
      <Dialog open={isCreateModalOpen} onOpenChange={setIsCreateModalOpen}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2 text-orange-600">
              <UserPlus className="h-5 w-5" />
              Nouveau Client
            </DialogTitle>
            <DialogDescription>
              Créer un nouveau client dans le système
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="create_full_name">Nom Complet *</Label>
                <Input
                  id="create_full_name"
                  value={formData.full_name}
                  onChange={(e) => setFormData({...formData, full_name: e.target.value})}
                  placeholder="Nom et prénom"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="create_email">Email</Label>
                <Input
                  id="create_email"
                  type="email"
                  value={formData.email}
                  onChange={(e) => setFormData({...formData, email: e.target.value})}
                  placeholder="email@exemple.com"
                />
              </div>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="create_phone">Téléphone *</Label>
                <Input
                  id="create_phone"
                  value={formData.phone}
                  onChange={(e) => setFormData({...formData, phone: e.target.value})}
                  placeholder="+225 XX XX XX XX"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="create_address">Adresse</Label>
                <Textarea
                  id="create_address"
                  value={formData.address}
                  onChange={(e) => setFormData({...formData, address: e.target.value})}
                  placeholder="Adresse complète"
                  rows={3}
                />
              </div>
            </div>
            <div className="flex items-center space-x-2">
              <input
                type="checkbox"
                id="create_is_active"
                checked={formData.is_active}
                onChange={(e) => setFormData({...formData, is_active: e.target.checked})}
                className="rounded"
              />
              <Label htmlFor="create_is_active">Client actif</Label>
            </div>
            <div className="bg-orange-50 border border-orange-200 rounded-lg p-4">
              <p className="text-sm text-orange-800">
                <strong>Note :</strong> Le client recevra un mot de passe par défaut lors de sa première connexion.
              </p>
              <p className="text-xs text-orange-600 mt-1">
                Il pourra changer ce mot de passe dans ses paramètres.
              </p>
            </div>
            <div className="flex justify-end gap-3 pt-4 border-t">
              <Button 
                variant="outline" 
                onClick={() => setIsCreateModalOpen(false)}
              >
                Annuler
              </Button>
              <Button 
                onClick={handleCreateUser}
                className="bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 text-white"
              >
                <UserPlus className="h-4 w-4 mr-2" />
                Créer le Client
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Modal d'édition de client */}
      <Dialog open={isEditModalOpen} onOpenChange={setIsEditModalOpen}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2 text-orange-600">
              <Edit className="h-5 w-5" />
              Modifier le Client
            </DialogTitle>
            <DialogDescription>
              Modifier les informations du client
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="edit_full_name">Nom Complet *</Label>
                <Input
                  id="edit_full_name"
                  value={formData.full_name}
                  onChange={(e) => setFormData({...formData, full_name: e.target.value})}
                  placeholder="Nom et prénom"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="edit_email">Email</Label>
                <Input
                  id="edit_email"
                  type="email"
                  value={formData.email}
                  onChange={(e) => setFormData({...formData, email: e.target.value})}
                  placeholder="email@exemple.com"
                />
              </div>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label htmlFor="edit_phone">Téléphone *</Label>
                <Input
                  id="edit_phone"
                  value={formData.phone}
                  onChange={(e) => setFormData({...formData, phone: e.target.value})}
                  placeholder="+225 XX XX XX XX"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="edit_address">Adresse</Label>
                <Textarea
                  id="edit_address"
                  value={formData.address}
                  onChange={(e) => setFormData({...formData, address: e.target.value})}
                  placeholder="Adresse complète"
                  rows={3}
                />
              </div>
            </div>
            <div className="flex items-center space-x-2">
              <input
                type="checkbox"
                id="edit_is_active"
                checked={formData.is_active}
                onChange={(e) => setFormData({...formData, is_active: e.target.checked})}
                className="rounded"
              />
              <Label htmlFor="edit_is_active">Client actif</Label>
            </div>
            <div className="flex justify-end gap-3 pt-4 border-t">
              <Button 
                variant="outline" 
                onClick={() => setIsEditModalOpen(false)}
              >
                Annuler
              </Button>
              <Button 
                onClick={handleUpdateUser}
                className="bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 text-white"
              >
                <Edit className="h-4 w-4 mr-2" />
                Enregistrer
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Modal de suppression */}
      <Dialog open={isDeleteModalOpen} onOpenChange={setIsDeleteModalOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2 text-red-600">
              <Trash2 className="h-5 w-5" />
              Désactiver le Client
            </DialogTitle>
            <DialogDescription>
              Êtes-vous sûr de vouloir désactiver ce client ? Cette action peut être annulée.
            </DialogDescription>
          </DialogHeader>
          {selectedUser && (
            <div className="space-y-4">
              <div className="bg-red-50 border border-red-200 rounded-lg p-4">
                <p className="text-sm text-red-800">
                  <strong>Client :</strong> {selectedUser.full_name || "Non renseigné"}
                </p>
                <p className="text-sm text-red-800">
                  <strong>Email :</strong> {selectedUser.email || "Non renseigné"}
                </p>
                <p className="text-sm text-red-800">
                  <strong>Téléphone :</strong> {selectedUser.phone || "Non renseigné"}
                </p>
              </div>
              <div className="flex justify-end gap-3">
                <Button 
                  variant="outline" 
                  onClick={() => setIsDeleteModalOpen(false)}
                >
                  Annuler
                </Button>
                <Button 
                  onClick={handleConfirmDelete}
                  variant="destructive"
                >
                  <Trash2 className="h-4 w-4 mr-2" />
                  Désactiver
                </Button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default AdminClients;