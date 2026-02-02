import { useState, useEffect } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { 
  Search, 
  Eye, 
  Clock, 
  MapPin, 
  Shield, 
  Key, 
  CheckCircle, 
  AlertCircle,
  Calendar,
  Truck,
  Package,
  TrendingUp,
  Filter,
  Download,
  ArrowLeft,
  DollarSign,
  Users,
  Activity
} from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { Link, useSearchParams } from "react-router-dom";
import OrderDetailModal from "@/components/admin/OrderDetailModal";
import { calculateDistance, estimateDeliveryTime, formatEstimatedTime, getEstimatedArrivalTime } from "@/utils/deliveryEstimation";

interface DriverInfo {
  id: number;
  name: string;
  current_lat: number | null;
  current_lng: number | null;
}

interface Order {
  id: number;
  customer_name: string | null;
  customer_phone: string;
  delivery_address: string | null;
  delivery_lat: number | null;
  delivery_lng: number | null;
  subtotal: number;
  delivery_fee: number | null;
  total_amount: number;
  status: string;
  delivery_type: string;
  created_at: string;
  estimated_delivery_time: string | null;
  assigned_driver?: DriverInfo | null;
  // Nouveaux champs pour les codes de livraison
  delivery_code?: string | null;
  delivery_code_generated_at?: string | null;
  delivery_code_expires_at?: string | null;
  delivery_confirmed_at?: string | null;
  delivery_confirmed_by?: string | null;
}

