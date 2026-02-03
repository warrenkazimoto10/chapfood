import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;

import '../config/osm_config.dart';
import '../utils/text_styles.dart';
import '../services/uber_style_tracking_service.dart';
import '../services/osrm_routing_service.dart';
import '../widgets/delivery/driver_info_card.dart';

/// Widget de carte OSM en temps réel pour suivre le livreur.
class RealtimeMapWidget extends StatefulWidget {
  final String orderId;
  final String customerName;
  final double customerLatitude;
  final double customerLongitude;
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
    required this.orderStatus,
    required this.driverName,
    required this.driverPhone,
    required this.driverLatitude,
    required this.driverLongitude,
    this.onClose,
  });

  @override
  State<RealtimeMapWidget> createState() => _RealtimeMapWidgetState();
}

class _RealtimeMapWidgetState extends State<RealtimeMapWidget> {
  final MapController _mapController = MapController();
  LatLng? _driverPosition;
  LatLng? _customerPosition;
  static const LatLng _restaurantPosition = LatLng(5.226313, -3.768063);

  final UberStyleTrackingService _trackingService = UberStyleTrackingService();
  StreamSubscription<DriverPosition>? _positionSubscription;
  RealtimeChannel? _orderStatusChannel;
  late String _currentOrderStatus;

  double? _latestDriverLat;
  double? _latestDriverLng;
  double? _lastRouteStartLat;
  double? _lastRouteStartLng;

  List<LatLng> _routePoints = [];
  Duration _eta = const Duration(minutes: 0);
  double _remainingDistance = 0.0;
  bool _isRealtimeMode = true;
  Timer? _statusPollingTimer;

  bool get _isPhase2Status =>
      _currentOrderStatus == 'picked_up' || _currentOrderStatus == 'in_transit';

  @override
  void initState() {
    super.initState();
    _currentOrderStatus = widget.orderStatus;
    _initializePositions();
    _loadDriverId();
    _subscribeToOrderStatus();
  }

  void _initializePositions() {
    if (widget.customerLatitude != 0 &&
        widget.customerLongitude != 0 &&
        widget.customerLatitude.isFinite &&
        widget.customerLongitude.isFinite) {
      _customerPosition = LatLng(
        widget.customerLatitude,
        widget.customerLongitude,
      );
    } else {
      _customerPosition = const LatLng(5.3500, -4.0300);
    }
    if (widget.driverLatitude != 0 &&
        widget.driverLongitude != 0 &&
        widget.driverLatitude.isFinite &&
        widget.driverLongitude.isFinite) {
      _driverPosition = LatLng(widget.driverLatitude, widget.driverLongitude);
      _latestDriverLat = widget.driverLatitude;
      _latestDriverLng = widget.driverLongitude;
    } else {
      _driverPosition = const LatLng(5.3563, -4.0363);
      _latestDriverLat = 5.3563;
      _latestDriverLng = -4.0363;
    }
  }

  Future<void> _loadDriverId() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('order_driver_assignments')
          .select('driver_id')
          .eq('order_id', int.tryParse(widget.orderId) ?? 0)
          .maybeSingle();

