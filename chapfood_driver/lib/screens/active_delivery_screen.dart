import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../widgets/map/mapbox_map_widget.dart';
import '../widgets/map/mapbox_directional_marker.dart';
import '../config/mapbox_config.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:url_launcher/url_launcher.dart';
import '../services/active_delivery_service.dart';
import '../services/session_service.dart';
import '../services/state_persistence_service.dart';
import '../services/driver_location_service.dart';
import '../services/mapbox_routing_service.dart' as routing;
import '../services/smooth_movement_service.dart';
import '../models/order_model.dart';
import '../models/active_delivery_state.dart';
import '../models/driver_model.dart';
import '../widgets/delivery/delivery_status_card.dart';
import '../widgets/delivery/delivery_actions_panel.dart';
import '../widgets/delivery/delivery_completion_modal.dart';
import '../widgets/delivery/route_progress_card.dart';
import '../widgets/map/directional_marker.dart';

/// Ã‰cran dÃ©diÃ© Ã  la livraison active avec carte et suivi en temps rÃ©el
class ActiveDeliveryScreen extends StatefulWidget {
  final OrderModel order;

  const ActiveDeliveryScreen({super.key, required this.order});

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  OrderModel? _currentOrder;
  bool _hasPickedUp = false;
  bool _hasArrived = false;
  bool _isLoading = true;
  StreamSubscription<OrderModel>? _orderSubscription;
  StreamSubscription<geo.Position>? _positionSubscription;
  DriverModel? _currentDriver;

  // Ã‰tat pour la carte
  MapboxMap? _mapController;
  MapboxAnnotationHelper? _annotationHelper;
  MapboxCameraHelper? _cameraHelper;
  geo.Position? _currentPosition;
  // Les marqueurs et polylines sont maintenant gérés via MapboxAnnotationHelper
  routing.RouteInfo? _currentRoute;
  Timer? _routeUpdateTimer;

  // CoordonnÃ©es du restaurant (en dur)
  static const double restaurantLat = 5.226313;
  static const double restaurantLng = -3.768063;

  // Service pour lisser le mouvement du livreur (marker fluide)
  final SmoothMovementService _smoothMovementService = SmoothMovementService();

