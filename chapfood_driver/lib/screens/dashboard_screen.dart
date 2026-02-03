import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../services/session_service.dart';
import '../services/active_delivery_service.dart';
import '../services/state_persistence_service.dart';
import '../services/order_status_service.dart';
import '../services/order_service.dart';
import '../services/driver_location_service.dart';
import '../models/order_model.dart';
import '../models/driver_model.dart';
import '../models/active_delivery_state.dart';
import '../widgets/order_notification_bottom_sheet.dart';
import '../widgets/map/osm_map_widget.dart';
import '../config/osm_config.dart';
import '../widgets/dashboard/status_card.dart';
import '../widgets/dashboard/customer_service_modal.dart';
import 'active_delivery_screen.dart';

/// Ã‰cran principal du dashboard du livreur
/// GÃ¨re la restauration automatique de l'Ã©tat et redirige vers active_delivery_screen si nÃ©cessaire
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isInitializing = true;
  bool _isDriverAvailable = true;
  DriverModel? _currentDriver;
  StreamSubscription<OrderModel>? _orderSubscription;
  StreamSubscription<List<OrderModel>>? _availableOrdersSubscription;

  // Commandes temporairement masquÃ©es (refusÃ©es par ce livreur)
  final Map<int, DateTime> _dismissedOrders = {};

  // État pour la carte OSM
  MapController? _mapController;
  geo.Position? _currentPosition;
  geo.Position? _previousPosition;
  double? _currentBearing;
  StreamSubscription<geo.Position>? _positionSubscription;

  // Ã‰tat de livraison
  bool _isOnDelivery = false;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  /// RafraÃ®chir le dashboard (vÃ©rifier les livraisons actives)
  Future<void> _refreshDashboard() async {
    print('ðŸ”„ RafraÃ®chissement du dashboard...');

    if (_currentDriver == null) {
      print('âš ï¸ Aucun livreur connectÃ©');
      return;
    }

    try {
      // Afficher un indicateur de chargement
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Actualisation en cours...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // 1. Nettoyer l'Ã©tat sauvegardÃ© et vÃ©rifier depuis la DB
      await StatePersistenceService.clearActiveDelivery();
      print('ðŸ§¹ Ã‰tat sauvegardÃ© nettoyÃ© pour forcer la vÃ©rification');

      // 2. VÃ©rifier directement dans la DB pour une livraison active
      OrderModel? activeOrder;
      try {
        activeOrder =
            await ActiveDeliveryService.getActiveDelivery(
              _currentDriver!.id,
            ).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                print('âš ï¸ Timeout lors de la vÃ©rification');
                return null;
              },
            );

        // Mettre Ã  jour l'Ã©tat de livraison
        if (mounted) {
          setState(() {
            _isOnDelivery = activeOrder != null;
          });
        }
      } catch (e) {
        print('âŒ Erreur lors de la vÃ©rification: $e');
        activeOrder = null;
      }

      if (activeOrder != null) {
        // Sauvegarder l'Ã©tat et rediriger
        final state = ActiveDeliveryState.fromOrder(activeOrder);
        await StatePersistenceService.saveActiveDelivery(state);
        print('âœ… Livraison active trouvÃ©e: #${activeOrder.id}');

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Livraison active trouvÃ©e'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          _navigateToActiveDelivery(activeOrder);
        }
      } else {
        // Aucune livraison active
        print('â„¹ï¸ Aucune livraison active trouvÃ©e');
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucune livraison active'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('âŒ Erreur lors du rafraÃ®chissement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'actualisation: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Initialisation du dashboard avec restauration de l'Ã©tat
  Future<void> _initializeDashboard() async {
    print('ðŸš€ DÃ©but de l\'initialisation du dashboard...');
    try {
      setState(() {
        _isInitializing = true;
      });

      // 1. VÃ©rifier la session
      print('ðŸ‘¤ VÃ©rification de la session...');
      final driver = await SessionService.getCurrentDriver();
      if (driver == null) {
        print('âš ï¸ Aucun livreur connectÃ©, redirection vers login');
        if (mounted) {
          setState(() {
            _isInitializing = false;
          });
          context.go('/login');
        }
        return;
      }

      print('âœ… Livreur connectÃ©: ${driver.id}');
      setState(() {
        _currentDriver = driver;
        _isDriverAvailable = driver.isAvailable;
      });

      // 2. Restaurer l'Ã©tat de livraison active depuis le stockage local
      print('ðŸ’¾ VÃ©rification de l\'Ã©tat sauvegardÃ©...');
      final savedState = await StatePersistenceService.restoreActiveDelivery();

      if (savedState != null) {
        print(
          'ðŸ“¦ Ã‰tat sauvegardÃ© trouvÃ© pour commande #${savedState.orderId}',
        );
        // 3. VÃ©rifier la cohÃ©rence avec la DB
        final isValid = await StatePersistenceService.validateActiveDelivery(
          savedState.orderId,
        );

        if (isValid) {
          // RÃ©cupÃ©rer la commande depuis la DB avec timeout
          print('ðŸ” RÃ©cupÃ©ration de la commande depuis la DB...');
          OrderModel? activeOrder;
          try {
            activeOrder =
                await ActiveDeliveryService.getActiveDelivery(
                  driver.id,
                ).timeout(
                  const Duration(seconds: 10),
                  onTimeout: () {
                    print(
                      'âš ï¸ Timeout lors de la rÃ©cupÃ©ration de la commande active',
                    );
                    return null;
                  },
                );
          } catch (e) {
            print('âŒ Erreur lors de la rÃ©cupÃ©ration de la commande: $e');
            activeOrder = null;
          }

          print(
            'ðŸ” Ã‰tat sauvegardÃ© trouvÃ©, commande active: ${activeOrder?.id}',
          );

          if (activeOrder != null && mounted) {
            print(
              'âœ… Redirection vers active-delivery depuis Ã©tat sauvegardÃ©',
            );
            // Mettre Ã  jour l'Ã©tat avant de rediriger
            final orderToNavigate =
                activeOrder; // Variable locale pour Ã©viter le problÃ¨me de null
            setState(() {
              _isInitializing = false;
            });
            // Rediriger vers l'Ã©cran de livraison active
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _navigateToActiveDelivery(orderToNavigate);
              }
            });
            return;
          } else {
            print(
              'âš ï¸ Commande active non trouvÃ©e, nettoyage de l\'Ã©tat...',
            );
            await StatePersistenceService.clearActiveDelivery();
          }
        } else {
          print('âš ï¸ Ã‰tat sauvegardÃ© invalide, nettoyage...');
          // Ã‰tat invalide, nettoyer
          await StatePersistenceService.clearActiveDelivery();
        }
      } else {
        print('â„¹ï¸ Aucun Ã©tat sauvegardÃ© trouvÃ©');
      }

      // Pas d'Ã©tat sauvegardÃ© ou Ã©tat invalide, vÃ©rifier directement dans la DB
      print(
        'ðŸ” VÃ©rification directe dans la DB pour une livraison active...',
      );
      OrderModel? activeOrder;
      try {
        activeOrder = await ActiveDeliveryService.getActiveDelivery(driver.id)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                print(
                  'âš ï¸ Timeout lors de la vÃ©rification de la livraison active',
                );
                return null;
              },
            );

        // Mettre Ã  jour l'Ã©tat de livraison
        if (mounted) {
          setState(() {
            _isOnDelivery = activeOrder != null;
          });
        }
        print('ðŸ“¦ Commande active trouvÃ©e: ${activeOrder?.id}');
      } catch (e) {
        print('âŒ Erreur lors de la vÃ©rification de la livraison active: $e');
        activeOrder = null;
      }

      if (activeOrder != null && mounted) {
        // Sauvegarder l'Ã©tat
        final orderToNavigate =
            activeOrder; // Variable locale pour Ã©viter le problÃ¨me de null
        final state = ActiveDeliveryState.fromOrder(orderToNavigate);
        await StatePersistenceService.saveActiveDelivery(state);
        print('ðŸ’¾ Ã‰tat sauvegardÃ© pour commande #${orderToNavigate.id}');

        // Mettre Ã  jour l'Ã©tat avant de rediriger
        setState(() {
          _isInitializing = false;
        });

        // Rediriger vers l'Ã©cran de livraison active
        print('âœ… Redirection vers active-delivery depuis DB');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _navigateToActiveDelivery(orderToNavigate);
          }
        });
        return;
      } else {
        print('â„¹ï¸ Aucune livraison active trouvÃ©e');
      }

      // 4. Pas de livraison active, afficher le dashboard normal
      print('âœ… Initialisation du dashboard normal...');
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }

      // DÃ©marrer le suivi GPS (ne pas bloquer si Ã§a Ã©choue)
      print('ðŸ“ DÃ©marrage du suivi GPS...');
      try {
        await DriverLocationService.startLocationTracking(driver.id);
        print('âœ… Suivi GPS dÃ©marrÃ©');
      } catch (e) {
        print('âš ï¸ Erreur lors du dÃ©marrage du suivi GPS: $e');
        // Continuer mÃªme si le GPS Ã©choue
      }

      // Obtenir la position initiale (avec timeout)
      try {
        _currentPosition = await DriverLocationService.getCurrentPosition().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print(
              'âš ï¸ Timeout lors de la rÃ©cupÃ©ration de la position initiale',
            );
            return null;
          },
        );
        if (_currentPosition != null) {
          print(
            'ðŸ“ Position initiale obtenue: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
          );
        } else {
          print('âš ï¸ Position initiale non disponible');
        }
      } catch (e) {
        print('âš ï¸ Erreur lors de la rÃ©cupÃ©ration de la position: $e');
        _currentPosition = null;
      }

      // Ã‰couter les mises Ã  jour de position pour la carte
      _startListeningToPosition();

      // Ã‰couter les nouvelles commandes disponibles
      _startListeningToAvailableOrders();

      print('âœ… Initialisation du dashboard terminÃ©e');
    } catch (e, stackTrace) {
      print('âŒ Erreur lors de l\'initialisation du dashboard: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'initialisation: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    _availableOrdersSubscription?.cancel();
    _positionSubscription?.cancel();
    // Ne pas arrÃªter le GPS ici car il doit continuer mÃªme sur le dashboard
    super.dispose();
  }

  /// Ã‰couter les mises Ã  jour de position pour mettre Ã  jour la carte
  void _startListeningToPosition() {
    // Mettre Ã  jour pÃ©riodiquement (toutes les 2 secondes pour plus de fluiditÃ©)
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final position = await DriverLocationService.getCurrentPosition();
      if (position != null && mounted) {
        // Calculer la distance depuis la position prÃ©cÃ©dente
        double? distance;
        if (_previousPosition != null) {
          distance = geo.Geolocator.distanceBetween(
            _previousPosition!.latitude,
            _previousPosition!.longitude,
            position.latitude,
            position.longitude,
          );

          // Ne mettre Ã  jour le bearing que si le livreur s'est dÃ©placÃ© d'au moins 10 mÃ¨tres
          // Cela Ã©vite que le marqueur bouge quand on est stationnÃ©
          if (distance >= 10.0) {
            _currentBearing = geo.Geolocator.bearingBetween(
              _previousPosition!.latitude,
              _previousPosition!.longitude,
              position.latitude,
              position.longitude,
            );
            // Normaliser Ã  0-360
            if (_currentBearing! < 0) {
              _currentBearing = _currentBearing! + 360;
            }
          }
          // Si on est stationnÃ© (distance < 10m), garder le bearing prÃ©cÃ©dent
        }

        // Ne mettre Ã  jour le marqueur que si la position a vraiment changÃ© (au moins 3 mÃ¨tres)
        // Cela Ã©vite les mises Ã  jour inutiles qui causent des saccades
        bool shouldUpdate = false;
        if (_currentPosition == null) {
          shouldUpdate = true; // PremiÃ¨re position
        } else {
          final currentDistance = geo.Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            position.latitude,
            position.longitude,
          );
          shouldUpdate =
              currentDistance >= 3.0; // Seuil de 3 mÃ¨tres pour la fluiditÃ©
        }

        if (shouldUpdate) {
          setState(() {
            _previousPosition = _currentPosition;
            _currentPosition = position;
          });
          setState(() {});
        }
      }
    });
  }

  /// Mettre Ã  jour le marqueur du livreur sur la carte
  void _updateDriverMarkerOnMap() {
    setState(() {});
  }

  /// Naviguer vers l'Ã©cran de livraison active
  void _navigateToActiveDelivery(OrderModel order) {
    if (!mounted) {
      print('âš ï¸ Widget non montÃ©, navigation annulÃ©e');
      return;
    }

    print('ðŸš€ Navigation vers active-delivery avec commande #${order.id}');
    print(
      'ðŸ“ Order details: status=${order.status.value}, deliveryLat=${order.deliveryLat}, deliveryLng=${order.deliveryLng}',
    );

    try {
      // Utiliser go pour remplacer complÃ¨tement la route
      context.go('/active-delivery', extra: order);
      print('âœ… Navigation effectuÃ©e vers /active-delivery');
    } catch (e) {
      print('âŒ Erreur lors de la navigation: $e');
      // Fallback: utiliser pushReplacement avec MaterialPageRoute
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ActiveDeliveryScreen(order: order),
        ),
      );
      print('âœ… Navigation effectuÃ©e via MaterialPageRoute (fallback)');
    }
  }

  /// Ã‰couter les nouvelles commandes disponibles
  void _startListeningToAvailableOrders() {
    if (_currentDriver == null) return;

    print('ðŸ”” DÃ©marrage de l\'Ã©coute des commandes disponibles');
    print('ðŸ“Š Livreur disponible: $_isDriverAvailable');

    _availableOrdersSubscription = OrderStatusService.watchAvailableOrders().listen(
      (orders) {
        print('ðŸ“¦ Commandes reÃ§ues: ${orders.length} commandes');
        print('ðŸ” Livreur disponible: $_isDriverAvailable');

        // Filtrer les commandes masquÃ©es rÃ©cemment (moins de 2 minutes)
        final now = DateTime.now();
        final availableOrders = orders.where((order) {
          final dismissedAt = _dismissedOrders[order.id];
          if (dismissedAt != null) {
            final timeSinceDismissed = now.difference(dismissedAt);
            // Si moins de 2 minutes, ne pas afficher
            if (timeSinceDismissed.inMinutes < 2) {
              print(
                'â¸ï¸ Commande #${order.id} masquÃ©e rÃ©cemment, ignorÃ©e',
              );
              return false;
            } else {
              // Plus de 2 minutes, retirer de la liste des masquÃ©es
              _dismissedOrders.remove(order.id);
              print('âœ… Commande #${order.id} peut Ãªtre rÃ©affichÃ©e');
            }
          }
          return true;
        }).toList();

        // Les commandes retournÃ©es sont dÃ©jÃ  filtrÃ©es :
        // - status == 'ready_for_delivery'
        // - driver_id == null
        if (availableOrders.isNotEmpty && _isDriverAvailable) {
          print(
            'âœ… Affichage de la notification pour la commande #${availableOrders.first.id}',
          );
          // Afficher une notification pour la premiÃ¨re commande disponible
          _showNewOrderNotification(availableOrders.first);
        } else {
          if (availableOrders.isEmpty) {
            print('âš ï¸ Aucune commande disponible (aprÃ¨s filtrage)');
          }
          if (!_isDriverAvailable) {
            print(
              'âš ï¸ Livreur non disponible - Activez le switch dans le header',
            );
          }
        }
      },
      onError: (error) {
        print('âŒ Erreur dans le stream de commandes: $error');
      },
    );

    // Nettoyer pÃ©riodiquement les commandes masquÃ©es anciennes (plus de 2 minutes)
    Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final now = DateTime.now();
      _dismissedOrders.removeWhere((orderId, dismissedAt) {
        final timeSinceDismissed = now.difference(dismissedAt);
        return timeSinceDismissed.inMinutes >= 2;
      });
    });
  }

  /// Afficher une notification pour une nouvelle commande
  void _showNewOrderNotification(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isDismissible: true, // Permettre de masquer en glissant vers le bas
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderNotificationBottomSheet(
        order: order,
        onAccept: () {
          // Ne pas masquer si la commande est acceptÃ©e
          _acceptOrder(order);
        },
        onCancel: () {
          // L'utilisateur a masquÃ© la commande en glissant vers le bas
          _dismissOrder(order.id);
        },
      ),
    ).then((value) {
      // Quand le bottom sheet est fermÃ© (glissÃ© vers le bas), masquer la commande
      // onCancel sera appelÃ© automatiquement par le widget
    });
  }

  /// Masquer une commande temporairement (2 minutes)
  void _dismissOrder(int orderId) {
    setState(() {
      _dismissedOrders[orderId] = DateTime.now();
    });
    print(
      'â¸ï¸ Commande #$orderId masquÃ©e, rÃ©affichage dans 2 minutes si non acceptÃ©e',
    );
  }

  /// Accepter une commande
  Future<void> _acceptOrder(OrderModel order) async {
    if (_currentDriver == null) return;

    try {
      // VÃ©rifier qu'il n'y a pas dÃ©jÃ  une livraison active
      final activeDelivery = await ActiveDeliveryService.getActiveDelivery(
        _currentDriver!.id,
      );

      // Mettre Ã  jour l'Ã©tat de livraison
      if (mounted) {
        setState(() {
          _isOnDelivery = activeDelivery != null;
        });
      }

      if (activeDelivery != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous avez dÃ©jÃ  une livraison en cours'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Accepter la commande
      final accepted = await OrderService.acceptOrder(
        order.id,
        _currentDriver!.id,
      );

      if (accepted) {
        // RÃ©cupÃ©rer la commande mise Ã  jour
        final updatedOrder = await OrderService.getOrderDetails(order.id);

        if (updatedOrder != null) {
          print('âœ… Commande acceptÃ©e avec succÃ¨s: #${updatedOrder.id}');

          // Mettre Ã  jour l'Ã©tat de livraison
          if (mounted) {
            setState(() {
              _isOnDelivery = true;
            });
          }

          // Sauvegarder l'Ã©tat
          final state = ActiveDeliveryState.fromOrder(updatedOrder);
          await StatePersistenceService.saveActiveDelivery(state);
          print('ðŸ’¾ Ã‰tat sauvegardÃ© pour commande #${updatedOrder.id}');

          // Rediriger vers l'Ã©cran de livraison active
          if (mounted) {
            print('ðŸš€ Navigation vers active-delivery...');
            _navigateToActiveDelivery(updatedOrder);
          }
        } else {
          print(
            'âŒ Commande acceptÃ©e mais impossible de rÃ©cupÃ©rer les dÃ©tails',
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cette commande a dÃ©jÃ  Ã©tÃ© acceptÃ©e par un autre livreur',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('âŒ Erreur lors de l\'acceptation de la commande: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      // Pas d'AppBar, on utilise un header personnalisÃ©
      body: Stack(
        children: [
          // CARTE PLEIN Ã‰CRAN
          _buildMapView(),

          // OVERLAY SI INDISPONIBLE (en dessous du header)
          if (!_isDriverAvailable) _buildUnavailableOverlay(),

          // NOUVEAU HEADER (menu gauche, statut centre, service client droite)
          _buildNewHeader(),

          // BOUTON POUR ACTUALISER (en bas Ã  gauche)
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh),
                color: Colors.blue[700],
                onPressed: _refreshDashboard,
                tooltip: 'Actualiser',
              ),
            ),
          ),

          // BOUTON POUR RECENTRER LA CARTE (en bas Ã  droite)
          if (_mapController != null)
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.my_location, color: Colors.blue[700]),
                  onPressed: _centerMapOnDriverPosition,
                  tooltip: 'Recentrer la carte',
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Carte OSM plein écran
  Widget _buildMapView() {
    final center = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : LatLng(OsmConfig.defaultLat, OsmConfig.defaultLng);
    return OsmMapWidget(
      initialCenter: center,
      initialZoom: OsmConfig.defaultZoom,
      onMapCreated: _onMapCreated,
      markers: _buildDashboardMarkers(),
    );
  }

  List<Marker> _buildDashboardMarkers() {
    if (_currentPosition == null) return [];
    return [
      Marker(
        point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        width: 40,
        height: 40,
        child: const Icon(Icons.delivery_dining, color: Colors.blue, size: 40),
      ),
    ];
  }

  /// Initialisation de la carte
  void _onMapCreated(MapController controller) {
    _mapController = controller;

    try {
      // Si on a dÃ©jÃ  une position, ajouter le marqueur et centrer
      if (_currentPosition != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _centerMapOnDriverPosition();
        });
      } else {
        // Attendre un peu et rÃ©essayer si la position n'est pas encore disponible
        Future.delayed(const Duration(seconds: 1), () async {
          if (mounted && _currentPosition == null) {
            final position = await DriverLocationService.getCurrentPosition();
            if (position != null && mounted) {
              setState(() {
                _currentPosition = position;
              });
              _centerMapOnDriverPosition();
            }
          }
        });
      }
    } catch (e) {
      print('âŒ Erreur initialisation carte: $e');
    }
  }

  /// Centrer la carte sur la position du livreur
  Future<void> _centerMapOnDriverPosition() async {
    // Obtenir la position actuelle si elle n'est pas disponible
    if (_currentPosition == null) {
      final position = await DriverLocationService.getCurrentPosition();
      if (position != null && mounted) {
        setState(() {
          _currentPosition = position;
        });
      } else {
        print('âš ï¸ Position non disponible pour centrer la carte');
        return;
      }
    }

    if (_mapController == null || _currentPosition == null) {
      print('âš ï¸ Carte ou position non disponible');
      return;
    }

    try {
      print(
        'ðŸ“ Centrage de la carte sur: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
      );

      _mapController!.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        15.0,
      );

      print('âœ… Carte centrÃ©e sur la position du livreur');

      // Afficher un feedback visuel
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Carte recentrÃ©e sur votre position'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('âŒ Erreur centrage carte: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du centrage: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Nouveau header avec menu gauche, statut centre, service client droite
  Widget _buildNewHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Bouton menu Ã  gauche
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  // TODO: Ouvrir le menu latÃ©ral
                  Scaffold.of(context).openDrawer();
                },
                color: Colors.black87,
              ),
            ),

            // Card statut au centre
            StatusCard(
              isAvailable: _isDriverAvailable,
              isOnDelivery: _isOnDelivery,
              onToggle: _isOnDelivery ? null : _toggleAvailability,
              canToggle: !_isOnDelivery,
            ),

            // Bouton service client Ã  droite
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.headset_mic),
                onPressed: _showCustomerServiceModal,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Afficher le modal de service client
  void _showCustomerServiceModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CustomerServiceModal(),
    );
  }

  /// Overlay si le livreur est indisponible
  Widget _buildUnavailableOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pause_circle_outline,
              size: 80,
              color: Colors.white.withOpacity(0.8),
            ),
            const SizedBox(height: 20),
            const Text(
              'Mode Indisponible',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Vous ne recevrez pas de nouvelles commandes',
              style: TextStyle(fontSize: 16, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Toggle la disponibilitÃ© du livreur
  Future<void> _toggleAvailability(bool value) async {
    if (_currentDriver == null) return;

    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('drivers')
          .update({
            'is_available': value,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _currentDriver!.id);

      setState(() {
        _isDriverAvailable = value;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Vous Ãªtes maintenant disponible'
                : 'Vous Ãªtes maintenant indisponible',
          ),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      print('âŒ Erreur lors de la mise Ã  jour de la disponibilitÃ©: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
