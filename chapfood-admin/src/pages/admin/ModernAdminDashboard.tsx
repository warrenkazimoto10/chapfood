import React, { useEffect, useState } from 'react';
import { useAdminAuth } from '@/hooks/useAdminAuth';
import { Navigate, Link, useNavigate } from 'react-router-dom';
import { KitchenDashboard } from '@/components/admin/KitchenDashboard';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { 
  ChefHat, 
  LogOut, 
  Users, 
  Calendar, 
  Truck, 
  Package, 
  BarChart3,
  Bell,
  MapPin,
  Clock,
  TrendingUp,
  DollarSign,
  Activity,
  CreditCard,
  AlertCircle
} from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';

const ModernAdminDashboard = () => {
  const { admin, loading, logout } = useAdminAuth();
  const navigate = useNavigate();
  const { toast } = useToast();
  const [currentTime, setCurrentTime] = useState(new Date());
  
  // États pour les données réelles
  const [dashboardData, setDashboardData] = useState({
    ordersToday: 0,
    totalRevenue: 0,
    activeDrivers: 0,
    driversOnDelivery: 0,
    pendingOrders: 0,
    preparingOrders: 0,
    inTransitOrders: 0,
    availableDrivers: 0,
    totalUsers: 0,
    totalMenuItems: 0,
    notificationsCount: 0,
    satisfactionRating: 0,
    revenueYesterday: 0,
    ordersYesterday: 0
  });
  const [loadingData, setLoadingData] = useState(true);
  const [pendingOrdersList, setPendingOrdersList] = useState<any[]>([]);

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(new Date());
    }, 1000);

    return () => clearInterval(timer);
  }, []);

  // Fonction pour récupérer les données du dashboard
  const fetchDashboardData = async () => {
    try {
      setLoadingData(true);
      
      const today = new Date();
      const yesterday = new Date(today);
      yesterday.setDate(yesterday.getDate() - 1);
      
      const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate());
      const todayEnd = new Date(todayStart.getTime() + 24 * 60 * 60 * 1000);
      const yesterdayStart = new Date(yesterday.getFullYear(), yesterday.getMonth(), yesterday.getDate());
      const yesterdayEnd = new Date(yesterdayStart.getTime() + 24 * 60 * 60 * 1000);

      // Commandes d'aujourd'hui
      const { data: ordersToday, error: ordersTodayError } = await supabase
        .from('orders')
        .select('id, total_amount, status')
        .gte('created_at', todayStart.toISOString())
        .lt('created_at', todayEnd.toISOString());

      // Commandes d'hier pour comparaison
      const { data: ordersYesterday, error: ordersYesterdayError } = await supabase
        .from('orders')
        .select('id, total_amount')
        .gte('created_at', yesterdayStart.toISOString())
        .lt('created_at', yesterdayEnd.toISOString());

      // Livreurs actifs
      const { data: drivers, error: driversError } = await supabase
        .from('drivers')
        .select('id, current_lat, current_lng');

      // Livreurs en livraison
      const { data: driversOnDelivery, error: driversOnDeliveryError } = await supabase
        .from('order_driver_assignments')
        .select('driver_id')
        .is('delivered_at', null);

      // Utilisateurs totaux
      const { data: users, error: usersError } = await supabase
        .from('users')
        .select('id')
        .eq('is_active', true);

      // Articles du menu
      const { data: menuItems, error: menuItemsError } = await supabase
        .from('menu_items')
        .select('id');

      // Notifications non lues (utiliser une table existante ou simuler)
      // Pour l'instant, on utilise les commandes en attente comme "notifications"
      const { data: notifications, error: notificationsError } = await supabase
        .from('orders')
        .select('id')
        .eq('status', 'pending');

      // Récupérer les détails des commandes en attente pour les alertes d'urgence
      const { data: pendingOrdersData, error: pendingOrdersError } = await supabase
        .from('orders')
        .select(`
          id, 
          customer_name, 
          total_amount, 
          created_at, 
          customer_phone, 
          subtotal, 
          delivery_fee,
          order_items (
            id,
            item_name,
            quantity,
            selected_garnitures,
            selected_extras,
            instructions
          )
        `)
        .eq('status', 'pending')
        .order('created_at', { ascending: true });

      if (ordersTodayError || ordersYesterdayError || driversError || driversOnDeliveryError || usersError || menuItemsError || notificationsError || pendingOrdersError) {
        console.error('Erreurs lors de la récupération des données:', {
          ordersTodayError, ordersYesterdayError, driversError, driversOnDeliveryError, usersError, menuItemsError, notificationsError, pendingOrdersError
        });
        return;
      }

      // Mettre à jour la liste des commandes en attente
      setPendingOrdersList(pendingOrdersData || []);

      // Calculs
      const ordersTodayCount = ordersToday?.length || 0;
      const ordersYesterdayCount = ordersYesterday?.length || 0;
      const totalRevenue = ordersToday?.reduce((sum, order) => sum + (order.total_amount || 0), 0) || 0;
      const revenueYesterday = ordersYesterday?.reduce((sum, order) => sum + (order.total_amount || 0), 0) || 0;
      
      const activeDrivers = drivers?.filter(driver => driver.current_lat && driver.current_lng).length || 0;
      const driversOnDeliveryCount = new Set(driversOnDelivery?.map(d => d.driver_id)).size || 0;
      const availableDrivers = activeDrivers - driversOnDeliveryCount;

      // Statistiques des commandes par statut
      const pendingOrders = ordersToday?.filter(order => order.status === 'pending').length || 0;
      const preparingOrders = ordersToday?.filter(order => ['accepted', 'ready_for_delivery'].includes(order.status)).length || 0;
      // Commandes en cours de livraison (repas récupéré ou statut historique in_transit)
      const inTransitOrders = ordersToday?.filter(order =>
        ['picked_up', 'in_transit'].includes(order.status as string),
      ).length || 0;

      const dashboardDataUpdate = {
        ordersToday: ordersTodayCount,
        totalRevenue,
        activeDrivers,
        driversOnDelivery: driversOnDeliveryCount,
        pendingOrders,
        preparingOrders,
        inTransitOrders,
        availableDrivers,
        totalUsers: users?.length || 0,
        totalMenuItems: menuItems?.length || 0,
        notificationsCount: notifications?.length || 0,
        satisfactionRating: 4.8, // Placeholder - peut être calculé avec des avis
        revenueYesterday,
        ordersYesterday: ordersYesterdayCount
      };

      setDashboardData(dashboardDataUpdate);

    } catch (error) {
      console.error('Erreur lors du chargement des données du dashboard:', error);
      toast({
        title: "Erreur",
        description: "Impossible de charger les données du dashboard",
        variant: "destructive",
      });
    } finally {
      setLoadingData(false);
    }
  };

  useEffect(() => {
    fetchDashboardData();
    
    // Actualiser les données toutes les 30 secondes
    const interval = setInterval(fetchDashboardData, 30000);
    return () => clearInterval(interval);
  }, []);

  const handleLogout = async () => {
    await logout();
    toast({
      title: "Déconnexion réussie",
      description: "À bientôt sur ChapFood !",
    });
    navigate('/');
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-orange-50 via-red-50 to-yellow-50 flex items-center justify-center">
        <div className="text-center">
          <div className="relative mb-8">
            <img 
              src="/logo-chapfood.png" 
              alt="ChapFood Logo" 
              className="h-24 w-24 object-contain mx-auto animate-pulse"
            />
          </div>
          <div className="animate-spin rounded-full h-16 w-16 border-4 border-orange-200 border-t-orange-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Chargement...</p>
        </div>
      </div>
    );
  }

  if (!admin) {
    return <Navigate to="/admin/login" replace />;
  }

  // Si c'est un rôle cuisine, utiliser l'ancien dashboard
  if (admin.role === 'cuisine') {
    return <KitchenDashboard />;
  }

  // Dashboard principal moderne
  return (
    <div className="min-h-screen bg-gradient-to-br from-orange-50 via-red-50 to-yellow-50">
      {/* Header */}
      <div className="bg-white/90 backdrop-blur-sm border-b border-orange-200 sticky top-0 z-50">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className="relative">
                <img 
                  src="/logo-chapfood.png" 
                  alt="ChapFood Logo" 
                  className="h-16 w-16 object-contain"
                />
                <Badge className="absolute -top-1 -right-1 bg-green-500 text-white text-xs">
                  <Activity className="h-2 w-2 mr-1" />
                  Live
                </Badge>
              </div>
              <div>
                <h1 className="text-2xl font-bold bg-gradient-to-r from-orange-600 to-red-600 bg-clip-text text-transparent">
                  ChapFood Admin
                </h1>
                <p className="text-sm text-gray-600">
                  {admin.role?.includes('admin') ? 'Administrateur' : 'Gestionnaire'} • {currentTime.toLocaleDateString('fr-FR')}
                </p>
              </div>
            </div>

            <div className="flex items-center gap-4">
              {/* Heure actuelle */}
              <div className="text-right">
                <div className="text-2xl font-bold text-gray-800">
                  {currentTime.toLocaleTimeString('fr-FR', { 
                    hour: '2-digit', 
                    minute: '2-digit' 
                  })}
                </div>
                <div className="text-sm text-gray-600">
                  {currentTime.toLocaleDateString('fr-FR', { 
                    weekday: 'long',
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric'
                  })}
                </div>
              </div>

              {/* Notifications */}
              <Button variant="ghost" size="sm" className="relative">
                <Bell className="h-5 w-5" />
                <Badge className="absolute -top-1 -right-1 h-5 w-5 flex items-center justify-center text-xs bg-red-500">
                  {dashboardData.notificationsCount}
                </Badge>
              </Button>

              {/* Menu utilisateur */}
              <div className="flex items-center gap-2">
                <div className="text-right">
                  <p className="font-medium text-gray-800">{admin.email}</p>
                  <p className="text-xs text-gray-600">
                    {admin.role?.includes('admin') ? 'Administrateur' : 'Gestionnaire'}
                  </p>
                </div>
                <Button variant="ghost" size="sm" onClick={handleLogout}>
                  <LogOut className="h-4 w-4" />
                </Button>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Contenu principal */}
      <div className="container mx-auto px-4 py-8">
        {/* Alertes d'urgence pour les commandes en attente */}
        {pendingOrdersList.length > 0 && (
          <div className="mb-6 space-y-3">
            {pendingOrdersList.map((order) => (
              <Card 
                key={order.id} 
                className="bg-gradient-to-r from-red-500 to-orange-500 text-white border-0 shadow-lg animate-pulse"
              >
                <CardContent className="p-4">
                  <div className="grid grid-cols-12 gap-4 items-center">
                    {/* Colonne 1: Icône d'alerte */}
                    <div className="col-span-1 flex items-center justify-center">
                      <div className="bg-white/20 rounded-full p-3">
                        <AlertCircle className="h-6 w-6" />
                      </div>
                    </div>
                    
                    {/* Colonne 2: Information du client avec date de la commande */}
                    <div className="col-span-3">
                      <div className="flex items-center gap-2 mb-2">
                        <Badge className="bg-white/30 text-white border-white/50">
                          URGENT
                        </Badge>
                        <span className="font-bold text-lg">#{order.id}</span>
                      </div>
                      <div className="text-sm text-white/90 mb-1">
                        <span className="font-medium">{order.customer_name || 'Client inconnu'}</span>
                      </div>
                      {order.customer_phone && (
                        <div className="text-xs text-white/80 mb-1">
                          {order.customer_phone}
                        </div>
                      )}
                      <div className="text-xs text-white/80">
                        {new Date(order.created_at).toLocaleString('fr-FR', {
                          day: '2-digit',
                          month: '2-digit',
                          year: 'numeric',
                          hour: '2-digit',
                          minute: '2-digit'
                        })}
                      </div>
                    </div>
                    
                    {/* Colonne 3: Liste des plats commandés avec garnitures */}
                    <div className="col-span-4">
                      {order.order_items && order.order_items.length > 0 ? (
                        <div className="text-xs text-white/90 space-y-1">
                          {order.order_items.map((item: any, idx: number) => (
                            <div key={idx} className="flex flex-col gap-0.5">
                              <div className="flex items-start gap-1">
                                <span className="font-medium">
                                  {item.quantity}x {item.item_name}
                                </span>
                              </div>
                              {item.selected_garnitures && 
                               Array.isArray(item.selected_garnitures) && 
                               item.selected_garnitures.length > 0 && (
                                <div className="text-white/70 ml-4 text-[10px]">
                                  Garnitures: {item.selected_garnitures.map((g: any) => typeof g === 'string' ? g : g.name || g).join(', ')}
                                </div>
                              )}
                              {item.selected_extras && 
                               Array.isArray(item.selected_extras) && 
                               item.selected_extras.length > 0 && (
                                <div className="text-white/70 ml-4 text-[10px]">
                                  Extras: {item.selected_extras.map((e: any) => typeof e === 'string' ? e : e.name || e).join(', ')}
                                </div>
                              )}
                            </div>
                          ))}
                        </div>
                      ) : (
                        <div className="text-xs text-white/70 italic">Aucun plat</div>
                      )}
                    </div>
                    
                    {/* Colonne 4: Prix commande + Prix livraison */}
                    <div className="col-span-2 text-right">
                      <div className="text-xs text-white/80 mb-1">Prix commande</div>
                      <div className="text-sm font-semibold mb-3">
                        {(order.subtotal || 0).toFixed(0)} FCFA
                      </div>
                      <div className="text-xs text-white/80 mb-1">Prix livraison</div>
                      <div className="text-sm font-semibold">
                        {(order.delivery_fee || 0).toFixed(0)} FCFA
                      </div>
                    </div>
                    
                    {/* Colonnes 11-12: Total + Bouton */}
                    <div className="col-span-2 text-right">
                      <div className="text-xs text-white/80 mb-1">Total</div>
                      <div className="text-lg font-bold mb-3">
                        {(order.total_amount || 0).toFixed(0)} FCFA
                      </div>
                      <Button
                        onClick={() => navigate(`/admin/reservations?orderId=${order.id}`)}
                        className="bg-white text-orange-600 hover:bg-orange-50 font-semibold text-sm px-3 py-1.5 h-auto"
                      >
                        Gérer cette commande
                      </Button>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        )}

        {/* Stats rapides */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <Card className="bg-white/90 backdrop-blur-sm border-orange-200 hover:shadow-lg transition-shadow">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Commandes Aujourd'hui</p>
                  <div className="text-3xl font-bold text-orange-600">
                    {loadingData ? (
                      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-orange-500"></div>
                    ) : (
                      dashboardData.ordersToday
                    )}
                  </div>
                  <p className="text-xs text-green-600 flex items-center gap-1">
                    <TrendingUp className="h-3 w-3" />
                    {dashboardData.ordersYesterday > 0 ? (
                      `+${Math.round(((dashboardData.ordersToday - dashboardData.ordersYesterday) / dashboardData.ordersYesterday) * 100)}% vs hier`
                    ) : (
                      "Nouvelle journée"
                    )}
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
                  <p className="text-sm font-medium text-gray-600">Chiffre d'Affaires</p>
                  <div className="text-3xl font-bold text-red-600">
                    {loadingData ? (
                      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-red-500"></div>
                    ) : (
                      `${dashboardData.totalRevenue.toLocaleString()}`
                    )}
                  </div>
                  <p className="text-xs text-green-600 flex items-center gap-1">
                    <TrendingUp className="h-3 w-3" />
                    {dashboardData.revenueYesterday > 0 ? (
                      `+${Math.round(((dashboardData.totalRevenue - dashboardData.revenueYesterday) / dashboardData.revenueYesterday) * 100)}% vs hier`
                    ) : (
                      "Premier jour"
                    )}
                  </p>
                </div>
                <div className="h-12 w-12 bg-red-100 rounded-full flex items-center justify-center">
                  <DollarSign className="h-6 w-6 text-red-600" />
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="bg-white/90 backdrop-blur-sm border-yellow-200 hover:shadow-lg transition-shadow">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Livreurs Actifs</p>
                  <div className="text-3xl font-bold text-yellow-600">
                    {loadingData ? (
                      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-yellow-500"></div>
                    ) : (
                      dashboardData.activeDrivers
                    )}
                  </div>
                  <p className="text-xs text-green-600 flex items-center gap-1">
                    <Clock className="h-3 w-3" />
                    {dashboardData.driversOnDelivery} en livraison
                  </p>
                </div>
                <div className="h-12 w-12 bg-yellow-100 rounded-full flex items-center justify-center">
                  <Truck className="h-6 w-6 text-yellow-600" />
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="bg-white/90 backdrop-blur-sm border-green-200 hover:shadow-lg transition-shadow">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">Satisfaction</p>
                  <div className="text-3xl font-bold text-green-600">
                    {loadingData ? (
                      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-green-500"></div>
                    ) : (
                      `${dashboardData.satisfactionRating}★`
                    )}
                  </div>
                  <p className="text-xs text-green-600 flex items-center gap-1">
                    <TrendingUp className="h-3 w-3" />
                    96% satisfaction
                  </p>
                </div>
                <div className="h-12 w-12 bg-green-100 rounded-full flex items-center justify-center">
                  <BarChart3 className="h-6 w-6 text-green-600" />
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Actions rapides */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
          {/* Gestion des commandes */}
          <Card className="bg-white/90 backdrop-blur-sm border-orange-200">
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-orange-600">
                <Calendar className="h-5 w-5" />
                Gestion des Commandes
              </CardTitle>
              <CardDescription>
                Suivez et gérez toutes les commandes en temps réel
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <Button asChild className="bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 text-white">
                  <Link to="/admin/reservations">
                    <Calendar className="h-4 w-4 mr-2" />
                    Voir Commandes
                  </Link>
                </Button>
                <Button asChild variant="outline" className="border-orange-300 text-orange-600 hover:bg-orange-50">
                  <Link to="/admin/live-tracking">
                    <MapPin className="h-4 w-4 mr-2" />
                    Suivi Live
                  </Link>
                </Button>
              </div>
              <div className="bg-orange-50 rounded-lg p-4">
                <div className="flex items-center justify-between text-sm">
                  <span className="text-orange-700">Commandes en attente:</span>
                  <Badge className="bg-orange-500 text-white">
                    {loadingData ? "..." : dashboardData.pendingOrders}
                  </Badge>
                </div>
                <div className="flex items-center justify-between text-sm mt-2">
                  <span className="text-orange-700">En préparation:</span>
                  <Badge className="bg-yellow-500 text-white">
                    {loadingData ? "..." : dashboardData.preparingOrders}
                  </Badge>
                </div>
                <div className="flex items-center justify-between text-sm mt-2">
                  <span className="text-orange-700">En livraison:</span>
                  <Badge className="bg-blue-500 text-white">
                    {loadingData ? "..." : dashboardData.inTransitOrders}
                  </Badge>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Gestion des livreurs */}
          <Card className="bg-white/90 backdrop-blur-sm border-yellow-200">
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-yellow-600">
                <Truck className="h-5 w-5" />
                Gestion des Livreurs
              </CardTitle>
              <CardDescription>
                Suivez vos livreurs et optimisez les livraisons
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <Button asChild className="bg-gradient-to-r from-yellow-500 to-orange-500 hover:from-yellow-600 hover:to-orange-600 text-white">
                  <Link to="/admin/livreurs">
                    <Truck className="h-4 w-4 mr-2" />
                    Voir Livreurs
                  </Link>
                </Button>
                <Button asChild variant="outline" className="border-yellow-300 text-yellow-600 hover:bg-yellow-50">
                  <Link to="/admin/live-tracking">
                    <MapPin className="h-4 w-4 mr-2" />
                    Carte Live
                  </Link>
                </Button>
              </div>
              <div className="bg-yellow-50 rounded-lg p-4">
                <div className="flex items-center justify-between text-sm">
                  <span className="text-yellow-700">Livreurs disponibles:</span>
                  <Badge className="bg-green-500 text-white">
                    {loadingData ? "..." : dashboardData.availableDrivers}
                  </Badge>
                </div>
                <div className="flex items-center justify-between text-sm mt-2">
                  <span className="text-yellow-700">En livraison:</span>
                  <Badge className="bg-blue-500 text-white">
                    {loadingData ? "..." : dashboardData.driversOnDelivery}
                  </Badge>
                </div>
                <div className="flex items-center justify-between text-sm mt-2">
                  <span className="text-yellow-700">Total livreurs:</span>
                  <Badge className="bg-purple-500 text-white">
                    {loadingData ? "..." : dashboardData.activeDrivers}
                  </Badge>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Modules principaux */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <Card className="bg-white/90 backdrop-blur-sm border-green-200 hover:shadow-lg transition-all hover:scale-105">
            <CardHeader className="text-center">
              <div className="mx-auto w-16 h-16 bg-gradient-to-br from-green-100 to-green-200 rounded-full flex items-center justify-center mb-4">
                <Users className="h-8 w-8 text-green-600" />
              </div>
              <CardTitle className="text-green-600">Gestion Clients</CardTitle>
              <CardDescription>
                Base client complète avec historique
              </CardDescription>
            </CardHeader>
            <CardContent className="text-center">
              <Button asChild className="w-full bg-gradient-to-r from-green-500 to-green-600 hover:from-green-600 hover:to-green-700 text-white">
                <Link to="/admin/clients">
                  <Users className="h-4 w-4 mr-2" />
                  Accéder
                </Link>
              </Button>
            </CardContent>
          </Card>

          <Card className="bg-white/90 backdrop-blur-sm border-blue-200 hover:shadow-lg transition-all hover:scale-105">
            <CardHeader className="text-center">
              <div className="mx-auto w-16 h-16 bg-gradient-to-br from-blue-100 to-blue-200 rounded-full flex items-center justify-center mb-4">
                <Package className="h-8 w-8 text-blue-600" />
              </div>
              <CardTitle className="text-blue-600">Stock & Menu</CardTitle>
              <CardDescription>
                Gestion complète du menu et stocks
              </CardDescription>
            </CardHeader>
            <CardContent className="text-center">
              <Button asChild className="w-full bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 text-white">
                <Link to="/admin/stock">
                  <Package className="h-4 w-4 mr-2" />
                  Accéder
                </Link>
              </Button>
            </CardContent>
          </Card>

          <Card className="bg-white/90 backdrop-blur-sm border-purple-200 hover:shadow-lg transition-all hover:scale-105">
            <CardHeader className="text-center">
              <div className="mx-auto w-16 h-16 bg-gradient-to-br from-purple-100 to-purple-200 rounded-full flex items-center justify-center mb-4">
                <ChefHat className="h-8 w-8 text-purple-600" />
              </div>
              <CardTitle className="text-purple-600">Système de Caisse</CardTitle>
              <CardDescription>
                Gestion des commandes manuelles
              </CardDescription>
            </CardHeader>
            <CardContent className="text-center">
              <Button asChild className="w-full bg-gradient-to-r from-purple-500 to-purple-600 hover:from-purple-600 hover:to-purple-700 text-white">
                <Link to="/admin/cashier">
                  <ChefHat className="h-4 w-4 mr-2" />
                  Accéder
                </Link>
              </Button>
            </CardContent>
          </Card>

          <Card className="bg-white/90 backdrop-blur-sm border-emerald-200 hover:shadow-lg transition-all hover:scale-105">
            <CardHeader className="text-center">
              <div className="mx-auto w-16 h-16 bg-gradient-to-br from-emerald-100 to-emerald-200 rounded-full flex items-center justify-center mb-4">
                <CreditCard className="h-8 w-8 text-emerald-600" />
              </div>
              <CardTitle className="text-emerald-600">Gestion des Gains</CardTitle>
              <CardDescription>
                Suivi des rémunérations des livreurs
              </CardDescription>
            </CardHeader>
            <CardContent className="text-center">
              <Button asChild className="w-full bg-gradient-to-r from-emerald-500 to-emerald-600 hover:from-emerald-600 hover:to-emerald-700 text-white">
                <Link to="/admin/earnings">
                  <CreditCard className="h-4 w-4 mr-2" />
                  Accéder
                </Link>
              </Button>
            </CardContent>
          </Card>
        </div>

        {/* Footer */}
        <div className="mt-12 text-center">
          <p className="text-gray-500 text-sm">
            ChapFood Admin Dashboard • {new Date().getFullYear()} • 
            <span className="text-green-600 font-medium"> Système opérationnel</span>
          </p>
        </div>
      </div>
    </div>
  );
};

export default ModernAdminDashboard;
