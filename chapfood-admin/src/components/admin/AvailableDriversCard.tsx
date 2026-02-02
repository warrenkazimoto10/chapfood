import { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Truck, Phone, MapPin, Clock, User } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { useToast } from "@/hooks/use-toast";

interface Driver {
  id: number;
  name: string;
  phone: string;
  email: string | null;
  is_active: boolean | null;
  is_available: boolean | null;
  current_lat: number | null;
  current_lng: number | null;
  created_at: string | null;
}

interface AvailableDriversCardProps {
  orderId: number;
  onDriverSelected: (driverId: number, driverName: string) => void;
  loading?: boolean;
}

const AvailableDriversCard = ({ orderId, onDriverSelected, loading = false }: AvailableDriversCardProps) => {
  const [availableDrivers, setAvailableDrivers] = useState<Driver[]>([]);
  const [loadingDrivers, setLoadingDrivers] = useState(false);
  const [assigningDriver, setAssigningDriver] = useState<number | null>(null);
  const { toast } = useToast();

  useEffect(() => {
    fetchAvailableDrivers();
  }, []);

  const fetchAvailableDrivers = async () => {
    try {
      setLoadingDrivers(true);
      
      // Récupérer tous les livreurs actifs et disponibles
      const { data: drivers, error: driversError } = await supabase
        .from('drivers')
        .select('*')
        .eq('is_active', true)
        .eq('is_available', true);

      if (driversError) throw driversError;

      // Récupérer les livreurs qui ont déjà des livraisons en cours (assignées mais pas encore livrées)
      const { data: busyDrivers, error: busyError } = await supabase
        .from('order_driver_assignments')
        .select('driver_id')
        .in('driver_id', drivers?.map(d => d.id) || [])
        .is('delivered_at', null);

      if (busyError) throw busyError;

      // Filtrer les livreurs occupés
      const busyDriverIds = busyDrivers?.map(bd => bd.driver_id) || [];
      const availableDriversList = drivers?.filter(driver => 
        !busyDriverIds.includes(driver.id)
      ) || [];

      setAvailableDrivers(availableDriversList);
    } catch (error) {
      console.error('Erreur lors du chargement des livreurs:', error);
      toast({
        title: "Erreur",
        description: "Impossible de charger la liste des livreurs",
        variant: "destructive",
      });
    } finally {
      setLoadingDrivers(false);
    }
  };

  const assignDriverToOrder = async (driverId: number, driverName: string) => {
    try {
      setAssigningDriver(driverId);
      
      // Créer l'assignation livreur-commande
      const { error: assignError } = await supabase
        .from('order_driver_assignments')
        .insert({
          order_id: orderId,
          driver_id: driverId,
          assigned_at: new Date().toISOString()
        });

      if (assignError) throw assignError;

      // Mettre à jour le statut de la commande à "in_transit"
      const { error: statusError } = await supabase
        .from('orders')
        .update({
          status: 'in_transit',
          updated_at: new Date().toISOString()
        })
        .eq('id', orderId);

      if (statusError) throw statusError;

      // Créer une notification pour le livreur
      await supabase
        .from('driver_notifications')
        .insert({
          driver_id: driverId,
          order_id: orderId,
          message: `Nouvelle livraison assignée - Commande #${orderId}`,
          type: 'order_assigned'
        });

      // Créer une notification pour le client
      await supabase
        .from('order_notifications')
        .insert({
          order_id: orderId,
          message: `Votre commande est en cours de livraison. Livreur: ${driverName}`,
          type: 'status_update',
          user_id: null // sera rempli par la logique existante
        });

      toast({
        title: "Livreur assigné",
        description: `${driverName} a été assigné à la commande #${orderId}`,
      });

      // Notifier le composant parent
      onDriverSelected(driverId, driverName);
      
      // Recharger la liste des livreurs
      fetchAvailableDrivers();
      
    } catch (error) {
      console.error('Erreur lors de l\'assignation:', error);
      toast({
        title: "Erreur",
        description: "Impossible d'assigner le livreur à la commande",
        variant: "destructive",
      });
    } finally {
      setAssigningDriver(null);
    }
  };

  const getDriverInitials = (name: string) => {
    return name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);
  };

  const getDistanceText = (lat: number | null, lng: number | null) => {
    if (!lat || !lng) return "Position inconnue";
    return `${lat.toFixed(4)}, ${lng.toFixed(4)}`;
  };

  if (loading || loadingDrivers) {
    return (
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Truck className="h-5 w-5" />
            Livreurs disponibles
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-center py-4">
            <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-primary mx-auto"></div>
            <p className="text-sm text-muted-foreground mt-2">
              Chargement des livreurs...
            </p>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Truck className="h-5 w-5" />
          Livreurs disponibles
          <Badge variant="secondary" className="ml-auto">
            {availableDrivers.length}
          </Badge>
        </CardTitle>
      </CardHeader>
      <CardContent>
        {availableDrivers.length === 0 ? (
          <div className="text-center py-6">
            <Truck className="h-12 w-12 text-muted-foreground mx-auto mb-3" />
            <p className="text-sm text-muted-foreground">
              Aucun livreur disponible actuellement
            </p>
            <p className="text-xs text-muted-foreground mt-1">
              Tous les livreurs ont des livraisons en cours
            </p>
          </div>
        ) : (
          <div className="space-y-3">
            {availableDrivers.map((driver) => (
              <div
                key={driver.id}
                className="flex items-center justify-between p-3 border rounded-lg hover:bg-muted/50 transition-colors"
              >
                <div className="flex items-center gap-3">
                  <Avatar className="h-10 w-10">
                    <AvatarFallback className="bg-primary text-primary-foreground">
                      {getDriverInitials(driver.name)}
                    </AvatarFallback>
                  </Avatar>
                  
                  <div className="flex-1">
                    <div className="flex items-center gap-2">
                      <h4 className="font-medium text-sm">{driver.name}</h4>
                      <Badge variant="outline" className="text-xs">
                        Disponible
                      </Badge>
                    </div>
                    
                    <div className="flex items-center gap-4 mt-1">
                      <div className="flex items-center gap-1 text-xs text-muted-foreground">
                        <Phone className="h-3 w-3" />
                        {driver.phone}
                      </div>
                      <div className="flex items-center gap-1 text-xs text-muted-foreground">
                        <MapPin className="h-3 w-3" />
                        {getDistanceText(driver.current_lat, driver.current_lng)}
                      </div>
                    </div>
                  </div>
                </div>

                <Button
                  size="sm"
                  onClick={() => assignDriverToOrder(driver.id, driver.name)}
                  disabled={assigningDriver === driver.id}
                  className="ml-2"
                >
                  {assigningDriver === driver.id ? (
                    <>
                      <div className="animate-spin rounded-full h-3 w-3 border-b-2 border-white mr-2"></div>
                      Assignation...
                    </>
                  ) : (
                    <>
                      <User className="h-3 w-3 mr-1" />
                      Assigner
                    </>
                  )}
                </Button>
              </div>
            ))}
          </div>
        )}
        
        <div className="mt-4 pt-3 border-t">
          <Button
            variant="outline"
            size="sm"
            onClick={fetchAvailableDrivers}
            className="w-full"
          >
            <Clock className="h-3 w-3 mr-2" />
            Actualiser la liste
          </Button>
        </div>
      </CardContent>
    </Card>
  );
};

export default AvailableDriversCard;
