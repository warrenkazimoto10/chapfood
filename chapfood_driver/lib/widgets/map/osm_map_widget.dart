import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../config/osm_config.dart';

/// Widget réutilisable pour afficher une carte OSM (flutter_map + tuiles Carto).
/// Remplace MapboxMapWidget.
class OsmMapWidget extends StatefulWidget {
  /// Centre initial de la carte
  final LatLng initialCenter;

  /// Zoom initial
  final double initialZoom;

  /// Callback appelé quand la carte est créée (pour MapController)
  final void Function(MapController)? onMapCreated;

  /// Marqueurs à afficher
  final List<Marker> markers;

  /// Polylines à afficher
  final List<Polyline>? polylines;

  const OsmMapWidget({
    super.key,
    required this.initialCenter,
    this.initialZoom = OsmConfig.defaultZoom,
    this.onMapCreated,
    this.markers = const [],
    this.polylines,
  });

  @override
  State<OsmMapWidget> createState() => _OsmMapWidgetState();
}

class _OsmMapWidgetState extends State<OsmMapWidget> {
  late final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onMapCreated?.call(_mapController);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.initialCenter,
        initialZoom: widget.initialZoom,
      ),
      children: [
        TileLayer(
          urlTemplate: OsmConfig.tileUrlTemplate,
          userAgentPackageName: 'com.chapfood.driver',
          maxZoom: 19,
        ),
        if (widget.polylines != null && widget.polylines!.isNotEmpty)
          PolylineLayer(polylines: widget.polylines!),
        if (widget.markers.isNotEmpty) MarkerLayer(markers: widget.markers),
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
    );
  }
}
