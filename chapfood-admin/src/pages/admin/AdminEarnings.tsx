import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { 
  ArrowLeft, 
  Search, 
  Download, 
  Filter, 
  TrendingUp, 
  DollarSign, 
  Calendar, 
  Users, 
  Package,
  Eye,
  RefreshCw,
  BarChart3,
  Clock
} from 'lucide-react';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';

interface DriverEarnings {
  driver_id: number;
  driver_name: string;
  total_orders: number;
  completed_orders: number;
  total_earnings: number;
  pending_earnings: number;
  average_order_value: number;
  last_payment_date: string | null;
  current_month_earnings: number;
  last_month_earnings: number;
}

interface EarningsHistory {
  id: number;
  driver_id: number;
  driver_name: string;
  order_id: number;
  order_amount: number;
  commission_rate: number;
  commission_amount: number;
  payment_status: 'pending' | 'paid' | 'cancelled';
  created_at: string;
  paid_at: string | null;
}

const AdminEarnings = () => {
  const navigate = useNavigate();
  const { toast } = useToast();
  
  // États pour les données
  const [driversEarnings, setDriversEarnings] = useState<DriverEarnings[]>([]);
  const [earningsHistory, setEarningsHistory] = useState<EarningsHistory[]>([]);
  const [loading, setLoading] = useState(true);
  
  // États pour les filtres
  const [searchTerm, setSearchTerm] = useState('');
  const [periodFilter, setPeriodFilter] = useState('current_month');
  const [statusFilter, setStatusFilter] = useState('all');
  const [selectedDriver, setSelectedDriver] = useState<number | null>(null);
  
  // États pour les modals
  const [showDriverDetails, setShowDriverDetails] = useState(false);
  const [selectedDriverData, setSelectedDriverData] = useState<DriverEarnings | null>(null);
  
  // Statistiques globales
  const [totalEarnings, setTotalEarnings] = useState(0);
  const [totalPending, setTotalPending] = useState(0);
  const [totalDrivers, setTotalDrivers] = useState(0);
  const [averageEarnings, setAverageEarnings] = useState(0);

  useEffect(() => {
    fetchEarningsData();
  }, [periodFilter, statusFilter, selectedDriver]);

  const fetchEarningsData = async () => {
    try {
      setLoading(true);
      
      // Récupérer les gains des livreurs
      const { data: driversData, error: driversError } = await supabase
        .from('drivers')
        .select(`
          id,
          name,
          is_active
        `)
        .eq('is_active', true);

      if (driversError) throw driversError;

      // Calculer les gains pour chaque livreur
      const earningsPromises = driversData?.map(async (driver) => {
        // Récupérer les commandes du livreur
        const { data: ordersData, error: ordersError } = await supabase
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
          .eq('driver_id', driver.id);

        if (ordersError) throw ordersError;

        const orders = ordersData || [];
        const completedOrders = orders.filter(o => o.orders?.status === 'delivered');
        
        // Calcul des gains (5% du montant de la commande)
        const totalEarnings = completedOrders.reduce((sum, o) => {
          return sum + (o.orders?.total_amount * 0.05 || 0);
        }, 0);

        const currentMonth = new Date().getMonth();
        const currentYear = new Date().getFullYear();
        
        const currentMonthOrders = completedOrders.filter(o => {
          const orderDate = new Date(o.orders?.created_at || '');
          return orderDate.getMonth() === currentMonth && orderDate.getFullYear() === currentYear;
        });

        const lastMonth = currentMonth === 0 ? 11 : currentMonth - 1;
        const lastMonthYear = currentMonth === 0 ? currentYear - 1 : currentYear;
        
        const lastMonthOrders = completedOrders.filter(o => {
          const orderDate = new Date(o.orders?.created_at || '');
          return orderDate.getMonth() === lastMonth && orderDate.getFullYear() === lastMonthYear;
        });

        const currentMonthEarnings = currentMonthOrders.reduce((sum, o) => {
          return sum + (o.orders?.total_amount * 0.05 || 0);
        }, 0);

        const lastMonthEarnings = lastMonthOrders.reduce((sum, o) => {
          return sum + (o.orders?.total_amount * 0.05 || 0);
        }, 0);

        // Calculer le montant moyen par commande (pas les gains moyens, mais le montant moyen des commandes)
        const totalOrderAmounts = completedOrders.reduce((sum, o) => {
          return sum + (o.orders?.total_amount || 0);
        }, 0);
        const averageOrderValue = completedOrders.length > 0 ? totalOrderAmounts / completedOrders.length : 0;

        return {
          driver_id: driver.id,
          driver_name: driver.name,
          total_orders: orders.length,
          completed_orders: completedOrders.length,
          total_earnings: totalEarnings,
          pending_earnings: totalEarnings * 0.1, // 10% en attente
          average_order_value: averageOrderValue, // Montant moyen par commande livrée
          last_payment_date: null, // À implémenter avec une table de paiements
          current_month_earnings: currentMonthEarnings,
          last_month_earnings: lastMonthEarnings
        };
      }) || [];

      const earningsData = await Promise.all(earningsPromises);
      setDriversEarnings(earningsData);

      // Calculer les statistiques globales
      const total = earningsData.reduce((sum, d) => sum + d.total_earnings, 0);
      const pending = earningsData.reduce((sum, d) => sum + d.pending_earnings, 0);
      const average = earningsData.length > 0 ? total / earningsData.length : 0;

      setTotalEarnings(total);
      setTotalPending(pending);
      setTotalDrivers(earningsData.length);
      setAverageEarnings(average);

    } catch (error) {
      console.error('Erreur lors du chargement des gains:', error);
      toast({
        title: "Erreur",
        description: "Impossible de charger les données des gains",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const filteredEarnings = driversEarnings.filter(driver => {
    const matchesSearch = driver.driver_name.toLowerCase().includes(searchTerm.toLowerCase());
    return matchesSearch;
  });

  const handleViewDriverDetails = (driver: DriverEarnings) => {
    setSelectedDriverData(driver);
    setShowDriverDetails(true);
    fetchDriverHistory(driver.driver_id);
  };

  const fetchDriverHistory = async (driverId: number) => {
    try {
      const { data, error } = await supabase
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
        .eq('driver_id', driverId)
        .eq('orders.status', 'delivered')
        .order('assigned_at', { ascending: false });

      if (error) throw error;

      const history = data?.map(assignment => ({
        id: assignment.id,
        driver_id: driverId,
        driver_name: selectedDriverData?.driver_name || '',
        order_id: assignment.orders?.id || 0,
        order_amount: assignment.orders?.total_amount || 0,
        commission_rate: 0.05, // 5%
        commission_amount: (assignment.orders?.total_amount || 0) * 0.05,
        payment_status: 'paid' as const,
        created_at: assignment.orders?.created_at || '',
        paid_at: assignment.orders?.created_at || null
      })) || [];

      setEarningsHistory(history);
    } catch (error) {
      console.error('Erreur lors du chargement de l\'historique:', error);
    }
  };

  const formatPrice = (price: number) => {
    return `${price.toLocaleString('fr-FR')} FCFA`;
  };

  const getEarningsGrowth = (current: number, previous: number) => {
    if (previous === 0) return current > 0 ? 100 : 0;
    return ((current - previous) / previous) * 100;
  };

  const formatPercentage = (value: number) => {
    return isNaN(value) ? '0%' : `${value.toFixed(1)}%`;
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
                size="sm"
                onClick={() => navigate('/admin')}
                className="border-orange-300 text-orange-600 hover:bg-orange-50"
              >
                <ArrowLeft className="h-4 w-4 mr-2" />
                Retour
              </Button>
              <div>
                <h1 className="text-2xl font-bold bg-gradient-to-r from-orange-600 to-red-600 bg-clip-text text-transparent">
                  Gestion des Gains
                </h1>
                <p className="text-gray-600">Suivi des rémunérations des livreurs</p>
              </div>
            </div>
            
            <div className="flex items-center gap-3">
              <Button
                variant="outline"
                onClick={fetchEarningsData}
                className="border-orange-300 text-orange-600 hover:bg-orange-50"
              >
                <RefreshCw className="h-4 w-4 mr-2" />
                Actualiser
              </Button>
              <Button
                className="bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 text-white"
              >
                <Download className="h-4 w-4 mr-2" />
                Exporter
              </Button>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-6 py-6">
        {/* Statistiques globales */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <Card className="bg-gradient-to-r from-green-50 to-green-100 border-green-200">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-green-600 font-medium">Gains Totaux</p>
                  <p className="text-2xl font-bold text-green-700">{formatPrice(totalEarnings)}</p>
                </div>
                <DollarSign className="h-8 w-8 text-green-600" />
              </div>
            </CardContent>
          </Card>

          <Card className="bg-gradient-to-r from-orange-50 to-orange-100 border-orange-200">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-orange-600 font-medium">En Attente</p>
                  <p className="text-2xl font-bold text-orange-700">{formatPrice(totalPending)}</p>
                </div>
                <Clock className="h-8 w-8 text-orange-600" />
              </div>
            </CardContent>
          </Card>

          <Card className="bg-gradient-to-r from-blue-50 to-blue-100 border-blue-200">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-blue-600 font-medium">Livreurs Actifs</p>
                  <p className="text-2xl font-bold text-blue-700">{totalDrivers}</p>
                </div>
                <Users className="h-8 w-8 text-blue-600" />
              </div>
            </CardContent>
          </Card>

          <Card className="bg-gradient-to-r from-purple-50 to-purple-100 border-purple-200">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-purple-600 font-medium">Moyenne/Livreur</p>
                  <p className="text-2xl font-bold text-purple-700">{formatPrice(averageEarnings)}</p>
                </div>
                <BarChart3 className="h-8 w-8 text-purple-600" />
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Filtres */}
        <Card className="mb-6">
          <CardHeader>
            <CardTitle className="text-orange-700 flex items-center gap-2">
              <Filter className="h-5 w-5" />
              Filtres
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex items-center gap-4">
              <div className="relative flex-1">
                <Search className="absolute left-3 top-3 h-4 w-4 text-orange-500" />
                <Input
                  placeholder="Rechercher un livreur..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-10 border-orange-300 focus:border-orange-500"
                />
              </div>
              
              <Select value={periodFilter} onValueChange={setPeriodFilter}>
                <SelectTrigger className="w-48 border-orange-300">
                  <SelectValue placeholder="Période" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="current_month">Ce mois</SelectItem>
                  <SelectItem value="last_month">Mois dernier</SelectItem>
                  <SelectItem value="last_3_months">3 derniers mois</SelectItem>
                  <SelectItem value="all_time">Tout le temps</SelectItem>
                </SelectContent>
              </Select>

              <Select value={statusFilter} onValueChange={setStatusFilter}>
                <SelectTrigger className="w-40 border-orange-300">
                  <SelectValue placeholder="Statut" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Tous</SelectItem>
                  <SelectItem value="paid">Payés</SelectItem>
                  <SelectItem value="pending">En attente</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </CardContent>
        </Card>

        {/* Tableau des gains */}
        <Card>
          <CardHeader>
            <CardTitle className="text-orange-700">Gains par Livreur</CardTitle>
            <CardDescription>
              {filteredEarnings.length} livreur(s) trouvé(s)
            </CardDescription>
          </CardHeader>
          <CardContent className="p-0">
            {loading ? (
              <div className="text-center py-12">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-orange-500 mx-auto"></div>
                <p className="text-gray-600 mt-4">Chargement des données...</p>
              </div>
            ) : (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="text-orange-700">Livreur</TableHead>
                    <TableHead className="text-orange-700">Commandes</TableHead>
                    <TableHead className="text-orange-700">Gains Totaux (5%)</TableHead>
                    <TableHead className="text-orange-700">Ce Mois</TableHead>
                    <TableHead className="text-orange-700">Évolution</TableHead>
                    <TableHead className="text-orange-700">Moy. Gain/Livraison</TableHead>
                    <TableHead className="text-orange-700">Montant Moy. Cmd</TableHead>
                    <TableHead className="text-orange-700">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredEarnings.map((driver) => {
                    const growth = getEarningsGrowth(driver.current_month_earnings, driver.last_month_earnings);
                    return (
                      <TableRow key={driver.driver_id}>
                        <TableCell>
                          <div className="font-medium text-gray-900">{driver.driver_name}</div>
                          <div className="text-sm text-gray-500">ID: #{driver.driver_id}</div>
                        </TableCell>
                        <TableCell>
                          <div className="text-center">
                            <div className="font-semibold">{driver.completed_orders}</div>
                            <div className="text-sm text-gray-500">/{driver.total_orders}</div>
                          </div>
                        </TableCell>
                        <TableCell>
                          <div className="font-semibold text-green-600">
                            {formatPrice(driver.total_earnings)}
                          </div>
                        </TableCell>
                        <TableCell>
                          <div className="font-semibold text-orange-600">
                            {formatPrice(driver.current_month_earnings)}
                          </div>
                        </TableCell>
                        <TableCell>
                          <Badge 
                            variant={growth >= 0 ? "default" : "destructive"}
                            className={growth >= 0 ? "bg-green-100 text-green-800" : "bg-red-100 text-red-800"}
                          >
                            {growth >= 0 ? '+' : ''}{formatPercentage(growth)}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          <div className="text-gray-700 font-medium">
                            {driver.completed_orders > 0 
                              ? formatPrice(driver.total_earnings / driver.completed_orders)
                              : '0 FCFA'
                            }
                          </div>
                        </TableCell>
                        <TableCell>
                          <div className="text-gray-600">
                            {formatPrice(driver.average_order_value)}
                          </div>
                        </TableCell>
                        <TableCell>
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => handleViewDriverDetails(driver)}
                            className="border-orange-300 text-orange-600 hover:bg-orange-50"
                          >
                            <Eye className="h-4 w-4 mr-2" />
                            Détails
                          </Button>
                        </TableCell>
                      </TableRow>
                    );
                  })}
                  {filteredEarnings.length === 0 && !loading && (
                    <TableRow>
                      <TableCell colSpan={8} className="text-center py-12">
                        <div className="flex flex-col items-center gap-4">
                          <div className="h-16 w-16 bg-gray-100 rounded-full flex items-center justify-center">
                            <Package className="h-8 w-8 text-gray-400" />
                          </div>
                          <div>
                            <h3 className="text-lg font-medium text-gray-600">Aucun livreur trouvé</h3>
                            <p className="text-sm text-gray-500">
                              {searchTerm ? "Essayez avec d'autres mots-clés" : "Aucun livreur actif"}
                            </p>
                          </div>
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

      {/* Modal détails du livreur */}
      <Dialog open={showDriverDetails} onOpenChange={setShowDriverDetails}>
        <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="text-orange-700">
              Détails des gains - {selectedDriverData?.driver_name}
            </DialogTitle>
            <DialogDescription>
              Historique complet des gains et commissions
            </DialogDescription>
          </DialogHeader>
          
          {selectedDriverData && (
            <Tabs defaultValue="overview" className="w-full">
              <TabsList className="grid w-full grid-cols-2">
                <TabsTrigger value="overview">Aperçu</TabsTrigger>
                <TabsTrigger value="history">Historique</TabsTrigger>
              </TabsList>
              
              <TabsContent value="overview" className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <Card>
                    <CardHeader>
                      <CardTitle className="text-lg">Statistiques</CardTitle>
                    </CardHeader>
                    <CardContent className="space-y-2">
                      <div className="flex justify-between">
                        <span>Commandes complétées:</span>
                        <span className="font-semibold">{selectedDriverData.completed_orders}</span>
                      </div>
                      <div className="flex justify-between">
                        <span>Total commandes:</span>
                        <span className="font-semibold">{selectedDriverData.total_orders}</span>
                      </div>
                      <div className="flex justify-between">
                        <span>Taux de réussite:</span>
                        <span className="font-semibold text-green-600">
                          {formatPercentage(
                            selectedDriverData.total_orders > 0 
                              ? (selectedDriverData.completed_orders / selectedDriverData.total_orders) * 100
                              : 0
                          )}
                        </span>
                      </div>
                    </CardContent>
                  </Card>
                  
                  <Card>
                    <CardHeader>
                      <CardTitle className="text-lg">Gains</CardTitle>
                    </CardHeader>
                    <CardContent className="space-y-2">
                      <div className="flex justify-between">
                        <span>Gains totaux (5%):</span>
                        <span className="font-semibold text-green-600">
                          {formatPrice(selectedDriverData.total_earnings)}
                        </span>
                      </div>
                      <div className="flex justify-between">
                        <span>Ce mois:</span>
                        <span className="font-semibold text-orange-600">
                          {formatPrice(selectedDriverData.current_month_earnings)}
                        </span>
                      </div>
                      <div className="flex justify-between">
                        <span>Mois dernier:</span>
                        <span className="font-semibold text-gray-600">
                          {formatPrice(selectedDriverData.last_month_earnings)}
                        </span>
                      </div>
                      <div className="flex justify-between">
                        <span>Gain moy./livraison:</span>
                        <span className="font-semibold text-blue-600">
                          {formatPrice(
                            selectedDriverData.completed_orders > 0
                              ? selectedDriverData.total_earnings / selectedDriverData.completed_orders
                              : 0
                          )}
                        </span>
                      </div>
                      <div className="flex justify-between">
                        <span>Montant moy. cmd:</span>
                        <span className="font-semibold text-purple-600">
                          {formatPrice(selectedDriverData.average_order_value)}
                        </span>
                      </div>
                    </CardContent>
                  </Card>
                </div>
              </TabsContent>
              
              <TabsContent value="history" className="space-y-4">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Commande</TableHead>
                      <TableHead>Montant</TableHead>
                      <TableHead>Commission</TableHead>
                      <TableHead>Date</TableHead>
                      <TableHead>Statut</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {earningsHistory.map((earning) => (
                      <TableRow key={earning.id}>
                        <TableCell>#{earning.order_id}</TableCell>
                        <TableCell>{formatPrice(earning.order_amount)}</TableCell>
                        <TableCell className="font-semibold text-green-600">
                          {formatPrice(earning.commission_amount)}
                        </TableCell>
                        <TableCell>
                          {new Date(earning.created_at).toLocaleDateString('fr-FR')}
                        </TableCell>
                        <TableCell>
                          <Badge 
                            variant={earning.payment_status === 'paid' ? 'default' : 'secondary'}
                            className={earning.payment_status === 'paid' ? 'bg-green-100 text-green-800' : 'bg-orange-100 text-orange-800'}
                          >
                            {earning.payment_status === 'paid' ? 'Payé' : 'En attente'}
                          </Badge>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TabsContent>
            </Tabs>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default AdminEarnings;
