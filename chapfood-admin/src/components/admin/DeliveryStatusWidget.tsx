import { useState, useEffect } from "react";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Truck, Clock, CheckCircle, AlertCircle } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";

interface DeliveryStats {
  total: number;
  inTransit: number;
  readyForAssignment: number;
  delivered: number;
  lastUpdate: Date;
}

const DeliveryStatusWidget = () => {
  const [stats, setStats] = useState<DeliveryStats>({
    total: 0,
    inTransit: 0,
    readyForAssignment: 0,
    delivered: 0,
    lastUpdate: new Date()
  });

  useEffect(() => {
    fetchStats();
    const interval = setInterval(fetchStats, 30000); // Update every 30 seconds
    return () => clearInterval(interval);
  }, []);

  const fetchStats = async () => {
    try {
      // Commandes avec repas récupéré ou en livraison (picked_up / in_transit)
      const { data: inTransitData, error: inTransitError } = await supabase
        .from('orders')
        .select('id')
        .in('status', ['picked_up', 'in_transit']);

      if (inTransitError) throw inTransitError;

      // Commandes prêtes pour assignation
      const { data: readyData, error: readyError } = await supabase
        .from('orders')
        .select('id')
        .eq('status', 'ready_for_delivery');

      if (readyError) throw readyError;

      // Commandes livrées aujourd'hui
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      
      const { data: deliveredData, error: deliveredError } = await supabase
        .from('orders')
        .select('id')
        .eq('status', 'delivered')
        .gte('actual_delivery_time', today.toISOString());

      if (deliveredError) throw deliveredError;

      setStats({
        total: (inTransitData?.length || 0) + (readyData?.length || 0),
        inTransit: inTransitData?.length || 0,
        readyForAssignment: readyData?.length || 0,
        delivered: deliveredData?.length || 0,
        lastUpdate: new Date()
      });
    } catch (error) {
      console.error('Erreur lors du chargement des statistiques:', error);
    }
  };

  return (
    <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
      <Card className="border-2 border-blue-200 bg-blue-50">
        <CardContent className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-blue-700 font-medium">En cours de livraison</p>
              <p className="text-3xl font-bold text-blue-900">{stats.inTransit}</p>
            </div>
            <Truck className="h-8 w-8 text-blue-600" />
          </div>
        </CardContent>
      </Card>

      <Card className="border-2 border-orange-200 bg-orange-50">
        <CardContent className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-orange-700 font-medium">Prêtes pour assignation</p>
              <p className="text-3xl font-bold text-orange-900">{stats.readyForAssignment}</p>
            </div>
            <Clock className="h-8 w-8 text-orange-600" />
          </div>
        </CardContent>
      </Card>

      <Card className="border-2 border-green-200 bg-green-50">
        <CardContent className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-green-700 font-medium">Livrées aujourd'hui</p>
              <p className="text-3xl font-bold text-green-900">{stats.delivered}</p>
            </div>
            <CheckCircle className="h-8 w-8 text-green-600" />
          </div>
        </CardContent>
      </Card>

      <Card className="border-2 border-purple-200 bg-purple-50">
        <CardContent className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-purple-700 font-medium">Total actif</p>
              <p className="text-3xl font-bold text-purple-900">{stats.total}</p>
            </div>
            <AlertCircle className="h-8 w-8 text-purple-600" />
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default DeliveryStatusWidget;

