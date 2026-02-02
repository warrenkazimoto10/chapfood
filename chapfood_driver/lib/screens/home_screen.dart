import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../widgets/map/mapbox_map_widget.dart';
import '../widgets/map/mapbox_directional_marker.dart';
import '../config/mapbox_config.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import '../constants/app_colors.dart';
import '../utils/text_styles.dart';
import '../services/theme_service.dart';
import '../services/location_service.dart';
import '../services/session_service.dart';
import '../services/order_service.dart';
import '../services/mapbox_routing_service.dart';
import '../services/realtime_debug_service.dart';
import '../services/delivery_code_service.dart';
import '../models/order_model.dart';
import '../models/driver_model.dart';
import '../widgets/chapfood_logo.dart';
import '../widgets/notification_badge.dart';
import '../widgets/driver_status_toggle.dart';
import '../widgets/order_notification_card.dart';
import '../widgets/delivery_code_modal.dart';
import '../widgets/delivery_panel.dart';
import '../widgets/map/directional_marker.dart';
import 'profile_screen.dart';
import 'revenue_history_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MapboxMap? _mapController;
  MapboxAnnotationHelper? _annotationHelper;
  MapboxCameraHelper? _cameraHelper;
  geo.Position? _currentPosition;
  geo.Position? _previousPosition; // Pour calculer le bearing
  double? _currentBearing; // Direction en degrÃ©s
  // Set<Marker> _markers = {};
  // Set<Polyline> _polylines = {};
  // // BitmapDescriptor? _driverMarkerIcon;
  // // BitmapDescriptor? _clientMarkerIcon;
  bool _isDrivingMode = false; // Mode conduite activÃ©
  Timer? _routeUpdateTimer; // Timer pour mettre Ã  jour l'itinÃ©raire
  RouteInfo? _currentRoute; // Informations de l'itinÃ©raire actuel
  DriverModel? _currentDriver;
  List<OrderModel> _availableOrders = [];
  OrderModel? _currentOrder;
  bool _isDriverAvailable = true;
  bool _isLoading = true;
  bool _isOnDelivery = false;
  bool _isModalOpen = false; // Nouvelle variable pour contrÃ´ler l'Ã©tat du modal
  bool _isDeliveryCardVisible =
      true; // Variable pour contrÃ´ler l'affichage du card de livraison
  StreamSubscription<List<OrderModel>>? _ordersSubscription;
  Timer? _locationTimer;
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _notificationTimer?.cancel();
    _ordersSubscription?.cancel();
    _routeUpdateTimer?.cancel(); // Nettoyer le timer de routage
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      await _loadDriverData();
      await _initializeLocation();
      await _checkCurrentOrder();
      _startLocationTracking();
      _startRealtimeOrderListening();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur initialisation: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDriverData() async {
    try {
      _currentDriver = await SessionService.getCurrentDriver();
      if (_currentDriver == null && mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      print('Erreur chargement driver: $e');
    }
  }

  Future<void> _initializeLocation() async {
    try {
      final hasPermission = await LocationService.checkLocationPermission();
      if (!hasPermission) {
        await LocationService.checkLocationPermission();
      }

      _currentPosition = await LocationService.getCurrentPosition();
      print(
        'ðŸ“ Position initiale: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}',
      );
    } catch (e) {
      print('Erreur gÃ©olocalisation: $e');
    }
  }

  Future<void> _checkCurrentOrder() async {
    if (_currentDriver == null) return;

    try {
      // VÃ©rifier le statut du livreur dans la DB
      final driverResponse = await Supabase.instance.client
          .from('drivers')
          .select('is_available')
          .eq('id', _currentDriver!.id)
          .single();

      if (driverResponse != null) {
        setState(() {
          _isDriverAvailable = driverResponse['is_available'] ?? true;
        });
      }

      // VÃ©rifier s'il y a une commande en cours
      final currentOrder = await OrderService.getCurrentDriverOrder(
        _currentDriver!.id,
      );
      if (currentOrder != null && mounted) {
        setState(() {
          _currentOrder = currentOrder;
          _isOnDelivery = true;
        });
        print('ðŸ“¦ Commande en cours: ${currentOrder.id}');

        // ðŸŽ¯ RESTAURER LE MARQUEUR CLIENT ET LE MODE CONDUITE
        if (currentOrder.deliveryLat != null &&
            currentOrder.deliveryLng != null) {
          print('ðŸ”„ Restauration du marqueur client et du mode conduite...');
          // Attendre que la carte soit prÃªte
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (_mapController != null) {
              _addClient// Marker(
                currentOrder.deliveryLat!,
                currentOrder.deliveryLng!,
              );
              _activateDrivingMode(
                currentOrder.deliveryLat!,
                currentOrder.deliveryLng!,
              );
              print('âœ… Marqueur client et mode conduite restaurÃ©s');
            }
          });
        }
      }
    } catch (e) {
      print('Erreur vÃ©rification commande actuelle: $e');
    }
  }

  void _startLocationTracking() {
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        final newPosition = await LocationService.getCurrentPosition();
        if (newPosition != null && mounted) {
          setState(() => _currentPosition = newPosition);
          _updateMapLocation();
          await _updateDriverLocationInDB();
        }
      } catch (e) {
        print('Erreur tracking position: $e');
      }
    });
  }

  // MÃ©thode de test pour vÃ©rifier les commandes disponibles
  Future<void> _testCheckOrders() async {
    try {
      print('ðŸ§ª Test: VÃ©rification des commandes disponibles...');
      final orders = await OrderService.getReadyOrdersTest();
      print('ðŸ§ª Test: ${orders.length} commandes trouvÃ©es');

      if (orders.isNotEmpty) {
        for (final order in orders) {
          print(
            'ðŸ§ª Test: Commande #${order.id} - ${order.customerName} - ${order.deliveryAddress}',
          );
        }

        if (_isDriverAvailable && !_isOnDelivery) {
          setState(() {
            _availableOrders = orders;
          });
          _showNotificationModal();
        }
      }
    } catch (e) {
      print('ðŸ§ª Test: Erreur lors de la vÃ©rification: $e');
    }
  }

  void _startRealtimeOrderListening() {
    if (_currentDriver == null) {
      print('âŒ Pas de driver connectÃ©, impossible d\'Ã©couter les commandes');
      return;
    }

    print(
      'ðŸ”” DÃ©marrage de l\'Ã©coute des commandes temps rÃ©el pour le driver ${_currentDriver!.id}',
    );

    // Diagnostic Realtime
    RealtimeDebugService.testRealtimeConnection();

    // TEMPORAIRE: Utiliser un timer au lieu de Realtime
    _notificationTimer = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) async {
      if (_isDriverAvailable && !_isOnDelivery && !_isModalOpen) {
        await _testCheckOrders();
      }
    });

    // Ã‰couter les nouvelles commandes en temps rÃ©el (si Realtime est configurÃ©)
    _ordersSubscription = OrderService.listenToReadyOrders().listen(
      (orders) {
        print('ðŸ“¦ Commandes reÃ§ues: ${orders.length} commandes disponibles');
        print(
          'ðŸ” Driver disponible: $_isDriverAvailable, En livraison: $_isOnDelivery',
        );

        if (mounted && _isDriverAvailable && !_isOnDelivery && !_isModalOpen) {
          setState(() {
            _availableOrders = orders;
          });

          if (orders.isNotEmpty) {
            print('ðŸš¨ Affichage du modal avec ${orders.length} commandes');
            _showNotificationModal();
          } else {
            print('ðŸ“­ Aucune commande disponible');
          }
        } else {
          print(
            'â¸ï¸ Modal non affichÃ© - Driver indisponible, en livraison ou modal dÃ©jÃ  ouvert',
          );
        }
      },
      onError: (error) {
        print('âŒ Erreur Ã©coute commandes: $error');
      },
    );
  }

  Future<void> _updateDriverLocationInDB() async {
    if (_currentPosition != null && _currentDriver != null) {
      try {
        await Supabase.instance.client
            .from('drivers')
            .update({
              'current_lat': _currentPosition!.latitude,
              'current_lng': _currentPosition!.longitude,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', _currentDriver!.id);

        print(
          'ðŸ“ Position mise Ã  jour en DB: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
        );
      } catch (e) {
        print('Erreur mise Ã  jour DB: $e');
      }
    }
  }

  Future<void> _onMapCreated(MapboxMap controller) async {
    _mapController = controller;
    _annotationHelper = MapboxAnnotationHelper(controller);
    _cameraHelper = MapboxCameraHelper(controller);
    await _annotationHelper!.initialize();
    try {
      _mapController = controller;

      // ðŸŽ¯ CHARGER LES IMAGES UNE SEULE FOIS AU DÃ‰MARRAGE
      await _loadMarkerIcons();

      print('âœ… Images des marqueurs chargÃ©es');

      _updateMapLocation();

      // ðŸ”„ RESTAURER LE MODE CONDUITE APRÃˆS HOT RESTART
      if (_isOnDelivery &&
          _currentOrder != null &&
          _currentOrder!.deliveryLat != null &&
          _currentOrder!.deliveryLng != null) {
        print('ðŸ”„ Restauration du mode conduite aprÃ¨s hot restart...');
        Future.delayed(const Duration(milliseconds: 500), () {
          _addClient// Marker(
            _currentOrder!.deliveryLat!,
            _currentOrder!.deliveryLng!,
          );
          _activateDrivingMode(
            _currentOrder!.deliveryLat!,
            _currentOrder!.deliveryLng!,
          );
          print('âœ… Mode conduite restaurÃ© aprÃ¨s hot restart');
        });
      }
    } catch (e) {
      print('Erreur crÃ©ation carte: $e');
    }
  }

  Future<void> _loadMarkerIcons() async {
    try {
      // CrÃ©er des cercles colorÃ©s simples
      _driverMarkerIcon = await DirectionalMarker.createSimple// Marker(
        color: Colors.blue,
        size: 40.0,
      );

      _clientMarkerIcon = await DirectionalMarker.createSimple// Marker(
        color: Colors.yellow,
        size: 40.0,
      );

      print('âœ… Marqueurs (cercles colorÃ©s) crÃ©Ã©s avec succÃ¨s');
    } catch (e) {
      print(
        'âš ï¸ Erreur crÃ©ation markers, utilisation des markers par dÃ©faut: $e',
      );
      _driverMarkerIcon = // BitmapDescriptor.defaultMarkerWithHue(
        // BitmapDescriptor.hueBlue,
      );
      _clientMarkerIcon = // BitmapDescriptor.defaultMarkerWithHue(
        // BitmapDescriptor.hueGreen,
      );
    }
  }

  void _updateMapLocation() async {
    if (_mapController != null && _currentPosition != null) {
      try {
        // ðŸ” Zoom adaptatif selon le mode
        double zoom = 15.0;
        if (_isDrivingMode && _currentOrder != null) {
          // En mode conduite, utiliser le zoom adaptatif
          final distance = geo.Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            _currentOrder!.deliveryLat!,
            _currentOrder!.deliveryLng!,
          );

          if (distance > 10000) zoom = 11.0;
          if (distance > 5000) zoom = 12.0;
          if (distance > 2000) zoom = 13.0;
          if (distance < 500) zoom = 16.0;
          if (distance < 100) zoom = 18.0;
        }

        await // _mapController!.animateCamera(
          // CameraUpdate.newLatLngZoom(
            // LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom,
          ),
        );

        // Calculer le bearing si on a une position prÃ©cÃ©dente
        if (_previousPosition != null) {
          final distance = geo.Geolocator.distanceBetween(
            _previousPosition!.latitude,
            _previousPosition!.longitude,
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          );

          // Ne calculer le bearing que si le livreur s'est dÃ©placÃ© d'au moins 10 mÃ¨tres
          // Cela Ã©vite que le marqueur bouge quand on est stationnÃ©
          if (distance >= 10.0) {
            _currentBearing = geo.Geolocator.bearingBetween(
              _previousPosition!.latitude,
              _previousPosition!.longitude,
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            );
            // Normaliser Ã  0-360
            if (_currentBearing! < 0) {
              _currentBearing = _currentBearing! + 360;
            }
          }
          // Sinon, garder le bearing prÃ©cÃ©dent pour Ã©viter les mouvements erratiques
        }

        // âœ… Supprimer uniquement l'ancien marker du livreur (PAS le client)
        // _markers.removeWhere((m) => m.markerId == const MarkerId('driver'));

        // CrÃ©er le marqueur directionnel avec halo (sans popup)
        // Utiliser le bearing prÃ©cÃ©dent si on est stationnÃ©
        final bearing = _currentBearing ?? 0.0;
        final directionalIcon = await DirectionalMarker.createDirectional// Marker(
          color: Colors.blue,
          bearing: bearing,
          showPopup: false,
        );

        // Ajouter le marker du livreur
        final driverMarker = // Marker(
          markerId: const MarkerId('driver'),
          position: // LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: directionalIcon,
          anchor: const Offset(
            0.5,
            0.5,
          ), // Ancrage au centre pour le marqueur directionnel
        );

        // Mettre Ã  jour la position prÃ©cÃ©dente
        _previousPosition = _currentPosition;

        setState(() {
          // _markers.add(driverMarker);
        });

        print('ðŸ“ Marker livreur mis Ã  jour (client prÃ©servÃ©)');
      } catch (e) {
        print('Erreur mise Ã  jour carte: $e');
      }
    }
  }

  void _showNotificationModal() {
    _isModalOpen = true; // Marquer le modal comme ouvert
    print('ðŸš¨ Ouverture du modal de notification');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true, // Permettre la fermeture par tap
      enableDrag: true, // Permettre la fermeture par glissement
      builder: (context) => MultiOrderNotificationModal(
        orders: _availableOrders,
        onAccept: _acceptOrder,
        onDecline: _declineOrder,
        onClose: _closeNotificationModal,
      ),
    ).then((_) {
      // Callback appelÃ© quand le modal se ferme
      _isModalOpen = false;
      print('ðŸ”’ Modal fermÃ© via callback');
    });
  }

  Future<void> _acceptOrder(String orderId) async {
    if (_currentDriver == null) return;

    // VÃ©rifier si on est dÃ©jÃ  en train de traiter cette commande
    if (_isOnDelivery) {
      print(
        'âš ï¸ DÃ©jÃ  en livraison, impossible d\'accepter une nouvelle commande',
      );
      return;
    }

    try {
      print('âœ… Acceptation de la commande $orderId');
      final orderIdInt = int.parse(orderId);
      final success = await OrderService.acceptOrder(
        orderIdInt,
        _currentDriver!.id,
      );

      if (success) {
        final order = _availableOrders.firstWhere((o) => o.id == orderIdInt);

        // Fermer le modal AVANT de mettre Ã  jour l'Ã©tat
        _closeNotificationModal();

        setState(() {
          _currentOrder = order;
          _isOnDelivery = true;
          _isDriverAvailable =
              true; // Rester disponible pour voir la position du client
          _availableOrders.clear();
        });

        // Afficher la position de livraison sur la carte
        if (order.deliveryLat != null && order.deliveryLng != null) {
          print(
            'ðŸ“ Affichage position client: ${order.deliveryLat}, ${order.deliveryLng}',
          );
          _showDeliveryLocation(order.deliveryLat!, order.deliveryLng!);
        } else {
          print(
            'âŒ CoordonnÃ©es de livraison manquantes: lat=${order.deliveryLat}, lng=${order.deliveryLng}',
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Commande #$orderId acceptÃ©e !'),
            backgroundColor: AppColors.successColor,
          ),
        );

        print('âœ… Commande acceptÃ©e: $orderId');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Commande dÃ©jÃ  acceptÃ©e par un autre livreur'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } catch (e) {
      print('Erreur acceptation commande: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'acceptation'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Future<void> _declineOrder(String orderId) async {
    try {
      setState(() {
        _availableOrders.removeWhere((o) => o.id.toString() == orderId);
      });

      if (_availableOrders.isEmpty) {
        _closeNotificationModal();
      }

      print('âŒ Commande refusÃ©e: $orderId');
    } catch (e) {
      print('Erreur refus commande: $e');
    }
  }

  void _closeNotificationModal() {
    _isModalOpen = false; // Marquer le modal comme fermÃ©
    print('ðŸ”’ Fermeture du modal de notification');

    // Essayer plusieurs mÃ©thodes pour fermer le modal
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      print('âœ… Modal fermÃ© avec Navigator.pop()');
    } else {
      print('âš ï¸ Impossible de fermer le modal avec Navigator.pop()');
    }

    // Nettoyer la liste des commandes disponibles
    setState(() {
      _availableOrders.clear();
    });
  }

  void _showDeliveryLocation(double lat, double lng) {
    print('ðŸŽ¯ _showDeliveryLocation appelÃ© avec: lat=$lat, lng=$lng');
    print('ðŸ“ CoordonnÃ©es pour Google Maps: // LatLng($lat, $lng)');
    print('ðŸŒ VÃ©rification: Ces coordonnÃ©es sont-elles en CÃ´te d\'Ivoire ?');

    if (_mapController != null) {
      print('ðŸ—ºï¸ Carte disponible, centrage sur la position client');
      // Centrer la carte sur la position de livraison
      // _mapController!.animateCamera(
        // CameraUpdate.newLatLngZoom(// LatLng(lat, lng), 15.0),
      );

      // Ajouter un marqueur jaune pour la destination du client
      _addClient// Marker(lat, lng);

      // ðŸš— ACTIVER LE MODE CONDUITE
      _activateDrivingMode(lat, lng);
    } else {
      print('âŒ Carte non disponible');
    }
  }

  void _addClient// Marker(double lat, double lng) async {
    print('ðŸŸ¡ _addClientMarker appelÃ© avec: $lat, $lng');
    if (_mapController == null) {
      print('âŒ GoogleMapController non disponible');
      return;
    }

    try {
      // Supprimer l'ancien marqueur client s'il existe
      // _markers.removeWhere((m) => m.markerId == const MarkerId('client'));

      // S'assurer que l'icÃ´ne est chargÃ©e
      if (_clientMarkerIcon == null) {
        await _loadMarkerIcons();
      }

      // CrÃ©er le nouveau marqueur client
      final clientMarker = // Marker(
        markerId: const MarkerId('client'),
        position: // LatLng(lat, lng),
        icon:
            _clientMarkerIcon ??
            // BitmapDescriptor.defaultMarkerWithHue(// BitmapDescriptor.hueGreen),
        anchor: const Offset(0.5, 1.0),
      );

      setState(() {
        // _markers.add(clientMarker);
      });

      print('âœ… Marqueur client ajoutÃ© Ã  la position: $lat, $lng');
    } catch (e) {
      print('âŒ Erreur ajout marqueur client: $e');
    }
  }

  /// ðŸš— Active le mode conduite avec tracÃ© directionnel
  void _activateDrivingMode(double clientLat, double clientLng) {
    setState(() {
      _isDrivingMode = true;
    });

    print('ðŸš— Mode conduite activÃ©');

    // Calculer et afficher l'itinÃ©raire
    _calculateAndDisplayRoute(clientLat, clientLng);

    // DÃ©marrer la mise Ã  jour pÃ©riodique de l'itinÃ©raire
    _startRouteUpdateTimer(clientLat, clientLng);

    // Zoom adaptatif pour la conduite
    _setDrivingZoom();
  }

  /// ðŸ—ºï¸ Calcule et affiche l'itinÃ©raire entre le livreur et le client
  Future<void> _calculateAndDisplayRoute(
    double clientLat,
    double clientLng,
  ) async {
    if (_currentPosition == null) {
      print('âŒ Position du livreur non disponible pour calculer l\'itinÃ©raire');
      return;
    }

    try {
      print('ðŸ—ºï¸ Calcul de l\'itinÃ©raire Google Maps en cours...');
      print(
        'ðŸ“ Position livreur: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
      );
      print('ðŸ“ Position client: $clientLat, $clientLng');

      // Utiliser le service de routage Mapbox
      final route = await MapboxRoutingService.getRoute(
        startLat: _currentPosition!.latitude,
        startLng: _currentPosition!.longitude,
        endLat: clientLat,
        endLng: clientLng,
      );

      if (route != null) {
        setState(() {
          _currentRoute = route;
        });

        // Afficher l'itinÃ©raire sur la carte
        await _drawRoute(route.coordinates);

        // Centrer la carte sur l'itinÃ©raire complet
        await _centerMapOnRoute(route.coordinates);

        print(
          'âœ… ItinÃ©raire affichÃ©: ${route.formattedDistance} â€¢ ${route.formattedDuration}',
        );
      } else {
        print('âŒ Impossible de calculer l\'itinÃ©raire');
        // Fallback: ligne droite
        await _drawFallbackRoute(clientLat, clientLng);
      }
    } catch (e) {
      print('âŒ Erreur calcul itinÃ©raire: $e');
      // Fallback: ligne droite
      await _drawFallbackRoute(clientLat, clientLng);
    }
  }

  /// ðŸ›£ï¸ Fallback: ligne droite si le routage Ã©choue
  Future<void> _drawFallbackRoute(double clientLat, double clientLng) async {
    if (_currentPosition == null) return;

    final fallbackRoute = [
      // LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      // LatLng(clientLat, clientLng),
    ];

    await _drawRoute(fallbackRoute);
    print('âš ï¸ Utilisation de l\'itinÃ©raire de secours (ligne droite)');
  }

  /// ðŸŽ¯ Centre la carte sur l'itinÃ©raire complet
  Future<void> _centerMapOnRoute(List<LatLng> coordinates) async {
    if (_mapController == null || coordinates.isEmpty) return;

    try {
      // Calculer les limites de l'itinÃ©raire
      double minLat = coordinates.first.latitude;
      double maxLat = coordinates.first.latitude;
      double minLng = coordinates.first.longitude;
      double maxLng = coordinates.first.longitude;

      for (final coord in coordinates) {
        minLat = minLat < coord.latitude ? minLat : coord.latitude;
        maxLat = maxLat > coord.latitude ? maxLat : coord.latitude;
        minLng = minLng < coord.longitude ? minLng : coord.longitude;
        maxLng = maxLng > coord.longitude ? maxLng : coord.longitude;
      }

      // Centrer la carte sur l'itinÃ©raire avec animation
      // Calculer le centre de l'itinÃ©raire
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;

      // Calculer le zoom pour encadrer l'itinÃ©raire
      final latDiff = maxLat - minLat;
      final lngDiff = maxLng - minLng;
      final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

      double zoom = 15.0;
      if (maxDiff > 0.1) zoom = 10.0;
      if (maxDiff > 0.05) zoom = 12.0;
      if (maxDiff > 0.01) zoom = 14.0;

      await // _mapController!.animateCamera(
        // CameraUpdate.newCameraPosition(
          CameraPosition(target: // LatLng(centerLat, centerLng), zoom: zoom),
        ),
      );

      print('ðŸŽ¯ Carte centrÃ©e sur l\'itinÃ©raire');
    } catch (e) {
      print('âŒ Erreur centrage carte: $e');
    }
  }

  /// ðŸŽ¨ Dessine la polyline de l'itinÃ©raire sur la carte
  Future<void> _drawRoute(List<LatLng> coordinates) async {
    if (_mapController == null) return;

    try {
      print('ðŸŽ¨ Dessin de la polyline avec ${coordinates.length} points');
      if (coordinates.isNotEmpty) {
        print(
          'ðŸ“ Premier point: ${coordinates.first.latitude}, ${coordinates.first.longitude}',
        );
        print(
          'ðŸ“ Dernier point: ${coordinates.last.latitude}, ${coordinates.last.longitude}',
        );
      }

      // Supprimer l'ancienne polyline
      // _polylines.removeWhere((p) => p.polylineId == const PolylineId('route'));

      // CrÃ©er la nouvelle polyline avec geodesic pour suivre la route rÃ©elle
      final routePolyline = // Polyline(
        polylineId: const PolylineId('route'),
        points: coordinates,
        color: AppColors.primaryRed,
        width: 5,
        geodesic:
            true, // Suivre la courbure de la Terre pour une route plus rÃ©aliste
      );

      setState(() {
        // _polylines.add(routePolyline);
      });

      print('âœ… Polyline de l\'itinÃ©raire dessinÃ©e');
    } catch (e) {
      print('âŒ Erreur dessin polyline: $e');
    }
  }

  /// â° DÃ©marre le timer de mise Ã  jour de l'itinÃ©raire
  void _startRouteUpdateTimer(double clientLat, double clientLng) {
    _routeUpdateTimer?.cancel();

    _routeUpdateTimer = Timer.periodic(const Duration(seconds: 30), (
      timer,
    ) async {
      if (_currentPosition != null && _isOnDelivery && _isDrivingMode) {
        print('ðŸ”„ Mise Ã  jour de l\'itinÃ©raire...');
        await _calculateAndDisplayRoute(clientLat, clientLng);
      } else {
        timer.cancel();
        print('â¹ï¸ ArrÃªt de la mise Ã  jour de l\'itinÃ©raire');
      }
    });
  }

  /// ðŸ” Zoom adaptatif pour le mode conduite avec animation visible
  void _setDrivingZoom() {
    if (_mapController == null ||
        _currentPosition == null ||
        _currentOrder == null)
      return;

    // Calculer la distance entre le livreur et le client
    final distance = geo.Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _currentOrder!.deliveryLat!,
      _currentOrder!.deliveryLng!,
    );

    // Zoom adaptatif selon la distance
    double zoom = 15.0;
    if (distance > 10000)
      zoom = 11.0; // Vue trÃ¨s large pour trÃ¨s longues distances
    if (distance > 5000) zoom = 12.0; // Vue large pour longues distances
    if (distance > 2000) zoom = 13.0; // Vue moyenne
    if (distance < 500) zoom = 16.0; // Vue rapprochÃ©e pour arrivÃ©e
    if (distance < 100) zoom = 18.0; // Vue trÃ¨s rapprochÃ©e pour arrivÃ©e

    // _mapController!.animateCamera(
      // CameraUpdate.newLatLngZoom(
        // LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        zoom,
      ),
    );

    print(
      'ðŸ” Zoom adaptatif: $zoom (distance: ${distance.toStringAsFixed(0)}m)',
    );
  }

  /// ðŸ—‘ï¸ Supprime l'itinÃ©raire de la carte
  Future<void> _clearRoute() async {
    // _polylines.removeWhere((p) => p.polylineId == const PolylineId('route'));

    _routeUpdateTimer?.cancel();
    _routeUpdateTimer = null;

    setState(() {
      _isDrivingMode = false;
    });

    print('ðŸ—‘ï¸ ItinÃ©raire supprimÃ© de la carte');
  }

  // MÃ©thodes supprimÃ©es - les markers sont maintenant chargÃ©s via _loadMarkerIcons()

  /// âœ… Finalise une livraison avec code de confirmation
  Future<void> _completeDelivery() async {
    if (_currentOrder == null) return;

    try {
      print(
        'âœ… Finalisation de la livraison de la commande ${_currentOrder!.id}',
      );

      // Afficher le modal de saisie du code
      _showDeliveryCodeModal();
    } catch (e) {
      print('âŒ Erreur finalisation livraison: $e');
      _showErrorSnackBar('Erreur lors de la finalisation de la livraison');
    }
  }

  /// ðŸ” Affiche le modal de saisie du code de livraison
  void _showDeliveryCodeModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeliveryCodeModal(
        orderId: _currentOrder!.id.toString(),
        customerName: _currentOrder!.customerName ?? 'Client',
        onConfirm: _handleDeliveryCodeConfirmation,
        onCancel: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  /// âœ… Traite la confirmation du code de livraison
  Future<void> _handleDeliveryCodeConfirmation(String code) async {
    if (_currentOrder == null) return;

    try {
      print('ðŸ” Validation du code de livraison: $code');

      // Valider le code avec Supabase
      final isValid = await DeliveryCodeService.validateDeliveryCode(
        _currentOrder!.id,
        code,
      );

      if (!isValid) {
        _showErrorSnackBar('Code de livraison invalide ou expirÃ©');
        return;
      }

      // Confirmer la livraison
      final isConfirmed = await DeliveryCodeService.confirmDelivery(
        _currentOrder!.id,
        code,
        'driver_${_currentDriver!.id}',
      );

      if (!isConfirmed) {
        _showErrorSnackBar('Erreur lors de la confirmation de la livraison');
        return;
      }

      // Fermer le modal
      Navigator.of(context).pop();

      // Finaliser la livraison dans l'app
      await _finalizeDelivery();
    } catch (e) {
      print('âŒ Erreur confirmation code: $e');
      _showErrorSnackBar('Erreur lors de la validation du code');
    }
  }

  /// ðŸŽ¯ Finalise la livraison aprÃ¨s confirmation du code
  Future<void> _finalizeDelivery() async {
    try {
      // Marquer la livraison comme terminÃ©e dans order_driver_assignments
      await OrderService.completeDelivery(_currentOrder!.id);

      // Nettoyer l'Ã©tat de l'app
      setState(() {
        _currentOrder = null;
        _isOnDelivery = false;
        _isDriverAvailable = true;
        _isDeliveryCardVisible = true;
      });

      // Supprimer le marqueur client
      // _markers.removeWhere((m) => m.markerId == const MarkerId('client'));

      // Nettoyer l'itinÃ©raire
      await _clearRoute();

      // Afficher le message de succÃ¨s
      _showSuccessSnackBar('Livraison confirmÃ©e avec succÃ¨s !');

      print('âœ… Livraison finalisÃ©e avec succÃ¨s');
    } catch (e) {
      print('âŒ Erreur finalisation: $e');
      _showErrorSnackBar('Erreur lors de la finalisation');
    }
  }

  /// ðŸ“± Affiche un message d'erreur
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// âœ… Affiche un message de succÃ¨s
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _toggleDriverStatus(bool isAvailable) async {
    setState(() {
      _isDriverAvailable = isAvailable;
    });

    // Mettre Ã  jour le statut dans la base de donnÃ©es
    if (_currentDriver != null) {
      try {
        await Supabase.instance.client
            .from('drivers')
            .update({
              'is_available': isAvailable,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', _currentDriver!.id);

        print(
          'ðŸ“± Statut livreur mis Ã  jour: ${isAvailable ? "Disponible" : "Indisponible"}',
        );
      } catch (e) {
        print('Erreur mise Ã  jour statut: $e');
      }
    }

    // Si on passe en mode indisponible et qu'on a une commande en cours, la garder
    if (!isAvailable && _isOnDelivery) {
      // Le livreur reste en livraison mÃªme s'il passe en indisponible
      return;
    }

    // Fermer le modal de notifications si on passe en indisponible
    if (!isAvailable && Navigator.of(context).canPop()) {
      _closeNotificationModal();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: themeService.getMapBackgroundColor(),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryRed),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9), // Fond gris clair fixe
      body: Stack(
        children: [
          // CARTE PLEIN Ã‰CRAN
          MapboxMapWidget(
            initialPosition: _currentPosition,
            onMapCreated: _onMapCreated,
            initialZoom: 15.0,
          ),

          // OVERLAY MODE INDISPONIBLE
          if (!_isDriverAvailable)
            Container(
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
                    Text(
                      'Mode Indisponible',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Vous ne recevrez pas de nouvelles commandes',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // HEADER
          _buildHeader(themeService),

          // STATUS PANEL
          _buildStatusPanel(themeService),

          // NAVIGATION PANEL (si en mode conduite)
          if (_isDrivingMode && _currentRoute != null) _buildNavigationPanel(),

          // DELIVERY PANEL (si en livraison)
          if (_isOnDelivery && _currentOrder != null) _buildDeliveryPanel(),

          // BOTTOM NAVIGATION
          _buildBottomNavigation(themeService),

          // BOUTON FLOTTANT POSITION ACTUELLE
          _buildCurrentLocationButton(),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeService themeService) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Logo ChapFood
                Expanded(flex: 2, child: const ChapFoodLogo()),

                // Actions droite
                Expanded(
                  flex: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge notifications
                      NotificationBadge(
                        count: _availableOrders.length,
                        onTap: () {
                          if (_availableOrders.isNotEmpty) {
                            _showNotificationModal();
                          }
                        },
                      ),

                      const SizedBox(width: 8),

                      // Bouton mode sombre/clair
                      Consumer<ThemeService>(
                        builder: (context, themeService, child) {
                          return IconButton(
                            onPressed: () {
                              themeService.toggleTheme();
                            },
                            icon: Icon(
                              themeService.isDarkMode
                                  ? Icons.light_mode
                                  : Icons.dark_mode,
                              color: AppColors.primaryRed,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primaryRed.withOpacity(
                                0.1,
                              ),
                              shape: const CircleBorder(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ðŸ§­ Panneau d'informations de navigation
  Widget _buildNavigationPanel() {
    if (_currentRoute == null) return const SizedBox.shrink();

    return Positioned(
      top: 140, // Sous le panneau de statut
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // IcÃ´ne de navigation
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.navigation,
                color: AppColors.primaryRed,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Informations de route
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Navigation active',
                    style: AppTextStyles.foodItemTitle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.route, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _currentRoute!.formattedDistance,
                        style: AppTextStyles.foodItemDescription.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _currentRoute!.formattedDuration,
                        style: AppTextStyles.foodItemDescription.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bouton pour dÃ©sactiver le mode conduite
            IconButton(
              onPressed: () {
                setState(() {
                  _isDrivingMode = false;
                });
                _clearRoute();
              },
              icon: const Icon(
                Icons.close,
                color: AppColors.primaryRed,
                size: 20,
              ),
              tooltip: 'DÃ©sactiver la navigation',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPanel(ThemeService themeService) {
    return Positioned(
      top: 140,
      left: 16,
      right: 16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _isOnDelivery
            ? _buildCompactStatusPanel()
            : _buildFullStatusPanel(),
      ),
    );
  }

  Widget _buildCompactStatusPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.delivery_dining,
              color: AppColors.primaryRed,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Livraison en cours',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Commande #${_currentOrder?.id}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Bouton pour masquer/dÃ©masquer le card de dÃ©tails
          IconButton(
            onPressed: () {
              print(
                'ðŸ”„ Bouton cliquÃ©: _isDeliveryCardVisible = $_isDeliveryCardVisible',
              );
              setState(() {
                _isDeliveryCardVisible = !_isDeliveryCardVisible;
              });
              print(
                'ðŸ”„ AprÃ¨s clic: _isDeliveryCardVisible = $_isDeliveryCardVisible',
              );
            },
            icon: Icon(
              _isDeliveryCardVisible
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_up,
              color: AppColors.primaryRed,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primaryRed.withOpacity(0.1),
              shape: const CircleBorder(),
            ),
            tooltip: _isDeliveryCardVisible
                ? 'Masquer les dÃ©tails'
                : 'Voir les dÃ©tails',
          ),
        ],
      ),
    );
  }

  Widget _buildFullStatusPanel() {
    return Column(
      children: [
        DriverStatusToggle(
          isAvailable: _isDriverAvailable,
          onToggle: _toggleDriverStatus,
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                _currentDriver?.name ?? 'Livreur',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _currentDriver?.phone ?? 'TÃ©lÃ©phone non disponible',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    icon: Icons.motorcycle,
                    label: 'VÃ©hicule',
                    value: _currentDriver?.vehicleDisplayName ?? 'Non spÃ©cifiÃ©',
                  ),
                  _buildStatItem(
                    icon: Icons.star,
                    label: 'Note',
                    value: _currentDriver?.ratingDisplay ?? 'N/A',
                  ),
                  _buildStatItem(
                    icon: Icons.location_on,
                    label: 'Position',
                    value: _currentPosition != null ? 'Active' : 'Inactive',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryRed, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(ThemeService themeService) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(icon: Icons.home, label: 'Accueil', isActive: true),
            _buildNavItem(
              icon: Icons.history,
              label: 'Historique',
              isActive: false,
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const RevenueHistoryScreen(),
                  ),
                );
              },
              child: _buildNavItem(
                icon: Icons.attach_money,
                label: 'Revenus',
                isActive: false,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              child: _buildNavItem(
                icon: Icons.person,
                label: 'Profil',
                isActive: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isActive ? AppColors.primaryRed : Colors.grey[400],
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isActive ? AppColors.primaryRed : Colors.grey[400],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentLocationButton() {
    return Positioned(
      right: 16,
      bottom: 100,
      child: FloatingActionButton(
        onPressed: _centerOnCurrentLocation,
        backgroundColor: AppColors.primaryRed,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }

  void _centerOnCurrentLocation() {
    if (_mapController != null && _currentPosition != null) {
      // _mapController!.animateCamera(
        // CameraUpdate.newLatLngZoom(
          // LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15.0,
        ),
      );
    }
  }

  Widget _buildDeliveryPanel() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: _isDeliveryCardVisible
          ? DeliveryPanel(
              order: _currentOrder!,
              onCallCustomer: () {
                // L'appel est gÃ©rÃ© dans le DeliveryPanel
              },
              onCompleteDelivery: _completeDelivery,
              distance: 2.5, // TODO: Calculer la vraie distance
              estimatedTime: 15, // TODO: Calculer le vrai temps
            )
          : const SizedBox.shrink(), // Widget vide quand masquÃ©
    );
  }
}

// Modal pour les notifications de commandes multiples
class MultiOrderNotificationModal extends StatelessWidget {
  final List<OrderModel> orders;
  final Function(String) onAccept;
  final Function(String) onDecline;
  final VoidCallback onClose;

  const MultiOrderNotificationModal({
    super.key,
    required this.orders,
    required this.onAccept,
    required this.onDecline,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.buttonGradient,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_active,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Nouvelles commandes disponibles',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Liste des commandes
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return OrderNotificationCard(
                  order: order,
                  onAccept: () => onAccept(order.id.toString()),
                  onDecline: () => onDecline(order.id.toString()),
                );
              },
            ),
          ),

          // Bouton refuser tout
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  for (final order in orders) {
                    onDecline(order.id.toString());
                  }
                  onClose();
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  "Refuser Tout",
                  style: GoogleFonts.poppins(
                    color: Colors.red[400],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

