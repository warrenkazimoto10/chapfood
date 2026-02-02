import { useState, useEffect } from "react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { 
  MapPin, 
  Clock, 
  Phone, 
  User, 
  CreditCard, 
  Truck,
  CheckCircle,
  AlertCircle,
  Package,
  ChefHat,
  Shield,
  Key,
  Timer,
  Copy
} from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { useToast } from "@/hooks/use-toast";
import AvailableDriversCard from "./AvailableDriversCard";

interface OrderDetailModalProps {
  order: any | null;
  isOpen: boolean;
  onClose: () => void;
  onOrderUpdate: () => void;
}

interface OrderItem {
  id: number;
  item_name: string;
  quantity: number;
  item_price: number;
  total_price: number;
  instructions?: string;
  selected_extras?: any;
  selected_garnitures?: any;
  item_image?: string | null;
  included_garnishes?: string[];
}

// Statuts selon le nouveau flux (restaurant -> client)
const ORDER_STATUSES = [
  { value: "pending", label: "En attente", color: "bg-yellow-100 text-yellow-800" },
  { value: "accepted", label: "Acceptée (vers restaurant)", color: "bg-blue-100 text-blue-800" },
  { value: "ready_for_delivery", label: "Prête pour livraison", color: "bg-green-100 text-green-800" },
  { value: "picked_up", label: "Repas récupéré (vers client)", color: "bg-purple-100 text-purple-800" },
  { value: "in_transit", label: "En cours de livraison", color: "bg-purple-100 text-purple-800" },
  { value: "delivered", label: "Livrée", color: "bg-emerald-100 text-emerald-800" },
  { value: "cancelled", label: "Annulée", color: "bg-red-100 text-red-800" }
];

// Interface pour les transitions de statut
interface StatusTransition {
  value: string;
  label: string;
  variant: "default" | "success" | "destructive" | "secondary";
  icon: React.ReactNode;
  description?: string;
}

// Fonction pour obtenir les transitions valides selon le statut actuel
const getAvailableStatusTransitions = (
  currentStatus: string,
  hasDriver: boolean
): StatusTransition[] => {
  switch (currentStatus) {
    case "pending":
      return [
        {
          value: "accepted",
          label: "Accepter",
          variant: "success",
          icon: <CheckCircle className="h-4 w-4" />,
          description: "La commande est acceptée et passe en préparation",
        },
        {
          value: "cancelled",
          label: "Refuser",
          variant: "destructive",
          icon: <AlertCircle className="h-4 w-4" />,
          description: "La commande est refusée et annulée",
        },
      ];

    case "accepted":
      return [
        {
          value: "ready_for_delivery",
          label: "Prête pour livraison",
          variant: "default",
          icon: <Package className="h-4 w-4" />,
          description: "Le repas est prêt, un livreur peut être assigné",
        },
        {
          value: "cancelled",
          label: "Annuler",
          variant: "destructive",
          icon: <AlertCircle className="h-4 w-4" />,
          description: "Annuler la commande",
        },
      ];

    case "ready_for_delivery":
      if (hasDriver) {
        return [
          {
            value: "picked_up",
            label: "Repas récupéré",
            variant: "default",
            icon: <Truck className="h-4 w-4" />,
            description: "Le livreur a récupéré le repas et se dirige vers le client",
          },
          {
            value: "cancelled",
            label: "Annuler",
            variant: "destructive",
            icon: <AlertCircle className="h-4 w-4" />,
            description: "Annuler la commande",
          },
        ];
      } else {
        return [
          {
            value: "cancelled",
            label: "Annuler",
            variant: "destructive",
            icon: <AlertCircle className="h-4 w-4" />,
            description: "Annuler la commande",
          },
        ];
      }

    case "picked_up":
      return [
        {
          value: "in_transit",
          label: "En cours de livraison",
          variant: "default",
          icon: <Truck className="h-4 w-4" />,
          description: "Le livreur est en route vers le client",
        },
        {
          value: "cancelled",
          label: "Annuler",
          variant: "destructive",
          icon: <AlertCircle className="h-4 w-4" />,
          description: "Annuler la commande (rare)",
        },
      ];

    case "in_transit":
      return [
        {
          value: "delivered",
          label: "Livrée",
          variant: "success",
          icon: <CheckCircle className="h-4 w-4" />,
          description: "La commande a été livrée avec succès",
        },
        {
          value: "cancelled",
          label: "Annuler",
          variant: "destructive",
          icon: <AlertCircle className="h-4 w-4" />,
          description: "Annuler la commande (rare)",
        },
      ];

    case "delivered":
    case "cancelled":
      // Statuts finaux, aucune transition possible
      return [];

    default:
      return [];
  }
};

