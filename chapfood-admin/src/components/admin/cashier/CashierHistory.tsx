import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { supabase } from '@/integrations/supabase/client';
import { useNavigate } from 'react-router-dom';
import { useToast } from '@/hooks/use-toast';
import { 
  History,
  Download,
  Eye,
  TrendingUp,
  DollarSign,
  Package,
  Clock,
  Calendar
} from 'lucide-react';

interface CashierOrder {
  id: number;
  customer_name: string;
  delivery_type: string;
  total_amount: number;
  status: string;
  created_at: string;
}

interface CashierHistoryProps {
  isOpen: boolean;
  onClose: () => void;
}

const CashierHistory: React.FC<CashierHistoryProps> = ({ isOpen, onClose }) => {
  const navigate = useNavigate();
  const { toast } = useToast();
  const [orders, setOrders] = useState<CashierOrder[]>([]);
  const [loading, setLoading] = useState(false);
  const [typeFilter, setTypeFilter] = useState<'all' | 'delivery' | 'pickup'>('all');
  const [stats, setStats] = useState({
    totalOrders: 0,
    totalRevenue: 0,
    averageOrder: 0,
    deliveriesCount: 0,
    pickupsCount: 0
  });

  const fetchTodaysOrders = async () => {
    try {
      setLoading(true);
      
      // Obtenir la date du jour (début et fin)
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);

      let query = supabase
        .from('orders')
        .select('id, customer_name, delivery_type, total_amount, status, created_at')
        .gte('created_at', today.toISOString())
        .lt('created_at', tomorrow.toISOString())
        .order('created_at', { ascending: false });

      const { data, error } = await query;

      if (error) throw error;

      const allOrders = data || [];
      
      // Filtrer selon le type
      const filtered = typeFilter === 'all' 
        ? allOrders 
        : allOrders.filter(o => o.delivery_type === typeFilter);

      setOrders(filtered as CashierOrder[]);

      // Calculer les statistiques
      const totalRevenue = allOrders.reduce((sum, o) => sum + o.total_amount, 0);
      const deliveriesCount = allOrders.filter(o => o.delivery_type === 'delivery').length;
      const pickupsCount = allOrders.filter(o => o.delivery_type === 'pickup').length;

      setStats({
        totalOrders: allOrders.length,
        totalRevenue,
        averageOrder: allOrders.length > 0 ? totalRevenue / allOrders.length : 0,
        deliveriesCount,
        pickupsCount
      });
    } catch (error) {
      console.error('Erreur lors du chargement des commandes:', error);
      toast({
        title: "Erreur",
        description: "Impossible de charger l'historique",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (isOpen) {
      fetchTodaysOrders();
      
      // Rafraîchir toutes les 30 secondes
      const interval = setInterval(() => {
        fetchTodaysOrders();
      }, 30000);

      return () => clearInterval(interval);
    }
  }, [isOpen, typeFilter]);

  const exportToCSV = () => {
    const headers = ['#', 'Heure', 'Client', 'Type', 'Montant', 'Statut'];
    const rows = orders.map(order => [
      order.id,
      new Date(order.created_at).toLocaleTimeString('fr-FR'),
      order.customer_name,
      order.delivery_type === 'delivery' ? 'Livraison' : 'À emporter',
      order.total_amount.toLocaleString() + ' FCFA',
      order.status
    ]);

    const csvContent = [headers, ...rows]
      .map(row => row.join(','))
      .join('\n');

    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);
    link.setAttribute('href', url);
    link.setAttribute('download', `commandes_caisse_${new Date().toISOString().split('T')[0]}.csv`);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    toast({
      title: "Export réussi",
      description: "Les données ont été exportées en CSV",
    });
  };

  const getStatusBadge = (status: string) => {
    const variants: { [key: string]: string } = {
      pending: 'bg-yellow-100 text-yellow-800',
      preparing: 'bg-blue-100 text-blue-800',
      ready: 'bg-purple-100 text-purple-800',
      'ready_for_delivery': 'bg-orange-100 text-orange-800',
      'in_transit': 'bg-indigo-100 text-indigo-800',
      delivered: 'bg-green-100 text-green-800',
      cancelled: 'bg-red-100 text-red-800'
    };
    
    return (
      <Badge className={variants[status] || 'bg-gray-100 text-gray-800'}>
        {status}
      </Badge>
    );
  };

  const handleViewOrder = (orderId: number) => {
    navigate(`/admin/reservations?order=${orderId}`);
    onClose();
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-6xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="text-orange-700 flex items-center gap-2">
            <History className="h-6 w-6" />
            Historique des Commandes Caisse - Aujourd'hui
          </DialogTitle>
          <DialogDescription>
            Liste des commandes créées via le système de caisse aujourd'hui
          </DialogDescription>
        </DialogHeader>

        {/* Statistiques */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-4">
          <Card className="bg-gradient-to-br from-blue-50 to-blue-100 border-blue-200">
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-blue-600 text-sm font-medium">Commandes</p>
                  <p className="text-2xl font-bold text-blue-700">{stats.totalOrders}</p>
                </div>
                <Package className="h-8 w-8 text-blue-600" />
              </div>
            </CardContent>
          </Card>

          <Card className="bg-gradient-to-br from-green-50 to-green-100 border-green-200">
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-green-600 text-sm font-medium">CA Total</p>
                  <p className="text-2xl font-bold text-green-700">
                    {stats.totalRevenue.toLocaleString()} FCFA
                  </p>
                </div>
                <DollarSign className="h-8 w-8 text-green-600" />
              </div>
            </CardContent>
          </Card>

          <Card className="bg-gradient-to-br from-purple-50 to-purple-100 border-purple-200">
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-purple-600 text-sm font-medium">Panier Moyen</p>
                  <p className="text-2xl font-bold text-purple-700">
                    {Math.round(stats.averageOrder).toLocaleString()} FCFA
                  </p>
                </div>
                <TrendingUp className="h-8 w-8 text-purple-600" />
              </div>
            </CardContent>
          </Card>

          <Card className="bg-gradient-to-br from-orange-50 to-orange-100 border-orange-200">
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-orange-600 text-sm font-medium">Livraisons</p>
                  <p className="text-2xl font-bold text-orange-700">{stats.deliveriesCount}</p>
                  <p className="text-xs text-orange-600">{stats.pickupsCount} à emporter</p>
                </div>
                <Package className="h-8 w-8 text-orange-600" />
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Filtres et actions */}
        <div className="flex items-center justify-between mb-4">
          <Select value={typeFilter} onValueChange={(value: any) => setTypeFilter(value)}>
            <SelectTrigger className="w-48 border-orange-300">
              <SelectValue placeholder="Type de commande" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Toutes ({stats.totalOrders})</SelectItem>
              <SelectItem value="delivery">Livraisons ({stats.deliveriesCount})</SelectItem>
              <SelectItem value="pickup">À emporter ({stats.pickupsCount})</SelectItem>
            </SelectContent>
          </Select>

          <Button
            onClick={exportToCSV}
            variant="outline"
            className="border-green-300 text-green-600 hover:bg-green-50"
            disabled={orders.length === 0}
          >
            <Download className="h-4 w-4 mr-2" />
            Exporter CSV
          </Button>
        </div>

        {/* Tableau */}
        {loading ? (
          <div className="text-center py-12">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-orange-500 mx-auto"></div>
            <p className="text-gray-600 mt-4">Chargement des commandes...</p>
          </div>
        ) : orders.length === 0 ? (
          <div className="text-center py-12">
            <Package className="h-16 w-16 text-gray-300 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-600 mb-2">Aucune commande</h3>
            <p className="text-sm text-gray-500">Aucune commande créée aujourd'hui</p>
          </div>
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="text-orange-700">#</TableHead>
                <TableHead className="text-orange-700">Heure</TableHead>
                <TableHead className="text-orange-700">Client</TableHead>
                <TableHead className="text-orange-700">Type</TableHead>
                <TableHead className="text-orange-700">Montant</TableHead>
                <TableHead className="text-orange-700">Statut</TableHead>
                <TableHead className="text-orange-700">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {orders.map((order) => (
                <TableRow key={order.id}>
                  <TableCell className="font-medium">#{order.id}</TableCell>
                  <TableCell>
                    <div className="flex items-center gap-1 text-sm">
                      <Clock className="h-4 w-4 text-gray-400" />
                      {new Date(order.created_at).toLocaleTimeString('fr-FR')}
                    </div>
                  </TableCell>
                  <TableCell>{order.customer_name}</TableCell>
                  <TableCell>
                    <Badge variant="outline" className={
                      order.delivery_type === 'delivery' 
                        ? 'border-blue-300 text-blue-700' 
                        : 'border-green-300 text-green-700'
                    }>
                      {order.delivery_type === 'delivery' ? 'Livraison' : 'À emporter'}
                    </Badge>
                  </TableCell>
                  <TableCell className="font-semibold text-green-600">
                    {order.total_amount.toLocaleString()} FCFA
                  </TableCell>
                  <TableCell>{getStatusBadge(order.status)}</TableCell>
                  <TableCell>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => handleViewOrder(order.id)}
                      className="border-orange-300 text-orange-600 hover:bg-orange-50"
                    >
                      <Eye className="h-4 w-4 mr-2" />
                      Voir
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </DialogContent>
    </Dialog>
  );
};

export default CashierHistory;