      if (response != null && response['driver_id'] != null) {
        final driverId = response['driver_id'] as int;
        _trackingService.setDriverId(driverId);
        if (!_trackingService.isTracking) {
          _startTracking();
        } else {
          _trackingService.retryRealtimeConnection();
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _generateRealRoute();
        });
      }
    } catch (_) {}
  }

  void _subscribeToOrderStatus() {
    try {
      _orderStatusChannel = Supabase.instance.client
          .channel('order_status_${widget.orderId}')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'orders',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: int.tryParse(widget.orderId) ?? 0,
            ),
            callback: (payload) {
              final newStatus = payload.newRecord['status'] as String?;
              if (newStatus != null && mounted) {
                setState(() => _currentOrderStatus = newStatus);
                _generateRealRoute();
              }
            },
          )
          .subscribe();
    } catch (_) {}
  }

  void _startTracking() {
    _trackingService.startTracking();
    _positionSubscription = _trackingService.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _latestDriverLat = position.latitude;
          _latestDriverLng = position.longitude;
          _driverPosition = LatLng(position.latitude, position.longitude);
          _eta = _trackingService.getEstimatedTimeOfArrival();
          _remainingDistance = _trackingService.getRemainingDistance();
          _isRealtimeMode = _trackingService.isRealtimeMode;
        });
        _maybeRecalculateRouteOnMovement();
      }
    });
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
    if (distance > 100) {
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
    return geo.Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  Future<void> _generateRealRoute() async {
    final startLat =
        _latestDriverLat ?? _driverPosition?.latitude ?? widget.driverLatitude;
    final startLng =
        _latestDriverLng ??
        _driverPosition?.longitude ??
        widget.driverLongitude;
    final customerLat = _customerPosition?.latitude ?? widget.customerLatitude;
    final customerLng =
        _customerPosition?.longitude ?? widget.customerLongitude;
    final targetLat = _isPhase2Status
        ? customerLat
        : _restaurantPosition.latitude;
    final targetLng = _isPhase2Status
        ? customerLng
        : _restaurantPosition.longitude;

    try {
      final points = await OsrmRoutingService.getRoute(
        originLat: startLat,
        originLng: startLng,
        destLat: targetLat,
        destLng: targetLng,
      );
      if (points != null && points.length >= 2 && mounted) {
        final routeLatLngs = points.map((p) => LatLng(p[0], p[1])).toList();
        double dist = 0;
        for (int i = 1; i < routeLatLngs.length; i++) {
          dist += _distanceBetweenMeters(
            routeLatLngs[i - 1].latitude,
            routeLatLngs[i - 1].longitude,
            routeLatLngs[i].latitude,
            routeLatLngs[i].longitude,
          );
        }
        setState(() {
          _routePoints = routeLatLngs;
          _remainingDistance = dist / 1000;
          _eta = Duration(
            minutes: (dist / 1000 / 30 * 60).round().clamp(1, 120),
          );
          _lastRouteStartLat = startLat;
          _lastRouteStartLng = startLng;
        });
      } else {
        _drawFallbackRoute(startLat, startLng, targetLat, targetLng);
      }
    } catch (_) {
      _drawFallbackRoute(startLat, startLng, targetLat, targetLng);
    }
  }

  void _drawFallbackRoute(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    setState(() {
      _routePoints = [LatLng(startLat, startLng), LatLng(endLat, endLng)];
    });
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
    }
    super.dispose();
  }

  String _truncateOrderId(String orderId) {
    return orderId.length <= 8 ? orderId : orderId.substring(0, 8);
  }

  Future<void> _callDriver() async {
    final cleanPhone = widget.driverPhone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ouverture de l\'appel vers le livreur...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final centerLat =
        ((_driverPosition?.latitude ?? widget.driverLatitude) +
            (_customerPosition?.latitude ?? widget.customerLatitude)) /
        2;
    final centerLng =
        ((_driverPosition?.longitude ?? widget.driverLongitude) +
            (_customerPosition?.longitude ?? widget.customerLongitude)) /
        2;

    final markers = <Marker>[];
    if (_driverPosition != null) {
      markers.add(
        Marker(
          point: _driverPosition!,
          width: 40,
          height: 40,
          child: const Icon(
            Icons.delivery_dining,
            color: Colors.blue,
            size: 40,
          ),
        ),
      );
    }
    markers.add(
      Marker(
        point: _restaurantPosition,
        width: 32,
        height: 32,
        child: const Icon(Icons.restaurant, color: Colors.orange, size: 32),
      ),
    );
    if (_isPhase2Status && _customerPosition != null) {
      markers.add(
        Marker(
          point: _customerPosition!,
          width: 32,
          height: 32,
          child: const Icon(
            Icons.person_pin_circle,
            color: Colors.red,
            size: 32,
          ),
        ),
      );
    }

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
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(centerLat, centerLng),
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: OsmConfig.tileUrlTemplate,
                userAgentPackageName: 'com.chapfood.app',
                maxZoom: 19,
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.blue,
                      strokeWidth: 5,
                    ),
                  ],
                ),
              MarkerLayer(markers: markers),
              RichAttributionWidget(
                animationConfig: const ScaleRAWA(),
                showFlutterMapAttribution: false,
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    prependCopyright: true,
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isRealtimeMode ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
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
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
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
                            DriverInfoCard(
                              driverName: widget.driverName,
                              driverPhone: widget.driverPhone,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        '${_eta.inMinutes} min',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const Text(
                                        'ETA',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        '${_remainingDistance.toStringAsFixed(1)} km',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const Text(
                                        'Distance',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _callDriver,
                                icon: const Icon(Icons.phone),
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
        ],
      ),
    );
  }
}
