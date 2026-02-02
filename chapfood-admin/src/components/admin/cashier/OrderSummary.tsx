import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { useToast } from '@/hooks/use-toast';
import { supabase } from '@/integrations/supabase/client';
import { 
  CreditCard, 
  User, 
  Package, 
  MapPin, 
  Truck, 
  CheckCircle,
  Clock,
  DollarSign,
  Edit,
  Send
} from 'lucide-react';

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

interface Driver {
  id: string;
  name: string;
  phone: string;
  current_lat?: number;
  current_lng?: number;
  is_available: boolean;
}

interface OrderSummaryProps {
  client: Client;
  cart: CartItem[];
  orderType: 'delivery' | 'pickup';
  deliveryLocation?: any;
  orderTotal: number;
  onOrderCreated: (order: any) => void;
  onCancel: () => void;
}

const OrderSummary: React.FC<OrderSummaryProps> = ({
  client,
  cart,
  orderType,
  deliveryLocation,
  orderTotal,
  onOrderCreated,
  onCancel
}) => {
  const { toast } = useToast();
  const [specialInstructions, setSpecialInstructions] = useState('');
  const [paymentMethod, setPaymentMethod] = useState<'cash' | 'mobile_money'>('cash');
  const [creating, setCreating] = useState(false);
  const [deliveryFee, setDeliveryFee] = useState(2000);
  const [receivedAmount, setReceivedAmount] = useState('');
  const [mobileMoneyDetails, setMobileMoneyDetails] = useState({ transactionNumber: '', operator: 'orange' });

  // Charger les frais de livraison configurables
  useEffect(() => {
    const loadDeliveryFee = async () => {
      try {
        const { data, error } = await supabase
          .from('cashier_settings')
          .select('setting_value')
          .eq('setting_key', 'default_delivery_fee')
          .single();

        if (!error && data) {
          setDeliveryFee(Number(data.setting_value) || 2000);
        }
      } catch (error) {
        console.warn('Erreur lors du chargement des frais de livraison:', error);
        setDeliveryFee(2000); // Fallback
      }
    };

    loadDeliveryFee();
  }, []);

  const finalTotal = orderTotal + (orderType === 'delivery' ? deliveryFee : 0);
  const change = paymentMethod === 'cash' && receivedAmount ? Number(receivedAmount) - finalTotal : 0;

  const createOrder = async () => {
    try {
      setCreating(true);

      // Validation du paiement
      if (paymentMethod === 'cash' && Number(receivedAmount) < finalTotal) {
        toast({
          title: "Montant insuffisant",
          description: `Le montant reçu (${Number(receivedAmount).toLocaleString()} FCFA) est inférieur au total (${finalTotal.toLocaleString()} FCFA)`,
          variant: "destructive",
        });
        return;
      }

      if (paymentMethod === 'mobile_money' && !mobileMoneyDetails.transactionNumber.trim()) {
        toast({
          title: "Numéro de transaction requis",
          description: "Veuillez entrer le numéro de transaction",
          variant: "destructive",
        });
        return;
      }

      // Calculer les frais de livraison
      const calculatedDeliveryFee = orderType === 'delivery' ? deliveryFee : 0;

      // Créer la commande
      const orderData = {
        user_id: client.id,
        customer_name: client.full_name,
        customer_phone: client.phone,
        delivery_type: orderType,
        delivery_address: orderType === 'delivery' ? deliveryLocation?.address : null,
        delivery_lat: orderType === 'delivery' ? deliveryLocation?.latitude : null,
        delivery_lng: orderType === 'delivery' ? deliveryLocation?.longitude : null,
        subtotal: orderTotal,
        delivery_fee: calculatedDeliveryFee,
        total_amount: finalTotal,
        payment_method: paymentMethod,
        payment_number: paymentMethod === 'mobile_money' ? mobileMoneyDetails.transactionNumber : null,
        status: 'pending',
        instructions: specialInstructions.trim() || null
      };

      const { data: order, error: orderError } = await supabase
        .from('orders')
        .insert([orderData])
        .select()
        .single();

      if (orderError) throw orderError;

      // Créer les articles de la commande
      const orderItems = cart.map(item => ({
        order_id: order.id,
        menu_item_id: item.menu_item.id,
        item_name: item.menu_item.name,
        item_price: item.menu_item.price,
        quantity: item.quantity,
        total_price: item.total_price,
        selected_extras: item.selected_extras,
        selected_garnitures: item.selected_garnitures,
        instructions: item.special_instructions
      }));

      const { error: itemsError } = await supabase
        .from('order_items')
        .insert(orderItems);

      if (itemsError) throw itemsError;

      // La commande est créée en statut 'pending'
      // L'assignation du livreur se fera depuis la page des commandes

      // Créer une notification pour le client
      const notificationData = {
        user_id: client.id,
        order_id: order.id,
        message: `Votre commande #${order.id} a été créée avec succès. Votre commande sera préparée.`,
        type: 'order_created',
        read_at: null
      };

      const { error: notificationError } = await supabase
        .from('order_notifications')
        .insert([notificationData]);

      if (notificationError) {
        console.warn('Erreur lors de la création de la notification:', notificationError);
        // Ne pas faire échouer la commande pour une notification
      }

      toast({
        title: "Commande créée avec succès",
        description: `Commande #${order.id} créée pour ${client.full_name}`,
      });

      onOrderCreated(order);
    } catch (error) {
      console.error('Erreur lors de la création de la commande:', error);
      toast({
        title: "Erreur",
        description: "Impossible de créer la commande",
        variant: "destructive",
      });
    } finally {
      setCreating(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <Card className="bg-white/90 backdrop-blur-sm border-orange-200 shadow-lg">
        <CardHeader className="bg-gradient-to-r from-orange-50 to-red-50 border-b border-orange-200">
          <CardTitle className="text-orange-700 flex items-center gap-2">
            <CreditCard className="h-6 w-6" />
            Récapitulatif de la Commande
          </CardTitle>
        </CardHeader>
        <CardContent className="p-6">
          <p className="text-gray-600">
            Vérifiez les détails de la commande avant de la finaliser
          </p>
        </CardContent>
      </Card>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Détails de la commande */}
        <div className="space-y-6">
          {/* Informations client */}
          <Card className="bg-white/90 backdrop-blur-sm border-orange-200">
            <CardHeader className="bg-gradient-to-r from-orange-50 to-red-50 border-b border-orange-200">
              <CardTitle className="text-orange-700 flex items-center gap-2">
                <User className="h-5 w-5" />
                Informations Client
              </CardTitle>
            </CardHeader>
            <CardContent className="p-4">
              <div className="flex items-center gap-4">
                <Avatar className="h-12 w-12">
                  <AvatarFallback className="bg-gradient-to-r from-orange-500 to-red-500 text-white font-bold">
                    {client.full_name.split(' ').map(n => n[0]).join('').slice(0, 2)}
                  </AvatarFallback>
                </Avatar>
                <div>
                  <h3 className="font-semibold text-gray-800">{client.full_name}</h3>
                  <p className="text-gray-600">{client.phone}</p>
                  {client.email && <p className="text-sm text-gray-500">{client.email}</p>}
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Type de commande */}
          <Card className="bg-white/90 backdrop-blur-sm border-orange-200">
            <CardHeader className="bg-gradient-to-r from-orange-50 to-red-50 border-b border-orange-200">
              <CardTitle className="text-orange-700 flex items-center gap-2">
                {orderType === 'delivery' ? <MapPin className="h-5 w-5" /> : <Package className="h-5 w-5" />}
                Type de Commande
              </CardTitle>
            </CardHeader>
            <CardContent className="p-4">
              <div className="flex items-center gap-3">
                <Badge className={orderType === 'delivery' ? "bg-blue-100 text-blue-800" : "bg-green-100 text-green-800"}>
                  {orderType === 'delivery' ? 'Livraison' : 'À emporter'}
                </Badge>
                {deliveryLocation && (
                  <p className="text-sm text-gray-600">{deliveryLocation.address}</p>
                )}
              </div>
            </CardContent>
          </Card>


          {/* Articles commandés */}
          <Card className="bg-white/90 backdrop-blur-sm border-orange-200">
            <CardHeader className="bg-gradient-to-r from-orange-50 to-red-50 border-b border-orange-200">
              <CardTitle className="text-orange-700 flex items-center gap-2">
                <Package className="h-5 w-5" />
                Articles ({cart.length})
              </CardTitle>
            </CardHeader>
            <CardContent className="p-4">
              <div className="space-y-3">
                {cart.map((item) => (
                  <div key={item.id} className="p-3 bg-gray-50 rounded-lg">
                    <div className="flex justify-between items-start mb-2">
                      <div>
                        <h4 className="font-semibold text-gray-800">{item.menu_item.name}</h4>
                        <p className="text-sm text-gray-600">× {item.quantity}</p>
                      </div>
                      <span className="font-bold text-green-600">
                        {item.total_price.toLocaleString()} FCFA
                      </span>
                    </div>
                    
                    {item.selected_extras.length > 0 && (
                      <div className="mb-2">
                        <p className="text-xs font-medium text-purple-700 mb-1">Suppléments:</p>
                        {item.selected_extras.map((extra) => (
                          <p key={extra.id} className="text-xs text-purple-600">
                            + {extra.name} ({extra.price.toLocaleString()} FCFA)
                          </p>
                        ))}
                      </div>
                    )}
                    
                    {item.selected_garnitures.length > 0 && (
                      <div className="mb-2">
                        <p className="text-xs font-medium text-green-700 mb-1">Garnitures:</p>
                        {item.selected_garnitures.map((garniture) => (
                          <p key={garniture.id} className="text-xs text-green-600">
                            + {garniture.name} ({garniture.price.toLocaleString()} FCFA)
                          </p>
                        ))}
                      </div>
                    )}
                    
                    {item.special_instructions && (
                      <p className="text-xs text-blue-600 italic">
                        Note: {item.special_instructions}
                      </p>
                    )}
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Récapitulatif et finalisation */}
        <div className="space-y-6">
          {/* Instructions spéciales */}
          <Card className="bg-white/90 backdrop-blur-sm border-orange-200">
            <CardHeader className="bg-gradient-to-r from-orange-50 to-red-50 border-b border-orange-200">
              <CardTitle className="text-orange-700 flex items-center gap-2">
                <Edit className="h-5 w-5" />
                Instructions Spéciales
              </CardTitle>
            </CardHeader>
            <CardContent className="p-4">
              <div className="space-y-2">
                <Label className="text-orange-700 font-medium">Instructions pour la commande</Label>
                <Textarea
                  value={specialInstructions}
                  onChange={(e) => setSpecialInstructions(e.target.value)}
                  placeholder="Ex: Livraison rapide, appeler avant d'arriver..."
                  className="border-orange-300 focus:border-orange-500"
                  rows={3}
                />
              </div>
            </CardContent>
          </Card>

          {/* Méthode de paiement */}
          <Card className="bg-white/90 backdrop-blur-sm border-orange-200">
            <CardHeader className="bg-gradient-to-r from-orange-50 to-red-50 border-b border-orange-200">
              <CardTitle className="text-orange-700 flex items-center gap-2">
                <DollarSign className="h-5 w-5" />
                Méthode de Paiement
              </CardTitle>
            </CardHeader>
            <CardContent className="p-4">
              <div className="space-y-4">
                <div className="flex items-center gap-3">
                  <input
                    type="radio"
                    id="cash"
                    name="payment"
                    value="cash"
                    checked={paymentMethod === 'cash'}
                    onChange={(e) => setPaymentMethod(e.target.value as 'cash' | 'mobile_money')}
                    className="text-orange-500"
                  />
                  <Label htmlFor="cash" className="font-medium">Espèces</Label>
                </div>
                <div className="flex items-center gap-3">
                  <input
                    type="radio"
                    id="mobile_money"
                    name="payment"
                    value="mobile_money"
                    checked={paymentMethod === 'mobile_money'}
                    onChange={(e) => setPaymentMethod(e.target.value as 'cash' | 'mobile_money')}
                    className="text-orange-500"
                  />
                  <Label htmlFor="mobile_money" className="font-medium">Mobile Money</Label>
                </div>

                {/* Champs spécifiques selon la méthode */}
                {paymentMethod === 'cash' && (
                  <div className="space-y-3 pt-2 border-t border-gray-200">
                    <div className="space-y-2">
                      <Label className="text-gray-700 font-medium">Montant reçu (FCFA)</Label>
                      <Input
                        type="number"
                        value={receivedAmount}
                        onChange={(e) => setReceivedAmount(e.target.value)}
                        placeholder="Entrez le montant reçu"
                        className="border-orange-300 focus:border-orange-500"
                        min={0}
                      />
                    </div>
                    {receivedAmount && (
                      <div className={`p-4 rounded-lg ${change >= 0 ? 'bg-green-50 border border-green-200' : 'bg-red-50 border border-red-200'}`}>
                        {change >= 0 ? (
                          <div>
                            <p className="text-sm text-gray-600 mb-1">Rendu de monnaie:</p>
                            <p className="text-3xl font-bold text-green-600">
                              {change.toLocaleString()} FCFA
                            </p>
                          </div>
                        ) : (
                          <div>
                            <p className="text-sm text-red-700 mb-1">Montant insuffisant!</p>
                            <p className="text-xl font-bold text-red-600">
                              Manque: {Math.abs(change).toLocaleString()} FCFA
                            </p>
                          </div>
                        )}
                      </div>
                    )}
                  </div>
                )}

                {paymentMethod === 'mobile_money' && (
                  <div className="space-y-3 pt-2 border-t border-gray-200">
                    <div className="space-y-2">
                      <Label className="text-gray-700 font-medium">Opérateur</Label>
                      <select
                        value={mobileMoneyDetails.operator}
                        onChange={(e) => setMobileMoneyDetails({ ...mobileMoneyDetails, operator: e.target.value })}
                        className="w-full px-3 py-2 border border-orange-300 rounded-md focus:outline-none focus:ring-2 focus:ring-orange-500"
                      >
                        <option value="orange">Orange Money</option>
                        <option value="mtn">MTN Mobile Money</option>
                        <option value="moov">Moov Money</option>
                      </select>
                    </div>
                    <div className="space-y-2">
                      <Label className="text-gray-700 font-medium">Numéro de transaction *</Label>
                      <Input
                        type="text"
                        value={mobileMoneyDetails.transactionNumber}
                        onChange={(e) => setMobileMoneyDetails({ ...mobileMoneyDetails, transactionNumber: e.target.value })}
                        placeholder="Ex: 1234567890"
                        className="border-orange-300 focus:border-orange-500"
                      />
                      <p className="text-xs text-gray-500">
                        Entrez le numéro de transaction reçu
                      </p>
                    </div>
                  </div>
                )}
              </div>
            </CardContent>
          </Card>

          {/* Récapitulatif des prix */}
          <Card className="bg-white/90 backdrop-blur-sm border-green-200">
            <CardHeader className="bg-gradient-to-r from-green-50 to-emerald-50 border-b border-green-200">
              <CardTitle className="text-green-700 flex items-center gap-2">
                <DollarSign className="h-5 w-5" />
                Récapitulatif des Prix
              </CardTitle>
            </CardHeader>
            <CardContent className="p-4">
              <div className="space-y-3">
                <div className="flex justify-between">
                  <span className="text-gray-600">Sous-total:</span>
                  <span className="font-semibold">{orderTotal.toLocaleString()} FCFA</span>
                </div>
                {deliveryFee > 0 && (
                  <div className="flex justify-between">
                    <span className="text-gray-600">Frais de livraison:</span>
                    <span className="font-semibold">{deliveryFee.toLocaleString()} FCFA</span>
                  </div>
                )}
                <div className="border-t border-green-200 pt-3">
                  <div className="flex justify-between items-center">
                    <span className="text-lg font-bold text-green-800">Total:</span>
                    <span className="text-2xl font-bold text-green-600">
                      {finalTotal.toLocaleString()} FCFA
                    </span>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Actions */}
          <div className="space-y-4">
            <Button
              onClick={createOrder}
              disabled={creating || (paymentMethod === 'cash' && (!receivedAmount || change < 0)) || (paymentMethod === 'mobile_money' && !mobileMoneyDetails.transactionNumber.trim())}
              className="w-full bg-gradient-to-r from-green-500 to-emerald-500 hover:from-green-600 hover:to-emerald-600 text-white h-12 text-lg disabled:opacity-50"
            >
              {creating ? (
                <div className="flex items-center gap-2">
                  <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white"></div>
                  Création de la commande...
                </div>
              ) : (
                <div className="flex items-center gap-2">
                  <CheckCircle className="h-5 w-5" />
                  Finaliser la Commande
                </div>
              )}
            </Button>
            
            <Button
              variant="outline"
              onClick={onCancel}
              className="w-full border-orange-300 text-orange-600 hover:bg-orange-50"
            >
              Retour
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default OrderSummary;
