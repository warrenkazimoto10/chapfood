import 'package:flutter/material.dart';
import '../services/order_status_service.dart';
import '../services/session_service.dart';
import '../services/delivery_tracking_service.dart';
import '../utils/text_styles.dart';
import '../models/order_model.dart';
import '../models/enums.dart';
import '../constants/app_colors.dart';
import 'order_detail_screen.dart';
import '../widgets/realtime_map_widget.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  late Stream<List<OrderModel>> _ordersStream;

  @override
  void initState() {
    super.initState();
    _ordersStream = OrderStatusService.ordersStream;

    // Démarrer le monitoring des statuts
    OrderStatusService.startStatusMonitoring();
    OrderStatusService.startRealtimeSubscription();
  }

  @override
  void dispose() {
    OrderStatusService.stopStatusMonitoring();
    OrderStatusService.stopRealtimeSubscription();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getSurfaceColor(context),
      appBar: AppBar(
        title: Text(
          'Mes commandes',
          style: TextStyle(color: AppColors.getTextColor(context)),
        ),
        backgroundColor: AppColors.getCardColor(context),
        foregroundColor: AppColors.getTextColor(context),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.getTextColor(context)),
            onPressed: () {
              OrderStatusService.startStatusMonitoring();
            },
          ),
          IconButton(
            icon: Icon(
              Icons.bug_report,
              color: AppColors.getTextColor(context),
            ),
            onPressed: () {
              _showDebugDialog(context);
            },
          ),
        ],
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: _ordersStream,
        builder: (context, snapshot) {
          print('Stream snapshot state: ${snapshot.connectionState}');
          print('Stream snapshot has data: ${snapshot.hasData}');
          print('Stream snapshot has error: ${snapshot.hasError}');

          if (snapshot.hasError) {
            print('Stream Error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      OrderStatusService.startStatusMonitoring();
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!;
          print('Stream Orders count: ${orders.length}');

          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text('Aucune commande trouvée'),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, i) {
              final order = orders[i];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderDetailScreen(order: order),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.getCardColor(context),
                    borderRadius: BorderRadius.circular(14),
                    border: _getStatusBorder(order.status),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getStatusIcon(order.status),
                          color: _getStatusColor(order.status),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Commande #${order.id}',
                              style: AppTextStyles.foodItemTitle.copyWith(
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${order.totalAmount.toStringAsFixed(0)} FCFA • ${_getStatusText(order.status)}',
                              style: AppTextStyles.foodItemDescription,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(order.createdAt ?? DateTime.now()),
                              style: AppTextStyles.foodItemDescription,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                      const SizedBox(width: 8),
                      // Bouton "Suivre la livraison" si en cours de livraison
                      if (_canTrackOrder(order))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: GestureDetector(
                            onTap: () => _navigateToRealtimeMap(order),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.track_changes,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Suivre',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Détermine si une commande peut être suivie en temps réel
  /// Le bouton "Suivre" s'affiche uniquement si un livreur est assigné
  bool _canTrackOrder(OrderModel order) {
    // Le suivi est possible pour les commandes en cours de livraison
    // et seulement pour les commandes de type delivery
    // ET seulement si un livreur est assigné
    return order.deliveryType == DeliveryType.delivery &&
        (order.status == OrderStatus.readyForDelivery ||
            order.status == OrderStatus.pickedUp ||
            order.status == OrderStatus.inTransit) &&
        (order.hasAssignedDriver == true || order.driverId != null);
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.accepted:
        return 'Acceptée';
      case OrderStatus.readyForDelivery:
        return 'Prête à être livrée';
      case OrderStatus.pickedUp:
        return 'Repas récupéré';
      case OrderStatus.inTransit:
        return 'En route';
      case OrderStatus.delivered:
        return 'Livrée';
      case OrderStatus.cancelled:
        return 'Annulée';
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.accepted:
        return Colors.blue;
      case OrderStatus.readyForDelivery:
        return Colors.purple;
      case OrderStatus.pickedUp:
        return Colors.green;
      case OrderStatus.inTransit:
        return Colors.green;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.hourglass_empty;
      case OrderStatus.accepted:
        return Icons.check_circle_outline;
      case OrderStatus.readyForDelivery:
        return Icons.restaurant;
      case OrderStatus.pickedUp:
        return Icons.local_shipping;
      case OrderStatus.inTransit:
        return Icons.local_shipping;
      case OrderStatus.delivered:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  Border? _getStatusBorder(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Border.all(color: Colors.orange.withOpacity(0.3), width: 1);
      case OrderStatus.accepted:
        return Border.all(color: Colors.blue.withOpacity(0.3), width: 1);
      case OrderStatus.readyForDelivery:
        return Border.all(color: Colors.purple.withOpacity(0.3), width: 1);
      case OrderStatus.pickedUp:
      case OrderStatus.inTransit:
        return Border.all(color: Colors.green.withOpacity(0.3), width: 1);
      case OrderStatus.delivered:
        return Border.all(color: Colors.green.withOpacity(0.3), width: 1);
      case OrderStatus.cancelled:
        return Border.all(color: Colors.red.withOpacity(0.3), width: 1);
    }
  }

  // Dialog de debug pour nettoyer la session
  void _showDebugDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Debug - Session'),
          content: const Text(
            'Cette action va nettoyer complètement la session utilisateur. '
            'Vous devrez vous reconnecter. Continuer ?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await SessionService.clearSession();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Session nettoyée. Redémarrage nécessaire.'),
                    backgroundColor: Colors.green,
                  ),
                );
                // Rediriger vers la page de connexion
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              },
              child: const Text('Nettoyer'),
            ),
          ],
        );
      },
    );
  }

  /// Navigue directement vers la carte de suivi en temps réel
  void _navigateToRealtimeMap(OrderModel order) async {
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Récupérer les détails de livraison
      final deliveryData = await DeliveryTrackingService.getDeliveryDetails(
        order.id,
      );

      // Fermer l'indicateur de chargement
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (deliveryData != null) {
        final orderData = deliveryData['order'] as OrderModel;
        final driver = deliveryData['driver'];

        // Extraire les coordonnées du client
        double customerLat = 5.3700; // Valeur par défaut
        double customerLng = -4.0200; // Valeur par défaut

        if (orderData.deliveryLat != null &&
            orderData.deliveryLng != null &&
            orderData.deliveryLat!.isFinite &&
            orderData.deliveryLng!.isFinite) {
          customerLat = orderData.deliveryLat!;
          customerLng = orderData.deliveryLng!;
        } else if (orderData.deliveryAddress != null) {
          final addressMatch = RegExp(
            r'\(([0-9.-]+),\s*([0-9.-]+)\)',
          ).firstMatch(orderData.deliveryAddress!);
          if (addressMatch != null) {
            customerLat = double.tryParse(addressMatch.group(1)!) ?? 5.3700;
            customerLng = double.tryParse(addressMatch.group(2)!) ?? -4.0200;
          }
        }

        // Coordonnées du livreur
        double driverLat = 5.3563; // Position par défaut (restaurant)
        double driverLng = -4.0363;

        if (driver?.currentLat != null &&
            driver?.currentLng != null &&
            driver!.currentLat!.isFinite &&
            driver.currentLng!.isFinite) {
          driverLat = driver.currentLat!;
          driverLng = driver.currentLng!;
        }

        // Naviguer vers RealtimeMapWidget
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RealtimeMapWidget(
                orderId: order.id.toString(),
                customerName: order.customerName ?? 'Client',
                customerLatitude: customerLat,
                customerLongitude: customerLng,
                orderStatus: order.status.value,
                driverName: driver?.name ?? 'Livreur ChapFood',
                driverPhone: driver?.phone ?? '+225 XX XX XX XX',
                driverLatitude: driverLat,
                driverLongitude: driverLng,
                onClose: () => Navigator.pop(context),
              ),
            ),
          );
        }
      } else {
        // Erreur lors de la récupération des données
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Impossible de charger les informations de livraison',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Fermer l'indicateur de chargement en cas d'erreur
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
