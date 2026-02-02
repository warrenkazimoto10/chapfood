import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';
import { 
  ArrowLeft,
  Search,
  UserPlus,
  ShoppingCart,
  MapPin,
  Truck,
  CreditCard,
  CheckCircle,
  Package,
  ChefHat,
  Users,
  Clock,
  DollarSign,
  History,
  Maximize2,
  Minimize2,
  BarChart3,
  TrendingUp,
  Settings
} from 'lucide-react';

// Composants pour les étapes
import ClientSearch from '@/components/admin/cashier/ClientSearch';
import OrderBuilder from '@/components/admin/cashier/OrderBuilder';
import DeliveryLocationPicker from '@/components/admin/DeliveryLocationPicker';
import OrderSummary from '@/components/admin/cashier/OrderSummary';
import CashierHistory from '@/components/admin/cashier/CashierHistory';
import CashierSettings from '@/components/admin/cashier/CashierSettings';

interface CartItem {
  id: string;
  menu_item: any;
  quantity: number;
  selected_extras: any[];
  selected_garnitures: any[];
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

const CashierSystem = () => {
  const navigate = useNavigate();
  const { toast } = useToast();
  
  // États pour les étapes du processus
  const [currentStep, setCurrentStep] = useState<'client' | 'order' | 'location' | 'summary' | 'complete'>('client');
  
  // Données de la commande
  const [selectedClient, setSelectedClient] = useState<Client | null>(null);
  const [cart, setCart] = useState<CartItem[]>([]);
  const [orderType, setOrderType] = useState<'delivery' | 'pickup'>('pickup');
  const [deliveryLocation, setDeliveryLocation] = useState<any>(null);
  const [orderTotal, setOrderTotal] = useState(0);
  const [createdOrder, setCreatedOrder] = useState<any>(null);
  
  // Nouveaux états
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [showHistory, setShowHistory] = useState(false);
  const [showSettings, setShowSettings] = useState(false);
  const [todayStats, setTodayStats] = useState({
    totalOrders: 0,
    totalRevenue: 0,
    averageOrder: 0
  });
  const [hasSessionData, setHasSessionData] = useState(false);

  // Panier persistant - Charger depuis localStorage
  useEffect(() => {
    const savedSession = localStorage.getItem('chapfood_cashier_session');
    if (savedSession) {
      try {
        const session = JSON.parse(savedSession);
        setHasSessionData(true);
        // Ne pas charger automatiquement, juste indiquer qu'il y a une session
      } catch (error) {
        console.error('Erreur lors de la lecture de la session:', error);
      }
    }
  }, []);

  // Sauvegarder dans localStorage
  useEffect(() => {
    if (selectedClient || cart.length > 0) {
      const sessionData = {
        selectedClient,
        cart,
        orderType,
        deliveryLocation,
        timestamp: Date.now()
      };
      localStorage.setItem('chapfood_cashier_session', JSON.stringify(sessionData));
    }
  }, [selectedClient, cart, orderType, deliveryLocation]);
  
  // Rafraîchir les stats après création de commande
  useEffect(() => {
    if (createdOrder) {
      // Déclencher un rafraîchissement immédiat des stats
      const fetchStats = async () => {
        try {
          const today = new Date();
          today.setHours(0, 0, 0, 0);
          const tomorrow = new Date(today);
          tomorrow.setDate(tomorrow.getDate() + 1);

          const { data, error } = await supabase
            .from('orders')
            .select('total_amount')
            .gte('created_at', today.toISOString())
            .lt('created_at', tomorrow.toISOString());

          if (error) throw error;

          const totalRevenue = data?.reduce((sum, o) => sum + o.total_amount, 0) || 0;
          const totalOrders = data?.length || 0;

          setTodayStats({
            totalOrders,
            totalRevenue,
            averageOrder: totalOrders > 0 ? totalRevenue / totalOrders : 0
          });
        } catch (error) {
          console.error('Erreur lors du chargement des stats:', error);
        }
      };
      
      fetchStats();
    }
  }, [createdOrder]);

  // Calcul du total
  useEffect(() => {
    const total = cart.reduce((sum, item) => sum + item.total_price, 0);
    setOrderTotal(total);
  }, [cart]);

  // Charger les statistiques du jour
  useEffect(() => {
    const fetchTodayStats = async () => {
      try {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);

        const { data, error } = await supabase
          .from('orders')
          .select('total_amount')
          .gte('created_at', today.toISOString())
          .lt('created_at', tomorrow.toISOString());

        if (error) throw error;

        const totalRevenue = data?.reduce((sum, o) => sum + o.total_amount, 0) || 0;
        const totalOrders = data?.length || 0;

        setTodayStats({
          totalOrders,
          totalRevenue,
          averageOrder: totalOrders > 0 ? totalRevenue / totalOrders : 0
        });
      } catch (error) {
        console.error('Erreur lors du chargement des stats:', error);
      }
    };

    fetchTodayStats();
    
    // Rafraîchir toutes les 30 secondes
    const interval = setInterval(fetchTodayStats, 30000);
    return () => clearInterval(interval);
  }, []);

