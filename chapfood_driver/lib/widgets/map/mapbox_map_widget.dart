import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../../config/mapbox_config.dart';

/// Widget rÃ©utilisable pour afficher une carte Mapbox
/// GÃ¨re l'initialisation, les annotations (marqueurs et polylines), et les contrÃ´les de camÃ©ra
class MapboxMapWidget extends StatefulWidget {
  /// Position initiale de la camÃ©ra
  final geo.Position? initialPosition;
  
  /// Callback appelÃ© quand la carte est crÃ©Ã©e
  final Function(MapboxMap)? onMapCreated;
  
  /// Style de carte Ã  utiliser
  final String? styleUri;
  
  /// Zoom initial
  final double initialZoom;
  
  /// Pitch (inclinaison) initial
  final double initialPitch;
  
  /// Bearing (rotation) initial
  final double initialBearing;

  const MapboxMapWidget({
    super.key,
    this.initialPosition,
    this.onMapCreated,
    this.styleUri,
    this.initialZoom = 15.0,
    this.initialPitch = 0.0,
    this.initialBearing = 0.0,
  });

  @override
  State<MapboxMapWidget> createState() => _MapboxMapWidgetState();
}

class _MapboxMapWidgetState extends State<MapboxMapWidget> {
  MapboxMap? _mapboxMap;

  @override
  Widget build(BuildContext context) {
    // DÃ©terminer la position initiale
    final lat = widget.initialPosition?.latitude ?? MapboxConfig.defaultLat;
    final lng = widget.initialPosition?.longitude ?? MapboxConfig.defaultLng;

    return MapWidget(
      styleUri: widget.styleUri ?? MapboxConfig.styleStreets,
      cameraOptions: CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        zoom: widget.initialZoom,
        pitch: widget.initialPitch,
        bearing: widget.initialBearing,
      ),
      onMapCreated: (MapboxMap mapboxMap) {
        _mapboxMap = mapboxMap;
        widget.onMapCreated?.call(mapboxMap);
      },
    );
  }
}

/// Helper class pour gÃ©rer les annotations de carte Mapbox
class MapboxAnnotationHelper {
  final MapboxMap mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  PolylineAnnotationManager? _polylineAnnotationManager;
  
  // Stockage des annotations pour pouvoir les mettre Ã  jour/supprimer
  final Map<String, PointAnnotation> _pointAnnotations = {};
  final Map<String, PolylineAnnotation> _polylineAnnotations = {};

  MapboxAnnotationHelper(this.mapboxMap);

  /// Initialise les gestionnaires d'annotations
  Future<void> initialize() async {
    _pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    _polylineAnnotationManager = await mapboxMap.annotations.createPolylineAnnotationManager();
  }

  /// Ajoute ou met Ã  jour un marqueur ponctuel
  Future<void> addOrUpdatePointAnnotation({
    required String id,
    required double lat,
    required double lng,
    String? iconImage,
    double iconSize = 1.0,
    int? iconColor,
  }) async {
    if (_pointAnnotationManager == null) {
      await initialize();
    }

    // Supprimer l'ancienne annotation si elle existe
    if (_pointAnnotations.containsKey(id)) {
      await _pointAnnotationManager!.delete(_pointAnnotations[id]!);
      _pointAnnotations.remove(id);
    }

    // CrÃ©er la nouvelle annotation
    final options = PointAnnotationOptions(
      geometry: Point(coordinates: Position(lng, lat)),
      iconImage: iconImage,
      iconSize: iconSize,
    );

    if (iconColor != null) {
      options.iconColor = iconColor;
    }

    final annotation = await _pointAnnotationManager!.create(options);
    _pointAnnotations[id] = annotation;
  }

  /// Supprime un marqueur ponctuel
  Future<void> removePointAnnotation(String id) async {
    if (_pointAnnotations.containsKey(id)) {
      await _pointAnnotationManager?.delete(_pointAnnotations[id]!);
      _pointAnnotations.remove(id);
    }
  }

