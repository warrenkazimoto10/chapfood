import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../widgets/map/mapbox_map_widget.dart';
import '../widgets/map/mapbox_directional_marker.dart';
import '../config/mapbox_config.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../services/theme_service.dart';
import '../services/session_service.dart';
import '../services/smooth_movement_service.dart';
import '../services/navigation_service.dart';
import '../models/driver_model.dart';
import '../widgets/home/animated_bottom_nav.dart';
import '../widgets/home/order_notification_card.dart';
import '../widgets/responsive/responsive_layout.dart';
import '../widgets/loading/loading_states.dart';
import '../widgets/map/directional_marker.dart';

class RealDataHomeScreen extends StatefulWidget {
  const RealDataHomeScreen({super.key});

  @override
  State<RealDataHomeScreen> createState() => _RealDataHomeScreenState();
}

class _RealDataHomeScreenState extends State<RealDataHomeScreen> {
  int _currentNavIndex = 0;
  bool _isDriverAvailable = true;
  bool _isDarkMode = false;
  bool _isLoading = true;
  bool _isUpdatingStatus = false;
  String? _errorMessage;

  // Vraies donnÃ©es du livreur
  DriverModel? _currentDriver;

  // Google Maps
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
  StreamSubscription<geo.Position>? _positionStream;

  // Commande en cours
  Map<String, dynamic>? _currentOrder;
  bool _isOnDelivery = false;

  // Supabase Realtime pour la position
  RealtimeChannel? _positionChannel;

  // Service de mouvement fluide
  final SmoothMovementService _smoothMovementService = SmoothMovementService();
  StreamSubscription<geo.Position>? _smoothPositionSubscription;

  // Service de navigation
  final NavigationService _navigationService = NavigationService();

  // ClÃ©s pour SharedPreferences (persistance d'Ã©tat)
  static const String _activeOrderKey = 'active_order_id';
  static const String _isOnDeliveryKey = 'is_on_delivery';
  static const String _clientLatKey = 'client_delivery_lat';
  static const String _clientLngKey = 'client_delivery_lng';