  // Gestion du mode plein écran
  const toggleFullscreen = () => {
    if (!isFullscreen) {
      if (document.documentElement.requestFullscreen) {
        document.documentElement.requestFullscreen();
      }
    } else {
      if (document.exitFullscreen) {
        document.exitFullscreen();
      }
    }
    setIsFullscreen(!isFullscreen);
  };

  // Écouter les changements de plein écran
  useEffect(() => {
    const handleFullscreenChange = () => {
      setIsFullscreen(!!document.fullscreenElement);
    };
    
    document.addEventListener('fullscreenchange', handleFullscreenChange);
    return () => document.removeEventListener('fullscreenchange', handleFullscreenChange);
  }, []);

  // Raccourci clavier pour plein écran
  useEffect(() => {
    const handleKeyPress = (e: KeyboardEvent) => {
      if ((e.key === 'F11') || (e.ctrlKey && e.shiftKey && e.key === 'F')) {
        e.preventDefault();
        toggleFullscreen();
      }
    };
    
    window.addEventListener('keydown', handleKeyPress);
    return () => window.removeEventListener('keydown', handleKeyPress);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isFullscreen]);

  // Reprendre une session
  const handleResumeSession = () => {
    const savedSession = localStorage.getItem('chapfood_cashier_session');
    if (savedSession) {
      try {
        const session = JSON.parse(savedSession);
        setSelectedClient(session.selectedClient);
        setCart(session.cart);
        setOrderType(session.orderType);
        setDeliveryLocation(session.deliveryLocation);
        setHasSessionData(false);
        toast({
          title: "Session reprise",
          description: "Votre session précédente a été restaurée",
        });
      } catch (error) {
        console.error('Erreur lors de la reprise de session:', error);
      }
    }
  };

  const handleClientSelected = (client: Client) => {
    setSelectedClient(client);
    setCurrentStep('order');
    toast({
      title: "Client sélectionné",
      description: `Commande pour ${client.full_name}`,
    });
  };

  const handleClientCreated = (client: Client) => {
    setSelectedClient(client);
    setCurrentStep('order');
    toast({
      title: "Nouveau client créé",
      description: `${client.full_name} a été ajouté avec le mot de passe par défaut`,
    });
  };

  const handleOrderComplete = () => {
    if (orderType === 'delivery') {
      setCurrentStep('location');
    } else {
      setCurrentStep('summary');
    }
  };

  const handleLocationSelected = (location: any) => {
    setDeliveryLocation(location);
    setCurrentStep('summary');
  };


  const handleOrderCreated = (order: any) => {
    setCreatedOrder(order);
    setCurrentStep('complete');
    toast({
      title: "Commande créée avec succès",
      description: `Commande #${order.id} créée pour ${selectedClient?.full_name}`,
    });
  };

  const resetSystem = () => {
    setCurrentStep('client');
    setSelectedClient(null);
    setCart([]);
    setOrderType('pickup');
    setDeliveryLocation(null);
    setCreatedOrder(null);
    // Vider le localStorage
    localStorage.removeItem('chapfood_cashier_session');
    
    // Son de succès
    const audio = new Audio('data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBTGH0fPReCwFI4DH8tiJPgk');
    audio.volume = 0.3;
    audio.play().catch(() => {});
  };

  const getStepTitle = () => {
    switch (currentStep) {
      case 'client': return 'Recherche Client';
      case 'order': return 'Construction Commande';
      case 'location': return 'Sélection Adresse';
      case 'summary': return 'Récapitulatif';
      case 'complete': return 'Commande Finalisée';
      default: return 'Système de Caisse';
    }
  };

