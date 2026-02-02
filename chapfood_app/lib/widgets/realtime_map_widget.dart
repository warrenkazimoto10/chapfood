import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../utils/text_styles.dart';
import '../services/uber_style_tracking_service.dart';
import '../services/google_maps_routing_service.dart';
import '../widgets/delivery/driver_info_card.dart';

/// Widget de carte en temps réel pour suivre le livreur
class RealtimeMapWidget extends StatefulWidget {
  final String orderId;
  final String customerName;
  final double customerLatitude;
  final double customerLongitude;

  /// Statut de la commande (pending, ready_for_delivery, picked_up, in_transit, delivered...)
  final String orderStatus;
  final String driverName;
  final String driverPhone;
  final double driverLatitude;
  final double driverLongitude;
  final VoidCallback? onClose;

  const RealtimeMapWidget({
    super.key,
    required this.orderId,
    required this.customerName,
    required this.customerLatitude,
    required this.customerLongitude,
    required this.driverName,
    required this.driverPhone,
    required this.driverLatitude,
    required this.driverLongitude,
    required this.orderStatus,
    this.onClose,
  });

  @override
  State<RealtimeMapWidget> createState() => _RealtimeMapWidgetState();
}

class _RealtimeMapWidgetState extends State<RealtimeMapWidget> {
  GoogleMapController? _mapController;
  LatLng? _driverPosition;
  LatLng? _customerPosition;
  // Point fixe pour le restaurant (même coordonnées que côté livreur/admin)
  final LatLng _restaurantPosition = const LatLng(5.226313, -3.768063);
  final UberStyleTrackingService _trackingService = UberStyleTrackingService();
  StreamSubscription<DriverPosition>? _positionSubscription;
  RealtimeChannel? _orderStatusChannel;
  late String _currentOrderStatus;
  double? _latestDriverLat;
  double? _latestDriverLng;
  double? _lastRouteStartLat;
  double? _lastRouteStartLng;

  // Marqueurs et polylines
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  BitmapDescriptor? _driverMarkerIcon;
  BitmapDescriptor? _customerMarkerIcon;
  BitmapDescriptor? _restaurantMarkerIcon;
  RouteInfo? _currentRoute;
  Timer? _routeUpdateTimer;

  // Informations de suivi en temps réel
  double _currentSpeed = 0.0;
  Duration _eta = const Duration(minutes: 0);
  double _remainingDistance = 0.0;
  bool _isRealtimeMode = true;

  @override
  void initState() {
    super.initState();
    _currentOrderStatus = widget.orderStatus;
    _initializePositions();
    _loadDriverId();
    _subscribeToOrderStatus();
  }

  /// Charge l'ID du livreur depuis la base de données
  Future<void> _loadDriverId() async {
    try {
      final supabase = Supabase.instance.client;

      // Récupérer l'ID du livreur assigné à cette commande
      final response = await supabase
          .from('order_driver_assignments')
          .select('driver_id')
          .eq('order_id', int.tryParse(widget.orderId) ?? 0)
          .maybeSingle();

      if (response != null && response['driver_id'] != null) {
        final driverId = response['driver_id'] as int;
        _trackingService.setDriverId(driverId);

        // Démarrer le tracking si ce n'est pas déjà fait
        if (!_trackingService.isTracking) {
          _startTracking();
        } else {
          // Si déjà démarré, forcer la reconnexion Realtime
          _trackingService.retryRealtimeConnection();
        }

        print(
          '🚚 ID du livreur chargé: $driverId pour la commande ${widget.orderId}',
        );
      } else {
        print('⚠️ Aucun livreur assigné à la commande ${widget.orderId}');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement de l\'ID du livreur: $e');
    }
  }

