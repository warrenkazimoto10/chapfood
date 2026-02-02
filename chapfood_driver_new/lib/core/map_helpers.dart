import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapboxAnnotationHelper {
  final MapboxMap mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  PolylineAnnotationManager? _polylineAnnotationManager;

  MapboxAnnotationHelper(this.mapboxMap);

  Future<void> initialize() async {
    _pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    _polylineAnnotationManager = await mapboxMap.annotations.createPolylineAnnotationManager();
  }

  final Map<String, String> _annotationIds = {};

  Future<void> addOrUpdatePointAnnotation({
    required String id,
    required double lat,
    required double lng,
    required String iconImage,
    double? iconRotate,
  }) async {
    if (_pointAnnotationManager == null) return;

    final existingUuid = _annotationIds[id];
    
    if (existingUuid != null) {
      // Delete old annotation
      try {
        await _pointAnnotationManager?.deleteAll();
      } catch (e) {
        // Ignore delete errors
      }
    }

    // Create new annotation (or recreate)
    final annotation = await _pointAnnotationManager?.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: Position(lng, lat)),
        iconImage: iconImage,
        iconSize: 1.0,
        iconRotate: iconRotate,
      ),
    );
    
    if (annotation != null) {
      _annotationIds[id] = annotation.id;
    }
  }

  Future<void> addOrUpdatePolyline({
    required String id,
    required List<Position> coordinates,
    required int lineColor,
    required double lineWidth,
  }) async {
    if (_polylineAnnotationManager == null) return;

    await _polylineAnnotationManager?.create(
      PolylineAnnotationOptions(
        geometry: LineString(coordinates: coordinates),
        lineColor: lineColor,
        lineWidth: lineWidth,
      ),
    );
  }
  
  Future<void> clearAll() async {
    await _pointAnnotationManager?.deleteAll();
    await _polylineAnnotationManager?.deleteAll();
  }
}

class MapboxCameraHelper {
  final MapboxMap mapboxMap;

  MapboxCameraHelper(this.mapboxMap);

  Future<void> animateTo({
    required double lat,
    required double lng,
    required double zoom,
    double? bearing,
    double? pitch,
  }) async {
    await mapboxMap.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        zoom: zoom,
        bearing: bearing,
        pitch: pitch,
      ),
      MapAnimationOptions(duration: 1000),
    );
  }

  Future<void> fitBounds({
    required List<Position> coordinates,
    EdgeInsets padding = const EdgeInsets.all(0),
  }) async {
    if (coordinates.isEmpty) return;

    // Calculate bounds manually or use cameraForCoordinateBounds if available
    // Mapbox SDK has cameraForCoordinates
    
    final camera = await mapboxMap.cameraForCoordinates(
      coordinates.map((p) => Point(coordinates: p)).toList(),
      MbxEdgeInsets(
        top: padding.top,
        left: padding.left,
        bottom: padding.bottom,
        right: padding.right,
      ),
      null, // bearing
      null, // pitch
    );
    
    await mapboxMap.flyTo(camera, MapAnimationOptions(duration: 1000));
  }
}
