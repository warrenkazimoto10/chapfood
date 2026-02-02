import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/map/mapbox_map_widget.dart';
import '../../widgets/map/mapbox_directional_marker.dart';
import '../../core/map_helpers.dart';
import '../../services/location_service.dart';
import '../../constants/app_colors.dart';
import '../../widgets/dashboard_bottom_sheet.dart';
import '../../core/position_interpolator.dart';
import '../../services/order_service.dart';
import '../../models/order_model.dart';
import '../../widgets/order_notification_sheet.dart';
import '../../services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  MapboxAnnotationHelper? _annotationHelper;
  MapboxCameraHelper? _cameraHelper;
  geo.Position? _currentPosition;
  StreamSubscription<geo.Position>? _positionSubscription;
  StreamSubscription<List<OrderModel>>? _ordersSubscription;
  bool _isMapReady = false;
  bool _isOnline = false;
  
  // Interpolation pour mouvement fluide
  final PositionInterpolator _interpolator = PositionInterpolator();
  Timer? _interpolationTimer;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _startListeningToOrders();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _ordersSubscription?.cancel();
    _interpolationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    // ignore: avoid_print
    print('🔍 Initializing location...');
    
    final hasPermission = await LocationService.checkLocationPermission();
    // ignore: avoid_print
    print('📱 Location permission: $hasPermission');
    
    if (hasPermission) {
      final position = await LocationService.getCurrentPosition();
      // ignore: avoid_print
      print('📍 Initial position: $position');
      
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
      
      // ignore: avoid_print
      print('🎧 Starting location stream...');
      _startLocationTracking();
    } else {
      // ignore: avoid_print
      print('❌ Location permission denied!');
    }
  }

  void _startLocationTracking() {
    _positionSubscription = LocationService.getPositionStream().listen(
      (position) {
        // ignore: avoid_print
        print('📍 New GPS position: ${position.latitude}, ${position.longitude}, heading: ${position.heading}');
        
        // Définir la nouvelle cible pour l'interpolation
        _interpolator.setTarget(position);
        
        // Démarrer le timer d'interpolation si pas déjà actif
        if (_interpolationTimer == null || !_interpolationTimer!.isActive) {
          _startInterpolationTimer();
        }
      },
      onError: (error) {
        // ignore: avoid_print
        print('❌ Location stream error: $error');
      },
      onDone: () {
        // ignore: avoid_print
        print('⚠️ Location stream closed');
      },
    );
    
    // ignore: avoid_print
    print('✅ Location stream listener attached');
  }
  
  void _startInterpolationTimer() {
    int frameCount = 0;
    DateTime lastUpdate = DateTime.now();
    
    // Mettre à jour la position interpolée 30 fois par seconde
    _interpolationTimer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      frameCount++;
      
      final interpolatedPosition = _interpolator.getCurrentPosition();
      
      if (interpolatedPosition != null) {
        setState(() {
          _currentPosition = interpolatedPosition;
        });
        
        // Mettre à jour le marqueur seulement toutes les 3 frames (10 FPS au lieu de 30)
        // Cela réduit le clignotement tout en gardant un mouvement fluide
        if (frameCount % 3 == 0) {
          _updateDriverMarker();
        }
        
        lastUpdate = DateTime.now();
      }
      
      // Arrêter le timer si l'interpolation est terminée
      // OU si aucune nouvelle position GPS depuis 5 secondes
      if (!_interpolator.isInterpolating || 
          DateTime.now().difference(lastUpdate).inSeconds > 5) {
        timer.cancel();
        _interpolationTimer = null;
        // ignore: avoid_print
        print('⏸️ Interpolation arrêtée');
      }
    });
  }
  
  void _startListeningToOrders() {
    _ordersSubscription = OrderService.listenToReadyOrders().listen((orders) {
      // ignore: avoid_print
      print('📦 Received ${orders.length} ready orders');
      
      // Afficher notification seulement si en ligne et qu'il y a des commandes
      if (orders.isNotEmpty && _isOnline && mounted) {
        _showOrderNotification(orders.first);
      }
    });
  }
  
  void _showOrderNotification(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderNotificationSheet(
        order: order,
        onAccept: () => _handleOrderAccept(order),
        onReject: () {
          // ignore: avoid_print
          print('❌ Commande ${order.id} refusée');
        },
      ),
    );
  }
  
  Future<void> _checkForOrders() async {
    // ignore: avoid_print
    print('🔍 Vérification manuelle des commandes...');
    
    final orders = await OrderService.getReadyOrders();
    
    if (orders.isNotEmpty && mounted) {
      // ignore: avoid_print
      print('📦 ${orders.length} commandes trouvées, affichage notification');
      _showOrderNotification(orders.first);
    } else {
      // ignore: avoid_print
      print('📭 Aucune commande disponible');
    }
  }
  
  Future<void> _handleOrderAccept(OrderModel order) async {
    try {
      final driverInfo = await AuthService.getDriverInfo();
      
      if (driverInfo == null || driverInfo['id'] == null) {
        // ignore: avoid_print
        print('❌ Driver ID not found');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur: Informations du chauffeur introuvables'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      final driverId = driverInfo['id'] as int;
      
      final success = await OrderService.acceptOrder(order.id, driverId);
      
      if (success && mounted) {
        // ignore: avoid_print
        print('✅ Commande ${order.id} acceptée avec succès');
        
        // TODO: Navigation vers écran de livraison
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande acceptée ! Navigation à venir...'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande déjà acceptée par un autre livreur'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Erreur acceptation commande: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onMapCreated(MapboxMap controller) async {
    _annotationHelper = MapboxAnnotationHelper(controller);
    _cameraHelper = MapboxCameraHelper(controller);
    
    await _annotationHelper!.initialize();
    
    // Load icons
    final driverImageBytes = await MapboxDirectionalMarker.createSimpleMarkerImage(
      color: AppColors.secondary,
      size: 25.0, // Taille réduite
    );
    final driverImage = MbxImage(width: 25, height: 25, data: driverImageBytes);
    await controller.style.addStyleImage('driver_icon', 1.0, driverImage, false, [], [], null);

    setState(() {
      _isMapReady = true;
    });

    // ignore: avoid_print
    print('✅ Map is ready!');

    if (_currentPosition != null) {
      // ignore: avoid_print
      print('🎯 Updating marker with existing position');
      _updateDriverMarker();
      _centerMapOnUser();
    }
  }

  Future<void> _updateDriverMarker() async {
    if (!_isMapReady || _currentPosition == null || _annotationHelper == null) {
      // ignore: avoid_print
      print('⚠️ Cannot update marker: mapReady=$_isMapReady, position=${_currentPosition != null}, helper=${_annotationHelper != null}');
      return;
    }

    // ignore: avoid_print
    print('🚗 Updating driver marker at ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');

    await _annotationHelper!.addOrUpdatePointAnnotation(
      id: 'driver',
      lat: _currentPosition!.latitude,
      lng: _currentPosition!.longitude,
      iconImage: 'driver_icon',
      iconRotate: _currentPosition!.heading,
    );
  }

  Future<void> _centerMapOnUser() async {
    if (!_isMapReady || _currentPosition == null || _cameraHelper == null) return;

    await _cameraHelper!.animateTo(
      lat: _currentPosition!.latitude,
      lng: _currentPosition!.longitude,
      zoom: 17.0, // Zoom plus proche pour voir les détails
      pitch: 45.0, // Inclinaison pour la 3D
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _currentPosition == null
              ? const Center(child: CircularProgressIndicator())
              : MapboxMapWidget(
                  initialPosition: _currentPosition,
                  onMapCreated: _onMapCreated,
                ),
          
          // Overlay sombre quand hors ligne
          if (!_isOnline)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.power_settings_new,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Vous êtes hors ligne',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Passez en ligne pour recevoir des commandes',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          
          // Card flottant en haut (header)
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: DashboardBottomSheet(
              onStatusChanged: (status) {
                setState(() {
                  _isOnline = status;
                });
                
                // Vérifier les commandes quand on passe en ligne
                if (status) {
                  _checkForOrders();
                }
              },
            ),
          ),
          
          // FAB repositionné
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton(
              onPressed: _centerMapOnUser,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
