import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';

class GoogleMapsService {
  static final GoogleMapsService _instance = GoogleMapsService._internal();
  factory GoogleMapsService() => _instance;
  GoogleMapsService._internal();

  final Logger _logger = Logger();

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  Marker? _driverMarker;

  // Configuration
  static const double _targetMarkerSize = 48.0;
  BitmapDescriptor? _driverMarkerIcon;

  /// Initialise le service de carte
  Future<void> initialize(GoogleMapController controller) async {
    _mapController = controller;

    try {
      // Charger l'image du marker
      await _loadDriverMarkerIcon();

      _logger.i('GoogleMapsService initialisé avec succès');
    } catch (e) {
      _logger.e('Erreur lors de l\'initialisation du GoogleMapsService: $e');
      rethrow;
    }
  }

  /// Charge l'icône du marker depuis les assets
  Future<void> _loadDriverMarkerIcon() async {
    try {
      _driverMarkerIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/images/marker_livreur.png',
      );

      _logger.i('Icône du marker livreur chargée avec succès');
    } catch (e) {
      _logger.w(
        'Erreur lors du chargement du marker personnalisé, utilisation du marker par défaut: $e',
      );
      // Utiliser le marker par défaut si l'image n'existe pas
      _driverMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueBlue,
      );
    }
  }

  /// Charge une icône personnalisée depuis les assets
  Future<BitmapDescriptor> loadCustomMarkerIcon(
    String assetPath, {
    Size size = const Size(48, 48),
  }) async {
    try {
      return await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: size),
        assetPath,
      );
    } catch (e) {
      _logger.w(
        'Erreur lors du chargement de l\'icône $assetPath, utilisation du marker par défaut: $e',
      );
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  /// Ajoute ou met à jour le marker du driver
  Future<void> updateDriverMarker(geo.Position position) async {
    if (_mapController == null) {
      _logger.w('GoogleMapController non initialisé');
      return;
    }

    try {
      // Supprimer l'ancien marker s'il existe
      if (_driverMarker != null) {
        _markers.remove(_driverMarker);
        _driverMarker = null;
        _logger.d('Ancien marker supprimé');
      }

      _logger.d(
        'Position actuelle: ${position.latitude}, ${position.longitude}',
      );

      // S'assurer que l'icône est chargée
      if (_driverMarkerIcon == null) {
        await _loadDriverMarkerIcon();
      }

      // Créer le nouveau marker
      _driverMarker = Marker(
        markerId: const MarkerId('driver'),
        position: LatLng(position.latitude, position.longitude),
        icon:
            _driverMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        anchor: const Offset(
          0.5,
          1.0,
        ), // Ancrage en bas pour pointer vers la position GPS
      );

      _markers.add(_driverMarker!);

      _logger.i(
        'Marker du livreur ajouté à la position: ${position.latitude}, ${position.longitude}',
      );
    } catch (e) {
      _logger.e('Erreur lors de l\'ajout du marker: $e');
    }
  }

  /// Centre la carte sur une position
  Future<void> centerOnPosition(
    geo.Position position, {
    double zoom = 15.0,
  }) async {
    if (_mapController == null) return;

    try {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          zoom,
        ),
      );

      _logger.d(
        'Carte centrée sur: ${position.latitude}, ${position.longitude}',
      );
    } catch (e) {
      _logger.e('Erreur lors du centrage de la carte: $e');
    }
  }

  /// Obtient la position actuelle de la caméra
  Future<CameraPosition?> getCurrentCameraPosition() async {
    if (_mapController == null) return null;

    try {
      // Google Maps ne fournit pas directement getCameraPosition
      // On peut utiliser getVisibleRegion pour obtenir les limites visibles
      final visibleRegion = await _mapController!.getVisibleRegion();
      if (visibleRegion.northeast != null && visibleRegion.southwest != null) {
        final centerLat =
            (visibleRegion.northeast!.latitude +
                visibleRegion.southwest!.latitude) /
            2;
        final centerLng =
            (visibleRegion.northeast!.longitude +
                visibleRegion.southwest!.longitude) /
            2;
        // Estimation du zoom basée sur la taille de la région visible
        return CameraPosition(
          target: LatLng(centerLat, centerLng),
          zoom: 15.0, // Valeur par défaut, peut être améliorée
        );
      }
      return null;
    } catch (e) {
      _logger.e('Erreur lors de l\'obtention de l\'état de la caméra: $e');
      return null;
    }
  }

  /// Définit le style de la carte (MapType)
  Future<void> setMapType(MapType mapType) async {
    // Le type de carte est défini dans le widget GoogleMap, pas via le controller
    // Cette méthode est conservée pour compatibilité mais doit être appelée lors de la création du widget
    _logger.d(
      'Type de carte demandé: $mapType (à définir dans le widget GoogleMap)',
    );
  }

  /// Ajoute un marker pour un autre driver
  Future<Marker?> addOtherDriverMarker(
    int driverId,
    double latitude,
    double longitude, {
    BitmapDescriptor? customIcon,
  }) async {
    try {
      final marker = Marker(
        markerId: MarkerId('driver_$driverId'),
        position: LatLng(latitude, longitude),
        icon:
            customIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        anchor: const Offset(0.5, 1.0),
      );

      _markers.add(marker);

      _logger.d(
        'Marker autre driver ajouté: $driverId à $latitude, $longitude',
      );
      return marker;
    } catch (e) {
      _logger.e('Erreur lors de l\'ajout du marker autre driver: $e');
      return null;
    }
  }

  /// Supprime un marker
  Future<void> removeMarker(Marker marker) async {
    try {
      _markers.remove(marker);
      if (_driverMarker == marker) {
        _driverMarker = null;
      }
      _logger.d('Marker supprimé');
    } catch (e) {
      _logger.e('Erreur lors de la suppression du marker: $e');
    }
  }

  /// Calcule les limites de la carte pour inclure des positions
  Future<CameraUpdate> calculateBounds(List<geo.Position> positions) async {
    if (positions.isEmpty) {
      throw ArgumentError('La liste des positions ne peut pas être vide');
    }

    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (final position in positions) {
      minLat = minLat < position.latitude ? minLat : position.latitude;
      maxLat = maxLat > position.latitude ? maxLat : position.latitude;
      minLng = minLng < position.longitude ? minLng : position.longitude;
      maxLng = maxLng > position.longitude ? maxLng : position.longitude;
    }

    return CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
      50.0, // Padding en pixels
    );
  }

  /// Ajoute une polyline
  void addPolyline(Polyline polyline) {
    _polylines.add(polyline);
  }

  /// Supprime une polyline
  void removePolyline(PolylineId polylineId) {
    _polylines.removeWhere((p) => p.polylineId == polylineId);
  }

  /// Supprime toutes les polylines
  void clearPolylines() {
    _polylines.clear();
  }

  /// Getters pour les marqueurs et polylines
  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;
  GoogleMapController? get controller => _mapController;

  /// Libère les ressources
  void dispose() {
    _mapController = null;
    _markers.clear();
    _polylines.clear();
    _driverMarker = null;
    _driverMarkerIcon = null;
  }
}

