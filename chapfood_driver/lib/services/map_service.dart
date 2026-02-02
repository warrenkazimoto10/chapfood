import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:logger/logger.dart';

class MapService {
  static final MapService _instance = MapService._internal();
  factory MapService() => _instance;
  MapService._internal();

  final Logger _logger = Logger();
  
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  PointAnnotation? _driverMarker;
  
  // Configuration
  static const double _targetMarkerSize = 48.0;
  static const String _markerImageName = "driver-marker";

  /// Initialise le service de carte
  Future<void> initialize(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    
    try {
      // Initialiser le gestionnaire d'annotations
      _pointAnnotationManager = await _mapboxMap!.annotations.createPointAnnotationManager();
      
      // Charger l'image du marker
      await _loadMarkerImage();
      
      _logger.i('MapService initialisé avec succès');
    } catch (e) {
      _logger.e('Erreur lors de l\'initialisation du MapService: $e');
      rethrow;
    }
  }

  /// Charge l'image du marker depuis les assets
  Future<void> _loadMarkerImage() async {
    if (_mapboxMap == null) return;
    
    try {
      // Charger l'image du marker depuis les assets
      final ByteData data = await rootBundle.load('assets/images/marker.png');
      final Uint8List bytes = data.buffer.asUint8List();
      
      // Obtenir la vraie taille de l'image
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final int originalWidth = frame.image.width;
      final int originalHeight = frame.image.height;
      
      _logger.d('Dimensions originales du marker: ${originalWidth}x$originalHeight');
      
      // Redimensionner le marker pour qu'il soit plus petit et approprié
      final double scale = _targetMarkerSize / originalWidth;
      final int newWidth = (originalWidth * scale).round();
      final int newHeight = (originalHeight * scale).round();
      
      _logger.d('Nouvelles dimensions du marker: ${newWidth}x$newHeight (scale: ${scale.toStringAsFixed(2)})');
      
      // Redimensionner l'image
      final ui.Image resizedImage = await _resizeImage(frame.image, newWidth, newHeight);
      final ByteData? resizedData = await resizedImage.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List resizedBytes = resizedData!.buffer.asUint8List();
      
      // Créer un MbxImage avec les nouvelles dimensions
      final mbxImage = MbxImage(
        width: newWidth,
        height: newHeight,
        data: resizedBytes,
      );
      
      // Ajouter l'image au style de la carte
      await _mapboxMap!.style.addStyleImage(
        _markerImageName,
        1.0,
        mbxImage,
        false,
        [],
        [],
        null,
      );
      
      _logger.i('Marker chargé avec succès (${newWidth}x$newHeight)');
    } catch (e) {
      _logger.e('Erreur lors du chargement du marker: $e');
      rethrow;
    }
  }

  /// Redimensionne une image
  Future<ui.Image> _resizeImage(ui.Image image, int width, int height) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      ui.Paint(),
    );
    
    final ui.Picture picture = recorder.endRecording();
    return await picture.toImage(width, height);
  }

  /// Ajoute ou met à jour le marker du driver
  Future<void> updateDriverMarker(geo.Position position) async {
    if (_pointAnnotationManager == null) {
      _logger.w('PointAnnotationManager non initialisé');
      return;
    }
    
    try {
      // Supprimer l'ancien marker s'il existe
      if (_driverMarker != null) {
        await _pointAnnotationManager!.delete(_driverMarker!);
        _logger.d('Ancien marker supprimé');
      }
      
      _logger.d('Position actuelle: ${position.latitude}, ${position.longitude}');
      
      // Créer le nouveau marker avec l'image PNG
      _driverMarker = await _pointAnnotationManager!.create(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              position.longitude,
              position.latitude,
            ),
          ),
          iconImage: _markerImageName,
          iconSize: 1.0, // Taille fixe, ne change pas avec le zoom
          iconAnchor: IconAnchor.BOTTOM, // Ancrage en bas pour pointer vers la position GPS
          iconOffset: [0.0, 0.0], // Pas de décalage
        ),
      );
      
      _logger.d('Marker ajouté: $_driverMarker');
      _logger.i('Marker du livreur ajouté à la position: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      _logger.e('Erreur lors de l\'ajout du marker: $e');
    }
  }

  /// Centre la carte sur une position
  Future<void> centerOnPosition(geo.Position position, {double zoom = 15.0}) async {
    if (_mapboxMap == null) return;
    
    try {
      await _mapboxMap!.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(
              position.longitude,
              position.latitude,
            ),
          ),
          zoom: zoom,
        ),
        MapAnimationOptions(duration: 1000),
      );
      
      _logger.d('Carte centrée sur: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      _logger.e('Erreur lors du centrage de la carte: $e');
    }
  }

  /// Obtient la position actuelle de la caméra
  Future<CameraState?> getCurrentCameraState() async {
    if (_mapboxMap == null) return null;
    
    try {
      return await _mapboxMap!.getCameraState();
    } catch (e) {
      _logger.e('Erreur lors de l\'obtention de l\'état de la caméra: $e');
      return null;
    }
  }

  /// Définit le style de la carte
  Future<void> setMapStyle(String styleUri) async {
    if (_mapboxMap == null) return;
    
    try {
      await _mapboxMap!.loadStyleURI(styleUri);
      _logger.d('Style de carte changé: $styleUri');
    } catch (e) {
      _logger.e('Erreur lors du changement de style: $e');
    }
  }

  /// Ajoute un marker pour un autre driver
  Future<PointAnnotation?> addOtherDriverMarker(
    int driverId, 
    double latitude, 
    double longitude, 
    {String? customImage}
  ) async {
    if (_pointAnnotationManager == null) return null;
    
    try {
      final marker = await _pointAnnotationManager!.create(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(longitude, latitude),
          ),
          iconImage: customImage ?? "marker-15", // Marker par défaut
          iconSize: 0.8,
          iconAnchor: IconAnchor.BOTTOM,
        ),
      );
      
      _logger.d('Marker autre driver ajouté: $driverId à $latitude, $longitude');
      return marker;
    } catch (e) {
      _logger.e('Erreur lors de l\'ajout du marker autre driver: $e');
      return null;
    }
  }

  /// Supprime un marker
  Future<void> removeMarker(PointAnnotation marker) async {
    if (_pointAnnotationManager == null) return;
    
    try {
      await _pointAnnotationManager!.delete(marker);
      _logger.d('Marker supprimé');
    } catch (e) {
      _logger.e('Erreur lors de la suppression du marker: $e');
    }
  }

  /// Calcule les limites de la carte pour inclure des positions
  Future<CameraOptions> calculateBounds(List<geo.Position> positions) async {
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
    
    return CameraOptions(
      bounds: CoordinateBounds(
        southwest: Point(coordinates: Position(minLng, minLat)),
        northeast: Point(coordinates: Position(maxLng, maxLat)),
      ),
      padding: MbxEdgeInsets(top: 50, bottom: 50, left: 50, right: 50),
    );
  }

  /// Libère les ressources
  void dispose() {
    _mapboxMap = null;
    _pointAnnotationManager = null;
    _driverMarker = null;
  }
}