  const getStepIcon = () => {
    switch (currentStep) {
      case 'client': return <Search className="h-6 w-6" />;
      case 'order': return <ShoppingCart className="h-6 w-6" />;
      case 'location': return <MapPin className="h-6 w-6" />;
      case 'summary': return <CreditCard className="h-6 w-6" />;
      case 'complete': return <CheckCircle className="h-6 w-6" />;
      default: return <ChefHat className="h-6 w-6" />;
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-orange-50 via-red-50 to-yellow-50">
      {/* Header */}
      <div className="bg-white/95 backdrop-blur-sm shadow-lg border-b border-orange-200">
        <div className="container mx-auto px-4 py-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <Button
                variant="outline"
                size="sm"
                onClick={() => navigate('/admin')}
                className="border-orange-300 text-orange-600 hover:bg-orange-50"
              >
                <ArrowLeft className="h-4 w-4 mr-2" />
                Retour
              </Button>
              
              <div className="flex items-center gap-3">
                <div className="p-3 bg-gradient-to-r from-orange-500 to-red-500 rounded-xl">
                  <ChefHat className="h-8 w-8 text-white" />
                </div>
                <div>
                  <h1 className="text-2xl font-bold bg-gradient-to-r from-orange-600 to-red-600 bg-clip-text text-transparent">
                    Système de Caisse ChapFood
                  </h1>
                  <p className="text-gray-600">Gestion des commandes manuelles</p>
                </div>
              </div>
            </div>

            {/* Informations client actuel */}
            <div className="flex items-center gap-3">
              {selectedClient && (
                <Card className="bg-white/90 backdrop-blur-sm border-orange-200">
                  <CardContent className="p-4">
                    <div className="flex items-center gap-3">
                      <Avatar className="h-10 w-10">
                        <AvatarFallback className="bg-gradient-to-r from-orange-500 to-red-500 text-white">
                          {selectedClient.full_name.split(' ').map(n => n[0]).join('').slice(0, 2)}
                        </AvatarFallback>
                      </Avatar>
                      <div>
                        <p className="font-semibold text-gray-800">{selectedClient.full_name}</p>
                        <p className="text-sm text-gray-600">{selectedClient.phone}</p>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              )}
              
              {/* Boutons d'action */}
              <div className="flex items-center gap-2">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setShowHistory(true)}
                  className="border-blue-300 text-blue-600 hover:bg-blue-50 relative"
                  title="Historique des commandes"
                >
                  <History className="h-4 w-4 mr-2" />
                  Historique
                  {todayStats.totalOrders > 0 && (
                    <Badge className="absolute -top-2 -right-2 h-5 w-5 p-0 flex items-center justify-center bg-blue-600 text-white text-xs">
                      {todayStats.totalOrders}
                    </Badge>
                  )}
                </Button>
                
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setShowSettings(true)}
                  className="border-purple-300 text-purple-600 hover:bg-purple-50"
                  title="Paramètres de la caisse"
                >
                  <Settings className="h-4 w-4" />
                </Button>
                