  // Ã‰tat pour le mode 3D
  bool _is3DMode = true; // ActivÃ© par dÃ©faut
  geo.Position?
  _previousPosition; // Position prÃ©cÃ©dente pour calculer le bearing
  double? _currentBearing; // Bearing actuel calculÃ©

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _initializeDelivery();
  }

  Future<void> _initializeDelivery() async {
    try {
      // Activer automatiquement le mode 3D
      _is3DMode = true;
      _previousPosition = null;
      _currentBearing = null;

      final driver = await SessionService.getCurrentDriver();
      if (driver == null) {
        if (mounted) {
          context.go('/login');
        }
        return;
      }

      setState(() {
        _currentDriver = driver;
      });

      // Charger les informations de l'assignation
      await _loadAssignmentInfo();

      // Ã‰couter les changements de statut en temps rÃ©el
      _orderSubscription =
          ActiveDeliveryService.watchActiveDelivery(_currentOrder!.id).listen((
            order,
          ) {
            if (mounted) {
              setState(() {
                _currentOrder = order;
              });
              _loadAssignmentInfo();
            }
          });

      // DÃ©marrer le suivi GPS
      await DriverLocationService.startLocationTracking(driver.id);

      // Obtenir la position initiale
      final initialPosition = await DriverLocationService.getCurrentPosition();
      if (initialPosition != null) {
        setState(() {
          _currentPosition = initialPosition;
        });
      }

      // S'assurer que la carte est initialisÃ©e avant d'afficher les marqueurs
      // Si la carte n'est pas encore crÃ©Ã©e, attendre un peu
      if (_mapController == null) {
        await Future.delayed(const Duration(milliseconds: 1000));
      }

      // RÃ©initialiser les marqueurs et itinÃ©raires selon l'Ã©tape actuelle
      if (_mapController != null) {
        if (!_hasPickedUp) {
          // Ã‰tape 1 : Aller au restaurant
          print('ðŸ”„ RÃ©initialisation : Ã‰tape 1 - Restaurant');
          await _addRestaurantMarker(restaurantLat, restaurantLng);
          if (_currentPosition != null) {
            await _calculateAndDisplayRouteToRestaurant();
          }
        } else {
          // Ã‰tape 2 : Aller au client
          print('ðŸ”„ RÃ©initialisation : Ã‰tape 2 - Client');
          if (_currentOrder?.deliveryLat != null &&
              _currentOrder?.deliveryLng != null) {
            await _addClientMarker(
              _currentOrder!.deliveryLat!,
              _currentOrder!.deliveryLng!,
            );
            if (_currentPosition != null) {
              await _calculateAndDisplayRouteToClient();
            }
          }
        }
      }

      // Stream brut du GPS
      final rawPositionStream = geo.Geolocator.getPositionStream(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          distanceFilter: 3, // Mettre Ã  jour tous les ~3 mÃ¨tres
        ),
      );

      // DÃ©marrer le service de mouvement fluide
      _smoothMovementService.startSmoothTracking(rawPositionStream);

      // Ã‰couter les positions FLUIDES pour animer le marker
      _positionSubscription = _smoothMovementService.positionStream.listen(
        (position) {
          if (!mounted) return;

          setState(() {
            _currentPosition = position;
          });

          // Mettre Ã  jour le marker du livreur (sans saut)
          await _updateDriverMarker();

          // Mettre Ã  jour l'itinÃ©raire si nÃ©cessaire selon l'Ã©tape
          if (!_hasPickedUp) {
            // Ã‰tape 1 : vers le restaurant
            _updateRoute();
          } else if (_currentOrder?.deliveryLat != null &&
              _currentOrder?.deliveryLng != null) {
            // Ã‰tape 2 : vers le client
            _updateRoute();
          }
        },
        onError: (error) {
          print(
            'âŒ Erreur dans le suivi de position fluide (active_delivery): $error',
          );
        },
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('âŒ Erreur lors de l\'initialisation: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    _positionSubscription?.cancel();
    _routeUpdateTimer?.cancel();
    _smoothMovementService.stopSmoothTracking();
    // ArrÃªter le suivi GPS si nÃ©cessaire
    if (_currentDriver != null) {
      DriverLocationService.stopLocationTracking();
    }
    super.dispose();
  }

  Future<void> _loadAssignmentInfo() async {
    try {
      final assignment = await ActiveDeliveryService.getAssignmentInfo(
        _currentOrder!.id,
      );

      if (assignment != null && mounted) {
        final wasPickedUp = _hasPickedUp;

        // VÃ©rifier aussi le statut de la commande dans la DB
        final orderStatus = _currentOrder?.status.value;
        final isPickedUpInDB = orderStatus == 'picked_up';
        final hasPickedUpAt = assignment.pickedUpAt != null;

        // _hasPickedUp doit Ãªtre true si soit picked_up_at existe, soit le statut est 'picked_up'
        final shouldBePickedUp = hasPickedUpAt || isPickedUpInDB;

        setState(() {
          _hasPickedUp = shouldBePickedUp;
          _hasArrived = assignment.arrivedAt != null;
        });

        print(
          'ðŸ“‹ Ã‰tat assignation : picked_up_at = ${assignment.pickedUpAt}, statut DB = $orderStatus',
        );
        print('ðŸ“‹ _hasPickedUp mis Ã  jour Ã  : $shouldBePickedUp');

        // Si on passe de "pas rÃ©cupÃ©rÃ©" Ã  "rÃ©cupÃ©rÃ©" (mÃªme si changÃ© par l'admin)
        if (!wasPickedUp && _hasPickedUp && _mapController != null) {
          // Supprimer le marqueur du restaurant via MapboxAnnotationHelper
          if (_annotationHelper != null) {
            await _annotationHelper!.removePointAnnotation('restaurant');
          }

          // Supprimer le tracÃ© vers le restaurant
          // Supprimer le tracé vers le restaurant via MapboxAnnotationHelper
          if (_annotationHelper != null) {
            await _annotationHelper!.removePolyline('route-to-restaurant');
          }

          // Ajouter le marqueur du client et calculer l'itinÃ©raire vers le client
          if (_currentOrder!.deliveryLat != null &&
              _currentOrder!.deliveryLng != null) {
            await _addClientMarker(
              _currentOrder!.deliveryLat!,
              _currentOrder!.deliveryLng!,
            );
            await _calculateAndDisplayRouteToClient();
          }
        }
      }
    } catch (e) {
      print('âŒ Erreur lors du chargement de l\'assignation: $e');
    }
  }

  /// Initialisation de la carte Google Maps
  Future<void> _onMapCreated(MapboxMap controller) async {
    _mapController = controller;
    _annotationHelper = MapboxAnnotationHelper(controller);
    _cameraHelper = MapboxCameraHelper(controller);
    await _annotationHelper!.initialize();
    _mapController = controller;

    // Plus besoin de charger les images de marqueurs, MapboxAnnotationHelper gère les annotations

    // Initialiser les marqueurs et l'itinÃ©raire
    if (_currentPosition != null) {
      await _updateDriverMarker();
    }

    // Attendre un peu pour s'assurer que _loadAssignmentInfo() a terminÃ©
    await Future.delayed(const Duration(milliseconds: 500));

    // DÃ©terminer l'Ã©tape actuelle
    print('ðŸ” Ã‰tat actuel : _hasPickedUp = $_hasPickedUp');
    print('ðŸ” Statut de la commande : ${_currentOrder?.status.value}');

    // S'assurer que si le statut n'est pas 'picked_up', on est Ã  l'Ã©tape 1
    final isPickedUpInDB = _currentOrder?.status.value == 'picked_up';
    if (isPickedUpInDB && !_hasPickedUp) {
      print(
        'âš ï¸ IncohÃ©rence dÃ©tectÃ©e : statut DB = picked_up mais _hasPickedUp = false',
      );
      print('   Correction de l\'Ã©tat local...');
      setState(() {
        _hasPickedUp = true;
      });
    }

    if (!_hasPickedUp && !isPickedUpInDB) {
      // Ã‰tape 1 : Aller au restaurant
      print('ðŸ“ Ã‰tape 1 : Affichage du restaurant et tracÃ© vers le restaurant');
      // S'assurer qu'on supprime d'abord tout tracÃ© vers le client s'il existe
      // _polylines.removeWhere(
        (p) => p.polylineId == const PolylineId('route-to-client'),
      );
      // _markers.removeWhere((m) => m.markerId == const MarkerId('client'));
      print('ðŸ—‘ï¸ TracÃ© et marqueur client supprimÃ©s (Ã©tape 1)');

      await _addRestaurantMarker(restaurantLat, restaurantLng);
      if (_currentPosition != null) {
        await _calculateAndDisplayRouteToRestaurant();
      }
    } else {
      // Ã‰tape 2 : Aller au client
      print('ðŸ“ Ã‰tape 2 : Affichage du client et tracÃ© vers le client');
      // S'assurer qu'on supprime le marqueur et tracé du restaurant
      if (_annotationHelper != null) {
        await _annotationHelper!.removePointAnnotation('restaurant');
        await _annotationHelper!.removePolyline('route-to-restaurant');
      }
      print('ðŸ—‘ï¸ Marqueur et tracÃ© restaurant supprimÃ©s (Ã©tape 2)');

      if (_currentOrder?.deliveryLat != null &&
          _currentOrder?.deliveryLng != null) {
        await _addClientMarker(
          _currentOrder!.deliveryLat!,
          _currentOrder!.deliveryLng!,
        );
        if (_currentPosition != null) {
          await _calculateAndDisplayRouteToClient();
        }
      }
    }
  }

  /// Charger les images de marqueurs (cercles colorÃ©s simples)
  // Plus besoin de charger les images de marqueurs, MapboxAnnotationHelper gère les annotations directement

  /// Calculer le bearing (direction) entre deux positions GPS
  double _calculateBearing(geo.Position previous, geo.Position current) {
    final dLng = (current.longitude - previous.longitude) * (math.pi / 180);
    final lat1Rad = previous.latitude * (math.pi / 180);
    final lat2Rad = current.latitude * (math.pi / 180);

    final y = math.sin(dLng) * math.cos(lat2Rad);
    final x =
        math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLng);

    double bearing = math.atan2(y, x);
    bearing = bearing * (180 / math.pi);

    return (bearing + 360) % 360; // Normaliser Ã  0-360Â°
  }

  /// Mettre Ã  jour le marqueur du livreur
  Future<void> _updateDriverMarker() async {
    if (_mapController == null || _currentPosition == null) return;

    try {
      // Calculer le bearing si on a une position prÃ©cÃ©dente et que le mode 3D est activÃ©
      if (_is3DMode && _previousPosition != null) {
        final distance = geo.Geolocator.distanceBetween(
          _previousPosition!.latitude,
          _previousPosition!.longitude,
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );

        // Ne calculer le bearing que si le livreur s'est dÃ©placÃ© d'au moins 5 mÃ¨tres
        if (distance >= 5.0) {
          _currentBearing = _calculateBearing(
            _previousPosition!,
            _currentPosition!,
          );
          print('ðŸ§­ Bearing calculÃ©: ${_currentBearing!.toStringAsFixed(1)}Â°');
        }
      }

      // Calculer le bearing pour l'effet directionnel
      // Ne mettre Ã  jour le bearing que si on s'est vraiment dÃ©placÃ© (au moins 10 mÃ¨tres)
      double bearing = _currentBearing ?? 0.0;
      if (_previousPosition != null) {
        final distance = geo.Geolocator.distanceBetween(
          _previousPosition!.latitude,
          _previousPosition!.longitude,
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );

        // Ne calculer le bearing que si on s'est dÃ©placÃ© d'au moins 10 mÃ¨tres
        // Cela Ã©vite que le marqueur bouge quand on est stationnÃ©
        if (distance >= 10.0) {
          bearing = _calculateBearing(_previousPosition!, _currentPosition!);
          _currentBearing = bearing; // Sauvegarder le bearing
        }
        // Sinon, utiliser le bearing prÃ©cÃ©dent pour Ã©viter les mouvements erratiques
      }

      // Supprimer l'ancien marqueur via MapboxAnnotationHelper
      if (_annotationHelper != null) {
        await _annotationHelper!.removePointAnnotation('driver');
      }

      // Ajouter/mettre à jour le marqueur via MapboxAnnotationHelper
      if (_annotationHelper != null) {
        await _annotationHelper!.addOrUpdatePointAnnotation(
          id: 'driver',
          lat: _currentPosition!.latitude,
          lng: _currentPosition!.longitude,
          iconColor: MapboxConfig.driverMarkerColor,
        );
      }

      // Centrer la carte sur la position du livreur avec mode 3D
      if (_cameraHelper != null) {
        await _cameraHelper!.animateTo(
          lat: _currentPosition!.latitude,
          lng: _currentPosition!.longitude,
          zoom: _is3DMode ? 18.0 : 15.0,
          pitch: _is3DMode ? 60.0 : 0.0,
          bearing: (_is3DMode && _currentBearing != null)
              ? _currentBearing!
              : 0.0,
        );
      }

      // Stocker la position actuelle comme position prÃ©cÃ©dente
      _previousPosition = _currentPosition;
    } catch (e) {
      print('âŒ Erreur lors de la mise Ã  jour du marqueur livreur: $e');
    }
  }

  /// Ajouter le marqueur du restaurant
  Future<void> _addRestaurantMarker(double lat, double lng) async {
    if (_mapController == null) return;

    try {
      print('ðŸ“ Ajout du marqueur restaurant Ã : lat=$lat, lng=$lng');

      // Ajouter/mettre à jour le marqueur via MapboxAnnotationHelper
      if (_annotationHelper != null) {
        await _annotationHelper!.addOrUpdatePointAnnotation(
          id: 'restaurant',
          lat: lat,
          lng: lng,
          iconColor: MapboxConfig.restaurantMarkerColor,
        );
      }

      print('✅ Marqueur restaurant ajouté à Position($lat, $lng)');
    } catch (e) {
      print('âŒ Erreur lors de l\'ajout du marqueur restaurant: $e');
    }
  }

  /// Ajouter le marqueur du client
  Future<void> _addClientMarker(double lat, double lng) async {
    if (_mapController == null) return;

    try {
      print('ðŸ“ Ajout du marqueur client Ã : lat=$lat, lng=$lng');

      // VÃ©rifier si les coordonnÃ©es sont valides
      if (lat < 4.0 || lat > 6.0 || lng < -5.0 || lng > -3.0) {
        print(
          'âš ï¸ ATTENTION: CoordonnÃ©es client suspectes (hors de Grand-Bassam)',
        );
        print(
          '   VÃ©rifiez si les coordonnÃ©es ne sont pas inversÃ©es dans la base de donnÃ©es',
        );
      }

      // Ajouter/mettre à jour le marqueur via MapboxAnnotationHelper
      if (_annotationHelper != null) {
        await _annotationHelper!.addOrUpdatePointAnnotation(
          id: 'client',
          lat: lat,
          lng: lng,
          iconColor: MapboxConfig.clientMarkerColor,
        );
      }

      print('✅ Marqueur client ajouté à Position($lat, $lng)');
    } catch (e) {
      print('âŒ Erreur lors de l\'ajout du marqueur client: $e');
    }
  }

  /// Calculer et afficher l'itinÃ©raire vers le restaurant (Ã‰tape 1)
  Future<void> _calculateAndDisplayRouteToRestaurant() async {
    if (_currentPosition == null) {
      print(
        'âŒ Position livreur manquante pour calculer l\'itinÃ©raire vers le restaurant',
      );
      return;
    }

    try {
      print('ðŸ—ºï¸ Calcul de l\'itinÃ©raire vers le restaurant...');
      print(
        'ðŸ“ Position livreur: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
      );
      print('ðŸ“ Position restaurant: $restaurantLat, $restaurantLng');

      final route = await MapboxRoutingService.getRoute(
        startLat: _currentPosition!.latitude,
        startLng: _currentPosition!.longitude,
        endLat: restaurantLat,
        endLng: restaurantLng,
      );

      if (route != null) {
        setState(() {
          _currentRoute = route;
        });

        print('ðŸ“Š Route calculÃ©e avec ${route.coordinates.length} points');
        if (route.coordinates.length < 10) {
          print(
            'âš ï¸ ATTENTION: Route avec peu de points (${route.coordinates.length}), peut apparaÃ®tre rectiligne',
          );
        }

        await _drawRouteToRestaurant(route.coordinates);
        await _centerMapOnRoute(route.coordinates);

        print(
          'âœ… ItinÃ©raire vers restaurant affichÃ©: ${route.formattedDistance} â€¢ ${route.formattedDuration}',
        );

        // DÃ©marrer la mise Ã  jour pÃ©riodique de l'itinÃ©raire
        _startRouteUpdateTimer();
      } else {
        print('âŒ Impossible de calculer l\'itinÃ©raire vers le restaurant');
        // Fallback: ligne droite
        await _drawFallbackRouteToRestaurant();
      }
    } catch (e) {
      print('âŒ Erreur calcul itinÃ©raire vers restaurant: $e');
      await _drawFallbackRouteToRestaurant();
    }
  }

  /// Calculer et afficher l'itinÃ©raire vers le client (Ã‰tape 2)
  Future<void> _calculateAndDisplayRouteToClient() async {
    if (_currentPosition == null ||
        _currentOrder?.deliveryLat == null ||
        _currentOrder?.deliveryLng == null) {
      print(
        'âŒ Positions manquantes pour calculer l\'itinÃ©raire vers le client',
      );
      print(
        '   Position livreur: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}',
      );
      print(
        '   Position client: ${_currentOrder?.deliveryLat}, ${_currentOrder?.deliveryLng}',
      );
      return;
    }

    try {
      print('ðŸ—ºï¸ Calcul de l\'itinÃ©raire vers le client...');
      print(
        'ðŸ“ Position livreur: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
      );
      print(
        'ðŸ“ Position client (deliveryLat/deliveryLng): ${_currentOrder!.deliveryLat}, ${_currentOrder!.deliveryLng}',
      );

      // VÃ©rifier si les coordonnÃ©es sont valides (Grand-Bassam est environ 5.2, -4.2)
      if (_currentOrder!.deliveryLat! < 4.0 ||
          _currentOrder!.deliveryLat! > 6.0 ||
          _currentOrder!.deliveryLng! < -5.0 ||
          _currentOrder!.deliveryLng! > -3.0) {
        print(
          'âš ï¸ ATTENTION: CoordonnÃ©es de livraison suspectes (hors de Grand-Bassam)',
        );
        print('   Les coordonnÃ©es semblent incorrectes ou inversÃ©es');
      }

      final route = await MapboxRoutingService.getRoute(
        startLat: _currentPosition!.latitude,
        startLng: _currentPosition!.longitude,
        endLat: _currentOrder!.deliveryLat!,
        endLng: _currentOrder!.deliveryLng!,
      );

      if (route != null) {
        setState(() {
          _currentRoute = route;
        });

        print('ðŸ“Š Route calculÃ©e avec ${route.coordinates.length} points');
        if (route.coordinates.length < 10) {
          print(
            'âš ï¸ ATTENTION: Route avec peu de points (${route.coordinates.length}), peut apparaÃ®tre rectiligne',
          );
        }

        await _drawRouteToClient(route.coordinates);
        await _centerMapOnRoute(route.coordinates);

        print(
          'âœ… ItinÃ©raire vers client affichÃ©: ${route.formattedDistance} â€¢ ${route.formattedDuration}',
        );

        // DÃ©marrer la mise Ã  jour pÃ©riodique de l'itinÃ©raire
        _startRouteUpdateTimer();
      } else {
        print('âŒ Impossible de calculer l\'itinÃ©raire vers le client');
        // Fallback: ligne droite
        await _drawFallbackRouteToClient();
      }
    } catch (e) {
      print('âŒ Erreur calcul itinÃ©raire vers client: $e');
      await _drawFallbackRouteToClient();
    }
  }

  /// Mettre Ã  jour l'itinÃ©raire (appelÃ© pÃ©riodiquement)
  Future<void> _updateRoute() async {
    if (_currentPosition == null) return;

    // Mettre Ã  jour l'itinÃ©raire toutes les 30 secondes selon l'Ã©tape
    _routeUpdateTimer?.cancel();
    _routeUpdateTimer = Timer(const Duration(seconds: 30), () {
      if (!_hasPickedUp) {
        _calculateAndDisplayRouteToRestaurant();
      } else if (_currentOrder?.deliveryLat != null &&
          _currentOrder?.deliveryLng != null) {
        _calculateAndDisplayRouteToClient();
      }
    });
  }

  /// DÃ©marrer le timer de mise Ã  jour de l'itinÃ©raire
  void _startRouteUpdateTimer() {
    _routeUpdateTimer?.cancel();
    _routeUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_currentPosition != null) {
        if (!_hasPickedUp) {
          // Ã‰tape 1 : vers le restaurant
          _calculateAndDisplayRouteToRestaurant();
        } else if (_currentOrder?.deliveryLat != null &&
            _currentOrder?.deliveryLng != null) {
          // Ã‰tape 2 : vers le client
          _calculateAndDisplayRouteToClient();
        } else {
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  /// Dessiner l'itinÃ©raire vers le restaurant sur la carte
  Future<void> _drawRouteToRestaurant(List<routing.Position> coordinates) async {
    if (_mapController == null || _annotationHelper == null) return;

    try {
      // Dessiner la route via MapboxAnnotationHelper
      await _annotationHelper!.addOrUpdatePolyline(
        id: 'route-to-restaurant',
        coordinates: coordinates,
        lineColor: 0xFFFF6B35, // Orange
        lineWidth: 5.0,
      );
      
      // Supprimer l'ancienne route vers le client si elle existe
      await _annotationHelper!.removePolyline('route-to-client');
    } catch (e) {
      print('âŒ Erreur lors du dessin de l\'itinÃ©raire vers le restaurant: $e');
    }
  }

  /// Dessiner l'itinéraire vers le client sur la carte
  Future<void> _drawRouteToClient(List<routing.Position> coordinates) async {
    if (_mapController == null || _annotationHelper == null) return;

    try {
      // Dessiner la route via MapboxAnnotationHelper
      await _annotationHelper!.addOrUpdatePolyline(
        id: 'route-to-client',
        coordinates: coordinates,
        lineColor: 0xFF4CAF50, // Vert pour différencier du restaurant
        lineWidth: 5.0,
      );
      
      // Supprimer l'ancienne route vers le restaurant si elle existe
      await _annotationHelper!.removePolyline('route-to-restaurant');
    } catch (e) {
      print('âŒ Erreur lors du dessin de l\'itinÃ©raire vers le client: $e');
    }
  }

  /// Itinéraire de secours vers le restaurant (ligne droite)
  Future<void> _drawFallbackRouteToRestaurant() async {
    if (_currentPosition == null) return;

    final fallbackRoute = [
      Position(_currentPosition!.longitude, _currentPosition!.latitude),
      Position(restaurantLng, restaurantLat),
    ];

    await _drawRouteToRestaurant(fallbackRoute);
    print(
      'âš ï¸ Utilisation de l\'itinÃ©raire de secours vers le restaurant (ligne droite)',
    );
  }

  /// Itinéraire de secours vers le client (ligne droite)
  Future<void> _drawFallbackRouteToClient() async {
    if (_currentPosition == null ||
        _currentOrder?.deliveryLat == null ||
        _currentOrder?.deliveryLng == null)
      return;

    final fallbackRoute = [
      Position(_currentPosition!.longitude, _currentPosition!.latitude),
      Position(_currentOrder!.deliveryLng!, _currentOrder!.deliveryLat!),
    ];

    await _drawRouteToClient(fallbackRoute);
    print(
      'âš ï¸ Utilisation de l\'itinÃ©raire de secours vers le client (ligne droite)',
    );
  }

  /// Centrer la carte sur l'itinÃ©raire
  Future<void> _centerMapOnRoute(List<routing.Position> coordinates) async {
    if (_mapController == null || _cameraHelper == null || coordinates.isEmpty) return;

    try {
      // Utiliser MapboxCameraHelper pour centrer la carte sur la route
      await _cameraHelper!.fitBounds(
        coordinates: coordinates,
        padding: const EdgeInsets.all(50),
        durationMs: 1000,
      );
      
      print('✅ Carte centrée sur la route avec ${coordinates.length} points');
    } catch (e) {
      print('âŒ Erreur lors du centrage sur l\'itinÃ©raire: $e');
    }
  }

  Future<void> _markAsPickedUp() async {
    if (_currentDriver == null || _currentOrder == null) return;

    try {
      final success = await ActiveDeliveryService.markAsPickedUp(
        _currentOrder!.id,
        _currentDriver!.id,
      );

      if (success && mounted) {
        setState(() {
          _hasPickedUp = true;
        });

        // Supprimer le marqueur du restaurant via MapboxAnnotationHelper
        if (_annotationHelper != null) {
          await _annotationHelper!.removePointAnnotation('restaurant');
        }

        // Supprimer le tracé vers le restaurant via MapboxAnnotationHelper
        if (_annotationHelper != null) {
          await _annotationHelper!.removePolyline('route-to-restaurant');
        }

        // Ajouter le marqueur du client et calculer l'itinÃ©raire vers le client
        if (_currentOrder!.deliveryLat != null &&
            _currentOrder!.deliveryLng != null) {
          await _addClientMarker(
            _currentOrder!.deliveryLat!,
            _currentOrder!.deliveryLng!,
          );
          await _calculateAndDisplayRouteToClient();
        }

        final state = ActiveDeliveryState.fromOrder(
          _currentOrder!,
          hasPickedUp: true,
        );
        await StatePersistenceService.saveActiveDelivery(state);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande rÃ©cupÃ©rÃ©e ! Direction le client'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('âŒ Erreur: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _markAsArrived() async {
    if (_currentDriver == null || _currentOrder == null) return;

    try {
      final success = await ActiveDeliveryService.markAsArrived(
        _currentOrder!.id,
        _currentDriver!.id,
      );

      if (success && mounted) {
        setState(() {
          _hasArrived = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous Ãªtes arrivÃ© au point de livraison'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('âŒ Erreur: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showCompletionModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) => DeliveryCompletionModal(
        onQRCodeSelected: _scanQRCode,
        onCodeSelected: _enterDeliveryCode,
      ),
    );
  }

  void _scanQRCode() {
    final qrController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scanner le QR code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Entrez le code QR scannÃ© (format: order:123)',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: qrController,
              decoration: const InputDecoration(
                hintText: 'order:123',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            const Text(
              'Ou utilisez l\'appareil photo pour scanner',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final qrCode = qrController.text.trim();
              if (qrCode.isNotEmpty) {
                Navigator.pop(context);
                await _completeDelivery(qrCode: qrCode);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez entrer un code QR'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _enterDeliveryCode() {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Code de confirmation'),
        content: TextField(
          controller: codeController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Entrez le code Ã  6 chiffres',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.length == 6 && RegExp(r'^[0-9]{6}$').hasMatch(code)) {
                Navigator.pop(context);
                await _completeDelivery(code: code);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Le code doit contenir 6 chiffres'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  /// Appeler le client
  Future<void> _callCustomer(String phoneNumber) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        print('âœ… Appel lancÃ© vers: $phoneNumber');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'ouvrir l\'application tÃ©lÃ©phone'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('âŒ Erreur lors de l\'appel: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Basculer entre mode 2D et 3D
  Future<void> _toggle3DMode() async {
    setState(() {
      _is3DMode = !_is3DMode;
    });

    print('ðŸ”„ Mode 3D ${_is3DMode ? "activÃ©" : "dÃ©sactivÃ©"}');

    // Réappliquer les paramètres de caméra immédiatement
    if (_mapController != null && _cameraHelper != null && _currentPosition != null) {
      await _cameraHelper!.animateTo(
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
        zoom: _is3DMode ? 18.0 : 15.0, // Zoom plus élevé en mode 3D
        pitch: _is3DMode ? 60.0 : 0.0,
        bearing: (_is3DMode && _currentBearing != null)
            ? _currentBearing!
            : 0.0,
      );
    }
  }

  Future<void> _completeDelivery({String? code, String? qrCode}) async {
    if (_currentDriver == null || _currentOrder == null) return;

    try {
      // DÃ©sactiver le mode 3D avant de quitter
      _is3DMode = false;
      _previousPosition = null;
      _currentBearing = null;

      final success = await ActiveDeliveryService.completeDelivery(
        _currentOrder!.id,
        _currentDriver!.id,
        deliveryCode: code,
        qrCode: qrCode,
      );

      if (success && mounted) {
        await StatePersistenceService.clearActiveDelivery();
        await DriverLocationService.stopLocationTracking();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Livraison finalisÃ©e avec succÃ¨s !'),
            backgroundColor: Colors.green,
          ),
        );

        context.go('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code invalide ou expirÃ©'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('âŒ Erreur: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentOrder == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: const Center(child: Text('Commande introuvable')),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Carte pleine écran
          MapboxMapWidget(
            key: const ValueKey('map'),
            initialPosition: _currentPosition ??
                (_currentOrder!.deliveryLat != null &&
                        _currentOrder!.deliveryLng != null
                    ? geo.Position(
                        latitude: _currentOrder!.deliveryLat!,
                        longitude: _currentOrder!.deliveryLng!,
                        timestamp: DateTime.now(),
                        accuracy: 0,
                        altitude: 0,
                        heading: 0,
                        speed: 0,
                        speedAccuracy: 0,
                      )
                    : geo.Position(
                        latitude: 5.3600,
                        longitude: -4.0083,
                        timestamp: DateTime.now(),
                        accuracy: 0,
                        altitude: 0,
                        heading: 0,
                        speed: 0,
                        speedAccuracy: 0,
                      )),
            initialZoom: _is3DMode ? 18.0 : 15.0, // Zoom plus élevé en mode 3D
            initialPitch: _is3DMode ? 60.0 : 0.0,
            initialBearing: (_is3DMode && _currentBearing != null)
                ? _currentBearing!
                : 0.0,
            onMapCreated: _onMapCreated,
          ),

          // Bouton toggle mode 3D
          Positioned(
            top: 50,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: _is3DMode ? Colors.orange : Colors.grey[600],
              onPressed: _toggle3DMode,
              child: Icon(
                _is3DMode ? Icons.view_in_ar : Icons.map,
                color: Colors.white,
              ),
              tooltip: _is3DMode
                  ? 'DÃ©sactiver le mode 3D'
                  : 'Activer le mode 3D',
            ),
          ),

          // Bottom sheet draggable avec les informations de commande
          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.2,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Indicateur de glissement
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Contenu scrollable
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Informations de la commande
                            Text(
                              'Commande #${_currentOrder!.id}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Client: ${_currentOrder!.customerName ?? 'Client'}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (_currentOrder!
                                          .customerPhone
                                          .isNotEmpty)
                                        Text(
                                          _currentOrder!.customerPhone,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (_currentOrder!.customerPhone.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.phone,
                                      color: Colors.green,
                                    ),
                                    onPressed: () => _callCustomer(
                                      _currentOrder!.customerPhone,
                                    ),
                                    tooltip: 'Appeler le client',
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.green[50],
                                      padding: const EdgeInsets.all(12),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Adresse: ${_currentOrder!.deliveryAddress ?? 'N/A'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Card de progression de route style Uber/Glovo
                            if (_currentRoute != null &&
                                _currentPosition != null)
                              RouteProgressCard(
                                currentStep: _hasPickedUp
                                    ? 'Vers client'
                                    : 'Vers restaurant',
                                distanceRemaining: _currentRoute!.distance,
                                eta: Duration(
                                  seconds: _currentRoute!.duration.round(),
                                ),
                                progress: _calculateRouteProgress(),
                              ),
                            const SizedBox(height: 16),

                            // Carte de statut de livraison
                            DeliveryStatusCard(
                              order: _currentOrder!,
                              hasPickedUp: _hasPickedUp,
                              hasArrived: _hasArrived,
                            ),
                            const SizedBox(height: 16),

                            // Panneau d'actions
                            DeliveryActionsPanel(
                              hasPickedUp: _hasPickedUp,
                              hasArrived: _hasArrived,
                              onMarkPickedUp: _markAsPickedUp,
                              onMarkArrived: _markAsArrived,
                              onCompleteDelivery: _showCompletionModal,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Calcule la progression sur la route (0.0 Ã  1.0)
  double _calculateRouteProgress() {
    if (_currentRoute == null || _currentPosition == null) return 0.0;

    if (!_hasPickedUp) {
      // Ã‰tape 1: Vers le restaurant
      // Calculer la distance restante jusqu'au restaurant
      final remainingDistance = geo.Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        restaurantLat,
        restaurantLng,
      );
      // Progression approximative basÃ©e sur la distance restante
      final progress =
          1.0 - (remainingDistance / _currentRoute!.distance).clamp(0.0, 1.0);
      return progress;
    } else if (_currentOrder?.deliveryLat != null &&
        _currentOrder?.deliveryLng != null) {
      // Ã‰tape 2: Vers le client
      final remainingDistance = geo.Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _currentOrder!.deliveryLat!,
        _currentOrder!.deliveryLng!,
      );
      final progress =
          1.0 - (remainingDistance / _currentRoute!.distance).clamp(0.0, 1.0);
      return progress;
    }

    return 0.0;
  }
}

