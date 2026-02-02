import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Users, Calendar, Truck, Package, TrendingUp, DollarSign } from "lucide-react";
import { useEffect, useState } from "react";
import { supabase } from "@/integrations/supabase/client";

export function AdminDashboard() {
  const [stats, setStats] = useState({
    totalUsers: 0,
    totalOrders: 0,
    totalDrivers: 0,
    totalMenuItems: 0,
    todayRevenue: 0,
    pendingOrders: 0,
  });

  useEffect(() => {
    fetchDashboardStats();
  }, []);

  const fetchDashboardStats = async () => {
    try {
      // Fetch users count
      const { count: usersCount } = await supabase
        .from('users')
        .select('*', { count: 'exact', head: true });

      // Fetch orders count
      const { count: ordersCount } = await supabase
        .from('orders')
        .select('*', { count: 'exact', head: true });

      // Fetch drivers count
      const { count: driversCount } = await supabase
        .from('drivers')
        .select('*', { count: 'exact', head: true });

      // Fetch menu items count
      const { count: menuItemsCount } = await supabase
        .from('menu_items')
        .select('*', { count: 'exact', head: true });

      // Fetch pending orders
      const { count: pendingOrdersCount } = await supabase
        .from('orders')
        .select('*', { count: 'exact', head: true })
        .eq('status', 'pending');

      // Fetch today's revenue
      const today = new Date().toISOString().split('T')[0];
      const { data: todayOrders } = await supabase
        .from('orders')
        .select('total_amount')
        .gte('created_at', today)
        .eq('status', 'delivered');

      const todayRevenue = todayOrders?.reduce((sum, order) => sum + Number(order.total_amount), 0) || 0;

      setStats({
        totalUsers: usersCount || 0,
        totalOrders: ordersCount || 0,
        totalDrivers: driversCount || 0,
        totalMenuItems: menuItemsCount || 0,
        todayRevenue,
        pendingOrders: pendingOrdersCount || 0,
      });
    } catch (error) {
      console.error('Error fetching dashboard stats:', error);
    }
  };

  const statCards = [
    {
      title: "Total Clients",
      value: stats.totalUsers,
      icon: Users,
      description: "Clients enregistrés",
      color: "text-blue-600",
    },
    {
      title: "Commandes",
      value: stats.totalOrders,
      icon: Calendar,
      description: "Commandes totales",
      color: "text-green-600",
    },
    {
      title: "Livreurs",
      value: stats.totalDrivers,
      icon: Truck,
      description: "Livreurs actifs",
      color: "text-purple-600",
    },
    {
      title: "Articles Menu",
      value: stats.totalMenuItems,
      icon: Package,
      description: "Plats disponibles",
      color: "text-orange-600",
    },
    {
      title: "Revenus Aujourd'hui",
      value: `${stats.todayRevenue.toLocaleString()} FCFA`,
      icon: DollarSign,
      description: "Chiffre d'affaires du jour",
      color: "text-emerald-600",
    },
    {
      title: "Commandes en Attente",
      value: stats.pendingOrders,
      icon: TrendingUp,
      description: "À traiter",
      color: "text-red-600",
    },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-foreground">Tableau de Bord</h1>
        <p className="text-muted-foreground">Vue d'ensemble de votre restaurant</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {statCards.map((card) => (
          <Card key={card.title} className="hover:shadow-lg transition-shadow">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">{card.title}</CardTitle>
              <card.icon className={`h-4 w-4 ${card.color}`} />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{card.value}</div>
              <p className="text-xs text-muted-foreground">{card.description}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Activité Récente</CardTitle>
            <CardDescription>Dernières actions dans le système</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              <div className="flex items-center space-x-3">
                <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                <span className="text-sm">Nouvelle commande reçue</span>
                <span className="text-xs text-muted-foreground ml-auto">Il y a 5 min</span>
              </div>
              <div className="flex items-center space-x-3">
                <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
                <span className="text-sm">Livreur assigné à la commande #123</span>
                <span className="text-xs text-muted-foreground ml-auto">Il y a 10 min</span>
              </div>
              <div className="flex items-center space-x-3">
                <div className="w-2 h-2 bg-purple-500 rounded-full"></div>
                <span className="text-sm">Nouveau client enregistré</span>
                <span className="text-xs text-muted-foreground ml-auto">Il y a 1h</span>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Actions Rapides</CardTitle>
            <CardDescription>Raccourcis vers les tâches fréquentes</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 gap-3">
              <button className="p-3 text-left border border-border rounded-lg hover:bg-accent hover:text-accent-foreground transition-colors">
                <div className="font-medium">Nouvelle Commande</div>
                <div className="text-sm text-muted-foreground">Créer une commande</div>
              </button>
              <button className="p-3 text-left border border-border rounded-lg hover:bg-accent hover:text-accent-foreground transition-colors">
                <div className="font-medium">Ajouter Plat</div>
                <div className="text-sm text-muted-foreground">Au menu</div>
              </button>
              <button className="p-3 text-left border border-border rounded-lg hover:bg-accent hover:text-accent-foreground transition-colors">
                <div className="font-medium">Gérer Stock</div>
                <div className="text-sm text-muted-foreground">Inventaire</div>
              </button>
              <button className="p-3 text-left border border-border rounded-lg hover:bg-accent hover:text-accent-foreground transition-colors">
                <div className="font-medium">Voir Rapports</div>
                <div className="text-sm text-muted-foreground">Analyses</div>
              </button>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}