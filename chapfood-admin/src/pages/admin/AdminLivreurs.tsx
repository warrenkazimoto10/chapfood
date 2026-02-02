import { useState, useEffect } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle } from "@/components/ui/alert-dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { Search, Eye, Phone, Mail, MapPin, Plus, Truck, Users, Clock, CheckCircle, AlertCircle, ArrowLeft, Edit, Save, X, Package, Star, TrendingUp, Calendar, DollarSign, Trash2, Filter, Download, RefreshCw, MoreVertical } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { useNavigate } from "react-router-dom";
import { useToast } from "@/hooks/use-toast";

interface Driver {
  id: number;
  name: string;
  phone: string;
  email: string | null;
  is_available: boolean;
  is_active: boolean;
  current_lat: number | null;
  current_lng: number | null;
  created_at: string;
}

const AdminLivreurs = () => {
  const navigate = useNavigate();
  const { toast } = useToast();
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [searchTerm, setSearchTerm] = useState("");
  const [loading, setLoading] = useState(true);
  
  // États pour les modals
  const [showAddModal, setShowAddModal] = useState(false);
  const [showDetailModal, setShowDetailModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [selectedDriver, setSelectedDriver] = useState<Driver | null>(null);
  
  // États pour le formulaire d'ajout
  const [newDriver, setNewDriver] = useState({
    name: '',
    phone: '',
    email: '',
    is_active: true,
    is_available: true
  });
  
  const [creating, setCreating] = useState(false);
  
  // États pour les statistiques du livreur
  const [driverStats, setDriverStats] = useState({
    totalOrders: 0,
    completedOrders: 0,
    totalEarnings: 0,
    averageRating: 0,
    totalDistance: 0,
    lastDelivery: null as string | null
  });
  const [loadingStats, setLoadingStats] = useState(false);
  
  // États pour les filtres et tri
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [availabilityFilter, setAvailabilityFilter] = useState<string>('all');
  const [sortBy, setSortBy] = useState<string>('created_at');
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('desc');
  
  // États pour l'historique des livraisons
  const [deliveryHistory, setDeliveryHistory] = useState<any[]>([]);
  const [loadingHistory, setLoadingHistory] = useState(false);

  useEffect(() => {
    fetchDrivers();
  }, []);

  const fetchDrivers = async () => {
    try {
      const { data, error } = await supabase
        .from('drivers')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      setDrivers(data || []);
    } catch (error) {
      console.error('Error fetching drivers:', error);
    } finally {
      setLoading(false);
    }
  };

  const getAvailabilityBadge = (isAvailable: boolean) => {
    return (
      <Badge className={isAvailable ? "bg-green-100 text-green-800 border-green-200" : "bg-orange-100 text-orange-800 border-orange-200"}>
        {isAvailable ? "Disponible" : "Occupé"}
      </Badge>
    );
  };

  const getStatusBadge = (isActive: boolean) => {
    return (
      <Badge className={isActive ? "bg-green-100 text-green-800 border-green-200" : "bg-red-100 text-red-800 border-red-200"}>
        {isActive ? "Actif" : "Inactif"}
      </Badge>
    );
  };

  const filteredDrivers = drivers
    .filter(driver => {
      // Filtre par recherche
      const matchesSearch = driver.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                           driver.phone.includes(searchTerm) ||
                           driver.email?.toLowerCase().includes(searchTerm.toLowerCase());
      
      // Filtre par statut
      const matchesStatus = statusFilter === 'all' || 
                           (statusFilter === 'active' && driver.is_active) ||
                           (statusFilter === 'inactive' && !driver.is_active);
      
      // Filtre par disponibilité
      const matchesAvailability = availabilityFilter === 'all' ||
                                 (availabilityFilter === 'available' && driver.is_available) ||
                                 (availabilityFilter === 'busy' && !driver.is_available);
      
      return matchesSearch && matchesStatus && matchesAvailability;
    })
    .sort((a, b) => {
      let aValue: any, bValue: any;
      
      switch (sortBy) {
        case 'name':
          aValue = a.name.toLowerCase();
          bValue = b.name.toLowerCase();
          break;
        case 'created_at':
          aValue = new Date(a.created_at).getTime();
          bValue = new Date(b.created_at).getTime();
          break;
        case 'phone':
          aValue = a.phone;
          bValue = b.phone;
          break;
        default:
          aValue = a.created_at;
          bValue = b.created_at;
      }
      
      if (sortOrder === 'asc') {
        return aValue > bValue ? 1 : -1;
      } else {
        return aValue < bValue ? 1 : -1;
      }
    });

  // Fonction pour créer un nouveau livreur
  const handleCreateDriver = async () => {
    if (!newDriver.name.trim() || !newDriver.phone.trim()) {
      toast({
        title: "Erreur",
        description: "Le nom et le téléphone sont obligatoires",
        variant: "destructive",
      });
      return;
    }

    try {
      setCreating(true);
      const { data, error } = await supabase
        .from('drivers')
        .insert([{
          name: newDriver.name.trim(),
          phone: newDriver.phone.trim(),
          email: newDriver.email.trim() || null,
          password: '123456789', // Mot de passe par défaut
          is_active: newDriver.is_active,
          is_available: newDriver.is_available
        }])
        .select()
        .single();

      if (error) throw error;

      toast({
        title: "Succès",
        description: `Livreur ${data.name} créé avec succès. Mot de passe par défaut: 123456789`,
      });

      // Réinitialiser le formulaire
      setNewDriver({
        name: '',
        phone: '',
        email: '',
        is_active: true,
        is_available: true
      });
      setShowAddModal(false);
      fetchDrivers(); // Rafraîchir la liste
    } catch (error) {
      console.error('Erreur lors de la création du livreur:', error);
      toast({
        title: "Erreur",
        description: "Impossible de créer le livreur",
        variant: "destructive",
      });
    } finally {
      setCreating(false);
    }
  };

  // Fonction pour récupérer les statistiques d'un livreur
  const fetchDriverStats = async (driverId: number) => {
    try {
      setLoadingStats(true);
      
      // Récupérer les commandes du livreur
      const { data: orders, error: ordersError } = await supabase
        .from('order_driver_assignments')
        .select(`
          *,
          orders (
            id,
            total_amount,
            status,
            created_at
          )
        `)
        .eq('driver_id', driverId);

      if (ordersError) throw ordersError;

      // Calculer les statistiques
      const totalOrders = orders?.length || 0;
      const completedOrders = orders?.filter(o => o.orders?.status === 'delivered').length || 0;
      const totalEarnings = orders?.reduce((sum, o) => {
        if (o.orders?.status === 'delivered') {
          // Estimation des gains basée sur le total de la commande (5% du montant)
          return sum + (o.orders.total_amount * 0.05 || 0);
        }
        return sum;
      }, 0) || 0;
      
      const lastDelivery = orders?.filter(o => o.orders?.status === 'delivered')
        .sort((a, b) => new Date(b.created_at || 0).getTime() - new Date(a.created_at || 0).getTime())[0]
        ?.created_at || null;

      setDriverStats({
        totalOrders,
        completedOrders,
        totalEarnings,
        averageRating: 4.5, // Placeholder - à implémenter avec un système de notation
        totalDistance: totalOrders * 5.2, // Placeholder - calculer avec les vraies distances
        lastDelivery
      });
    } catch (error) {
      console.error('Erreur lors du chargement des statistiques:', error);
      toast({
        title: "Erreur",
        description: "Impossible de charger les statistiques du livreur",
        variant: "destructive",
      });
    } finally {
      setLoadingStats(false);
    }
  };

  // Fonction pour ouvrir les détails d'un livreur
  const handleViewDriver = (driver: Driver) => {
    setSelectedDriver(driver);
    setShowDetailModal(true);
    fetchDriverStats(driver.id);
    fetchDeliveryHistory(driver.id);
  };

  // Fonction pour modifier un livreur
  const handleEditDriver = (driver: Driver) => {
    setSelectedDriver(driver);
    setNewDriver({
      name: driver.name,
      phone: driver.phone,
      email: driver.email || '',
      is_active: driver.is_active,
      is_available: driver.is_available
    });
    setShowEditModal(true);
  };

  // Fonction pour sauvegarder les modifications
  const handleUpdateDriver = async () => {
    if (!selectedDriver || !newDriver.name.trim() || !newDriver.phone.trim()) {
      toast({
        title: "Erreur",
        description: "Le nom et le téléphone sont obligatoires",
        variant: "destructive",
      });
      return;
    }

    try {
      setCreating(true);
      const { error } = await supabase
        .from('drivers')
        .update({
          name: newDriver.name.trim(),
          phone: newDriver.phone.trim(),
          email: newDriver.email.trim() || null,
          is_active: newDriver.is_active,
          is_available: newDriver.is_available
        })
        .eq('id', selectedDriver.id);

      if (error) throw error;

      toast({
        title: "Succès",
        description: `Livreur ${newDriver.name} mis à jour avec succès`,
      });

      setShowEditModal(false);
      setSelectedDriver(null);
      fetchDrivers();
    } catch (error) {
      console.error('Erreur lors de la mise à jour du livreur:', error);
      toast({
        title: "Erreur",
        description: "Impossible de mettre à jour le livreur",
        variant: "destructive",
      });
    } finally {
      setCreating(false);
    }
  };

  // Fonction pour supprimer un livreur
  const handleDeleteDriver = (driver: Driver) => {
    setSelectedDriver(driver);
    setShowDeleteModal(true);
  };

  // Fonction pour confirmer la suppression
  const confirmDeleteDriver = async () => {
    if (!selectedDriver) return;

    try {
      setCreating(true);
      const { error } = await supabase
        .from('drivers')
        .delete()
        .eq('id', selectedDriver.id);

      if (error) throw error;

      toast({
        title: "Succès",
        description: `Livreur ${selectedDriver.name} supprimé avec succès`,
      });

      setShowDeleteModal(false);
      setSelectedDriver(null);
      fetchDrivers();
    } catch (error) {
      console.error('Erreur lors de la suppression du livreur:', error);
      toast({
        title: "Erreur",
        description: "Impossible de supprimer le livreur",
        variant: "destructive",
      });
    } finally {
      setCreating(false);
    }
  };

  // Fonction pour récupérer l'historique des livraisons
  const fetchDeliveryHistory = async (driverId: number) => {
    try {
      setLoadingHistory(true);
      const { data, error } = await supabase
        .from('order_driver_assignments')
        .select(`
          *,
          orders (
            id,
            customer_name,
            delivery_address,
            total_amount,
            status,
            created_at
          )
        `)
        .eq('driver_id', driverId)
        .order('assigned_at', { ascending: false })
        .limit(20);

      if (error) throw error;
      setDeliveryHistory(data || []);
    } catch (error) {
      console.error('Erreur lors du chargement de l\'historique:', error);
    } finally {
      setLoadingHistory(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-orange-50 via-white to-red-50">
      {/* Header */}
      <div className="bg-white/90 backdrop-blur-sm border-b border-orange-200 sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <Button
                variant="outline"
                onClick={() => navigate('/admin')}
                className="border-orange-300 text-orange-600 hover:bg-orange-50"
              >
                <ArrowLeft className="h-4 w-4 mr-2" />
                Retour
              </Button>
              <div className="h-8 w-px bg-orange-200"></div>
              <div>
                <h1 className="text-3xl font-bold bg-gradient-to-r from-orange-600 to-red-600 bg-clip-text text-transparent flex items-center gap-3">
                  <div className="p-2 bg-gradient-to-r from-orange-500 to-red-500 rounded-lg">
                    <Truck className="h-8 w-8 text-white" />
                  </div>
                  Gestion des Livreurs
                </h1>
                <p className="text-gray-600 mt-1">
                  🚚 Gérez votre équipe de livraison ChapFood
                </p>
              </div>
            </div>
            <Button 
              onClick={() => setShowAddModal(true)}
              className="bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 text-white shadow-lg"
            >
              <Plus className="h-4 w-4 mr-2" />
              Ajouter un livreur
            </Button>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-6 py-6">
        <div className="space-y-6">

            {/* Statistiques avec design ChapFood */}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
              <Card className="bg-white/90 backdrop-blur-sm border-orange-200 shadow-lg hover:shadow-xl transition-all duration-300">
                <CardHeader className="bg-gradient-to-r from-orange-50 to-red-50 border-b border-orange-200">
                  <CardTitle className="text-orange-700 flex items-center gap-2">
                    <Users className="h-5 w-5" />
                    Total Livreurs
                  </CardTitle>
                </CardHeader>
                <CardContent className="p-6">
                  <div className="text-3xl font-bold text-orange-600">{drivers.length}</div>
                  <p className="text-sm text-gray-600 mt-1">Livreurs inscrits</p>
                </CardContent>
              </Card>
              
              <Card className="bg-white/90 backdrop-blur-sm border-green-200 shadow-lg hover:shadow-xl transition-all duration-300">
                <CardHeader className="bg-gradient-to-r from-green-50 to-emerald-50 border-b border-green-200">
                  <CardTitle className="text-green-700 flex items-center gap-2">
                    <CheckCircle className="h-5 w-5" />
                    Disponibles
                  </CardTitle>
                </CardHeader>
                <CardContent className="p-6">
                  <div className="text-3xl font-bold text-green-600">
                    {drivers.filter(d => d.is_available && d.is_active).length}
                  </div>
                  <p className="text-sm text-gray-600 mt-1">Prêts à livrer</p>
                </CardContent>
              </Card>
              
              <Card className="bg-white/90 backdrop-blur-sm border-orange-200 shadow-lg hover:shadow-xl transition-all duration-300">
                <CardHeader className="bg-gradient-to-r from-orange-50 to-yellow-50 border-b border-orange-200">
                  <CardTitle className="text-orange-700 flex items-center gap-2">
                    <Truck className="h-5 w-5" />
                    En Livraison
                  </CardTitle>
                </CardHeader>
                <CardContent className="p-6">
                  <div className="text-3xl font-bold text-orange-600">
                    {drivers.filter(d => !d.is_available && d.is_active).length}
                  </div>
                  <p className="text-sm text-gray-600 mt-1">Actuellement en course</p>
                </CardContent>
              </Card>
              
              <Card className="bg-white/90 backdrop-blur-sm border-red-200 shadow-lg hover:shadow-xl transition-all duration-300">
                <CardHeader className="bg-gradient-to-r from-red-50 to-pink-50 border-b border-red-200">
                  <CardTitle className="text-red-700 flex items-center gap-2">
                    <AlertCircle className="h-5 w-5" />
                    Inactifs
                  </CardTitle>
                </CardHeader>
                <CardContent className="p-6">
                  <div className="text-3xl font-bold text-red-600">
                    {drivers.filter(d => !d.is_active).length}
                  </div>
                  <p className="text-sm text-gray-600 mt-1">Hors service</p>
                </CardContent>
              </Card>
            </div>

            {/* Table des livreurs avec design ChapFood */}
            <Card className="bg-white/90 backdrop-blur-sm border-orange-200 shadow-lg">
              <CardHeader className="bg-gradient-to-r from-orange-50 to-red-50 border-b border-orange-200">
                <div className="flex items-center justify-between">
                  <div>
                    <CardTitle className="text-orange-700 flex items-center gap-2">
                      <Truck className="h-5 w-5" />
                      Liste des Livreurs
                    </CardTitle>
                    <CardDescription className="text-gray-600">
                      {filteredDrivers.length} livreur(s) trouvé(s)
                    </CardDescription>
                  </div>
                  <div className="flex items-center space-x-3">
                    <div className="relative">
                      <Search className="absolute left-3 top-3 h-4 w-4 text-orange-500" />
                      <Input
                        placeholder="Rechercher un livreur..."
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        className="pl-10 w-64 border-orange-300 focus:border-orange-500 focus:ring-orange-500"
                      />
                    </div>
                    
                    <Select value={statusFilter} onValueChange={setStatusFilter}>
                      <SelectTrigger className="w-32 border-orange-300 focus:border-orange-500">
                        <SelectValue placeholder="Statut" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="all">Tous</SelectItem>
                        <SelectItem value="active">Actifs</SelectItem>
                        <SelectItem value="inactive">Inactifs</SelectItem>
                      </SelectContent>
                    </Select>
                    
                    <Select value={availabilityFilter} onValueChange={setAvailabilityFilter}>
                      <SelectTrigger className="w-36 border-orange-300 focus:border-orange-500">
                        <SelectValue placeholder="Disponibilité" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="all">Tous</SelectItem>
                        <SelectItem value="available">Disponibles</SelectItem>
                        <SelectItem value="busy">Occupés</SelectItem>
                      </SelectContent>
                    </Select>
                    
                    <Select value={sortBy} onValueChange={setSortBy}>
                      <SelectTrigger className="w-32 border-orange-300 focus:border-orange-500">
                        <SelectValue placeholder="Tri" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="created_at">Date</SelectItem>
                        <SelectItem value="name">Nom</SelectItem>
                        <SelectItem value="phone">Téléphone</SelectItem>
                      </SelectContent>
                    </Select>
                    
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc')}
                      className="border-orange-300 text-orange-600 hover:bg-orange-50"
                    >
                      {sortOrder === 'asc' ? '↑' : '↓'}
                    </Button>
                  </div>
                </div>
              </CardHeader>
              <CardContent className="p-0">
                {loading ? (
                  <div className="text-center py-12">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-orange-500 mx-auto"></div>
                    <p className="text-gray-600 mt-4">Chargement des livreurs...</p>
                  </div>
                ) : (
                  <Table>
                    <TableHeader className="bg-gradient-to-r from-orange-50 to-red-50">
                      <TableRow className="border-orange-200">
                        <TableHead className="text-orange-700 font-semibold">Nom</TableHead>
                        <TableHead className="text-orange-700 font-semibold">Téléphone</TableHead>
                        <TableHead className="text-orange-700 font-semibold">Email</TableHead>
                        <TableHead className="text-orange-700 font-semibold">Statut</TableHead>
                        <TableHead className="text-orange-700 font-semibold">Disponibilité</TableHead>
                        <TableHead className="text-orange-700 font-semibold">Position</TableHead>
                        <TableHead className="text-orange-700 font-semibold">Inscrit le</TableHead>
                        <TableHead className="text-orange-700 font-semibold">Actions</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {filteredDrivers.map((driver) => (
                        <TableRow key={driver.id} className="hover:bg-orange-50/50 transition-colors">
                          <TableCell className="font-semibold text-gray-800">
                            {driver.name}
                          </TableCell>
                          <TableCell>
                            <div className="flex items-center space-x-2">
                              <Phone className="h-4 w-4 text-orange-500" />
                              <span className="text-gray-700">{driver.phone}</span>
                            </div>
                          </TableCell>
                          <TableCell>
                            <div className="flex items-center space-x-2">
                              <Mail className="h-4 w-4 text-orange-500" />
                              <span className="text-gray-700">{driver.email || "Non renseigné"}</span>
                            </div>
                          </TableCell>
                          <TableCell>
                            {getStatusBadge(driver.is_active)}
                          </TableCell>
                          <TableCell>
                            {getAvailabilityBadge(driver.is_available)}
                          </TableCell>
                          <TableCell>
                            <div className="flex items-center space-x-2">
                              <MapPin className="h-4 w-4 text-orange-500" />
                              <span className="text-gray-700">
                                {driver.current_lat && driver.current_lng
                                  ? "Position connue"
                                  : "Position inconnue"
                                }
                              </span>
                            </div>
                          </TableCell>
                          <TableCell className="text-gray-700">
                            {new Date(driver.created_at).toLocaleDateString('fr-FR')}
                          </TableCell>
                          <TableCell>
                            <DropdownMenu>
                              <DropdownMenuTrigger asChild>
                                <Button variant="outline" size="sm" className="border-orange-300 text-orange-600 hover:bg-orange-50">
                                  <MoreVertical className="h-4 w-4" />
                                </Button>
                              </DropdownMenuTrigger>
                              <DropdownMenuContent align="end">
                                <DropdownMenuItem onClick={() => handleViewDriver(driver)}>
                                  <Eye className="h-4 w-4 mr-2" />
                                  Voir détails
                                </DropdownMenuItem>
                                <DropdownMenuItem onClick={() => handleEditDriver(driver)}>
                                  <Edit className="h-4 w-4 mr-2" />
                                  Modifier
                                </DropdownMenuItem>
                                <DropdownMenuItem 
                                  onClick={() => handleDeleteDriver(driver)}
                                  className="text-red-600 focus:text-red-600"
                                >
                                  <Trash2 className="h-4 w-4 mr-2" />
                                  Supprimer
                                </DropdownMenuItem>
                              </DropdownMenuContent>
                            </DropdownMenu>
                          </TableCell>
                        </TableRow>
                      ))}
                      {filteredDrivers.length === 0 && (
                        <TableRow>
                          <TableCell colSpan={8} className="text-center py-12">
                            <div className="flex flex-col items-center gap-3">
                              <Users className="h-12 w-12 text-gray-400" />
                              <p className="text-gray-500 text-lg">Aucun livreur trouvé</p>
                              <p className="text-gray-400 text-sm">Essayez de modifier votre recherche</p>
                            </div>
                          </TableCell>
                        </TableRow>
                      )}
                    </TableBody>
                  </Table>
                )}
              </CardContent>
            </Card>
        </div>
      </div>

      {/* Modal d'ajout de livreur */}
      <Dialog open={showAddModal} onOpenChange={setShowAddModal}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="text-orange-700 flex items-center gap-2">
              <Plus className="h-5 w-5" />
              Ajouter un nouveau livreur
            </DialogTitle>
            <DialogDescription>
              Remplissez les informations du nouveau livreur. Le mot de passe par défaut sera <strong>123456789</strong>.
            </DialogDescription>
          </DialogHeader>
          
          <div className="space-y-4">
            <div>
              <Label htmlFor="name" className="text-orange-700">Nom complet *</Label>
              <Input
                id="name"
                value={newDriver.name}
                onChange={(e) => setNewDriver({...newDriver, name: e.target.value})}
                placeholder="Nom du livreur"
                className="border-orange-300 focus:border-orange-500"
              />
            </div>
            
            <div>
              <Label htmlFor="phone" className="text-orange-700">Téléphone *</Label>
              <Input
                id="phone"
                value={newDriver.phone}
                onChange={(e) => setNewDriver({...newDriver, phone: e.target.value})}
                placeholder="Numéro de téléphone"
                className="border-orange-300 focus:border-orange-500"
              />
            </div>
            
            <div>
              <Label htmlFor="email" className="text-orange-700">Email</Label>
              <Input
                id="email"
                type="email"
                value={newDriver.email}
                onChange={(e) => setNewDriver({...newDriver, email: e.target.value})}
                placeholder="Email (optionnel)"
                className="border-orange-300 focus:border-orange-500"
              />
            </div>
            
            <div className="flex items-center justify-between">
              <Label htmlFor="is_active" className="text-orange-700">Statut actif</Label>
              <Switch
                id="is_active"
                checked={newDriver.is_active}
                onCheckedChange={(checked) => setNewDriver({...newDriver, is_active: checked})}
              />
            </div>
            
            <div className="flex items-center justify-between">
              <Label htmlFor="is_available" className="text-orange-700">Disponible</Label>
              <Switch
                id="is_available"
                checked={newDriver.is_available}
                onCheckedChange={(checked) => setNewDriver({...newDriver, is_available: checked})}
              />
            </div>
          </div>
          
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setShowAddModal(false)}
              className="border-orange-300 text-orange-600 hover:bg-orange-50"
            >
              Annuler
            </Button>
            <Button
              onClick={handleCreateDriver}
              disabled={creating}
              className="bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 text-white"
            >
              {creating ? (
                <div className="flex items-center gap-2">
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                  Création...
                </div>
              ) : (
                <div className="flex items-center gap-2">
                  <Save className="h-4 w-4" />
                  Créer le livreur
                </div>
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Modal de détails du livreur avec onglets */}
      <Dialog open={showDetailModal} onOpenChange={setShowDetailModal}>
        <DialogContent className="sm:max-w-4xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="text-orange-700 flex items-center gap-2">
              <Truck className="h-5 w-5" />
              Détails du livreur
            </DialogTitle>
            <DialogDescription>
              Informations complètes et statistiques du livreur
            </DialogDescription>
          </DialogHeader>
          
          {selectedDriver && (
            <Tabs defaultValue="info" className="w-full">
              <TabsList className="grid w-full grid-cols-3 bg-orange-100">
                <TabsTrigger value="info" className="data-[state=active]:bg-white data-[state=active]:text-orange-600">
                  <Users className="h-4 w-4 mr-2" />
                  Informations
                </TabsTrigger>
                <TabsTrigger value="stats" className="data-[state=active]:bg-white data-[state=active]:text-orange-600">
                  <TrendingUp className="h-4 w-4 mr-2" />
                  Statistiques
                </TabsTrigger>
                <TabsTrigger value="history" className="data-[state=active]:bg-white data-[state=active]:text-orange-600">
                  <Package className="h-4 w-4 mr-2" />
                  Historique
                </TabsTrigger>
              </TabsList>

              {/* Onglet Informations */}
              <TabsContent value="info" className="space-y-4">
                <div className="bg-gradient-to-r from-orange-50 to-red-50 p-4 rounded-lg border border-orange-200">
                  <h3 className="font-semibold text-orange-800 text-lg">{selectedDriver.name}</h3>
                  <p className="text-gray-600">ID: #{selectedDriver.id}</p>
                </div>
                
                <div className="grid grid-cols-1 gap-4">
                  <div className="flex items-center gap-3">
                    <Phone className="h-4 w-4 text-orange-500" />
                    <div>
                      <Label className="text-sm text-gray-600">Téléphone</Label>
                      <p className="font-medium">{selectedDriver.phone}</p>
                    </div>
                  </div>
                  
                  <div className="flex items-center gap-3">
                    <Mail className="h-4 w-4 text-orange-500" />
                    <div>
                      <Label className="text-sm text-gray-600">Email</Label>
                      <p className="font-medium">{selectedDriver.email || "Non renseigné"}</p>
                    </div>
                  </div>
                  
                  <div className="flex items-center gap-3">
                    <MapPin className="h-4 w-4 text-orange-500" />
                    <div>
                      <Label className="text-sm text-gray-600">Position GPS</Label>
                      <p className="font-medium">
                        {selectedDriver.current_lat && selectedDriver.current_lng
                          ? "Position connue"
                          : "Position inconnue"
                        }
                      </p>
                    </div>
                  </div>
                  
                  <div className="flex items-center gap-3">
                    <Clock className="h-4 w-4 text-orange-500" />
                    <div>
                      <Label className="text-sm text-gray-600">Inscrit le</Label>
                      <p className="font-medium">
                        {new Date(selectedDriver.created_at).toLocaleDateString('fr-FR', {
                          year: 'numeric',
                          month: 'long',
                          day: 'numeric'
                        })}
                      </p>
                    </div>
                  </div>
                </div>
                
                <div className="flex gap-3 pt-4">
                  {getStatusBadge(selectedDriver.is_active)}
                  {getAvailabilityBadge(selectedDriver.is_available)}
                </div>
              </TabsContent>

              {/* Onglet Statistiques */}
              <TabsContent value="stats" className="space-y-4">
                {loadingStats ? (
                  <div className="text-center py-8">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-orange-500 mx-auto"></div>
                    <p className="text-gray-600 mt-4">Chargement des statistiques...</p>
                  </div>
                ) : (
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <Card className="bg-gradient-to-r from-blue-50 to-blue-100 border-blue-200">
                      <CardContent className="p-4">
                        <div className="flex items-center gap-3">
                          <Package className="h-8 w-8 text-blue-600" />
                          <div>
                            <p className="text-sm text-blue-600 font-medium">Commandes totales</p>
                            <p className="text-2xl font-bold text-blue-800">{driverStats.totalOrders}</p>
                          </div>
                        </div>
                      </CardContent>
                    </Card>

                    <Card className="bg-gradient-to-r from-green-50 to-green-100 border-green-200">
                      <CardContent className="p-4">
                        <div className="flex items-center gap-3">
                          <CheckCircle className="h-8 w-8 text-green-600" />
                          <div>
                            <p className="text-sm text-green-600 font-medium">Livrées</p>
                            <p className="text-2xl font-bold text-green-800">{driverStats.completedOrders}</p>
                          </div>
                        </div>
                      </CardContent>
                    </Card>

                    <Card className="bg-gradient-to-r from-yellow-50 to-yellow-100 border-yellow-200">
                      <CardContent className="p-4">
                        <div className="flex items-center gap-3">
                          <DollarSign className="h-8 w-8 text-yellow-600" />
                          <div>
                            <p className="text-sm text-yellow-600 font-medium">Gains totaux</p>
                            <p className="text-2xl font-bold text-yellow-800">{driverStats.totalEarnings.toLocaleString()} FCFA</p>
                          </div>
                        </div>
                      </CardContent>
                    </Card>

                    <Card className="bg-gradient-to-r from-purple-50 to-purple-100 border-purple-200">
                      <CardContent className="p-4">
                        <div className="flex items-center gap-3">
                          <Star className="h-8 w-8 text-purple-600" />
                          <div>
                            <p className="text-sm text-purple-600 font-medium">Note moyenne</p>
                            <p className="text-2xl font-bold text-purple-800">{driverStats.averageRating}/5</p>
                          </div>
                        </div>
                      </CardContent>
                    </Card>

                    <Card className="bg-gradient-to-r from-orange-50 to-orange-100 border-orange-200">
                      <CardContent className="p-4">
                        <div className="flex items-center gap-3">
                          <MapPin className="h-8 w-8 text-orange-600" />
                          <div>
                            <p className="text-sm text-orange-600 font-medium">Distance parcourue</p>
                            <p className="text-2xl font-bold text-orange-800">{driverStats.totalDistance.toFixed(1)} km</p>
                          </div>
                        </div>
                      </CardContent>
                    </Card>

                    <Card className="bg-gradient-to-r from-red-50 to-red-100 border-red-200">
                      <CardContent className="p-4">
                        <div className="flex items-center gap-3">
                          <Calendar className="h-8 w-8 text-red-600" />
                          <div>
                            <p className="text-sm text-red-600 font-medium">Dernière livraison</p>
                            <p className="text-lg font-bold text-red-800">
                              {driverStats.lastDelivery 
                                ? new Date(driverStats.lastDelivery).toLocaleDateString('fr-FR')
                                : "Aucune"
                              }
                            </p>
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  </div>
                )}
              </TabsContent>

              {/* Onglet Historique */}
              <TabsContent value="history" className="space-y-4">
                {loadingHistory ? (
                  <div className="text-center py-8">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-orange-500 mx-auto"></div>
                    <p className="text-gray-600 mt-4">Chargement de l'historique...</p>
                  </div>
                ) : deliveryHistory.length === 0 ? (
                  <div className="text-center py-8">
                    <Package className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                    <p className="text-gray-500">Aucune livraison trouvée</p>
                    <p className="text-sm text-gray-400">Ce livreur n'a pas encore effectué de livraisons</p>
                  </div>
                ) : (
                  <div className="space-y-4">
                    <div className="flex items-center justify-between">
                      <h3 className="text-lg font-semibold text-orange-700">Dernières livraisons</h3>
                      <Badge variant="outline" className="border-orange-300 text-orange-600">
                        {deliveryHistory.length} livraison(s)
                      </Badge>
                    </div>
                    
                    <div className="space-y-3">
                      {deliveryHistory.map((assignment) => (
                        <Card key={assignment.id} className="bg-white/90 backdrop-blur-sm border-orange-200 shadow-sm">
                          <CardContent className="p-4">
                            <div className="flex items-center justify-between">
                              <div className="flex-1">
                                <div className="flex items-center gap-3 mb-2">
                                  <Badge 
                                    className={
                                      assignment.orders?.status === 'delivered' 
                                        ? "bg-green-100 text-green-800 border-green-200"
                                        : "bg-orange-100 text-orange-800 border-orange-200"
                                    }
                                  >
                                    {assignment.orders?.status === 'delivered' ? 'Livré' : 'En cours'}
                                  </Badge>
                                  <span className="font-semibold text-gray-800">
                                    Commande #{assignment.orders?.id}
                                  </span>
                                </div>
                                
                                <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
                                  <div>
                                    <p className="text-gray-600 font-medium">Client</p>
                                    <p className="text-gray-800">{assignment.orders?.customer_name || 'N/A'}</p>
                                  </div>
                                  <div>
                                    <p className="text-gray-600 font-medium">Adresse</p>
                                    <p className="text-gray-800">{assignment.orders?.delivery_address || 'N/A'}</p>
                                  </div>
                                  <div>
                                    <p className="text-gray-600 font-medium">Montant</p>
                                    <p className="text-green-600 font-semibold">
                                      {assignment.orders?.total_amount ? `${assignment.orders.total_amount.toLocaleString()} FCFA` : 'N/A'}
                                    </p>
                                  </div>
                                </div>
                              </div>
                              
                              <div className="text-right text-sm text-gray-500">
                                <p>Assigné le</p>
                                <p className="font-medium">
                                  {new Date(assignment.assigned_at).toLocaleDateString('fr-FR')}
                                </p>
                                {assignment.orders?.status === 'delivered' && (
                                  <>
                                    <p className="mt-1">Livré le</p>
                                    <p className="font-medium text-green-600">
                                      {new Date(assignment.assigned_at).toLocaleDateString('fr-FR')}
                                    </p>
                                  </>
                                )}
                              </div>
                            </div>
                          </CardContent>
                        </Card>
                      ))}
                    </div>
                  </div>
                )}
              </TabsContent>
            </Tabs>
          )}
          
          <DialogFooter>
            <Button
              onClick={() => setShowDetailModal(false)}
              className="bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 text-white"
            >
              Fermer
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Modal de modification de livreur */}
      <Dialog open={showEditModal} onOpenChange={setShowEditModal}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="text-orange-700 flex items-center gap-2">
              <Edit className="h-5 w-5" />
              Modifier le livreur
            </DialogTitle>
            <DialogDescription>
              Modifiez les informations du livreur
            </DialogDescription>
          </DialogHeader>
          
          <div className="space-y-4">
            <div>
              <Label htmlFor="edit-name" className="text-orange-700">Nom complet *</Label>
              <Input
                id="edit-name"
                value={newDriver.name}
                onChange={(e) => setNewDriver({...newDriver, name: e.target.value})}
                placeholder="Nom du livreur"
                className="border-orange-300 focus:border-orange-500"
              />
            </div>
            
            <div>
              <Label htmlFor="edit-phone" className="text-orange-700">Téléphone *</Label>
              <Input
                id="edit-phone"
                value={newDriver.phone}
                onChange={(e) => setNewDriver({...newDriver, phone: e.target.value})}
                placeholder="Numéro de téléphone"
                className="border-orange-300 focus:border-orange-500"
              />
            </div>
            
            <div>
              <Label htmlFor="edit-email" className="text-orange-700">Email</Label>
              <Input
                id="edit-email"
                type="email"
                value={newDriver.email}
                onChange={(e) => setNewDriver({...newDriver, email: e.target.value})}
                placeholder="Email (optionnel)"
                className="border-orange-300 focus:border-orange-500"
              />
            </div>
            
            <div className="flex items-center justify-between">
              <Label htmlFor="edit-is_active" className="text-orange-700">Statut actif</Label>
              <Switch
                id="edit-is_active"
                checked={newDriver.is_active}
                onCheckedChange={(checked) => setNewDriver({...newDriver, is_active: checked})}
              />
            </div>
            
            <div className="flex items-center justify-between">
              <Label htmlFor="edit-is_available" className="text-orange-700">Disponible</Label>
              <Switch
                id="edit-is_available"
                checked={newDriver.is_available}
                onCheckedChange={(checked) => setNewDriver({...newDriver, is_available: checked})}
              />
            </div>
          </div>
          
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setShowEditModal(false)}
              className="border-orange-300 text-orange-600 hover:bg-orange-50"
            >
              Annuler
            </Button>
            <Button
              onClick={handleUpdateDriver}
              disabled={creating}
              className="bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 text-white"
            >
              {creating ? (
                <div className="flex items-center gap-2">
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                  Mise à jour...
                </div>
              ) : (
                <div className="flex items-center gap-2">
                  <Save className="h-4 w-4" />
                  Sauvegarder
                </div>
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Modal de confirmation de suppression */}
      <AlertDialog open={showDeleteModal} onOpenChange={setShowDeleteModal}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle className="text-red-600 flex items-center gap-2">
              <Trash2 className="h-5 w-5" />
              Confirmer la suppression
            </AlertDialogTitle>
            <AlertDialogDescription>
              Êtes-vous sûr de vouloir supprimer le livreur <strong>{selectedDriver?.name}</strong> ?
              Cette action est irréversible et supprimera toutes les données associées à ce livreur.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel className="border-orange-300 text-orange-600 hover:bg-orange-50">
              Annuler
            </AlertDialogCancel>
            <AlertDialogAction
              onClick={confirmDeleteDriver}
              disabled={creating}
              className="bg-red-600 hover:bg-red-700 text-white"
            >
              {creating ? (
                <div className="flex items-center gap-2">
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                  Suppression...
                </div>
              ) : (
                <div className="flex items-center gap-2">
                  <Trash2 className="h-4 w-4" />
                  Supprimer
                </div>
              )}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
};

export default AdminLivreurs;