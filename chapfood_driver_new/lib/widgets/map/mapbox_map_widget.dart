import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../config/mapbox_config.dart';
import 'package:geolocator/geolocator.dart' as geo;

class MapboxMapWidget extends StatelessWidget {
  final void Function(MapboxMap)? onMapCreated;
  final geo.Position? initialPosition;
  final double initialZoom;

  const MapboxMapWidget({
    super.key,
    this.onMapCreated,
    this.initialPosition,
    this.initialZoom = 15.0,
  });

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      key: const ValueKey("mapWidget"),
      onMapCreated: onMapCreated,
      cameraOptions: CameraOptions(
        center: Point(
          coordinates: Position(
            initialPosition?.longitude ?? -4.0083,
            initialPosition?.latitude ?? 5.3600,
          ),
        ),
        zoom: initialZoom,
      ),
      styleUri: MapboxConfig.styleUrl,
      textureView: true, // Better performance on Android
    );
  }
}