const AdminReservations = () => {
  const [orders, setOrders] = useState<Order[]>([]);
  const [searchTerm, setSearchTerm] = useState("");
  const [loading, setLoading] = useState(true);
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [searchParams, setSearchParams] = useSearchParams();

  useEffect(() => {
    fetchOrders();
    
    // Vérifier si un orderId est dans l'URL
    const orderId = searchParams.get('orderId');
    if (orderId) {
      // Charger et ouvrir la commande
      const openOrderFromUrl = async () => {
        try {
          const { data, error } = await supabase
            .from('orders')
            .select(`
              *,
              order_driver_assignments (
                driver_id,
                assigned_at,
                drivers (
                  id,
                  name,
                  current_lat,
                  current_lng
                )
              )
            `)
            .eq('id', parseInt(orderId))
            .single();
          
          if (error) throw error;
          
          if (data) {
            // Transformer les données pour correspondre au format Order
            const orderWithDriver = {
              ...data,
              assigned_driver: data.delivery_type === 'delivery' 
                ? data.order_driver_assignments?.[0]?.drivers || null
                : null
            };
            
            setSelectedOrder(orderWithDriver as Order);
            setIsModalOpen(true);
            // Nettoyer l'URL après ouverture
            setSearchParams({});
          }
        } catch (error) {
          console.error('Erreur lors du chargement de la commande depuis l\'URL:', error);
        }
      };
      openOrderFromUrl();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [searchParams]);

  const fetchOrders = async () => {
    try {
      const { data, error } = await supabase
        .from('orders')
        .select(`
          *,
          order_driver_assignments (
            driver_id,
            assigned_at,
            drivers (
              id,
              name,
              current_lat,
              current_lng
            )
          )
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;
      
      // Transformer les données pour inclure les informations du livreur
      const ordersWithDriver = (data || []).map(order => {
        // Ne récupérer les infos du livreur que pour les livraisons
        const assignment = order.delivery_type === 'delivery' 
          ? order.order_driver_assignments?.[0] 
          : null;
        return {
          ...order,
          assigned_driver: assignment?.drivers || null
        };
      });
      
      setOrders(ordersWithDriver);
    } catch (error) {
      console.error('Error fetching orders:', error);
    } finally {
      setLoading(false);
    }
  };

  const getStatusBadge = (status: string) => {
    const statusConfig = {
      pending: { label: "En attente", variant: "secondary" as const },
      accepted: { label: "Acceptée", variant: "default" as const },
      ready_for_delivery: { label: "Prête pour livraison", variant: "default" as const },
      in_transit: { label: "En cours de livraison", variant: "secondary" as const },
      delivered: { label: "Livrée", variant: "default" as const },
      cancelled: { label: "Annulée", variant: "destructive" as const },
      // Anciens statuts pour compatibilité
      confirmed: { label: "Confirmée", variant: "default" as const },
      preparing: { label: "En préparation", variant: "secondary" as const },
      ready: { label: "Prête", variant: "default" as const },
      out_for_delivery: { label: "En livraison", variant: "secondary" as const },
      on_way: { label: "En route", variant: "secondary" as const },
    };

    const config = statusConfig[status as keyof typeof statusConfig] || { label: status, variant: "secondary" as const };
    return <Badge variant={config.variant}>{config.label}</Badge>;
  };

  const handleViewOrder = (order: Order) => {
    setSelectedOrder(order);
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setSelectedOrder(null);
  };

  const handleOrderUpdate = () => {
    fetchOrders(); // Recharger la liste des commandes
  };

  const getDeliveryTypeBadge = (type: string) => {
    const typeConfig = {
      delivery: { label: "Livraison", variant: "default" as const },
      pickup: { label: "À emporter", variant: "secondary" as const },
    };

    const config = typeConfig[type as keyof typeof typeConfig] || { label: type, variant: "secondary" as const };
    return <Badge variant={config.variant}>{config.label}</Badge>;
  };

  const getEstimatedDeliveryTime = (order: Order): string => {
    // Vérifier si c'est une livraison (pas à emporter)
    if (order.delivery_type !== 'delivery') {
      return "À emporter";
    }
    
    // Si un livreur est assigné et que nous avons les coordonnées
    if (order.assigned_driver && 
        order.assigned_driver.current_lat && 
        order.assigned_driver.current_lng &&
        order.delivery_lat && 
        order.delivery_lng) {
      
      // Calculer la distance entre le livreur et le client
      const distance = calculateDistance(
        order.assigned_driver.current_lat,
        order.assigned_driver.current_lng,
        order.delivery_lat,
        order.delivery_lng
      );
      
      // Estimer le temps de livraison
      const estimatedMinutes = estimateDeliveryTime(distance);
      
      // Calculer l'heure d'arrivée estimée
      const arrivalTime = getEstimatedArrivalTime(estimatedMinutes);
      
      return arrivalTime.toLocaleTimeString('fr-FR', {
        hour: '2-digit',
        minute: '2-digit'
      });
    }
    
    return "Non assigné";
  };

  const getEstimatedDeliveryDuration = (order: Order): string => {
    // Vérifier si c'est une livraison (pas à emporter)
    if (order.delivery_type !== 'delivery') {
      return "";
    }
    
    // Si un livreur est assigné et que nous avons les coordonnées
    if (order.assigned_driver && 
        order.assigned_driver.current_lat && 
        order.assigned_driver.current_lng &&
        order.delivery_lat && 
        order.delivery_lng) {
      
      // Calculer la distance entre le livreur et le client
      const distance = calculateDistance(
        order.assigned_driver.current_lat,
        order.assigned_driver.current_lng,
        order.delivery_lat,
        order.delivery_lng
      );
      
      // Estimer le temps de livraison
      const estimatedMinutes = estimateDeliveryTime(distance);
      
      return formatEstimatedTime(estimatedMinutes);
    }
    
    return "";
  };

  const getDeliveryCodeStatus = (order: Order): { status: string, icon: React.ReactNode, color: string } => {
    if (order.delivery_type !== 'delivery') {
      return { status: 'N/A', icon: null, color: 'text-gray-500' };
    }
    
    if (!order.delivery_code) {
      return { 
        status: 'Pas de code', 
        icon: <Key className="h-3 w-3" />, 
        color: 'text-gray-600' 
      };
    }
    
    if (order.delivery_confirmed_at) {
      return { 
        status: 'Confirmé', 
        icon: <CheckCircle className="h-3 w-3" />, 
        color: 'text-green-600' 
      };
    }
    
    if (order.delivery_code_expires_at && new Date(order.delivery_code_expires_at) < new Date()) {
      return { 
        status: 'Expiré', 
        icon: <AlertCircle className="h-3 w-3" />, 
        color: 'text-red-600' 
      };
    }
    
    return { 
      status: 'Actif', 
      icon: <Shield className="h-3 w-3" />, 
      color: 'text-blue-600' 
    };
  };

  const filteredOrders = orders.filter(order =>
    order.customer_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    order.customer_phone.includes(searchTerm) ||
    order.id.toString().includes(searchTerm)
  );

  // Calcul des statistiques
  const totalOrders = orders.length;
  const pendingOrders = orders.filter(o => o.status === 'pending').length;
  // Commandes en cours (acceptée, prête, repas récupéré ou en livraison)
  const inProgressOrders = orders.filter(o =>
    ['accepted', 'ready_for_delivery', 'picked_up', 'in_transit'].includes(o.status)
  ).length;
  const deliveredOrders = orders.filter(o => o.status === 'delivered').length;
  const totalRevenue = orders.reduce((sum, order) => sum + Number(order.total_amount), 0);

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
                  Gestion des Commandes
                </h1>
                <p className="text-sm text-gray-600">
                  Suivez et gérez toutes vos commandes en temps réel
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="container mx-auto px-4 py-8">
        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <Card className="bg-white/90 backdrop-blur-sm border-orange-200 hover:shadow-lg transition-shadow">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Total Commandes</p>
                  <p className="text-3xl font-bold text-orange-600">{totalOrders}</p>
                  <p className="text-xs text-green-600 flex items-center gap-1">
                    <TrendingUp className="h-3 w-3" />
                    {filteredOrders.length} affichées
                  </p>
                </div>
                <div className="h-12 w-12 bg-orange-100 rounded-full flex items-center justify-center">
                  <Calendar className="h-6 w-6 text-orange-600" />
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="bg-white/90 backdrop-blur-sm border-red-200 hover:shadow-lg transition-shadow">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">En Attente</p>
                  <p className="text-3xl font-bold text-red-600">{pendingOrders}</p>
                  <p className="text-xs text-red-600">
                    À traiter rapidement
                  </p>
                </div>
                <div className="h-12 w-12 bg-red-100 rounded-full flex items-center justify-center">
                  <AlertCircle className="h-6 w-6 text-red-600" />
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="bg-white/90 backdrop-blur-sm border-blue-200 hover:shadow-lg transition-shadow">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">En Cours</p>
                  <p className="text-3xl font-bold text-blue-600">{inProgressOrders}</p>
                  <p className="text-xs text-blue-600 flex items-center gap-1">
                    <Activity className="h-3 w-3" />
                    En préparation/livraison
                  </p>
                </div>
                <div className="h-12 w-12 bg-blue-100 rounded-full flex items-center justify-center">
                  <Truck className="h-6 w-6 text-blue-600" />
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="bg-white/90 backdrop-blur-sm border-green-200 hover:shadow-lg transition-shadow">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
            <div>
                  <p className="text-sm font-medium text-gray-600">Livrées</p>
                  <p className="text-3xl font-bold text-green-600">{deliveredOrders}</p>
                  <p className="text-xs text-green-600">
                    {totalOrders > 0 ? Math.round((deliveredOrders / totalOrders) * 100) : 0}% du total
                  </p>
                </div>
                <div className="h-12 w-12 bg-green-100 rounded-full flex items-center justify-center">
                  <CheckCircle className="h-6 w-6 text-green-600" />
                </div>
              </div>
            </CardContent>
          </Card>
            </div>

        {/* Revenue Card */}
        <Card className="bg-gradient-to-r from-orange-500 to-red-500 text-white mb-8">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-orange-100 mb-1">Chiffre d'Affaires Total</p>
                <p className="text-3xl font-bold">{totalRevenue.toLocaleString()} FCFA</p>
                <p className="text-orange-100 text-sm">
                  {orders.length} commandes • Moyenne: {(totalRevenue / Math.max(orders.length, 1)).toLocaleString()} FCFA
                </p>
              </div>
              <div className="h-16 w-16 bg-white/20 rounded-full flex items-center justify-center">
                <DollarSign className="h-8 w-8" />
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Main Content */}
        <Card className="bg-white/90 backdrop-blur-sm border-orange-200 shadow-lg">
              <CardHeader>
                <div className="flex items-center justify-between">
                  <div>
                <CardTitle className="flex items-center gap-2 text-orange-600">
                  <Package className="h-5 w-5" />
                  Liste des Commandes
                </CardTitle>
                    <CardDescription>
                  {filteredOrders.length} commande(s) trouvée(s) sur {totalOrders} total
                    </CardDescription>
                  </div>
              <div className="flex items-center space-x-3">
                    <div className="relative">
                  <Search className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
                      <Input
                        placeholder="Rechercher une commande..."
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
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                {loading ? (
              <div className="text-center py-12">
                <div className="animate-spin rounded-full h-12 w-12 border-4 border-orange-200 border-t-orange-600 mx-auto mb-4"></div>
                <p className="text-gray-600">Chargement des commandes...</p>
              </div>
                ) : (
              <div className="rounded-lg border border-gray-200 overflow-hidden">
                  <Table>
                  <TableHeader className="bg-orange-50">
                      <TableRow>
                      <TableHead className="text-orange-700 font-semibold">N° Commande</TableHead>
                      <TableHead className="text-orange-700 font-semibold">Client</TableHead>
                      <TableHead className="text-orange-700 font-semibold">Téléphone</TableHead>
                      <TableHead className="text-orange-700 font-semibold">Type</TableHead>
                      <TableHead className="text-orange-700 font-semibold">Adresse</TableHead>
                      <TableHead className="text-orange-700 font-semibold">Montant</TableHead>
                      <TableHead className="text-orange-700 font-semibold">Statut</TableHead>
                      <TableHead className="text-orange-700 font-semibold">Code livraison</TableHead>
                      <TableHead className="text-orange-700 font-semibold">Heure prévue</TableHead>
                      <TableHead className="text-orange-700 font-semibold">Actions</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {filteredOrders.map((order) => (
                      <TableRow key={order.id} className="hover:bg-orange-50/50 transition-colors">
                          <TableCell className="font-medium">
                          <div className="flex items-center gap-2">
                            <div className="h-8 w-8 bg-gradient-to-br from-orange-100 to-red-100 rounded-full flex items-center justify-center">
                              <Package className="h-4 w-4 text-orange-600" />
                            </div>
                            <span className="font-bold text-orange-600">
                            #{order.id.toString().slice(-6)}
                            </span>
                          </div>
                          </TableCell>
                          <TableCell>
                          <div className="flex items-center gap-2">
                            <Users className="h-4 w-4 text-gray-400" />
                            <span className="font-medium text-gray-800">
                            {order.customer_name || "Client anonyme"}
                            </span>
                          </div>
                        </TableCell>
                        <TableCell>
                          <div className="flex items-center gap-2">
                            <div className="h-4 w-4 text-green-500">📱</div>
                            <span className="text-gray-700">{order.customer_phone}</span>
                          </div>
                          </TableCell>
                          <TableCell>
                            {getDeliveryTypeBadge(order.delivery_type)}
                          </TableCell>
                          <TableCell>
                            <div className="flex items-center space-x-2">
                            <MapPin className={`h-4 w-4 ${
                              order.delivery_type === 'delivery' 
                                ? 'text-red-500' 
                                : 'text-green-500'
                            }`} />
                            <span className={`truncate max-w-32 ${
                              order.delivery_type === 'delivery' 
                                ? 'text-gray-700' 
                                : 'text-green-700'
                            }`}>
                              {order.delivery_type === 'delivery' 
                                ? (order.delivery_address || "Adresse non définie")
                                : "À emporter"
                              }
                              </span>
                            </div>
                          </TableCell>
                          <TableCell className="font-medium">
                          <div className="flex items-center gap-1">
                            <DollarSign className="h-4 w-4 text-green-500" />
                            <span className="text-green-600 font-bold">
                              {Number(order.total_amount).toLocaleString()} FCFA
                            </span>
                          </div>
                          </TableCell>
                          <TableCell>
                            {getStatusBadge(order.status)}
                          </TableCell>
                          <TableCell>
                            <div className="flex items-center space-x-2">
                            {(() => {
                              const codeStatus = getDeliveryCodeStatus(order);
                              return (
                                <>
                                  {codeStatus.icon && (
                                    <span className={codeStatus.color}>
                                      {codeStatus.icon}
                                    </span>
                                  )}
                                  <span className={`text-sm ${codeStatus.color}`}>
                                    {codeStatus.status}
                                  </span>
                                </>
                              );
                            })()}
                          </div>
                        </TableCell>
                        <TableCell>
                          <div className="flex items-center space-x-2">
                            <Clock className="h-4 w-4 text-gray-400" />
                            <div className="flex flex-col">
                              <span className={`text-sm ${
                                order.delivery_type === 'delivery' 
                                  ? 'text-blue-600' 
                                  : 'text-green-600'
                              }`}>
                                {getEstimatedDeliveryTime(order)}
                              </span>
                              {getEstimatedDeliveryDuration(order) && (
                                <span className="text-xs text-muted-foreground">
                                  ({getEstimatedDeliveryDuration(order)})
                                </span>
                              )}
                              {order.delivery_type === 'pickup' && (
                                <span className="text-xs text-muted-foreground">
                                  Prêt à récupérer
                              </span>
                              )}
                            </div>
                            </div>
                          </TableCell>
                          <TableCell>
                          <Button 
                            variant="outline" 
                            size="sm"
                            className="border-orange-300 text-orange-600 hover:bg-orange-50"
                            onClick={() => handleViewOrder(order)}
                          >
                            <Eye className="h-4 w-4 mr-1" />
                            Voir
                            </Button>
                          </TableCell>
                        </TableRow>
                      ))}
                      {filteredOrders.length === 0 && (
                        <TableRow>
                        <TableCell colSpan={10} className="text-center py-12">
                          <div className="flex flex-col items-center gap-4">
                            <div className="h-16 w-16 bg-gray-100 rounded-full flex items-center justify-center">
                              <Package className="h-8 w-8 text-gray-400" />
                            </div>
                            <div>
                              <h3 className="text-lg font-medium text-gray-600">Aucune commande trouvée</h3>
                              <p className="text-sm text-gray-500">
                                {searchTerm ? "Essayez avec d'autres mots-clés" : "Aucune commande enregistrée pour le moment"}
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

      {/* Modal de détail de commande */}
      <OrderDetailModal
        order={selectedOrder}
        isOpen={isModalOpen}
        onClose={handleCloseModal}
        onOrderUpdate={handleOrderUpdate}
      />
      </div>
  );
};

export default AdminReservations;