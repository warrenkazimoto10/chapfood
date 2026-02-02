import React, { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { useToast } from '@/hooks/use-toast';
import { Clock, CheckCircle, XCircle, Timer, ChefHat, AlertCircle } from 'lucide-react';
import { useAdminAuth } from '@/hooks/useAdminAuth';

interface Order {
  id: number;
  customer_name: string;
  customer_phone: string;
  status: string;
  total_amount: number;
  created_at: string;
  preparation_time?: number;
  kitchen_notes?: string;
  delivery_type: string;
  order_items: Array<{
    item_name: string;
    quantity: number;
    instructions?: string;
  }>;
}

export const KitchenDashboard = () => {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [preparationTimes, setPreparationTimes] = useState<{ [key: number]: number }>({});
  const [notes, setNotes] = useState<{ [key: number]: string }>({});
  const { admin, logout } = useAdminAuth();
  const { toast } = useToast();

  useEffect(() => {
    fetchPendingOrders();
    
    // Set up real-time subscription for new orders
    const channel = supabase
      .channel('kitchen-orders')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'orders'
        },
        () => {
          fetchPendingOrders();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  const fetchPendingOrders = async () => {
    try {
      const { data: ordersData, error } = await supabase
        .from('orders')
        .select(`
          id, customer_name, customer_phone, status, total_amount, created_at,
          preparation_time, kitchen_notes, delivery_type,
          order_items (item_name, quantity, instructions)
        `)
        .in('status', ['pending', 'confirmed', 'preparing'])
        .order('created_at', { ascending: true });

      if (error) throw error;
      setOrders(ordersData || []);
    } catch (error) {
      console.error('Error fetching orders:', error);
      toast({
        title: "Erreur",
        description: "Impossible de charger les commandes",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const acceptOrder = async (orderId: number) => {
    const prepTime = preparationTimes[orderId] || 30;
    const kitchenNotes = notes[orderId] || '';

    try {
      const { error } = await supabase
        .from('orders')
        .update({
          status: 'confirmed',
          preparation_time: prepTime,
          kitchen_notes: kitchenNotes,
          accepted_at: new Date().toISOString()
        })
        .eq('id', orderId);

      if (error) throw error;

      // Create notification for customer
      await supabase
        .from('order_notifications')
        .insert({
          order_id: orderId,
          message: `Votre commande a été acceptée. Temps de préparation estimé: ${prepTime} minutes`,
          type: 'order_confirmed'
        });

      toast({
        title: "Commande acceptée",
        description: `Commande #${orderId} acceptée avec ${prepTime} minutes de préparation`,
      });

      fetchPendingOrders();
    } catch (error) {
      console.error('Error accepting order:', error);
      toast({
        title: "Erreur",
        description: "Impossible d'accepter la commande",
        variant: "destructive",
      });
    }
  };

  const rejectOrder = async (orderId: number) => {
    try {
      const { error } = await supabase
        .from('orders')
        .update({
          status: 'cancelled',
          rejected_at: new Date().toISOString()
        })
        .eq('id', orderId);

      if (error) throw error;

      // Create notification for customer
      await supabase
        .from('order_notifications')
        .insert({
          order_id: orderId,
          message: 'Votre commande a été annulée par le restaurant',
          type: 'order_confirmed'
        });

      toast({
        title: "Commande rejetée",
        description: `Commande #${orderId} rejetée`,
      });

      fetchPendingOrders();
    } catch (error) {
      console.error('Error rejecting order:', error);
      toast({
        title: "Erreur",
        description: "Impossible de rejeter la commande",
        variant: "destructive",
      });
    }
  };

  const startPreparation = async (orderId: number) => {
    try {
      const { error } = await supabase
        .from('orders')
        .update({
          status: 'preparing'
        })
        .eq('id', orderId);

      if (error) throw error;

      // Create notification for customer
      await supabase
        .from('order_notifications')
        .insert({
          order_id: orderId,
          message: 'Votre commande est en cours de préparation',
          type: 'preparing'
        });

      toast({
        title: "Préparation démarrée",
        description: `Commande #${orderId} en cours de préparation`,
      });

      fetchPendingOrders();
    } catch (error) {
      console.error('Error starting preparation:', error);
      toast({
        title: "Erreur",
        description: "Impossible de démarrer la préparation",
        variant: "destructive",
      });
    }
  };

  const markReady = async (orderId: number) => {
    try {
      const { error } = await supabase
        .from('orders')
        .update({
          status: 'on_way',
          ready_at: new Date().toISOString()
        })
        .eq('id', orderId);

      if (error) throw error;

      // Create notification for customer and drivers
      await supabase
        .from('order_notifications')
        .insert({
          order_id: orderId,
          message: 'Votre commande est prête',
          type: 'ready'
        });

      // Notify available drivers
      const { data: drivers } = await supabase
        .from('drivers')
        .select('id')
        .eq('is_available', true)
        .eq('is_active', true);

      if (drivers) {
        const notifications = drivers.map(driver => ({
          driver_id: driver.id,
          order_id: orderId,
          message: `Nouvelle commande prête pour livraison #${orderId}`,
          type: 'order_ready'
        }));

        await supabase
          .from('driver_notifications')
          .insert(notifications);
      }

      toast({
        title: "Commande prête",
        description: `Commande #${orderId} prête pour livraison`,
      });

      fetchPendingOrders();
    } catch (error) {
      console.error('Error marking ready:', error);
      toast({
        title: "Erreur",
        description: "Impossible de marquer la commande comme prête",
        variant: "destructive",
      });
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'pending':
        return <Badge variant="secondary" className="bg-yellow-100 text-yellow-800"><AlertCircle className="w-3 h-3 mr-1" />En attente</Badge>;
      case 'accepted':
        return <Badge variant="secondary" className="bg-blue-100 text-blue-800"><Timer className="w-3 h-3 mr-1" />Acceptée</Badge>;
      case 'preparing':
        return <Badge variant="secondary" className="bg-orange-100 text-orange-800"><ChefHat className="w-3 h-3 mr-1" />En préparation</Badge>;
      default:
        return <Badge variant="outline">{status}</Badge>;
    }
  };

  const formatTime = (timestamp: string) => {
    return new Date(timestamp).toLocaleTimeString('fr-FR', {
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background p-6">
      <div className="max-w-7xl mx-auto">
        <div className="flex justify-between items-center mb-6">
          <div>
            <h1 className="text-3xl font-bold text-foreground">Cuisine - ChapFood</h1>
            <p className="text-muted-foreground">Bonjour {admin?.full_name || admin?.email}</p>
          </div>
          <Button variant="outline" onClick={logout}>
            Déconnexion
          </Button>
        </div>

        <div className="grid gap-6">
          {orders.length === 0 ? (
            <Card>
              <CardContent className="py-8 text-center">
                <ChefHat className="w-12 h-12 mx-auto text-muted-foreground mb-4" />
                <p className="text-lg font-medium text-muted-foreground">Aucune commande en attente</p>
                <p className="text-sm text-muted-foreground">Les nouvelles commandes apparaîtront ici automatiquement</p>
              </CardContent>
            </Card>
          ) : (
            orders.map((order) => (
              <Card key={order.id} className="w-full">
                <CardHeader>
                  <div className="flex justify-between items-start">
                    <div>
                      <CardTitle className="flex items-center gap-2">
                        Commande #{order.id}
                        {getStatusBadge(order.status)}
                      </CardTitle>
                      <CardDescription>
                        {order.customer_name} - {order.customer_phone} - {formatTime(order.created_at)}
                      </CardDescription>
                    </div>
                    <div className="text-right">
                      <p className="text-2xl font-bold text-primary">{order.total_amount.toLocaleString()} FCFA</p>
                      <p className="text-sm text-muted-foreground">{order.delivery_type}</p>
                    </div>
                  </div>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div>
                    <h4 className="font-medium mb-2">Articles commandés:</h4>
                    <div className="space-y-1">
                      {order.order_items.map((item, index) => (
                        <div key={index} className="flex justify-between text-sm">
                          <span>{item.quantity}x {item.item_name}</span>
                          {item.instructions && (
                            <span className="text-muted-foreground italic">"{item.instructions}"</span>
                          )}
                        </div>
                      ))}
                    </div>
                  </div>

                  {order.status === 'pending' && (
                    <div className="space-y-3 p-4 bg-muted/50 rounded-lg">
                      <div className="grid grid-cols-2 gap-4">
                        <div>
                          <label className="text-sm font-medium">Temps de préparation (minutes)</label>
                          <Input
                            type="number"
                            placeholder="30"
                            value={preparationTimes[order.id] || ''}
                            onChange={(e) => setPreparationTimes({
                              ...preparationTimes,
                              [order.id]: parseInt(e.target.value) || 0
                            })}
                          />
                        </div>
                        <div>
                          <label className="text-sm font-medium">Notes cuisine</label>
                          <Textarea
                            placeholder="Notes internes..."
                            value={notes[order.id] || ''}
                            onChange={(e) => setNotes({
                              ...notes,
                              [order.id]: e.target.value
                            })}
                            rows={2}
                          />
                        </div>
                      </div>
                      <div className="flex gap-2">
                        <Button 
                          onClick={() => acceptOrder(order.id)}
                          className="flex-1"
                        >
                          <CheckCircle className="w-4 h-4 mr-2" />
                          Accepter
                        </Button>
                        <Button 
                          variant="destructive"
                          onClick={() => rejectOrder(order.id)}
                          className="flex-1"
                        >
                          <XCircle className="w-4 h-4 mr-2" />
                          Rejeter
                        </Button>
                      </div>
                    </div>
                  )}

                  {order.status === 'accepted' && (
                    <div className="p-4 bg-blue-50 rounded-lg">
                      <div className="flex items-center justify-between">
                        <div>
                          <p className="font-medium">Temps estimé: {order.preparation_time} minutes</p>
                          {order.kitchen_notes && (
                            <p className="text-sm text-muted-foreground">Notes: {order.kitchen_notes}</p>
                          )}
                        </div>
                        <Button onClick={() => startPreparation(order.id)}>
                          <ChefHat className="w-4 h-4 mr-2" />
                          Commencer la préparation
                        </Button>
                      </div>
                    </div>
                  )}

                  {order.status === 'preparing' && (
                    <div className="p-4 bg-orange-50 rounded-lg">
                      <div className="flex items-center justify-between">
                        <div>
                          <p className="font-medium text-orange-800">En cours de préparation...</p>
                          <p className="text-sm text-orange-600">Temps estimé: {order.preparation_time} minutes</p>
                        </div>
                        <Button onClick={() => markReady(order.id)}>
                          <CheckCircle className="w-4 h-4 mr-2" />
                          Marquer comme prête
                        </Button>
                      </div>
                    </div>
                  )}
                </CardContent>
              </Card>
            ))
          )}
        </div>
      </div>
    </div>
  );
};