const OrderDetailModal = ({ order, isOpen, onClose, onOrderUpdate }: OrderDetailModalProps) => {
  const [orderItems, setOrderItems] = useState<OrderItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [updatingStatus, setUpdatingStatus] = useState(false);
  const [statusNotes, setStatusNotes] = useState("");
  const [assignedDriver, setAssignedDriver] = useState<{id: number, name: string} | null>(null);
  const [checkingDriverAssignment, setCheckingDriverAssignment] = useState(false);
  const [generatingCode, setGeneratingCode] = useState(false);
  const [timeUntilExpiry, setTimeUntilExpiry] = useState<string | null>(null);
  // État local pour l'ordre (mis à jour en temps réel)
  const [currentOrder, setCurrentOrder] = useState<any | null>(order);
  const { toast } = useToast();

  // Mettre à jour l'ordre local quand la prop change
  useEffect(() => {
    setCurrentOrder(order);
  }, [order]);

  // Abonnement Realtime pour mettre à jour l'ordre en temps réel
  useEffect(() => {
    if (!isOpen || !currentOrder?.id) return;

    const channel = supabase
      .channel(`order-${currentOrder.id}`)
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'orders',
          filter: `id=eq.${currentOrder.id}`,
        },
        (payload) => {
          console.log('🔄 Mise à jour Realtime de la commande:', payload.new);
          // Mettre à jour l'ordre local avec les nouvelles données
          setCurrentOrder((prev: any) => ({
            ...prev,
            ...payload.new,
          }));
          
          // Rafraîchir les items et l'assignation du livreur
          fetchOrderItems();
          checkDriverAssignment();
          
          // Afficher une notification discrète seulement si le statut a changé
          if (payload.new.status !== payload.old?.status) {
            toast({
              title: "Commande mise à jour",
              description: `Le statut est maintenant: ${ORDER_STATUSES.find(s => s.value === payload.new.status)?.label || payload.new.status}`,
            });
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [isOpen, currentOrder?.id]);

  useEffect(() => {
    if (currentOrder && isOpen) {
      fetchOrderItems();
      checkDriverAssignment();
    }
  }, [currentOrder, isOpen]);

  // Compteur en temps réel pour l'expiration du code
  useEffect(() => {
    let interval: NodeJS.Timeout | null = null;

    const updateCountdown = () => {
      if (!order?.delivery_code_expires_at) {
        setTimeUntilExpiry(null);
        return;
      }

      const expiryTime = new Date(order.delivery_code_expires_at);
      const now = new Date();
      const diffMs = expiryTime.getTime() - now.getTime();

      if (diffMs <= 0) {
        setTimeUntilExpiry(null);
        if (interval) clearInterval(interval);
        
        // Notification d'expiration
        toast({
          title: "Code expiré",
          description: "Le code de livraison a expiré. Un nouveau code peut être généré.",
          variant: "destructive",
        });
        return;
      }

      const minutes = Math.floor(diffMs / (1000 * 60));
      const seconds = Math.floor((diffMs % (1000 * 60)) / 1000);
      setTimeUntilExpiry(`${minutes}m ${seconds}s`);
    };

    // Mise à jour initiale
    updateCountdown();

    // Mise à jour toutes les secondes
    if (order?.delivery_code_expires_at && getDeliveryCodeStatus() === 'active') {
      interval = setInterval(updateCountdown, 1000);
    }

    return () => {
      if (interval) clearInterval(interval);
    };
  }, [order?.delivery_code_expires_at, order?.delivery_confirmed_at]);

  const fetchOrderItems = async () => {
    if (!currentOrder) return;
    
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('order_items')
        .select(`
          *,
          menu_items (
            name,
            price,
            image_url
          )
        `)
        .eq('order_id', currentOrder.id);

      if (error) throw error;
      
      const items = data?.map(item => ({
        ...item,
        item_name: item.menu_items?.name || item.item_name || 'Article supprimé',
        item_price: item.menu_items?.price || item.item_price || 0,
        item_image: item.menu_items?.image_url || null
      })) || [];

      setOrderItems(items);
    } catch (error) {
      console.error('Erreur lors du chargement des articles:', error);
      toast({
        title: "Erreur",
        description: "Impossible de charger les détails de la commande",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const checkDriverAssignment = async () => {
    if (!currentOrder) return;

    try {
      setCheckingDriverAssignment(true);
      const { data, error } = await supabase
        .from('order_driver_assignments')
        .select(`
          driver_id,
          drivers(name)
        `)
        .eq('order_id', currentOrder.id)
        .is('delivered_at', null)
        .maybeSingle();

      if (error && error.code !== 'PGRST116') { // PGRST116 = no rows returned
        throw error;
      }

      if (data) {
        setAssignedDriver({
          id: data.driver_id,
          name: data.drivers.name
        });
      } else {
        setAssignedDriver(null);
      }
    } catch (error) {
      console.error('Erreur lors de la vérification de l\'assignation:', error);
      setAssignedDriver(null);
    } finally {
      setCheckingDriverAssignment(false);
    }
  };

  const handleDriverSelected = (driverId: number, driverName: string) => {
    setAssignedDriver({ id: driverId, name: driverName });
    toast({
      title: "Livreur assigné",
      description: `${driverName} a été assigné à la commande`,
    });
    onOrderUpdate();
  };

  const updateOrderStatus = async (targetStatus: string) => {
    if (!currentOrder || !targetStatus) return;

    // Vérifier si le statut est valide selon les transitions autorisées
    const transitions = getAvailableStatusTransitions(currentOrder.status, assignedDriver !== null);
    const isValidTransition = transitions.some(t => t.value === targetStatus);

    if (!isValidTransition) {
      toast({
        title: "Erreur",
        description: "Cette transition de statut n'est pas autorisée",
        variant: "destructive",
      });
      return;
    }

    // Vérifier si le statut nécessite un livreur assigné
    if ((targetStatus === 'picked_up' || targetStatus === 'in_transit') && !assignedDriver) {
      toast({
        title: "Erreur",
        description: "Impossible de passer à ce statut sans assigner un livreur",
        variant: "destructive",
      });
      return;
    }

    try {
      setUpdatingStatus(true);
      
      // Préparer les données de mise à jour
      const updateData: any = {
        status: targetStatus,
        updated_at: new Date().toISOString()
      };

      // Ajouter des timestamps selon le statut
      switch (targetStatus) {
        case "accepted":
          updateData.accepted_at = new Date().toISOString();
          break;
        case "ready_for_delivery":
          updateData.ready_at = new Date().toISOString();
          break;
        case "delivered":
          updateData.actual_delivery_time = new Date().toISOString();
          // Mettre à jour l'assignation du livreur
          if (assignedDriver) {
            await supabase
              .from('order_driver_assignments')
              .update({
                delivered_at: new Date().toISOString()
              })
              .eq('order_id', currentOrder.id)
              .eq('driver_id', assignedDriver.id);
          }
          break;
      }

      // Mettre à jour la commande
      const { error } = await supabase
        .from('orders')
        .update(updateData)
        .eq('id', currentOrder.id);

      if (error) throw error;

      // Ajouter une notification si nécessaire
      if (statusNotes) {
        await supabase
          .from('order_notifications')
          .insert({
            order_id: currentOrder.id,
            message: `Statut mis à jour: ${ORDER_STATUSES.find(s => s.value === targetStatus)?.label}. ${statusNotes}`,
            type: 'status_update',
            user_id: currentOrder.user_id
          });
      }

      toast({
        title: "Statut mis à jour",
        description: `La commande #${currentOrder.id} a été mise à jour avec succès`,
      });

      // Rafraîchir les données sans fermer le modal pour permettre
      // à l'admin de continuer à gérer la commande
      onOrderUpdate();
    } catch (error) {
      console.error('Erreur lors de la mise à jour:', error);
      toast({
        title: "Erreur",
        description: "Impossible de mettre à jour le statut de la commande",
        variant: "destructive",
      });
    } finally {
      setUpdatingStatus(false);
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case "pending":
        return <AlertCircle className="h-4 w-4" />;
      case "accepted":
        return <CheckCircle className="h-4 w-4" />;
      case "ready_for_delivery":
        return <Package className="h-4 w-4" />;
      case "in_transit":
        return <Truck className="h-4 w-4" />;
      case "delivered":
        return <CheckCircle className="h-4 w-4" />;
      case "cancelled":
        return <AlertCircle className="h-4 w-4" />;
      default:
        return <AlertCircle className="h-4 w-4" />;
    }
  };

  const formatPrice = (price: number) => {
    return `${price.toLocaleString('fr-FR')} FCFA`;
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleString('fr-FR');
  };

  // Fonctions pour gérer les codes de livraison
  const generateDeliveryCode = async () => {
    if (!currentOrder) return;
    
    try {
      setGeneratingCode(true);
      // Utiliser la même fonction SQL que les apps client / livreur
      // pour garantir compatibilité avec validate_delivery_code()
      const { data: rpcData, error: rpcError } = await (supabase.rpc as any)('generate_delivery_code', {
        p_order_id: currentOrder.id
      });

      if (rpcError) throw rpcError;

      const code = rpcData as string | null;
      if (!code) {
        throw new Error('Code généré invalide');
      }

      // Sauvegarder le code dans la commande (même logique que côté mobile)
      const { data, error } = await supabase
        .from('orders')
        .update({
          delivery_code: code,
          delivery_code_generated_at: new Date().toISOString(),
          delivery_code_expires_at: new Date(Date.now() + 15 * 60 * 1000).toISOString(), // 15 minutes
        } as any)
        .eq('id', currentOrder.id)
        .select('delivery_code, delivery_code_generated_at, delivery_code_expires_at')
        .maybeSingle();

      if (error) throw error;
      if (!data) throw new Error('Mise à jour de la commande impossible');

      toast({
        title: "Code généré",
        description: `Code de livraison généré: ${code}`,
      });

      onOrderUpdate();
    } catch (error) {
      console.error('Erreur lors de la génération du code:', error);
      toast({
        title: "Erreur",
        description: "Impossible de générer le code de livraison",
        variant: "destructive",
      });
    } finally {
      setGeneratingCode(false);
    }
  };

  const copyDeliveryCode = (code: string) => {
    navigator.clipboard.writeText(code);
    toast({
      title: "Code copié",
      description: "Le code de livraison a été copié dans le presse-papiers",
    });
  };

  const getDeliveryCodeStatus = () => {
    if (!currentOrder?.delivery_code) return 'no_code';
    if (currentOrder.delivery_confirmed_at) return 'confirmed';
    if (currentOrder.delivery_code_expires_at && new Date(currentOrder.delivery_code_expires_at) < new Date()) return 'expired';
    return 'active';
  };

  const getDeliveryCodeStatusInfo = (status: string) => {
    switch (status) {
      case 'active':
        return { 
          label: 'Code actif', 
          color: 'text-green-600 bg-green-50', 
          icon: <CheckCircle className="h-4 w-4" />
        };
      case 'expired':
        return { 
          label: 'Code expiré', 
          color: 'text-red-600 bg-red-50', 
          icon: <AlertCircle className="h-4 w-4" />
        };
      case 'confirmed':
        return { 
          label: 'Livraison confirmée', 
          color: 'text-blue-600 bg-blue-50', 
          icon: <Shield className="h-4 w-4" />
        };
      default:
        return { 
          label: 'Aucun code', 
          color: 'text-gray-600 bg-gray-50', 
          icon: <Key className="h-4 w-4" />
        };
    }
  };


  if (!currentOrder) return null;

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto bg-gradient-to-br from-orange-50 via-red-50 to-yellow-50 border-orange-200">
        <DialogHeader className="border-b border-orange-200 pb-4">
          <DialogTitle className="flex items-center gap-3 text-orange-700">
            <div className="p-2 bg-gradient-to-r from-orange-500 to-red-500 rounded-lg">
              <ChefHat className="h-6 w-6 text-white" />
            </div>
            <span className="text-2xl font-bold bg-gradient-to-r from-orange-600 to-red-600 bg-clip-text text-transparent">
              Commande #{currentOrder?.id.toString().slice(-6) || 'N/A'}
            </span>
          </DialogTitle>
          <DialogDescription className="text-gray-600 text-lg">
            📅 Détails de la commande du {currentOrder ? formatDate(currentOrder.created_at) : 'N/A'}
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-6">
          {/* Informations client */}
          <Card className="bg-white/90 backdrop-blur-sm border-orange-200 shadow-lg">
            <CardHeader className="bg-gradient-to-r from-orange-50 to-red-50 border-b border-orange-200">
              <CardTitle className="text-lg flex items-center gap-2 text-orange-700">
                <User className="h-5 w-5" />
                👤 Informations Client
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4 p-6">
              <div className="flex items-center gap-3 p-3 bg-orange-50 rounded-lg border border-orange-200">
                <User className="h-5 w-5 text-orange-600" />
                <span className="font-semibold text-orange-800">
                  {currentOrder?.customer_name || "Client anonyme"}
                </span>
              </div>
              <div className="flex items-center gap-3 p-3 bg-green-50 rounded-lg border border-green-200">
                <Phone className="h-5 w-5 text-green-600" />
                <span className="font-medium text-green-800">{currentOrder?.customer_phone}</span>
              </div>
              {currentOrder?.delivery_address && (
                <div className="flex items-start gap-3 p-3 bg-blue-50 rounded-lg border border-blue-200">
                  <MapPin className="h-5 w-5 text-blue-600 mt-0.5" />
                  <span className="text-blue-800">{currentOrder.delivery_address}</span>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Informations commande */}
          <Card className="bg-white/90 backdrop-blur-sm border-orange-200 shadow-lg">
            <CardHeader className="bg-gradient-to-r from-orange-50 to-red-50 border-b border-orange-200">
              <CardTitle className="text-lg flex items-center gap-2 text-orange-700">
                <Package className="h-5 w-5" />
                📦 Informations Commande
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4 p-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="flex items-center gap-3 p-3 bg-purple-50 rounded-lg border border-purple-200">
                  <Truck className="h-5 w-5 text-purple-600" />
                  <div>
                    <Label className="text-xs text-purple-600">Type de commande</Label>
                    <Badge 
                      className={currentOrder?.delivery_type === 'delivery' 
                        ? "bg-orange-100 text-orange-800 border-orange-200 ml-2" 
                        : "bg-green-100 text-green-800 border-green-200 ml-2"
                      }
                    >
                      {currentOrder?.delivery_type === 'delivery' ? '🚚 Livraison' : '🏪 À emporter'}
                    </Badge>
                  </div>
                </div>
                <div className="flex items-center gap-3 p-3 bg-blue-50 rounded-lg border border-blue-200">
                  <CreditCard className="h-5 w-5 text-blue-600" />
                  <div>
                    <Label className="text-xs text-blue-600">Méthode de paiement</Label>
                    <span className="font-medium text-blue-800 ml-2">{currentOrder?.payment_method}</span>
                  </div>
                </div>
              </div>
              {currentOrder?.estimated_delivery_time && (
                <div className="flex items-center gap-3 p-3 bg-yellow-50 rounded-lg border border-yellow-200">
                  <Clock className="h-5 w-5 text-yellow-600" />
                  <div>
                    <Label className="text-xs text-yellow-600">Livraison prévue</Label>
                    <span className="font-medium text-yellow-800 ml-2">
                      {formatDate(currentOrder.estimated_delivery_time)}
                    </span>
                  </div>
                </div>
              )}
              {currentOrder?.instructions && (
                <div className="p-3 bg-gray-50 rounded-lg border border-gray-200">
                  <Label className="text-sm font-medium text-gray-700 flex items-center gap-2">
                    <ChefHat className="h-4 w-4" />
                    Instructions spéciales:
                  </Label>
                  <p className="text-sm text-gray-600 mt-2 italic">"{currentOrder.instructions}"</p>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Codes de livraison - affiché seulement pour les livraisons */}
          {currentOrder?.delivery_type === 'delivery' && (
            <Card className="bg-white/90 backdrop-blur-sm border-orange-200 shadow-lg">
              <CardHeader className="bg-gradient-to-r from-orange-50 to-red-50 border-b border-orange-200">
                <CardTitle className="text-lg flex items-center gap-2 text-orange-700">
                  <Shield className="h-5 w-5" />
                  🔐 Code de Confirmation de Livraison
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                {(() => {
                  const codeStatus = getDeliveryCodeStatus();
                  const statusInfo = getDeliveryCodeStatusInfo(codeStatus);
                  
                  return (
                    <div className="space-y-4">
                      {/* Statut du code */}
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                          {statusInfo.icon}
                          <span className={`px-3 py-1 rounded-full text-sm font-medium ${statusInfo.color}`}>
                            {statusInfo.label}
                          </span>
                        </div>
                        
                        {/* Bouton pour générer un nouveau code */}
                        {codeStatus === 'no_code' || codeStatus === 'expired' ? (
                          <Button
                            onClick={generateDeliveryCode}
                            disabled={generatingCode}
                            size="sm"
                            className="bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 text-white"
                          >
                            {generatingCode ? "Génération..." : "🔑 Générer un code"}
                          </Button>
                        ) : null}
                      </div>

                      {/* Affichage du code */}
                      {currentOrder?.delivery_code && (
                        <div className="space-y-3">
                          <div className="flex items-center gap-3">
                            <div className="flex-1">
                              <Label className="text-sm font-medium">Code de livraison</Label>
                              <div className="flex items-center gap-3 mt-1">
                                <div className="font-mono text-3xl font-bold bg-gradient-to-r from-orange-100 to-red-100 px-6 py-3 rounded-lg tracking-wider border-2 border-orange-300 shadow-lg">
                                  {currentOrder.delivery_code}
                                </div>
                                <Button
                                  variant="outline"
                                  size="sm"
                                  onClick={() => copyDeliveryCode(currentOrder.delivery_code!)}
                                  className="shrink-0 border-orange-300 text-orange-600 hover:bg-orange-50"
                                >
                                  <Copy className="h-4 w-4" />
                                </Button>
                              </div>
                            </div>
                          </div>

                          {/* Informations temporelles */}
                          <div className="grid grid-cols-2 gap-4 text-sm">
                            <div>
                              <Label className="text-xs text-muted-foreground">Généré le</Label>
                              <p className="font-medium">
                                {currentOrder?.delivery_code_generated_at 
                                  ? formatDate(currentOrder.delivery_code_generated_at)
                                  : "N/A"
                                }
                              </p>
                            </div>
                            <div>
                              <Label className="text-xs text-muted-foreground">Expire le</Label>
                              <p className="font-medium">
                                {currentOrder?.delivery_code_expires_at 
                                  ? formatDate(currentOrder.delivery_code_expires_at)
                                  : "N/A"
                                }
                              </p>
                            </div>
                          </div>

                          {/* Compte à rebours animé */}
                          {codeStatus === 'active' && timeUntilExpiry && (
                            <div className={`flex items-center gap-2 p-3 border rounded-lg transition-colors duration-300 ${
                              (() => {
                                const timeStr = timeUntilExpiry;
                                const minutes = parseInt(timeStr.split('m')[0]);
                                if (minutes <= 2) return 'bg-red-50 border-red-200';
                                if (minutes <= 5) return 'bg-orange-50 border-orange-200';
                                return 'bg-green-50 border-green-200';
                              })()
                            }`}>
                              <Timer className={`h-4 w-4 animate-pulse ${
                                (() => {
                                  const timeStr = timeUntilExpiry;
                                  const minutes = parseInt(timeStr.split('m')[0]);
                                  if (minutes <= 2) return 'text-red-600';
                                  if (minutes <= 5) return 'text-orange-600';
                                  return 'text-green-600';
                                })()
                              }`} />
                              <span className={`text-sm font-medium ${
                                (() => {
                                  const timeStr = timeUntilExpiry;
                                  const minutes = parseInt(timeStr.split('m')[0]);
                                  if (minutes <= 2) return 'text-red-800';
                                  if (minutes <= 5) return 'text-orange-800';
                                  return 'text-green-800';
                                })()
                              }`}>
                                Expire dans: <strong className="font-mono text-lg animate-pulse">{timeUntilExpiry}</strong>
                              </span>
                            </div>
                          )}

                          {/* Confirmation de livraison */}
                          {currentOrder?.delivery_confirmed_at && (
                            <div className="flex items-center gap-2 p-3 bg-green-50 border border-green-200 rounded-lg">
                              <CheckCircle className="h-4 w-4 text-green-600" />
                              <div>
                                <p className="text-sm font-medium text-green-800">
                                  Livraison confirmée
                                </p>
                                <p className="text-xs text-green-600">
                                  Confirmé le {formatDate(currentOrder.delivery_confirmed_at)}
                                  {currentOrder.delivery_confirmed_by && ` par ${currentOrder.delivery_confirmed_by}`}
                                </p>
                              </div>
                            </div>
                          )}
                        </div>
                      )}

                      {/* Instructions */}
                      <div className="p-3 bg-blue-50 border border-blue-200 rounded-lg">
                        <p className="text-sm text-blue-800">
                          <strong>Instructions:</strong> Le client doit générer un code de 6 chiffres dans son application. 
                          Quand le livreur arrive, le client lui donne ce code pour confirmer la livraison.
                        </p>
                      </div>
                    </div>
                  );
                })()}
              </CardContent>
            </Card>
          )}

          {/* Articles de la commande */}
          <Card className="bg-white/90 backdrop-blur-sm border-orange-200 shadow-lg">
            <CardHeader className="bg-gradient-to-r from-orange-50 to-red-50 border-b border-orange-200">
              <CardTitle className="text-lg flex items-center gap-2 text-orange-700">
                <ChefHat className="h-5 w-5" />
                🍽️ Articles Commandés
              </CardTitle>
            </CardHeader>
            <CardContent className="p-6">
              {loading ? (
                <div className="text-center py-8">
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-orange-500 mx-auto"></div>
                  <p className="text-orange-600 mt-2">Chargement des articles...</p>
                </div>
              ) : (
                <div className="space-y-4">
                  {orderItems.map((item) => (
                    <div key={item.id} className="border border-orange-200 rounded-lg p-4 bg-gradient-to-r from-orange-50 to-red-50 hover:shadow-md transition-shadow">
                      <div className="flex gap-4">
                        {/* Photo de l'article */}
                        <div className="flex-shrink-0">
                          <div className="w-20 h-20 rounded-lg overflow-hidden bg-gray-100 border-2 border-orange-200">
                            {item.item_image ? (
                              <img 
                                src={item.item_image} 
                                alt={item.item_name}
                                className="w-full h-full object-cover"
                              />
                            ) : (
                              <div className="w-full h-full flex items-center justify-center bg-gradient-to-br from-orange-100 to-red-100">
                                <ChefHat className="h-8 w-8 text-orange-400" />
                              </div>
                            )}
                          </div>
                        </div>
                        
                        {/* Détails de l'article */}
                        <div className="flex-1">
                          <div className="flex justify-between items-start">
                            <div className="flex-1">
                              <h4 className="font-semibold text-orange-800 text-lg">{item.item_name}</h4>
                              <p className="text-orange-600 mt-1">
                                Quantité: <span className="font-medium">{item.quantity}</span> × <span className="font-medium">{formatPrice(item.item_price)}</span>
                              </p>
                              
                              {/* Instructions spéciales */}
                              {item.instructions && (
                                <div className="mt-2 p-2 bg-yellow-50 border border-yellow-200 rounded">
                                  <p className="text-sm text-yellow-800">
                                    <strong>📝 Note:</strong> {item.instructions}
                                  </p>
                                </div>
                              )}
                              
                              {/* Garnitures/Extras */}
                              {item.selected_extras && Object.keys(item.selected_extras).length > 0 && (
                                <div className="mt-3 p-3 bg-purple-50 border border-purple-200 rounded-lg">
                                  <p className="text-sm font-medium text-purple-700 mb-2">🍯 Garnitures & Extras:</p>
                                  <div className="grid grid-cols-1 gap-2">
                                    {Object.entries(item.selected_extras).map(([key, value]: [string, any]) => (
                                      <div key={key} className="flex items-center justify-between text-sm">
                                        <div className="flex items-center gap-2">
                                          <span className="text-purple-500">•</span> 
                                          <span className="text-purple-600 font-medium">{key}</span>
                                        </div>
                                        {typeof value === 'number' && value > 0 && (
                                          <span className="text-purple-700 font-semibold">
                                            +{formatPrice(value)}
                                          </span>
                                        )}
                                        {typeof value === 'string' && value && (
                                          <span className="text-purple-700 font-medium">
                                            {value}
                                          </span>
                                        )}
                                      </div>
                                    ))}
                                  </div>
                                </div>
                              )}
                              
                              {/* Garnitures sélectionnées */}
                              {item.selected_garnitures && Object.keys(item.selected_garnitures).length > 0 && (
                                <div className="mt-3 p-3 bg-green-50 border border-green-200 rounded-lg">
                                  <p className="text-sm font-medium text-green-700 mb-2">🥗 Garnitures sélectionnées:</p>
                                  <div className="grid grid-cols-1 gap-2">
                                    {Object.entries(item.selected_garnitures).map(([key, value]: [string, any]) => (
                                      <div key={key} className="flex items-center justify-between text-sm">
                                        <div className="flex items-center gap-2">
                                          <span className="text-green-500">•</span> 
                                          <span className="text-green-600 font-medium">{key}</span>
                                        </div>
                                        {typeof value === 'number' && value > 0 && (
                                          <span className="text-green-700 font-semibold">
                                            +{formatPrice(value)}
                                          </span>
                                        )}
                                        {typeof value === 'string' && value && (
                                          <span className="text-green-700 font-medium">
                                            {value}
                                          </span>
                                        )}
                                      </div>
                                    ))}
                                  </div>
                                </div>
                              )}
                              
                              {/* Garnitures incluses (si elles existent) */}
                              {item.included_garnishes && Array.isArray(item.included_garnishes) && item.included_garnishes.length > 0 && (
                                <div className="mt-3 p-3 bg-blue-50 border border-blue-200 rounded-lg">
                                  <p className="text-sm font-medium text-blue-700 mb-2">🥗 Garnitures incluses:</p>
                                  <div className="flex flex-wrap gap-1">
                                    {item.included_garnishes.map((garnish: string, index: number) => (
                                      <span key={index} className="text-xs bg-blue-100 text-blue-700 px-2 py-1 rounded-full">
                                        {garnish}
                                      </span>
                                    ))}
                                  </div>
                                </div>
                              )}
                            </div>
                            
                            {/* Prix total */}
                            <div className="text-right ml-4">
                              <p className="font-bold text-lg text-green-600">{formatPrice(item.total_price)}</p>
                              {item.selected_extras && Object.keys(item.selected_extras).length > 0 && (
                                <p className="text-xs text-gray-500 mt-1">
                                  (base: {formatPrice(item.item_price)})
                                </p>
                              )}
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  ))}
                  
                  <div className="border-t border-orange-200 pt-4 mt-4">
                    {/* Détail des prix */}
                    <div className="space-y-3 bg-gradient-to-r from-gray-50 to-orange-50 p-4 rounded-lg border border-orange-200">
                      <div className="flex justify-between items-center">
                        <span className="text-gray-700 font-medium">Sous-total</span>
                        <span className="font-semibold text-gray-800">{formatPrice(order.subtotal || 0)}</span>
                      </div>
                      
                      {order.delivery_type === 'delivery' && order.delivery_fee && (
                        <div className="flex justify-between items-center">
                          <span className="flex items-center gap-2 text-orange-700">
                            <Truck className="h-4 w-4" />
                            <span className="font-medium">Frais de livraison</span>
                          </span>
                          <span className="font-semibold text-orange-800">{formatPrice(order.delivery_fee)}</span>
                        </div>
                      )}
                      
                      <div className="border-t border-orange-200 pt-3">
                        <div className="flex justify-between items-center text-xl font-bold">
                          <span className="text-gray-800">💰 Total</span>
                          <span className="text-green-600 text-2xl">{formatPrice(order.total_amount)}</span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Livreur assigné */}
          {(assignedDriver || checkingDriverAssignment) && (
            <Card className="bg-white/90 backdrop-blur-sm border-orange-200 shadow-lg">
              <CardHeader className="bg-gradient-to-r from-orange-50 to-red-50 border-b border-orange-200">
                <CardTitle className="text-lg flex items-center gap-2 text-orange-700">
                  <Truck className="h-5 w-5" />
                  🚚 Livreur Assigné
                </CardTitle>
              </CardHeader>
              <CardContent className="p-6">
                {checkingDriverAssignment ? (
                  <div className="text-center py-8">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-orange-500 mx-auto"></div>
                    <p className="text-orange-600 mt-2 font-medium">
                      Vérification de l'assignation...
                    </p>
                  </div>
                ) : assignedDriver ? (
                  <div className="flex items-center gap-4 p-4 border border-green-200 rounded-lg bg-gradient-to-r from-green-50 to-emerald-50">
                    <div className="h-12 w-12 rounded-full bg-gradient-to-r from-green-400 to-emerald-500 flex items-center justify-center shadow-lg">
                      <Truck className="h-6 w-6 text-white" />
                    </div>
                    <div>
                      <h4 className="font-semibold text-green-800 text-lg">{assignedDriver.name}</h4>
                      <p className="text-green-600">Livreur assigné à cette commande</p>
                      <div className="flex items-center gap-2 mt-1">
                        <span className="text-xs bg-green-100 text-green-700 px-2 py-1 rounded-full">
                          ✅ Actif
                        </span>
                      </div>
                    </div>
                  </div>
                ) : null}
              </CardContent>
            </Card>
          )}

          {/* Livreurs disponibles (affiché seulement si ready_for_delivery) */}
          {currentOrder?.status === 'ready_for_delivery' && !assignedDriver && (
            <AvailableDriversCard
              orderId={currentOrder.id}
              onDriverSelected={handleDriverSelected}
              loading={loading}
            />
          )}

          {/* Gestion du statut */}
          <Card className="bg-white/90 backdrop-blur-sm border-orange-200 shadow-lg">
            <CardHeader className="bg-gradient-to-r from-orange-50 to-red-50 border-b border-orange-200">
              <CardTitle className="text-lg flex items-center gap-2 text-orange-700">
                {getStatusIcon(currentOrder?.status || 'pending')}
                ⚙️ Gestion du Statut
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-6 p-6">
              {/* Statut actuel */}
              <div>
                <Label className="text-orange-700 font-medium mb-2 block">Statut actuel</Label>
                <div className="flex items-center gap-2 p-3 bg-orange-50 border border-orange-200 rounded-lg">
                  {getStatusIcon(currentOrder?.status || 'pending')}
                  <span className="font-medium text-orange-800">
                    {ORDER_STATUSES.find(s => s.value === currentOrder?.status)?.label || currentOrder?.status || 'N/A'}
                  </span>
                </div>
              </div>

              {/* Actions disponibles */}
              <div>
                <Label className="text-orange-700 font-medium mb-3 block">
                  Actions disponibles
                </Label>
                {(() => {
                  const transitions = getAvailableStatusTransitions(
                    currentOrder?.status || 'pending',
                    assignedDriver !== null
                  );

                  if (transitions.length === 0) {
                    return (
                      <div className="p-4 border border-gray-300 bg-gray-50 rounded-lg">
                        <p className="text-gray-600 text-sm">
                          Cette commande est dans un statut final. Aucune action disponible.
                        </p>
                      </div>
                    );
                  }

                  return (
                    <div className="space-y-3">
                      {transitions.map((transition) => {
                        const isDisabled = 
                          updatingStatus ||
                          (transition.value === 'picked_up' && !assignedDriver) ||
                          (transition.value === 'in_transit' && !assignedDriver);

                        let buttonClass = "";
                        switch (transition.variant) {
                          case "success":
                            buttonClass = "bg-green-600 hover:bg-green-700 text-white";
                            break;
                          case "destructive":
                            buttonClass = "bg-red-600 hover:bg-red-700 text-white";
                            break;
                          case "secondary":
                            buttonClass = "bg-gray-600 hover:bg-gray-700 text-white";
                            break;
                          default:
                            buttonClass = "bg-blue-600 hover:bg-blue-700 text-white";
                        }

                        return (
                          <div key={transition.value} className="space-y-1">
                            <Button
                              onClick={() => {
                                updateOrderStatus(transition.value);
                              }}
                              disabled={isDisabled}
                              className={`w-full justify-start ${buttonClass} ${
                                isDisabled ? "opacity-50 cursor-not-allowed" : ""
                              }`}
                            >
                              <div className="flex items-center gap-2">
                                {transition.icon}
                                <span className="font-medium">{transition.label}</span>
                              </div>
                            </Button>
                            {transition.description && (
                              <p className="text-xs text-gray-600 ml-6">
                                {transition.description}
                              </p>
                            )}
                            {isDisabled && transition.value !== currentOrder?.status && (
                              <p className="text-xs text-orange-600 ml-6">
                                ⚠️ {transition.value === 'picked_up' || transition.value === 'in_transit'
                                  ? "Assignez un livreur d'abord"
                                  : "Action non disponible"}
                              </p>
                            )}
                          </div>
                        );
                      })}
                    </div>
                  );
                })()}
              </div>

              {/* Message si ready_for_delivery sans livreur */}
              {currentOrder?.status === 'ready_for_delivery' && !assignedDriver && (
                <div className="p-4 border border-orange-300 bg-gradient-to-r from-orange-50 to-red-50 rounded-lg">
                  <div className="flex items-center gap-3">
                    <AlertCircle className="h-5 w-5 text-orange-600" />
                    <p className="text-orange-800 font-medium text-sm">
                      ⚠️ Assignez un livreur disponible pour pouvoir marquer le repas comme récupéré.
                    </p>
                  </div>
                </div>
              )}

              {/* Notes optionnelles */}
              <div>
                <Label htmlFor="status-notes" className="text-orange-700 font-medium">📝 Notes (optionnel)</Label>
                <Textarea
                  id="status-notes"
                  placeholder="Ajouter des notes sur le changement de statut..."
                  value={statusNotes}
                  onChange={(e) => setStatusNotes(e.target.value)}
                  className="mt-2 border-orange-300 focus:border-orange-500"
                  rows={3}
                />
              </div>

              {/* Bouton fermer */}
              <div className="flex justify-end">
                <Button 
                  variant="outline" 
                  onClick={onClose}
                  className="border-orange-300 text-orange-600 hover:bg-orange-50"
                >
                  ❌ Fermer
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      </DialogContent>
    </Dialog>
  );
};

export default OrderDetailModal;