  /// Supprime tous les marqueurs ponctuels
  Future<void> clearPointAnnotations() async {
    if (_pointAnnotationManager != null) {
      for (final annotation in _pointAnnotations.values) {
        await _pointAnnotationManager!.delete(annotation);
      }
      _pointAnnotations.clear();
    }
  }

  /// Ajoute ou met Ã  jour une polyline
  Future<void> addOrUpdatePolyline({
    required String id,
    required List<Position> coordinates,
    int lineColor = 0xFF3B82F6,
    double lineWidth = 6.0,
  }) async {
    if (_polylineAnnotationManager == null) {
      await initialize();
    }

    // Supprimer l'ancienne polyline si elle existe
    if (_polylineAnnotations.containsKey(id)) {
      await _polylineAnnotationManager!.delete(_polylineAnnotations[id]!);
      _polylineAnnotations.remove(id);
    }

    // CrÃ©er la nouvelle polyline
    final options = PolylineAnnotationOptions(
      geometry: LineString(coordinates: coordinates),
      lineColor: lineColor,
      lineWidth: lineWidth,
    );

    final annotation = await _polylineAnnotationManager!.create(options);
    _polylineAnnotations[id] = annotation;
  }

  /// Supprime une polyline
  Future<void> removePolyline(String id) async {
    if (_polylineAnnotations.containsKey(id)) {
      await _polylineAnnotationManager?.delete(_polylineAnnotations[id]!);
      _polylineAnnotations.remove(id);
    }
  }

  /// Supprime toutes les polylines
  Future<void> clearPolylines() async {
    if (_polylineAnnotationManager != null) {
      for (final annotation in _polylineAnnotations.values) {
        await _polylineAnnotationManager!.delete(annotation);
      }
      _polylineAnnotations.clear();
    }
  }

  /// Nettoie toutes les annotations
  Future<void> dispose() async {
    await clearPointAnnotations();
    await clearPolylines();
  }
}

/// Helper class pour contrÃ´ler la camÃ©ra Mapbox
class MapboxCameraHelper {
  final MapboxMap mapboxMap;

  MapboxCameraHelper(this.mapboxMap);

  /// Anime la camÃ©ra vers une nouvelle position
  Future<void> animateTo({
    required double lat,
    required double lng,
    double? zoom,
    double? pitch,
    double? bearing,
    int durationMs = 1000,
  }) async {
    await mapboxMap.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        zoom: zoom,
        pitch: pitch,
        bearing: bearing,
      ),
      MapAnimationOptions(duration: durationMs),
    );
  }

  /// Centre la camÃ©ra sur une liste de coordonnÃ©es
  Future<void> fitBounds({
    required List<Position> coordinates,
    EdgeInsets padding = const EdgeInsets.all(50),
    int durationMs = 1000,
  }) async {
    if (coordinates.isEmpty) return;

    // Calculer les limites
    double minLat = coordinates.first.lat.toDouble();
    double maxLat = coordinates.first.lat.toDouble();
    double minLng = coordinates.first.lng.toDouble();
    double maxLng = coordinates.first.lng.toDouble();

    for (final coord in coordinates) {
      if (coord.lat.toDouble() < minLat) minLat = coord.lat.toDouble();
      if (coord.lat.toDouble() > maxLat) maxLat = coord.lat.toDouble();
      if (coord.lng.toDouble() < minLng) minLng = coord.lng.toDouble();
      if (coord.lng.toDouble() > maxLng) maxLng = coord.lng.toDouble();
    }

    // CrÃ©er les bounds
    final bounds = CoordinateBounds(
      southwest: Point(coordinates: Position(minLng, minLat)),
      northeast: Point(coordinates: Position(maxLng, maxLat)),
      infiniteBounds: false,
    );

    // Animer vers les bounds
    await mapboxMap.flyTo(
      mapboxMap.cameraForCoordinateBounds(
        bounds,
        MbxEdgeInsets(
          top: padding.top,
          left: padding.left,
          bottom: padding.bottom,
          right: padding.right,
        ),
        null,
        null,
      ),
      MapAnimationOptions(duration: durationMs),
    );
  }

  /// Obtient la position actuelle de la camÃ©ra
  Future<CameraState> getCameraState() async {
    return await mapboxMap.getCameraState();
  }
}