  void _subscribeToOrderStatus() {
    final orderId = int.tryParse(widget.orderId);
    if (orderId == null) {
      print('⚠️ Impossible de s\'abonner au statut: orderId invalide');
      return;
    }

    print('📡 Abonnement au statut de la commande #$orderId...');

    final client = Supabase.instance.client;
    _orderStatusChannel =
        client
            .channel('order_status_$orderId')
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'orders',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'id',
                value: orderId,
              ),
              callback: (payload) {
                print('📨 Callback Realtime reçu pour commande #$orderId');
                print('   Payload: ${payload.newRecord}');
                if (!mounted) {
                  print('⚠️ Widget non monté, ignore la mise à jour');
                  return;
                }
                _handleOrderStatusUpdate(payload.newRecord);
              },
            )
          ..subscribe((status, [error]) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              print('✅ Abonnement Realtime réussi pour commande #$orderId');
              // Realtime fonctionne, mais on garde le polling comme fallback
            } else if (status == RealtimeSubscribeStatus.closed ||
                status == RealtimeSubscribeStatus.channelError) {
              print('❌ Erreur abonnement Realtime: $error');
              print('   Utilisation du mode polling uniquement');
            }
          });

    // Vérifier le statut immédiatement au démarrage
    _checkOrderStatus();

    // Démarrer un polling de fallback toutes les 5 secondes pour garantir la synchronisation
    _startStatusPolling();
  }

  Timer? _statusPollingTimer;

  void _startStatusPolling() {
    _statusPollingTimer?.cancel();
    _statusPollingTimer = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      await _checkOrderStatus();
    });
  }

  Future<void> _checkOrderStatus() async {
    final orderId = int.tryParse(widget.orderId);
    if (orderId == null) return;

    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('orders')
          .select('status')
          .eq('id', orderId)
          .maybeSingle();

      if (response != null) {
        final newStatus = response['status'] as String?;
        if (newStatus != null && newStatus != _currentOrderStatus) {
          print(
            '🔄 Statut détecté via polling: $_currentOrderStatus -> $newStatus',
          );
          if (mounted) {
            setState(() {
              _currentOrderStatus = newStatus;
            });
            _refreshForStatusChange();
          }
        }
      }
    } catch (e) {
      print('❌ Erreur lors de la vérification du statut: $e');
    }
  }

  void _handleOrderStatusUpdate(Map<String, dynamic>? newRecord) {
    if (newRecord == null) return;
    final newStatus = newRecord['status'] as String?;
    if (newStatus == null || newStatus == _currentOrderStatus) return;

    print('🔄 Statut de commande changé: $_currentOrderStatus -> $newStatus');

    setState(() {
      _currentOrderStatus = newStatus;
    });

    _refreshForStatusChange();

    // Recharger l'ID du livreur au cas où il aurait changé
    _loadDriverId();
  }

  Future<void> _refreshForStatusChange() async {
    await _generateRealRoute();
    await _refreshMarkersForStatus();
  }

  Future<void> _refreshMarkersForStatus() async {
    final driverLat =
        _latestDriverLat ?? _driverPosition?.latitude ?? widget.driverLatitude;
    final driverLng =
        _latestDriverLng ??
        _driverPosition?.longitude ??
        widget.driverLongitude;

    await _updateMarkers(driverLat: driverLat, driverLng: driverLng);
    _maybeRecalculateRouteOnMovement();
  }

  /// Met à jour les marqueurs sur la carte Google Maps
  Future<void> _updateMarkers({
    required double driverLat,
    required double driverLng,
  }) async {
    if (_mapController == null) return;

    setState(() {
      // Mettre à jour le marqueur du livreur
      _markers.removeWhere((m) => m.markerId == const MarkerId('driver'));
      _driverPosition = LatLng(driverLat, driverLng);
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverPosition!,
          icon:
              _driverMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          anchor: const Offset(0.5, 0.5),
        ),
      );

      // S'assurer que le marqueur du restaurant est présent
      _markers.removeWhere((m) => m.markerId == const MarkerId('restaurant'));
      _markers.add(
        Marker(
          markerId: const MarkerId('restaurant'),
          position: _restaurantPosition,
          icon:
              _restaurantMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          anchor: const Offset(0.5, 1.0),
        ),
      );

      // Ajouter le marqueur du client si en phase 2
      if (_isPhase2Status && _customerPosition != null) {
        _markers.removeWhere((m) => m.markerId == const MarkerId('customer'));
        _markers.add(
          Marker(
            markerId: const MarkerId('customer'),
            position: _customerPosition!,
            icon:
                _customerMarkerIcon ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            anchor: const Offset(0.5, 1.0),
          ),
        );
      } else {
        _markers.removeWhere((m) => m.markerId == const MarkerId('customer'));
      }
    });
  }

  /// Ajoute les marqueurs et calcule la route
  Future<void> _addMarkersAndRoute() async {
    if (_mapController == null || _driverPosition == null) return;

    await _updateMarkers(
      driverLat: _driverPosition!.latitude,
      driverLng: _driverPosition!.longitude,
    );
  }

  void _maybeRecalculateRouteOnMovement() {
    if (_latestDriverLat == null || _latestDriverLng == null) return;

    if (_lastRouteStartLat == null || _lastRouteStartLng == null) {
      _lastRouteStartLat = _latestDriverLat;
      _lastRouteStartLng = _latestDriverLng;
      return;
    }

    final distance = _distanceBetweenMeters(
      _lastRouteStartLat!,
      _lastRouteStartLng!,
      _latestDriverLat!,
      _latestDriverLng!,
    );

    // Recalculer la route si le livreur s'est déplacé de plus de 100 mètres
    if (distance > 100) {
      print(
        '🔄 Livreur déplacé de ${distance.toStringAsFixed(0)}m, recalcul de la route...',
      );
      _lastRouteStartLat = _latestDriverLat;
      _lastRouteStartLng = _latestDriverLng;
      _generateRealRoute();
    }
  }

  double _distanceBetweenMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371000; // mètres
    final dLat = (lat2 - lat1) * (math.pi / 180);
    final dLng = (lng2 - lng1) * (math.pi / 180);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180)) *
            math.cos(lat2 * (math.pi / 180)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _trackingService.stopTracking();
    _statusPollingTimer?.cancel();
    if (_orderStatusChannel != null) {
      try {
        Supabase.instance.client.removeChannel(_orderStatusChannel!);
      } catch (_) {}
      _orderStatusChannel = null;
    }
    super.dispose();
  }

  void _initializePositions() {
    // Position du client avec validation robuste
    if (widget.customerLatitude != 0 &&
        widget.customerLongitude != 0 &&
        widget.customerLatitude.isFinite &&
        widget.customerLongitude.isFinite) {
      _customerPosition = LatLng(
        widget.customerLatitude.toDouble(),
        widget.customerLongitude.toDouble(),
      );
      print(
        '✅ Position client valide: ${widget.customerLatitude}, ${widget.customerLongitude}',
      );
    } else {
      // Fallback Abidjan Plateau si invalide
      _customerPosition = const LatLng(5.3500, -4.0300);
      print(
        '⚠️ Coordonnées client invalides, fallback Abidjan Plateau appliqué',
      );
    }

    // Position du livreur avec validation robuste
    if (widget.driverLatitude != 0 &&
        widget.driverLongitude != 0 &&
        widget.driverLatitude.isFinite &&
        widget.driverLongitude.isFinite) {
      _driverPosition = LatLng(
        widget.driverLatitude.toDouble(),
        widget.driverLongitude.toDouble(),
      );
      _latestDriverLat = widget.driverLatitude;
      _latestDriverLng = widget.driverLongitude;
      print(
        '✅ Position livreur valide: ${widget.driverLatitude}, ${widget.driverLongitude}',
      );
    } else {
      // Fallback Treichville si invalide
      _driverPosition = const LatLng(5.3563, -4.0363);
      _latestDriverLat = 5.3563;
      _latestDriverLng = -4.0363;
      print('⚠️ Coordonnées livreur invalides, fallback Treichville appliqué');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Suivi Commande #${_truncateOrderId(widget.orderId)}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: widget.onClose ?? () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Carte Google Maps
          GoogleMap(
            key: const ValueKey("mapWidget"),
            initialCameraPosition: CameraPosition(
              target: LatLng(
                (widget.driverLatitude + widget.customerLatitude) / 2,
                (widget.driverLongitude + widget.customerLongitude) / 2,
              ),
              zoom: 13.0,
            ),
            onMapCreated: (GoogleMapController controller) async {
              _mapController = controller;
              await _loadMarkerIcons();
              await _addMarkersAndRoute();
              await _generateRealRoute();
              _startTracking();
            },
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
          ),

          // Indicateur de mode de connexion (en haut à gauche)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isRealtimeMode
                    ? Colors.green.withOpacity(0.9)
                    : Colors.orange.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isRealtimeMode ? Icons.wifi : Icons.update,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isRealtimeMode ? 'Temps réel' : 'Mode polling',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom sheet draggable avec les informations de livraison (style similaire livreur)
          DraggableScrollableSheet(
            initialChildSize: 0.28,
            minChildSize: 0.2,
            maxChildSize: 0.85,
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
                    // Handle de drag
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Livreur ChapFood',
                              style: AppTextStyles.foodItemTitle.copyWith(
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.driverName,
                              style: AppTextStyles.foodItemDescription.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.driverPhone,
                              style: AppTextStyles.foodItemDescription,
                            ),
                            const SizedBox(height: 12),

                            // Card d'informations du livreur style Uber
                            DriverInfoCard(
                              driverName: widget.driverName,
                              driverPhone: widget.driverPhone,
                            ),
                            const SizedBox(height: 16),

                            // Infos de suivi (vitesse / ETA / distance)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Vitesse',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_currentSpeed.toStringAsFixed(0)} km/h',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Temps restant',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_eta.inMinutes} min',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Distance',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_remainingDistance.toStringAsFixed(1)} km',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Étapes de la livraison (vue client)
                            _buildClientSteps(),
                            const SizedBox(height: 16),

                            // Légende des boutons de centrage
                            _buildMapControlsLegend(),
                            const SizedBox(height: 16),

                            // Bouton appeler le livreur
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _callDriver(),
                                icon: const Icon(Icons.phone, size: 18),
                                label: const Text('Appeler le livreur'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
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

          // Boutons de navigation flottants (en haut à droite)
          Positioned(
            top: 56,
            right: 16,
            child: Column(
              children: [
                // Bouton "Cibler Livreur"
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: FloatingActionButton.small(
                    heroTag: "center_driver",
                    onPressed: () => _centerOnDriver(),
                    backgroundColor: Colors.blue,
                    child: const Icon(
                      Icons.delivery_dining,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),

                // Bouton "Cibler Client / Restaurant"
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: FloatingActionButton.small(
                    heroTag: "center_customer",
                    onPressed: _isPhase2Status
                        ? () => _centerOnCustomer()
                        : () => _centerOnRestaurant(),
                    backgroundColor: _isPhase2Status
                        ? Colors.red
                        : Colors.orange,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),

                // Bouton "Vue d'ensemble"
                FloatingActionButton.small(
                  heroTag: "fit_both",
                  onPressed: () => _fitBothPoints(),
                  backgroundColor: Colors.green,
                  child: const Icon(
                    Icons.zoom_out_map,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construit les différentes étapes côté client et met en avant l'étape actuelle
  Widget _buildClientSteps() {
    // Déterminer l'étape en fonction du statut
    // 1: Aller au restaurant (ready_for_delivery)
    // 2: Repas récupéré (picked_up)
    // 3: En route vers vous (in_transit)
    // 4: Livré (delivered)
    final status = _currentOrderStatus;
    bool step1Completed = false;
    bool step2Completed = false;
    bool step3Completed = false;
    bool step4Completed = false;

    int currentStep = 1;

    if (status == 'ready_for_delivery') {
      currentStep = 1;
    } else if (status == 'picked_up') {
      step1Completed = true;
      currentStep = 2;
    } else if (status == 'in_transit') {
      step1Completed = true;
      step2Completed = true;
      currentStep = 3;
    } else if (status == 'delivered') {
      step1Completed = true;
      step2Completed = true;
      step3Completed = true;
      step4Completed = true;
      currentStep = 4;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Étapes de la livraison',
          style: AppTextStyles.foodItemTitle.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 8),
        _buildStepRow(
          label: '1. Le livreur va au restaurant',
          icon: Icons.restaurant,
          isCompleted: step1Completed || currentStep > 1,
          isCurrent: currentStep == 1,
        ),
        _buildStepRow(
          label: '2. Commande récupérée',
          icon: Icons.takeout_dining,
          isCompleted: step2Completed || currentStep > 2,
          isCurrent: currentStep == 2,
        ),
        _buildStepRow(
          label: '3. En route vers vous',
          icon: Icons.directions_bike,
          isCompleted: step3Completed || currentStep > 3,
          isCurrent: currentStep == 3,
        ),
        _buildStepRow(
          label: '4. Commande livrée',
          icon: Icons.check_circle_outline,
          isCompleted: step4Completed,
          isCurrent: currentStep == 4,
        ),
      ],
    );
  }

  Widget _buildStepRow({
    required String label,
    required IconData icon,
    required bool isCompleted,
    required bool isCurrent,
  }) {
    final Color activeColor = isCompleted
        ? Colors.green
        : (isCurrent ? Colors.orange : Colors.grey);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCurrent ? activeColor.withOpacity(0.15) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCurrent ? activeColor : Colors.grey.shade300,
                width: isCurrent ? 2 : 1,
              ),
            ),
            child: Icon(icon, size: 20, color: activeColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: (isCompleted || isCurrent)
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: (isCompleted || isCurrent)
                        ? Colors.black87
                        : Colors.grey.shade600,
                  ),
                ),
                if (isCurrent)
                  Text(
                    'En cours...',
                    style: TextStyle(
                      fontSize: 11,
                      color: activeColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          if (isCompleted)
            const Icon(Icons.check, size: 18, color: Colors.green),
        ],
      ),
    );
  }

  Widget _buildMapControlsLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Légende des boutons carte',
          style: AppTextStyles.foodItemTitle.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _legendChip(
              Icons.delivery_dining,
              Colors.blue,
              'Centrer sur le livreur',
            ),
            _legendChip(
              Icons.restaurant,
              Colors.orange,
              'Centrer sur le restaurant (phase 1)',
            ),
            _legendChip(
              Icons.location_on,
              Colors.red,
              'Centrer sur le client (phase 2)',
            ),
            _legendChip(Icons.zoom_out_map, Colors.green, 'Vue d’ensemble'),
          ],
        ),
      ],
    );
  }

  Widget _legendChip(IconData icon, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  bool get _isPhase2Status {
    return _currentOrderStatus == 'picked_up' ||
        _currentOrderStatus == 'in_transit' ||
        _currentOrderStatus == 'delivered';
  }

  void _startTracking() {
    _trackingService.startTracking();
    _positionSubscription = _trackingService.positionStream.listen(
      (position) {
        if (!mounted) return;

        // Mettre à jour les dernières positions connues
        _latestDriverLat = position.latitude;
        _latestDriverLng = position.longitude;

        _updateDriverMarker(position);
        _updateTrackingInfo(position);

        // Vérifier si on doit recalculer la route (si le livreur s'est déplacé significativement)
        _maybeRecalculateRouteOnMovement();
      },
      onError: (error) {
        print('❌ Erreur dans le stream de position: $error');
        // Tentative de reconnexion après 3 secondes
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _trackingService.isRealtimeMode == false) {
            print('🔄 Tentative de reconnexion après erreur...');
            _trackingService.retryRealtimeConnection();
          }
        });
      },
    );
  }

  /// Met à jour les informations de suivi (vitesse, ETA, distance)
  void _updateTrackingInfo(DriverPosition position) {
    if (mounted) {
      setState(() {
        _currentSpeed = position.speed;
        _eta = _trackingService.getEstimatedTimeOfArrival();
        _remainingDistance = _trackingService.getRemainingDistance();
        _isRealtimeMode = _trackingService.isRealtimeMode;
      });
    }
  }

  Future<void> _updateDriverMarker(DriverPosition position) async {
    if (_mapController == null) return;

    try {
      _latestDriverLat = position.latitude;
      _latestDriverLng = position.longitude;
      _driverPosition = LatLng(position.latitude, position.longitude);

      await _updateMarkers(
        driverLat: position.latitude,
        driverLng: position.longitude,
      );
      _maybeRecalculateRouteOnMovement();
    } catch (e) {
      print('❌ Erreur lors de la mise à jour du marqueur: $e');
    }
  }

  /// Génère une route réelle en utilisant Google Directions API
  Future<void> _generateRealRoute() async {
    if (_mapController == null) return;

    final isPhase2 = _isPhase2Status;
    final startLat =
        _latestDriverLat ?? _driverPosition?.latitude ?? widget.driverLatitude;
    final startLng =
        _latestDriverLng ??
        _driverPosition?.longitude ??
        widget.driverLongitude;

    final customerLat = _customerPosition?.latitude ?? widget.customerLatitude;
    final customerLng =
        _customerPosition?.longitude ?? widget.customerLongitude;

    final targetLat = isPhase2 ? customerLat : _restaurantPosition.latitude;
    final targetLng = isPhase2 ? customerLng : _restaurantPosition.longitude;

    try {
      print('🗺️ Génération de route réelle avec Google Maps...');
      print('📍 Départ livreur: $startLat, $startLng');
      print(
        isPhase2
            ? '📍 Arrivée client: $targetLat, $targetLng'
            : '📍 Arrivée restaurant: $targetLat, $targetLng',
      );

      final route = await GoogleMapsRoutingService.getRoute(
        startLat: startLat,
        startLng: startLng,
        endLat: targetLat,
        endLng: targetLng,
      );

      if (route != null) {
        setState(() {
          _currentRoute = route;
          _remainingDistance = route.distance / 1000; // Convertir en km
          _eta = Duration(seconds: route.duration.round());
        });

        // Dessiner la route
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: route.coordinates,
            color: Colors.blue,
            width: 5,
            geodesic: true, // Suivre la courbure de la Terre
          ),
        );

        // Centrer la carte sur la route
        await _centerMapOnRoute(route.coordinates);

        _lastRouteStartLat = startLat;
        _lastRouteStartLng = startLng;

        print(
          '✅ Route réelle générée: ${route.formattedDistance} • ${route.formattedDuration}',
        );
      } else {
        print('❌ Impossible de générer la route');
        // Fallback: ligne droite
        _drawFallbackRoute(startLat, startLng, targetLat, targetLng);
      }
    } catch (e) {
      print('❌ Erreur lors de la génération de route: $e');
      _drawFallbackRoute(startLat, startLng, targetLat, targetLng);
    }
  }

  /// Dessine une route de secours (ligne droite)
  void _drawFallbackRoute(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [LatLng(startLat, startLng), LatLng(endLat, endLng)],
          color: Colors.blue.withOpacity(0.5),
          width: 3,
          geodesic: true,
        ),
      );
    });
  }

  /// Centre la carte sur le livreur
  Future<void> _centerOnDriver() async {
    if (_mapController == null || _driverPosition == null) return;

    print('🎯 Centrage sur le livreur');
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _driverPosition!, zoom: 16.0),
      ),
    );
  }

  Future<void> _centerOnRestaurant() async {
    if (_mapController == null) return;

    print('🎯 Centrage sur le restaurant');
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _restaurantPosition, zoom: 16.0),
      ),
    );
  }

  /// Centre la carte sur le client
  Future<void> _centerOnCustomer() async {
    if (_mapController == null || _customerPosition == null) return;

    print('🎯 Centrage sur le client');
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _customerPosition!, zoom: 16.0),
      ),
    );
  }

  /// Ajuste la vue pour voir les deux points
  Future<void> _fitBothPoints() async {
    if (_mapController == null ||
        _driverPosition == null ||
        _customerPosition == null)
      return;

    print('🎯 Vue d\'ensemble des deux points');

    // Calculer le centre entre les deux points
    final centerLat =
        (_driverPosition!.latitude + _customerPosition!.latitude) / 2;
    final centerLng =
        (_driverPosition!.longitude + _customerPosition!.longitude) / 2;

    // Calculer la distance pour ajuster le zoom
    final latDiff = (_driverPosition!.latitude - _customerPosition!.latitude)
        .abs();
    final lngDiff = (_driverPosition!.longitude - _customerPosition!.longitude)
        .abs();
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

    // Ajuster le zoom en fonction de la distance
    double zoom = 13.0;
    if (maxDiff > 0.01) zoom = 12.0;
    if (maxDiff > 0.05) zoom = 11.0;
    if (maxDiff > 0.1) zoom = 10.0;

    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(centerLat, centerLng), zoom: zoom),
      ),
    );
  }

  /// Tronque l'ID de commande de manière sécurisée
  String _truncateOrderId(String orderId) {
    if (orderId.length <= 8) {
      return orderId;
    }
    return orderId.substring(0, 8);
  }

  /// Appelle le livreur
  Future<void> _callDriver() async {
    print('📞 Appel du livreur: ${widget.driverPhone}');

    // Nettoyer le numéro de téléphone (enlever les espaces et caractères spéciaux)
    final cleanPhoneNumber = widget.driverPhone.replaceAll(
      RegExp(r'[^\d+]'),
      '',
    );
    final phoneUri = Uri.parse('tel:$cleanPhoneNumber');

    try {
      // Vérifier si l'application peut ouvrir l'URI
      if (await canLaunchUrl(phoneUri)) {
        // Ouvrir l'application de téléphone avec le numéro prérempli
        await launchUrl(phoneUri);

        // Afficher une confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ouverture de l\'appel vers ${widget.driverName}...'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Si l'app de téléphone n'est pas disponible
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'ouvrir l\'application de téléphone'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur lors de l\'ouverture de l\'appel: $e');

      // Afficher une erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'ouverture de l\'appel: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