  Map<String, dynamic>? _currentOrderNotification;
  List<Map<String, dynamic>> _availableOrders = [];
  int _currentOrderIndex = 0;
  Set<int> _refusedOrders = {}; // Commandes refusÃ©es par ce driver
  StreamSubscription? _ordersSubscription;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    _loadDriverData();
    _initializeLocation();
  }

  void _loadThemeMode() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    setState(() {
      _isDarkMode = themeService.isDarkMode;
    });
  }

  Future<void> _loadDriverData() async {
    try {
      final driver = await SessionService.getCurrentDriver();
      setState(() {
        _currentDriver = driver;
        _isDriverAvailable = driver?.isAvailable ?? true;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement driver: $e');
      setState(() {
        _errorMessage = 'Erreur lors du chargement des donnÃ©es';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleDriverStatus() async {
    if (_currentDriver == null || _isUpdatingStatus) return;

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      // Mettre Ã  jour le statut localement d'abord pour une meilleure UX
      setState(() {
        _isDriverAvailable = !_isDriverAvailable;
      });

      // Mettre Ã  jour dans la base de donnÃ©es
      await _updateDriverStatusInDatabase(_isDriverAvailable);

      // Afficher un message de confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isDriverAvailable
                  ? 'Vous Ãªtes maintenant disponible'
                  : 'Vous Ãªtes maintenant indisponible',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: _isDriverAvailable ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // En cas d'erreur, revenir au statut prÃ©cÃ©dent
      setState(() {
        _isDriverAvailable = !_isDriverAvailable;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de la mise Ã  jour du statut: $e',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  Future<void> _updateDriverStatusInDatabase(bool isAvailable) async {
    try {
      final supabase = Supabase.instance.client;

      // VÃ©rifier la connexion
      print(
        'ðŸ”„ Tentative de mise Ã  jour du statut: $isAvailable pour driver ID: ${_currentDriver!.id}',
      );

      final response = await supabase
          .from('drivers')
          .update({
            'is_available': isAvailable,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _currentDriver!.id)
          .select();

      print('âœ… Statut mis Ã  jour dans la base de donnÃ©es: $isAvailable');
      print('ðŸ“Š RÃ©ponse Supabase: $response');
    } catch (e) {
      print('âŒ Erreur lors de la mise Ã  jour du statut: $e');
      print('ðŸ” Type d\'erreur: ${e.runtimeType}');

      // Ne pas rethrow pour Ã©viter de bloquer l'UI
      // L'utilisateur peut toujours changer le statut localement
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });

    // Navigation vers les autres Ã©crans
    switch (index) {
      case 1:
        // Naviguer vers historique
        break;
      case 2:
        // Naviguer vers revenus
        break;
      case 3:
        // Naviguer vers profil
        break;
    }
  }

  Future<void> _initializeLocation() async {
    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled.');
        return;
      }

      geo.LocationPermission permission =
          await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          print('Location permissions are denied');
          return;
        }
      }

      if (permission == geo.LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return;
      }

      _currentPosition = await geo.Geolocator.getCurrentPosition();
      print(
        'Position actuelle: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}',
      );

      // Forcer l'ajout du marker si la carte est dÃ©jÃ  crÃ©Ã©e
      await _updateDriverMarkerIfReady();

      // DÃ©marrer le suivi de position en temps rÃ©el
      _startPositionTracking();

      // Ã‰couter les positions des autres drivers via Supabase Realtime
      _startSupabasePositionTracking();

      // Restaurer l'Ã©tat de commande active (si existant)
      await _restoreActiveOrderState();

      // Ã‰couter les commandes ready_for_delivery
      _startOrdersListening();
    } catch (e) {
      print('Erreur lors de l\'initialisation de la localisation: $e');
    }
  }

  void _startOrdersListening() {
    try {
      final supabase = Supabase.instance.client;

      // Ã‰couter toutes les commandes pour dÃ©tecter les changements de statut
      _ordersSubscription = supabase.from('orders').stream(primaryKey: ['id']).listen((
        data,
      ) {
        print('ðŸ“¦ Mise Ã  jour des commandes reÃ§ue: ${data.length} commandes');

        // Filtrer les commandes ready_for_delivery non assignÃ©es et non refusÃ©es
        final availableOrders = data
            .where(
              (order) =>
                  order['status'] == 'ready_for_delivery' &&
                  order['driver_id'] == null &&
                  !_refusedOrders.contains(order['id']),
            )
            .toList();

        setState(() {
          _availableOrders = availableOrders.cast<Map<String, dynamic>>();

          // Si une commande est en cours, ne pas afficher de nouvelles commandes
          if (_isOnDelivery) {
            print('ðŸš« Livraison en cours, ignorer les nouvelles commandes');
            return;
          }

          // Si on a une commande en cours d'affichage, vÃ©rifier si elle est toujours disponible
          if (_currentOrderNotification != null) {
            final currentOrderId = _currentOrderNotification!['id'];
            final currentOrder = _availableOrders.firstWhere(
              (order) => order['id'] == currentOrderId,
              orElse: () => <String, dynamic>{},
            );

            // Si la commande n'existe plus ou n'est plus disponible, fermer le modal
            if (currentOrder.isEmpty ||
                currentOrder['status'] != 'ready_for_delivery' ||
                currentOrder['driver_id'] != null) {
              print(
                'ðŸ“¦ Commande $currentOrderId n\'est plus disponible, fermeture du modal',
              );
              _currentOrderNotification = null;
              _currentOrderIndex = 0;
              return;
            }
          }

          // Si on n'a pas de commande en cours et qu'il y a des commandes disponibles
          if (_currentOrderNotification == null &&
              _availableOrders.isNotEmpty) {
            _currentOrderIndex = 0;
            _showCurrentOrder();
          }
        });
      });

      print('ðŸ“¦ Ã‰coute des commandes dÃ©marrÃ©e (tous statuts)');
    } catch (e) {
      print('âŒ Erreur lors du dÃ©marrage de l\'Ã©coute des commandes: $e');
    }
  }

  void _showCurrentOrder() {
    if (_availableOrders.isNotEmpty &&
        _currentOrderIndex < _availableOrders.length) {
      final order = _availableOrders[_currentOrderIndex];
      _currentOrderNotification = {
        'id': order['id'],
        'customer_name': order['customer_name'] ?? 'Client',
        'total_amount': (order['total_amount'] ?? 0.0).toDouble(),
        'delivery_address':
            order['delivery_address'] ?? 'Adresse non spÃ©cifiÃ©e',
        'delivery_fee': (order['delivery_fee'] ?? 1500.0).toDouble(),
        'customer_phone': order['customer_phone'] ?? '',
        'restaurant_name': order['restaurant_name'] ?? 'Restaurant',
        'items': order['items'] ?? [],
      };
    }
  }

  void _nextOrder() {
    if (_availableOrders.length > 1) {
      setState(() {
        _currentOrderIndex = (_currentOrderIndex + 1) % _availableOrders.length;
        _showCurrentOrder();
      });
    }
  }

  void _previousOrder() {
    if (_availableOrders.length > 1) {
      setState(() {
        _currentOrderIndex =
            (_currentOrderIndex - 1 + _availableOrders.length) %
            _availableOrders.length;
        _showCurrentOrder();
      });
    }
  }

  void _startSupabasePositionTracking() {
    try {
      final supabase = Supabase.instance.client;

      _positionChannel = supabase
          .channel('driver_positions')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'drivers',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.neq,
              column: 'id',
              value: _currentDriver!.id.toString(),
            ),
            callback: (payload) async {
              print('ðŸ“¡ Position d\'un autre driver reÃ§ue: $payload');

              final data = payload.newRecord;
              if (data != null &&
                  data['latitude'] != null &&
                  data['longitude'] != null) {
                // Ici tu peux ajouter des markers pour les autres drivers
                // ou faire d'autres actions avec leur position
                print(
                  'ðŸ“ Autre driver Ã : ${data['latitude']}, ${data['longitude']}',
                );
              }
            },
          )
          .subscribe();

      print('ðŸ“¡ Ã‰coute des positions Supabase dÃ©marrÃ©e');
    } catch (e) {
      print('âŒ Erreur lors du dÃ©marrage de l\'Ã©coute Supabase: $e');
    }
  }

  void _startPositionTracking() {
    // Stream de position GPS brut (moins frÃ©quent)
    final rawPositionStream = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 3, // Mettre Ã  jour tous les 3 mÃ¨tres
      ),
    );

    // DÃ©marrer le service de mouvement fluide
    _smoothMovementService.startSmoothTracking(rawPositionStream);

    // Ã‰couter les positions fluides
    _smoothPositionSubscription = _smoothMovementService.positionStream.listen(
      (geo.Position smoothPosition) async {
        print(
          'ðŸŒŠ Position fluide: ${smoothPosition.latitude.toStringAsFixed(6)}, ${smoothPosition.longitude.toStringAsFixed(6)}',
        );

        setState(() {
          _currentPosition = smoothPosition;
        });

        // Mettre Ã  jour le marker si la carte est prÃªte
        if (_mapController != null) {
          await _addDriver// Marker();
        }

        // Envoyer la position Ã  Supabase (moins frÃ©quent pour Ã©viter la surcharge)
        if (_shouldSendToSupabase(smoothPosition)) {
          await _updatePositionInSupabase(smoothPosition);
        }
      },
      onError: (error) {
        print('âŒ Erreur dans le suivi de position fluide: $error');
      },
    );
  }

  // Compteur pour limiter l'envoi Ã  Supabase
  int _supabaseUpdateCounter = 0;

  bool _shouldSendToSupabase(geo.Position position) {
    _supabaseUpdateCounter++;
    // Envoyer Ã  Supabase seulement tous les 10 updates (environ toutes les secondes)
    return _supabaseUpdateCounter % 10 == 0;
  }

  Future<void> _updatePositionInSupabase(geo.Position position) async {
    try {
      final supabase = Supabase.instance.client;

      await supabase
          .from('drivers')
          .update({
            'latitude': position.latitude,
            'longitude': position.longitude,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _currentDriver!.id);

      print(
        'ðŸ“¡ Position envoyÃ©e Ã  Supabase: ${position.latitude}, ${position.longitude}',
      );
    } catch (e) {
      print('âŒ Erreur lors de l\'envoi de la position Ã  Supabase: $e');
    }
  }

  Future<void> _updateDriverMarkerIfReady() async {
    if (_mapController != null && _currentPosition != null) {
      print('ðŸ”„ Mise Ã  jour du marker aprÃ¨s obtention de la position');
      await _addDriver// Marker();
    }
  }

  Future<void> _addDriver// Marker() async {
    if (_currentPosition == null || _mapController == null) {
      print(
        'âš ï¸ Impossible d\'ajouter le marker: position=${_currentPosition != null}, controller=${_mapController != null}',
      );
      return;
    }

    try {
      // Supprimer l'ancien marker s'il existe
      // _markers.removeWhere((m) => m.markerId == const MarkerId('driver'));

      print(
        'ðŸ“ Position actuelle: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
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

      // CrÃ©er le marqueur directionnel avec halo (sans popup)
      // Utiliser le bearing prÃ©cÃ©dent si on est stationnÃ©
      final bearing = _currentBearing ?? 0.0;
      final directionalIcon = await DirectionalMarker.createDirectional// Marker(
        color: Colors.blue,
        bearing: bearing,
        showPopup: false,
      );

      // CrÃ©er le nouveau marker
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

      print(
        'âœ… Marker du livreur ajoutÃ© Ã  la position: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
      );
    } catch (e) {
      print('âŒ Erreur lors de l\'ajout du marker: $e');
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
      print('âŒ Erreur lors de la crÃ©ation des marqueurs: $e');
      // Utiliser les marqueurs par dÃ©faut en cas d'erreur
      _driverMarkerIcon = // BitmapDescriptor.defaultMarkerWithHue(
        // BitmapDescriptor.hueBlue,
      );
      _clientMarkerIcon = // BitmapDescriptor.defaultMarkerWithHue(
        // BitmapDescriptor.hueGreen,
      );
    }
  }

  void _onLocationTap() async {
    print('ðŸ“ Bouton de localisation cliquÃ©');

    try {
      // Obtenir la position actuelle la plus rÃ©cente
      final currentPos = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );

      print(
        'ðŸ“ Position actuelle obtenue: ${currentPos.latitude}, ${currentPos.longitude}',
      );

      // Forcer la position dans le service de mouvement fluide
      _smoothMovementService.forcePosition(currentPos);

      if (_mapController != null) {
        await // _mapController!.animateCamera(
          // CameraUpdate.newLatLngZoom(
            // LatLng(currentPos.latitude, currentPos.longitude),
            16.0, // Zoom plus proche pour voir le mouvement fluide
          ),
        );

        // Afficher un message de confirmation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Position mise Ã  jour et centrÃ©e',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: AppColors.primaryRed,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('âŒ Erreur lors de l\'obtention de la position: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de l\'obtention de la position',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: AppColors.errorColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildGoogleMap() {
    /* return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: // LatLng(
          _currentPosition?.latitude ?? 5.3600,
          _currentPosition?.longitude ?? -4.0083,
        ),
        zoom: 14.0,
      ),
      mapType: _isDarkMode ? MapType.normal : MapType.normal,
      onMapCreated: (GoogleMapController controller) async {
        _mapController = controller;
        print('Carte Google Maps crÃ©Ã©e avec succÃ¨s');

        // Charger les icÃ´nes des markers
        await _loadMarkerIcons();

        // Si on a la position actuelle, on centre la carte dessus et on ajoute le marker
        if (_currentPosition != null) {
          await _addDriver// Marker();

          await // _mapController!.animateCamera(
            // CameraUpdate.newLatLngZoom(
              // LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              15.0,
            ),
          );
        }
      },
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled:
          false, // DÃ©sactivÃ© pour Ã©viter le doublon avec notre marqueur personnalisÃ©
      myLocationButtonEnabled: false,
      zoomGesturesEnabled: true,
      scrollGesturesEnabled: true,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: true,
    );
  }

  Future<void> _onAcceptOrder() async {
    if (_currentOrderNotification == null || _currentDriver == null) return;

    try {
      final supabase = Supabase.instance.client;
      final orderId = _currentOrderNotification!['id'];
      final driverId = _currentDriver!.id;

      print(
        'ðŸ”„ Tentative d\'acceptation de la commande: $orderId par le driver: $driverId',
      );

      // 1. VÃ©rifier que la commande est toujours disponible
      final orderCheck = await supabase
          .from('orders')
          .select('status, driver_id, delivery_lat, delivery_lng')
          .eq('id', orderId)
          .maybeSingle();

      if (orderCheck == null) {
        print('âŒ Commande introuvable: $orderId');
        _showErrorSnackBar('Commande introuvable');
        return;
      }

      if (orderCheck['status'] != 'ready_for_delivery') {
        print(
          'âŒ Commande dÃ©jÃ  prise ou non disponible: ${orderCheck['status']}',
        );
        _showErrorSnackBar('Cette commande n\'est plus disponible');
        setState(() {
          _currentOrderNotification = null;
        });
        return;
      }

      if (orderCheck['driver_id'] != null) {
        print(
          'âŒ Commande dÃ©jÃ  assignÃ©e Ã  un autre driver: ${orderCheck['driver_id']}',
        );
        _showErrorSnackBar(
          'Cette commande a dÃ©jÃ  Ã©tÃ© prise par un autre livreur',
        );
        setState(() {
          _currentOrderNotification = null;
        });
        return;
      }

      // 2. Mettre Ã  jour la commande avec le driver assignÃ© (verrouillage atomique)
      final updateResult = await supabase
          .from('orders')
          .update({
            'driver_id': driverId,
            'status': 'in_transit',
            'accepted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .eq('status', 'ready_for_delivery') // Double vÃ©rification
          .isFilter(
            'driver_id',
            null,
          ) // S'assurer qu'elle n'est pas dÃ©jÃ  assignÃ©e
          .select();

      if (updateResult.isEmpty) {
        print('âŒ Ã‰chec de l\'assignation - commande prise entre temps');
        _showErrorSnackBar('Cette commande a Ã©tÃ© prise par un autre livreur');
        setState(() {
          _currentOrderNotification = null;
        });
        return;
      }

      // 3. CrÃ©er l'entrÃ©e dans order_driver_assignments
      await supabase.from('order_driver_assignments').insert({
        'order_id': orderId,
        'driver_id': driverId,
        'assigned_at': DateTime.now().toIso8601String(),
      });

      print('âœ… Commande acceptÃ©e avec succÃ¨s: $orderId');

      // 4. Mettre Ã  jour le statut du driver
      await supabase
          .from('drivers')
          .update({
            'is_available': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', driverId);

      print(
        'âœ… Statut du driver mis Ã  jour: indisponible avec commande $orderId',
      );

      // 5. Afficher le client sur la carte
      final deliveryLat = orderCheck['delivery_lat'] as double?;
      final deliveryLng = orderCheck['delivery_lng'] as double?;

      if (deliveryLat != null && deliveryLng != null) {
        await _addClient// Marker(deliveryLat, deliveryLng);

        // DÃ©marre le mode navigation
        if (_currentPosition != null) {
          _navigationService.startNavigation(
            startLat: _currentPosition!.latitude,
            startLng: _currentPosition!.longitude,
            endLat: deliveryLat,
            endLng: deliveryLng,
          );

          // Afficher l'itinÃ©raire sur la carte
          await _addRouteToMap();
        }

        // Sauvegarde l'Ã©tat pour persistance
        await _saveActiveOrderState(_currentOrderNotification!);

        setState(() {
          _currentOrder = _currentOrderNotification;
          _isOnDelivery = true;
          _currentOrderNotification = null;
        });

        _showSuccessSnackBar('Commande acceptÃ©e ! Navigation activÃ©e...');
      } else {
        _showErrorSnackBar('Position de livraison introuvable');
      }
    } catch (e) {
      print('âŒ Erreur lors de l\'acceptation de la commande: $e');
      _showErrorSnackBar('Erreur lors de l\'acceptation de la commande');
    }
  }

  void _onDeclineOrder() {
    if (_currentOrderNotification != null) {
      final orderId = _currentOrderNotification!['id'] as int;
      print('âŒ Commande $orderId refusÃ©e');

      setState(() {
        _refusedOrders.add(orderId); // Ajouter Ã  la liste des refusÃ©es
        _currentOrderNotification = null;
        _currentOrderIndex = 0;

        // Si il y a d'autres commandes disponibles, afficher la suivante
        if (_availableOrders.isNotEmpty) {
          _showCurrentOrder();
        }
      });
    }
  }

  /// Sauvegarde l'Ã©tat de la commande active
  Future<void> _saveActiveOrderState(Map<String, dynamic> order) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_activeOrderKey, order['id'] as int);
    await prefs.setBool(_isOnDeliveryKey, true);

    if (order['delivery_lat'] != null && order['delivery_lng'] != null) {
      await prefs.setDouble(_clientLatKey, order['delivery_lat'] as double);
      await prefs.setDouble(_clientLngKey, order['delivery_lng'] as double);
    }

    print('ðŸ’¾ Ã‰tat de commande sauvegardÃ©: ${order['id']}');
  }

  /// Restaure l'Ã©tat de la commande active depuis le stockage local
  Future<void> _restoreActiveOrderState() async {
    final prefs = await SharedPreferences.getInstance();
    final activeOrderId = prefs.getInt(_activeOrderKey);
    final isOnDelivery = prefs.getBool(_isOnDeliveryKey) ?? false;
    final clientLat = prefs.getDouble(_clientLatKey);
    final clientLng = prefs.getDouble(_clientLngKey);

    if (activeOrderId != null &&
        isOnDelivery &&
        clientLat != null &&
        clientLng != null) {
      print('ðŸ”„ Restauration commande active: $activeOrderId');

      setState(() {
        _isOnDelivery = true;
      });

      // Afficher le marker client
      await _addClient// Marker(clientLat, clientLng);

      // DÃ©marrer la navigation si position disponible
      if (_currentPosition != null) {
        _navigationService.startNavigation(
          startLat: _currentPosition!.latitude,
          startLng: _currentPosition!.longitude,
          endLat: clientLat,
          endLng: clientLng,
        );

        // Afficher l'itinÃ©raire restaurÃ©
        await _addRouteToMap();
      }

      print('âœ… Ã‰tat restaurÃ© avec succÃ¨s');
    }
  }

  /// Nettoie l'Ã©tat sauvegardÃ©
  Future<void> _clearActiveOrderState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeOrderKey);
    await prefs.remove(_isOnDeliveryKey);
    await prefs.remove(_clientLatKey);
    await prefs.remove(_clientLngKey);

    print('ðŸ—‘ï¸ Ã‰tat de commande nettoyÃ©');
  }

  /// Finalise une commande (quand livraison terminÃ©e)
  Future<void> _finalizeOrder() async {
    setState(() {
      _currentOrder = null;
      _isOnDelivery = false;
    });

    // Nettoyer le marker client
    // _markers.removeWhere((m) => m.markerId == const MarkerId('client'));

    // Nettoyer la route
    await _removeRouteFromMap();

    // ArrÃªter la navigation
    _navigationService.stopNavigation();

    // Nettoyer l'Ã©tat sauvegardÃ©
    await _clearActiveOrderState();

    print('âœ… Commande finalisÃ©e');
    _showSuccessSnackBar('Livraison terminÃ©e !');
  }

  void _toggleNavigationMode() {
    if (_navigationService.isNavigationActive) {
      _navigationService.stopNavigation();
      _showSuccessSnackBar('Mode navigation dÃ©sactivÃ©');
    } else if (_currentPosition != null && _currentOrder != null) {
      final order = _currentOrder!;
      final deliveryLat = order['delivery_lat'] as double?;
      final deliveryLng = _currentOrder!['delivery_lng'] as double?;

      if (deliveryLat != null && deliveryLng != null) {
        _navigationService.startNavigation(
          startLat: _currentPosition!.latitude,
          startLng: _currentPosition!.longitude,
          endLat: deliveryLat,
          endLng: deliveryLng,
        );
        _showSuccessSnackBar('Mode navigation activÃ©');
      } else {
        _showErrorSnackBar('Aucune commande en cours');
      }
    } else {
      _showErrorSnackBar('Position indisponible ou aucune commande');
    }

    setState(() {}); // Rebuild pour mettre Ã  jour le bouton
  }

  // MÃ©thode supprimÃ©e - les markers sont maintenant chargÃ©s via _loadMarkerIcons()

  Future<void> _addRouteToMap() async {
    if (_mapController == null) return;

    try {
      // Obtenir la route depuis le NavigationService
      final routeCoordinates = _navigationService.currentRouteCoordinates;

      if (routeCoordinates.isEmpty) {
        print('âŒ Aucune route Ã  afficher');
        return;
      }

      // Convertir en LatLng
      final latLngs = routeCoordinates
          .map((coord) => // LatLng(coord['latitude']!, coord['longitude']!))
          .toList();

      // CrÃ©er la polyline avec geodesic pour suivre la route rÃ©elle
      final routePolyline = // Polyline(
        polylineId: const PolylineId('route'),
        points: latLngs,
        color: AppColors.primaryRed,
        width: 5,
        geodesic:
            true, // Suivre la courbure de la Terre pour une route plus rÃ©aliste
      );

      setState(() {
        // _polylines.add(routePolyline);
      });

      print('ðŸ›£ï¸ Route affichÃ©e sur la carte');
    } catch (e) {
      print('âŒ Erreur affichage route: $e');
    }
  }

  Future<void> _removeRouteFromMap() async {
    // _polylines.removeWhere((p) => p.polylineId == const PolylineId('route'));
    print('ðŸ—‘ï¸ Route supprimÃ©e de la carte');
  }

  Future<void> _addClient// Marker(double latitude, double longitude) async {
    if (_mapController == null) return;

    try {
      // Supprimer l'ancien marker client s'il existe
      // _markers.removeWhere((m) => m.markerId == const MarkerId('client'));

      // S'assurer que l'icÃ´ne est chargÃ©e
      if (_clientMarkerIcon == null) {
        await _loadMarkerIcons();
      }

      // CrÃ©er le nouveau marker client
      final clientMarker = // Marker(
        markerId: const MarkerId('client'),
        position: // LatLng(latitude, longitude),
        icon:
            _clientMarkerIcon ??
            // BitmapDescriptor.defaultMarkerWithHue(// BitmapDescriptor.hueGreen),
        anchor: const Offset(0.5, 1.0),
      );

      setState(() {
        // _markers.add(clientMarker);
      });

      print('âœ… Marker client ajoutÃ© Ã  la position: $latitude, $longitude');

      // Centrer la carte sur le client
      await // _mapController!.animateCamera(
        // CameraUpdate.newLatLngZoom(// LatLng(latitude, longitude), 15.0),
      );
    } catch (e) {
      print('âŒ Erreur lors de l\'ajout du marker client: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.successColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _positionChannel?.unsubscribe();
    _ordersSubscription?.cancel();
    _smoothPositionSubscription?.cancel();
    _smoothMovementService.dispose();
    _navigationService.stopNavigation(); // ArrÃªter la navigation au dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _isDarkMode
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        body: const LoadingState(message: 'Chargement de vos donnÃ©es...'),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: _isDarkMode
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        body: ErrorState(
          message: _errorMessage!,
          onRetry: () {
            setState(() {
              _errorMessage = null;
              _isLoading = true;
            });
            _loadDriverData();
          },
        ),
      );
    }

    if (_currentDriver == null) {
      return Scaffold(
        backgroundColor: _isDarkMode
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        body: const ErrorState(message: 'Aucune donnÃ©e de livreur trouvÃ©e'),
      );
    }

    return Scaffold(
      backgroundColor: _isDarkMode
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Stack(
        children: [
          // Layout principal
          ResponsiveLayout(
            mobile: _buildMobileLayout(),
            tablet: _buildTabletLayout(),
            desktop: _buildDesktopLayout(),
          ),

          // Card de notification de commande (conditionnel)
          if (_currentOrderNotification != null)
            Positioned(
              top: 100, // En dessous du header
              left: 20,
              right: 20,
              child: Column(
                children: [
                  // Indicateurs de pagination en haut
                  if (_availableOrders.length > 1)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_availableOrders.length, (
                          index,
                        ) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: index == _currentOrderIndex
                                  ? AppColors.primaryRed
                                  : AppColors.primaryRed.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),
                  // Card de commande avec animation
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(1.0, 0.0),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeInOut,
                                  ),
                                ),
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                    child: OrderNotificationCard(
                      key: ValueKey(_currentOrderNotification!['id']),
                      order: _currentOrderNotification!,
                      onAccept: _onAcceptOrder,
                      onDecline: _onDeclineOrder,
                    ),
                  ),
                  // Boutons de navigation en bas
                  if (_availableOrders.length > 1)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Bouton prÃ©cÃ©dent
                          GestureDetector(
                            onTap: _previousOrder,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryRed.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: AppColors.primaryRed.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.chevron_left,
                                color: AppColors.primaryRed,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Bouton suivant
                          GestureDetector(
                            onTap: _nextOrder,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryRed.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: AppColors.primaryRed.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.chevron_right,
                                color: AppColors.primaryRed,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          // Bouton de localisation flottant (amÃ©liorÃ©)
          Positioned(
            bottom: 90, // Au-dessus du bottom menu
            right: 20,
            child: GestureDetector(
              onTap: _onLocationTap,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: context.isMobile
          ? AnimatedBottomNav(currentIndex: _currentNavIndex, onTap: _onNavTap)
          : null,
    );
  }

  Widget _buildMobileLayout() {
    return Stack(
      children: [
        // Carte full screen
        Positioned.fill(child: _buildGoogleMap()),

        // Petit header simple
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              right: 20,
              bottom: 10,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryRed.withOpacity(0.9),
                  AppColors.primaryOrange.withOpacity(0.9),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                // Logo ChapFood
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/logo-chapfood.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Titre
                Expanded(
                  child: Text(
                    'ChapFood Livreur',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Notifications
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  onPressed: () {
                    // Notifications
                  },
                ),
              ],
            ),
          ),
        ),

        // Card flottant pour les infos du livreur
        Positioned(
          top: MediaQuery.of(context).padding.top + 70,
          left: 20,
          right: 20,
          child: _buildFloatingDriverCard(),
        ),

        // Bouton de navigation (en bas Ã  droite)
        Positioned(bottom: 100, right: 20, child: _buildNavigationButton()),

        // Bouton de finalisation quand livraison active (en haut Ã  droite)
        if (_isOnDelivery)
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            right: 20,
            child: _buildFinalizeButton(),
          ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        // Sidebar pour tablette
        Container(
          width: 250,
          color: _isDarkMode ? AppColors.cardBackgroundDark : Colors.white,
          child: Column(
            children: [
              // Header compact
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: Column(
                  children: [
                    Text(
                      'ChapFood',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Livreur',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              // Navigation
              Expanded(
                child: ListView(
                  children: [
                    _buildTabletNavItem(Icons.home, 'Accueil', 0),
                    _buildTabletNavItem(Icons.history, 'Historique', 1),
                    _buildTabletNavItem(Icons.attach_money, 'Revenus', 2),
                    _buildTabletNavItem(Icons.person, 'Profil', 3),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Contenu principal
        Expanded(child: _buildMobileLayout()),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return _buildTabletLayout(); // MÃªme layout que tablette pour l'instant
  }

  Widget _buildTabletNavItem(IconData icon, String label, int index) {
    final isActive = _currentNavIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primaryRed.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? AppColors.primaryRed : AppColors.textTertiary,
        ),
        title: Text(
          label,
          style: GoogleFonts.poppins(
            color: isActive ? AppColors.primaryRed : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () => _onNavTap(index),
      ),
    );
  }

  Widget _buildFinalizeButton() {
    return GestureDetector(
      onTap: _finalizeOrder,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryOrange,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Livraison terminÃ©e',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButton() {
    return GestureDetector(
      onTap: _toggleNavigationMode,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _navigationService.isNavigationActive
              ? AppColors.primaryRed
              : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: _navigationService.isNavigationActive
                ? Colors.transparent
                : AppColors.primaryRed.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Icon(
          _navigationService.isNavigationActive ? Icons.stop : Icons.navigation,
          color: _navigationService.isNavigationActive
              ? Colors.white
              : AppColors.primaryRed,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildFloatingDriverCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColors.primaryRed.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 0),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: AppColors.primaryRed.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar du livreur compact
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryRed, AppColors.primaryOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryRed.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _currentDriver!.name.substring(0, 1).toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Infos du livreur compactes
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentDriver!.name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _currentDriver!.vehicleType ?? 'Moto',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Row(
                      children: [
                        Icon(Icons.star, size: 12, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          _currentDriver!.rating?.toStringAsFixed(1) ?? '0.0',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Toggle de statut compact
          GestureDetector(
            onTap: _isUpdatingStatus ? null : _toggleDriverStatus,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isUpdatingStatus
                      ? [Colors.grey.shade400, Colors.grey.shade500]
                      : _isDriverAvailable
                      ? [Colors.green.shade400, Colors.green.shade600]
                      : [Colors.orange.shade400, Colors.orange.shade600],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (_isDriverAvailable ? Colors.green : Colors.orange)
                        .withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isUpdatingStatus)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    Icon(
                      _isDriverAvailable
                          ? Icons.check_circle
                          : Icons.pause_circle,
                      size: 16,
                      color: Colors.white,
                    ),
                  const SizedBox(width: 6),
                  Text(
                    _isUpdatingStatus
                        ? '...'
                        : _isDriverAvailable
                        ? 'Disponible'
                        : 'Indisponible',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

