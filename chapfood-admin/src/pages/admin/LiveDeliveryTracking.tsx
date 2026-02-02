import { useState, useEffect, useRef } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { 
  Truck, 
  MapPin, 
  Clock, 
  Phone, 
  User, 
  RefreshCw, 
  Maximize2,
  Minimize2,
  Eye,
  Navigation,
  Map,
  ArrowLeft,
  TrendingUp,
  Users,
  Package,
  MapPin as MapIcon
} from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { useToast } from "@/hooks/use-toast";
import { Link } from "react-router-dom";
import LiveDeliveryMap from "@/components/admin/LiveDeliveryMap";
import TestLocationButton from "@/components/admin/TestLocationButton";

interface DeliveryOrder {
  id: number;
  customer_name: string | null;
  customer_phone: string;
  delivery_address: string | null;
  delivery_lat: number | null;
  delivery_lng: number | null;
  total_amount: number;
  estimated_delivery_time: string | null;
  created_at: string;
  accepted_at: string | null;
  ready_at: string | null;
  driver_assignment: {
    driver_id: number;
    assigned_at: string | null;
    picked_up_at: string | null;
    driver: {
      name: string;
      phone: string;
      current_lat: number | null;
      current_lng: number | null;
    };
  } | null;
}

const LiveDeliveryTracking = () => {
  const [deliveries, setDeliveries] = useState<DeliveryOrder[]>([]);
  const [loading, setLoading] = useState(true);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [lastUpdate, setLastUpdate] = useState<Date>(new Date());
  const [autoRefresh, setAutoRefresh] = useState(true);
  const refreshInterval = useRef<NodeJS.Timeout | null>(null);
  const [selectedOrderForMap, setSelectedOrderForMap] = useState<DeliveryOrder | null>(null);
  const [isMapOpen, setIsMapOpen] = useState(false);
  const { toast } = useToast();

  useEffect(() => {
    fetchDeliveries();
    
    if (autoRefresh) {
      refreshInterval.current = setInterval(fetchDeliveries, 10000); // Refresh every 10 seconds
    }

    return () => {
      if (refreshInterval.current) {
        clearInterval(refreshInterval.current);
      }
    };
  }, [autoRefresh]);

  const fetchDeliveries = async () => {
    try {
      const { data, error } = await supabase
        .from('orders')
        .select(`
          id,
          customer_name,
          customer_phone,
          delivery_address,
          delivery_lat,
          delivery_lng,
          total_amount,
          estimated_delivery_time,
          created_at,
          accepted_at,
          ready_at,
          order_driver_assignments(
            driver_id,
            assigned_at,
            picked_up_at,
            drivers(
              name,
              phone,
              current_lat,
              current_lng
            )
          )
        `)
        // Commandes actives : acceptées (vers restaurant) ou repas récupéré (vers client)
        .in('status', ['accepted', 'picked_up', 'in_transit'] as any)
        .order('created_at', { ascending: false });

      if (error) throw error;

      const formattedDeliveries = data?.map(order => ({
        ...order,
        driver_assignment: order.order_driver_assignments && order.order_driver_assignments.length > 0 ? {
          driver_id: order.order_driver_assignments[0].driver_id,
          assigned_at: order.order_driver_assignments[0].assigned_at,
          picked_up_at: order.order_driver_assignments[0].picked_up_at,
          driver: order.order_driver_assignments[0].drivers
        } : null
      })) || [];

      setDeliveries(formattedDeliveries);
      setLastUpdate(new Date());
    } catch (error) {
      console.error('Erreur lors du chargement des livraisons:', error);
      toast({
        title: "Erreur",
        description: "Impossible de charger les livraisons en cours",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const toggleFullscreen = () => {
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen();
      setIsFullscreen(true);
    } else {
      document.exitFullscreen();
      setIsFullscreen(false);
    }
  };

  const toggleAutoRefresh = () => {
    setAutoRefresh(!autoRefresh);
    if (refreshInterval.current) {
      clearInterval(refreshInterval.current);
    }
    if (!autoRefresh) {
      refreshInterval.current = setInterval(fetchDeliveries, 10000);
    }
  };

  const openDeliveryMap = (order: DeliveryOrder) => {
    setSelectedOrderForMap(order);
    setIsMapOpen(true);
  };

  const closeDeliveryMap = () => {
    setIsMapOpen(false);
    setSelectedOrderForMap(null);
  };

  const getDriverInitials = (name: string) => {
    return name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);
  };

  const getStatusBadge = (order: DeliveryOrder) => {
    if (!order.driver_assignment) {
      return <Badge variant="secondary">Prête pour assignation</Badge>;
    }
    
    if (order.driver_assignment.picked_up_at) {
      return <Badge variant="default">En cours de livraison</Badge>;
    }
    
    return <Badge variant="outline">Assignée au livreur</Badge>;
  };

  const getDeliveryTime = (order: DeliveryOrder) => {
    if (order.estimated_delivery_time) {
      return new Date(order.estimated_delivery_time).toLocaleTimeString('fr-FR', {
        hour: '2-digit',
        minute: '2-digit'
      });
    }
    return "Non définie";
  };

  const getDistanceText = (lat: number | null, lng: number | null) => {
    if (!lat || !lng) return "Position inconnue";
    return `${lat.toFixed(4)}, ${lng.toFixed(4)}`;
  };

  const formatPrice = (price: number) => {
    return `${price.toLocaleString('fr-FR')} FCFA`;
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
          <p className="text-muted-foreground mt-4">Chargement des livraisons...</p>
        </div>
      </div>
    );
  }

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
                    <Truck className="h-8 w-8 text-white" />
                  </div>
                  Suivi des Livraisons en Temps Réel
                </h1>
                <p className="text-gray-600 mt-1">
                  📍 Dernière mise à jour: {lastUpdate.toLocaleTimeString('fr-FR')}
                </p>
              </div>
            </div>
            
            <div className="flex items-center gap-3">
              <Button
                variant={autoRefresh ? "default" : "outline"}
                size="sm"
                onClick={toggleAutoRefresh}
                className={autoRefresh ? "bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 text-white" : "border-orange-300 text-orange-600 hover:bg-orange-50"}
              >
                <RefreshCw className={`h-4 w-4 mr-2 ${autoRefresh ? 'animate-spin' : ''}`} />
                {autoRefresh ? '🔄 Actualisation auto' : '⏸️ Actualisation manuelle'}
              </Button>
              
              <Button
                variant="outline"
                size="sm"
                onClick={fetchDeliveries}
                className="border-orange-300 text-orange-600 hover:bg-orange-50"
              >
                <RefreshCw className="h-4 w-4 mr-2" />
                Actualiser maintenant
              </Button>
              
              <Button
                variant="outline"
                size="sm"
                onClick={toggleFullscreen}
                className="border-orange-300 text-orange-600 hover:bg-orange-50"
              >
                {isFullscreen ? <Minimize2 className="h-4 w-4" /> : <Maximize2 className="h-4 w-4" />}
              </Button>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-6 py-6">

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          {/* Total des livraisons */}
          <Card className="bg-white/90 backdrop-blur-sm border-orange-200 shadow-lg hover:shadow-xl transition-shadow">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-orange-600">📦 Total des livraisons</p>
                  <p className="text-3xl font-bold text-orange-800 mt-1">{deliveries.length}</p>
                </div>
                <div className="p-3 bg-gradient-to-r from-orange-400 to-red-400 rounded-full">
                  <Package className="h-6 w-6 text-white" />
                </div>
              </div>
            </CardContent>
          </Card>
          
          {/* En cours de livraison */}
          <Card className="bg-white/90 backdrop-blur-sm border-green-200 shadow-lg hover:shadow-xl transition-shadow">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-green-600">🚚 En cours de livraison</p>
                  <p className="text-3xl font-bold text-green-800 mt-1">
                    {deliveries.filter(d => d.driver_assignment?.picked_up_at).length}
                  </p>
                </div>
                <div className="p-3 bg-gradient-to-r from-green-400 to-emerald-500 rounded-full">
                  <Navigation className="h-6 w-6 text-white" />
                </div>
              </div>
            </CardContent>
          </Card>
          
          {/* Assignées aux livreurs */}
          <Card className="bg-white/90 backdrop-blur-sm border-blue-200 shadow-lg hover:shadow-xl transition-shadow">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-blue-600">👥 Assignées aux livreurs</p>
                  <p className="text-3xl font-bold text-blue-800 mt-1">
                    {deliveries.filter(d => d.driver_assignment && !d.driver_assignment.picked_up_at).length}
                  </p>
                </div>
                <div className="p-3 bg-gradient-to-r from-blue-400 to-cyan-500 rounded-full">
                  <Users className="h-6 w-6 text-white" />
                </div>
              </div>
            </CardContent>
          </Card>
          
          {/* Prêtes pour assignation */}
          <Card className="bg-white/90 backdrop-blur-sm border-yellow-200 shadow-lg hover:shadow-xl transition-shadow">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-yellow-600">⏰ Prêtes pour assignation</p>
                  <p className="text-3xl font-bold text-yellow-800 mt-1">
                    {deliveries.filter(d => !d.driver_assignment).length}
                  </p>
                </div>
                <div className="p-3 bg-gradient-to-r from-yellow-400 to-orange-400 rounded-full">
                  <Clock className="h-6 w-6 text-white" />
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Livraisons */}
        <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
          {deliveries.map((order) => (
            <Card key={order.id} className="bg-white/90 backdrop-blur-sm border-orange-200 shadow-lg hover:shadow-xl transition-all duration-300 hover:scale-105">
            <CardHeader className="pb-3">
              <div className="flex items-center justify-between">
                <CardTitle className="text-lg">
                  Commande #{order.id.toString().slice(-6)}
                </CardTitle>
                {getStatusBadge(order)}
              </div>
            </CardHeader>
            
            <CardContent className="space-y-4">
              {/* Informations client */}
              <div className="space-y-2">
                <div className="flex items-center gap-2">
                  <User className="h-4 w-4 text-muted-foreground" />
                  <span className="font-medium">
                    {order.customer_name || "Client anonyme"}
                  </span>
                </div>
                
                <div className="flex items-center gap-2">
                  <Phone className="h-4 w-4 text-muted-foreground" />
                  <span className="text-sm">{order.customer_phone}</span>
                </div>
                
                {order.delivery_address && (
                  <div className="flex items-start gap-2">
                    <MapPin className="h-4 w-4 text-muted-foreground mt-0.5" />
                    <span className="text-sm">{order.delivery_address}</span>
                  </div>
                )}
                
                <div className="flex items-center gap-2">
                  <Clock className="h-4 w-4 text-muted-foreground" />
                  <span className="text-sm">Livraison prévue: {getDeliveryTime(order)}</span>
                </div>
              </div>

              {/* Informations livreur */}
              {order.driver_assignment ? (
                <div className="border-t pt-4">
                  <div className="flex items-center gap-3">
                    <Avatar className="h-10 w-10">
                      <AvatarFallback className="bg-primary text-primary-foreground">
                        {getDriverInitials(order.driver_assignment.driver.name)}
                      </AvatarFallback>
                    </Avatar>
                    
                    <div className="flex-1">
                      <h4 className="font-medium">{order.driver_assignment.driver.name}</h4>
                      <div className="flex items-center gap-4 text-sm text-muted-foreground">
                        <span>{order.driver_assignment.driver.phone}</span>
                        <span>{getDistanceText(order.driver_assignment.driver.current_lat, order.driver_assignment.driver.current_lng)}</span>
                      </div>
                    </div>
                  </div>
                  
                  {order.driver_assignment.assigned_at && (
                    <p className="text-xs text-muted-foreground mt-2">
                      Assigné à: {new Date(order.driver_assignment.assigned_at).toLocaleTimeString('fr-FR')}
                    </p>
                  )}
                  
                  {order.driver_assignment.picked_up_at && (
                    <p className="text-xs text-green-600 mt-2">
                      Récupéré à: {new Date(order.driver_assignment.picked_up_at).toLocaleTimeString('fr-FR')}
                    </p>
                  )}

                  {/* Bouton de test pour ajouter des coordonnées GPS */}
                  {(!order.driver_assignment.driver.current_lat || !order.driver_assignment.driver.current_lng) && (
                    <div className="mt-3">
                      <TestLocationButton 
                        driverId={order.driver_assignment.driver_id}
                        onLocationUpdated={fetchDeliveries}
                      />
                    </div>
                  )}
                </div>
              ) : (
                <div className="border-t pt-4">
                  <div className="text-center py-2">
                    <Clock className="h-8 w-8 text-muted-foreground mx-auto mb-2" />
                    <p className="text-sm text-muted-foreground">
                      En attente d'assignation d'un livreur
                    </p>
                  </div>
                </div>
              )}

              {/* Montant */}
              <div className="border-t pt-4">
                <div className="flex justify-between items-center">
                  <span className="text-sm text-muted-foreground">Montant total</span>
                  <span className="font-bold text-lg">{formatPrice(order.total_amount)}</span>
                </div>
              </div>

              {/* Actions */}
              {order.driver_assignment && (
                <div className="border-t pt-4">
                  <Button
                    onClick={() => openDeliveryMap(order)}
                    className="w-full"
                    size="sm"
                    variant={order.driver_assignment.driver.current_lat && order.driver_assignment.driver.current_lng ? "default" : "outline"}
                  >
                    <Map className="h-4 w-4 mr-2" />
                    {order.driver_assignment.driver.current_lat && order.driver_assignment.driver.current_lng 
                      ? "Suivi en temps réel" 
                      : "Carte de livraison"
                    }
                  </Button>
                </div>
              )}
            </CardContent>
          </Card>
        ))}
        
        {deliveries.length === 0 && (
          <div className="col-span-full text-center py-12">
            <Truck className="h-16 w-16 text-muted-foreground mx-auto mb-4" />
            <h3 className="text-xl font-semibold text-muted-foreground mb-2">
              Aucune livraison en cours
            </h3>
            <p className="text-muted-foreground">
              Toutes les commandes ont été livrées ou aucune n'est prête pour la livraison
            </p>
          </div>
        )}
        </div>
      </div>

      {/* Carte de suivi en temps réel */}
      {selectedOrderForMap && (
        <LiveDeliveryMap
          orderId={selectedOrderForMap.id}
          isOpen={isMapOpen}
          onClose={closeDeliveryMap}
          driverLocation={selectedOrderForMap.driver_assignment ? {
            driver_id: selectedOrderForMap.driver_assignment.driver_id,
            name: selectedOrderForMap.driver_assignment.driver.name,
            phone: selectedOrderForMap.driver_assignment.driver.phone,
            current_lat: selectedOrderForMap.driver_assignment.driver.current_lat || 0,
            current_lng: selectedOrderForMap.driver_assignment.driver.current_lng || 0,
            last_update: selectedOrderForMap.driver_assignment.assigned_at || new Date().toISOString()
          } : null}
          deliveryLocation={selectedOrderForMap.delivery_lat && selectedOrderForMap.delivery_lng ? {
            order_id: selectedOrderForMap.id,
            customer_name: selectedOrderForMap.customer_name,
            customer_phone: selectedOrderForMap.customer_phone,
            delivery_address: selectedOrderForMap.delivery_address || '',
            delivery_lat: selectedOrderForMap.delivery_lat,
            delivery_lng: selectedOrderForMap.delivery_lng,
            estimated_delivery_time: selectedOrderForMap.estimated_delivery_time || new Date().toISOString(),
            total_amount: selectedOrderForMap.total_amount,
            status: selectedOrderForMap.driver_assignment?.picked_up_at ? 'in_transit' : 'ready_for_delivery'
          } : null}
        />
      )}
    </div>
  );
};

export default LiveDeliveryTracking;