                <Button
                  variant="outline"
                  size="sm"
                  onClick={toggleFullscreen}
                  className="border-green-300 text-green-600 hover:bg-green-50"
                  title={isFullscreen ? "Quitter le mode plein écran" : "Mode plein écran"}
                >
                  {isFullscreen ? <Minimize2 className="h-4 w-4" /> : <Maximize2 className="h-4 w-4" />}
                </Button>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Alert pour session sauvegardée */}
      {hasSessionData && currentStep === 'client' && (
        <div className="container mx-auto px-4 py-4">
          <Card className="bg-blue-50 border-blue-200">
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <Package className="h-5 w-5 text-blue-600" />
                  <p className="text-blue-800">
                    Vous avez une session en cours. Voulez-vous la reprendre?
                  </p>
                </div>
                <div className="flex gap-2">
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => {
                      localStorage.removeItem('chapfood_cashier_session');
                      setHasSessionData(false);
                    }}
                    className="border-gray-300"
                  >
                    Ignorer
                  </Button>
                  <Button
                    size="sm"
                    onClick={handleResumeSession}
                    className="bg-blue-600 hover:bg-blue-700 text-white"
                  >
                    Reprendre
                  </Button>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Barre de progression */}
      <div className="bg-white/95 backdrop-blur-sm shadow-sm border-b border-orange-200">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            {['client', 'order', 'location', 'summary', 'complete'].map((step, index) => (
              <div key={step} className="flex items-center">
                <div className={`
                  flex items-center justify-center w-10 h-10 rounded-full text-sm font-bold
                  ${currentStep === step 
                    ? 'bg-gradient-to-r from-orange-500 to-red-500 text-white' 
                    : index < ['client', 'order', 'location', 'summary', 'complete'].indexOf(currentStep)
                    ? 'bg-green-500 text-white'
                    : 'bg-gray-200 text-gray-600'
                  }
                `}>
                  {index + 1}
                </div>
                {index < 4 && (
                  <div className={`
                    w-16 h-1 mx-2
                    ${index < ['client', 'order', 'location', 'summary', 'complete'].indexOf(currentStep)
                      ? 'bg-green-500'
                      : 'bg-gray-200'
                    }
                  `} />
                )}
              </div>
            ))}
          </div>
          
          <div className="flex items-center justify-center mt-4">
            <div className="flex items-center gap-2 text-lg font-semibold text-orange-700">
              {getStepIcon()}
              {getStepTitle()}
            </div>
          </div>
        </div>
      </div>

      {/* Contenu principal */}
      <div className="container mx-auto px-4 py-8">
        <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
          {/* Panneau principal */}
          <div className="lg:col-span-3">
            {currentStep === 'client' && (
              <ClientSearch 
                onClientSelected={handleClientSelected}
                onClientCreated={handleClientCreated}
              />
            )}

            {currentStep === 'order' && (
              <OrderBuilder
                client={selectedClient!}
                cart={cart}
                setCart={setCart}
                orderType={orderType}
                setOrderType={setOrderType}
                onComplete={handleOrderComplete}
              />
            )}

            {currentStep === 'location' && (
              <DeliveryLocationPicker
                onLocationConfirmed={handleLocationSelected}
                onCancel={() => setCurrentStep('order')}
              />
            )}


            {currentStep === 'summary' && (
              <OrderSummary
                client={selectedClient!}
                cart={cart}
                orderType={orderType}
                deliveryLocation={deliveryLocation}
                orderTotal={orderTotal}
                onOrderCreated={handleOrderCreated}
                onCancel={() => setCurrentStep(orderType === 'delivery' ? 'location' : 'order')}
              />
            )}

            {currentStep === 'complete' && (
              <div className="text-center">
                <Card className="bg-white/90 backdrop-blur-sm border-green-200">
                  <CardContent className="p-12">
                    <CheckCircle className="h-24 w-24 text-green-500 mx-auto mb-6" />
                    <h2 className="text-3xl font-bold text-green-600 mb-4">
                      Commande Finalisée !
                    </h2>
                    <p className="text-lg text-gray-600 mb-6">
                      Commande #{createdOrder?.id} créée avec succès pour {selectedClient?.full_name}
                    </p>
                    <div className="flex gap-4 justify-center">
                      <Button
                        onClick={resetSystem}
                        className="bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 text-white"
                      >
                        Nouvelle Commande
                      </Button>
                      <Button
                        variant="outline"
                        onClick={() => navigate('/admin/reservations')}
                        className="border-orange-300 text-orange-600 hover:bg-orange-50"
                      >
                        Voir Commandes
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              </div>
            )}
          </div>

          {/* Panneau latéral - Résumé */}
          <div className="space-y-6">
            {/* Statistiques du jour */}
            <Card className="bg-white/90 backdrop-blur-sm border-orange-200">
              <CardHeader className="bg-gradient-to-r from-orange-50 to-red-50 border-b border-orange-200">
                <CardTitle className="text-orange-700 flex items-center gap-2">
                  <BarChart3 className="h-5 w-5" />
                  Statistiques Aujourd'hui
                </CardTitle>
              </CardHeader>
              <CardContent className="p-4 space-y-3">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Package className="h-4 w-4 text-blue-500" />
                    <span className="text-sm text-gray-600">Commandes</span>
                  </div>
                  <Badge className="bg-blue-100 text-blue-800 font-bold">
                    {todayStats.totalOrders}
                  </Badge>
                </div>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <DollarSign className="h-4 w-4 text-green-500" />
                    <span className="text-sm text-gray-600">CA Total</span>
                  </div>
                  <span className="font-bold text-green-600">
                    {todayStats.totalRevenue.toLocaleString()} FCFA
                  </span>
                </div>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <TrendingUp className="h-4 w-4 text-purple-500" />
                    <span className="text-sm text-gray-600">Panier Moyen</span>
                  </div>
                  <span className="font-bold text-purple-600">
                    {Math.round(todayStats.averageOrder).toLocaleString()} FCFA
                  </span>
                </div>
              </CardContent>
            </Card>
            
            {/* Résumé client */}
            {selectedClient && (
              <Card className="bg-white/90 backdrop-blur-sm border-orange-200">
                <CardHeader className="bg-gradient-to-r from-orange-50 to-red-50 border-b border-orange-200">
                  <CardTitle className="text-orange-700 flex items-center gap-2">
                    <Users className="h-5 w-5" />
                    Client
                  </CardTitle>
                </CardHeader>
                <CardContent className="p-4">
                  <div className="space-y-3">
                    <div className="flex items-center gap-3">
                      <Avatar className="h-10 w-10">
                        <AvatarFallback className="bg-gradient-to-r from-orange-500 to-red-500 text-white">
                          {selectedClient.full_name.split(' ').map(n => n[0]).join('').slice(0, 2)}
                        </AvatarFallback>
                      </Avatar>
                      <div>
                        <p className="font-semibold">{selectedClient.full_name}</p>
                        <p className="text-sm text-gray-600">{selectedClient.phone}</p>
                      </div>
                    </div>
                    {selectedClient.email && (
                      <p className="text-sm text-gray-600">{selectedClient.email}</p>
                    )}
                    {selectedClient.address && (
                      <p className="text-sm text-gray-600">{selectedClient.address}</p>
                    )}
                  </div>
                </CardContent>
              </Card>
            )}

            {/* Résumé commande */}
            {cart.length > 0 && (
              <Card className="bg-white/90 backdrop-blur-sm border-orange-200">
                <CardHeader className="bg-gradient-to-r from-orange-50 to-red-50 border-b border-orange-200">
                  <CardTitle className="text-orange-700 flex items-center gap-2">
                    <Package className="h-5 w-5" />
                    Commande ({cart.length} articles)
                  </CardTitle>
                </CardHeader>
                <CardContent className="p-4">
                  <div className="space-y-2">
                    {cart.map((item) => (
                      <div key={item.id} className="flex justify-between items-center text-sm">
                        <div>
                          <p className="font-medium">{item.menu_item.name}</p>
                          <p className="text-gray-600">× {item.quantity}</p>
                        </div>
                        <p className="font-bold text-green-600">
                          {item.total_price.toLocaleString()} FCFA
                        </p>
                      </div>
                    ))}
                  </div>
                  <div className="border-t border-orange-200 pt-3 mt-3">
                    <div className="flex justify-between items-center font-bold text-lg">
                      <span>Total:</span>
                      <span className="text-green-600">{orderTotal.toLocaleString()} FCFA</span>
                    </div>
                  </div>
                </CardContent>
              </Card>
            )}

            {/* Type de commande */}
            {cart.length > 0 && (
              <Card className="bg-white/90 backdrop-blur-sm border-orange-200">
                <CardHeader className="bg-gradient-to-r from-orange-50 to-red-50 border-b border-orange-200">
                  <CardTitle className="text-orange-700 flex items-center gap-2">
                    <Clock className="h-5 w-5" />
                    Type de Commande
                  </CardTitle>
                </CardHeader>
                <CardContent className="p-4">
                  <div className="flex items-center gap-2">
                    {orderType === 'delivery' ? (
                      <>
                        <MapPin className="h-5 w-5 text-blue-500" />
                        <span className="font-semibold text-blue-600">Livraison</span>
                      </>
                    ) : (
                      <>
                        <Package className="h-5 w-5 text-green-500" />
                        <span className="font-semibold text-green-600">À emporter</span>
                      </>
                    )}
                  </div>
                  {deliveryLocation && (
                    <p className="text-sm text-gray-600 mt-2">
                      {deliveryLocation.address}
                    </p>
                  )}
                </CardContent>
              </Card>
            )}

          </div>
        </div>
      </div>

      {/* Modal Historique */}
      <CashierHistory 
        isOpen={showHistory} 
        onClose={() => setShowHistory(false)} 
      />

      {/* Modal Paramètres */}
      <CashierSettings 
        isOpen={showSettings} 
        onClose={() => setShowSettings(false)} 
      />
    </div>
  );
};

export default CashierSystem;
