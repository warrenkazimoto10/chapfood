import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';
import { 
  Truck, 
  MapPin, 
  Clock, 
  Phone, 
  Navigation,
  CheckCircle,
  AlertCircle,
  Package
} from 'lucide-react';

interface Driver {
  id: string;
  name: string;
  phone: string;
  current_lat?: number;
  current_lng?: number;
  last_update?: string;
  is_available: boolean;
}

interface DriverAssignmentProps {
  orderType: 'delivery' | 'pickup';
  deliveryLocation?: any;
  onDriverAssigned: (driver: Driver) => void;
  onCancel: () => void;
}

const DriverAssignment: React.FC<DriverAssignmentProps> = ({
  orderType,
  deliveryLocation,
  onDriverAssigned,
  onCancel
}) => {
  const { toast } = useToast();
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [loading, setLoading] = useState(true);
  const [assigning, setAssigning] = useState<string | null>(null);

  useEffect(() => {
    loadDrivers();
  }, []);

  const loadDrivers = async () => {
    try {
      setLoading(true);
      
      // Récupérer tous les livreurs
      const { data: driversData, error: driversError } = await supabase
        .from('drivers')
        .select('*')
        .eq('is_available', true);

      if (driversError) throw driversError;

      // Récupérer les livreurs occupés (en livraison)
      const { data: busyDriversData, error: busyError } = await supabase
        .from('order_driver_assignments')
        .select('driver_id')
        .is('delivered_at', null);

      if (busyError) throw busyError;

      const busyDriverIds = new Set(busyDriversData?.map(d => d.driver_id) || []);

      // Marquer les livreurs comme occupés
      const driversWithStatus = driversData?.map(driver => ({
        ...driver,
        is_available: !busyDriverIds.has(driver.id)
      })) || [];

      setDrivers(driversWithStatus);
    } catch (error) {
      console.error('Erreur lors du chargement des livreurs:', error);
      toast({
        title: "Erreur",
        description: "Impossible de charger les livreurs",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const assignDriver = async (driver: Driver) => {
    try {
      setAssigning(driver.id);
      
      // Simuler l'assignation du livreur
      // Dans un vrai système, on créerait l'assignation ici
      // Pour l'instant, on passe juste le livreur au parent
      
      toast({
        title: "Livreur assigné",
        description: `${driver.name} a été assigné à la commande`,
      });

      onDriverAssigned(driver);
    } catch (error) {
      console.error('Erreur lors de l\'assignation:', error);
      toast({
        title: "Erreur",
        description: "Impossible d'assigner le livreur",
        variant: "destructive",
      });
    } finally {
      setAssigning(null);
    }
  };

  const getDriverInitials = (name: string) => {
    return name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);
  };

  const formatLastUpdate = (lastUpdate: string) => {
    const date = new Date(lastUpdate);
    const now = new Date();
    const diffMinutes = Math.floor((now.getTime() - date.getTime()) / (1000 * 60));
    
    if (diffMinutes < 1) return 'À l\'instant';
    if (diffMinutes < 60) return `Il y a ${diffMinutes} min`;
    const diffHours = Math.floor(diffMinutes / 60);
    return `Il y a ${diffHours}h`;
  };

  const availableDrivers = drivers.filter(d => d.is_available);
  const busyDrivers = drivers.filter(d => !d.is_available);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-orange-500"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <Card className="bg-white/90 backdrop-blur-sm border-orange-200 shadow-lg">
        <CardHeader className="bg-gradient-to-r from-orange-50 to-red-50 border-b border-orange-200">
          <CardTitle className="text-orange-700 flex items-center gap-2">
            <Truck className="h-6 w-6" />
            Assignation Livreur
          </CardTitle>
        </CardHeader>
        <CardContent className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-gray-600">
                Type de commande: <span className="font-semibold">
                  {orderType === 'delivery' ? 'Livraison' : 'À emporter'}
                </span>
              </p>
              {deliveryLocation && (
                <p className="text-sm text-gray-500 mt-1">
                  Adresse: {deliveryLocation.address}
                </p>
              )}
            </div>
            
            <div className="text-right">
              <p className="text-sm text-gray-600">
                Livreurs disponibles: <span className="font-bold text-green-600">{availableDrivers.length}</span>
              </p>
              <p className="text-sm text-gray-600">
                En livraison: <span className="font-bold text-blue-600">{busyDrivers.length}</span>
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Livreurs disponibles */}
        <Card className="bg-white/90 backdrop-blur-sm border-green-200 shadow-lg">
          <CardHeader className="bg-gradient-to-r from-green-50 to-emerald-50 border-b border-green-200">
            <CardTitle className="text-green-700 flex items-center gap-2">
              <CheckCircle className="h-5 w-5" />
              Livreurs Disponibles ({availableDrivers.length})
            </CardTitle>
          </CardHeader>
          <CardContent className="p-6">
            {availableDrivers.length === 0 ? (
              <div className="text-center py-8">
                <AlertCircle className="h-12 w-12 text-orange-400 mx-auto mb-4" />
                <p className="text-gray-600 mb-2">Aucun livreur disponible</p>
                <p className="text-sm text-gray-500">
                  Tous les livreurs sont actuellement en livraison
                </p>
              </div>
            ) : (
              <div className="space-y-4">
                {availableDrivers.map((driver) => (
                  <div
                    key={driver.id}
                    className="p-4 bg-white rounded-lg border border-green-200 hover:bg-green-50 transition-colors"
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-4">
                        <Avatar className="h-12 w-12">
                          <AvatarFallback className="bg-gradient-to-r from-green-500 to-emerald-500 text-white font-bold">
                            {getDriverInitials(driver.name)}
                          </AvatarFallback>
                        </Avatar>
                        <div>
                          <h3 className="font-semibold text-gray-800">{driver.name}</h3>
                          <div className="flex items-center gap-3 text-sm text-gray-600">
                            <div className="flex items-center gap-1">
                              <Phone className="h-4 w-4" />
                              {driver.phone}
                            </div>
                            {driver.current_lat && driver.current_lng ? (
                              <div className="flex items-center gap-1 text-green-600">
                                <Navigation className="h-4 w-4" />
                                En ligne
                              </div>
                            ) : (
                              <div className="flex items-center gap-1 text-orange-600">
                                <AlertCircle className="h-4 w-4" />
                                Position inconnue
                              </div>
                            )}
                          </div>
                          {driver.last_update && (
                            <p className="text-xs text-gray-500 mt-1">
                              Dernière activité: {formatLastUpdate(driver.last_update)}
                            </p>
                          )}
                        </div>
                      </div>
                      
                      <Button
                        onClick={() => assignDriver(driver)}
                        disabled={assigning === driver.id}
                        className="bg-gradient-to-r from-green-500 to-emerald-500 hover:from-green-600 hover:to-emerald-600 text-white"
                      >
                        {assigning === driver.id ? (
                          <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                        ) : (
                          <>
                            <CheckCircle className="h-4 w-4 mr-2" />
                            Assigner
                          </>
                        )}
                      </Button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>

        {/* Livreurs occupés */}
        <Card className="bg-white/90 backdrop-blur-sm border-blue-200 shadow-lg">
          <CardHeader className="bg-gradient-to-r from-blue-50 to-cyan-50 border-b border-blue-200">
            <CardTitle className="text-blue-700 flex items-center gap-2">
              <Clock className="h-5 w-5" />
              Livreurs en Livraison ({busyDrivers.length})
            </CardTitle>
          </CardHeader>
          <CardContent className="p-6">
            {busyDrivers.length === 0 ? (
              <div className="text-center py-8">
                <Package className="h-12 w-12 text-green-400 mx-auto mb-4" />
                <p className="text-gray-600 mb-2">Aucun livreur en livraison</p>
                <p className="text-sm text-gray-500">
                  Tous les livreurs sont disponibles
                </p>
              </div>
            ) : (
              <div className="space-y-4">
                {busyDrivers.map((driver) => (
                  <div
                    key={driver.id}
                    className="p-4 bg-white rounded-lg border border-blue-200"
                  >
                    <div className="flex items-center gap-4">
                      <Avatar className="h-12 w-12">
                        <AvatarFallback className="bg-gradient-to-r from-blue-500 to-cyan-500 text-white font-bold">
                          {getDriverInitials(driver.name)}
                        </AvatarFallback>
                      </Avatar>
                      <div className="flex-1">
                        <h3 className="font-semibold text-gray-800">{driver.name}</h3>
                        <div className="flex items-center gap-3 text-sm text-gray-600">
                          <div className="flex items-center gap-1">
                            <Phone className="h-4 w-4" />
                            {driver.phone}
                          </div>
                          <Badge className="bg-blue-100 text-blue-800">
                            En livraison
                          </Badge>
                        </div>
                        {driver.last_update && (
                          <p className="text-xs text-gray-500 mt-1">
                            Dernière activité: {formatLastUpdate(driver.last_update)}
                          </p>
                        )}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Actions */}
      <div className="flex justify-between">
        <Button
          variant="outline"
          onClick={onCancel}
          className="border-orange-300 text-orange-600 hover:bg-orange-50"
        >
          Retour
        </Button>
        
        <Button
          onClick={loadDrivers}
          className="bg-gradient-to-r from-blue-500 to-cyan-500 hover:from-blue-600 hover:to-cyan-600 text-white"
        >
          Actualiser
        </Button>
      </div>
    </div>
  );
};

export default DriverAssignment;



