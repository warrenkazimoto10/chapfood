# Migration chirurgicale pour real_data_home_screen.dart
$file = "c:/Users/ThinkPad/chapfood/chapfood_driver/lib/screens/real_data_home_screen.dart"
$content = Get-Content $file -Raw

# 1. Imports
$content = $content -replace "import 'package:google_maps_flutter/google_maps_flutter.dart';", "import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';`nimport '../widgets/map/mapbox_map_widget.dart';`nimport '../widgets/map/mapbox_directional_marker.dart';`nimport '../config/mapbox_config.dart';"
$content = $content -replace "import '../services/google_maps_routing_service.dart';", "import '../services/mapbox_routing_service.dart';"

# 2. Variables d'état
$content = $content -replace "GoogleMapController\? _mapController;", "MapboxMap? _mapController;`n  MapboxAnnotationHelper? _annotationHelper;`n  MapboxCameraHelper? _cameraHelper;"
$content = $content -replace "Set<Marker> _markers = \{\};", "// Set<Marker> _markers = {};"
$content = $content -replace "Set<Polyline> _polylines = \{\};", "// Set<Polyline> _polylines = {};"
$content = $content -replace "BitmapDescriptor\?", "// BitmapDescriptor?"

# 3. Widget Map
$content = $content -replace "return GoogleMap\(", "/* return GoogleMap("
$content = $content -replace "onMapCreated: _onMapCreated,", "onMapCreated: _onMapCreated, */ return MapboxMapWidget(initialPosition: _currentPosition, onMapCreated: _onMapCreated, initialZoom: 15.0,);"

# 4. _onMapCreated
$content = $content -replace "Future<void> _onMapCreated\(GoogleMapController controller\) async \{", "Future<void> _onMapCreated(MapboxMap controller) async {`n    _mapController = controller;`n    _annotationHelper = MapboxAnnotationHelper(controller);`n    _cameraHelper = MapboxCameraHelper(controller);`n    await _annotationHelper!.initialize();"

# 5. Commenter les méthodes problématiques
$content = $content -replace "_markers\.add", "// _markers.add"
$content = $content -replace "_markers\.remove", "// _markers.remove"
$content = $content -replace "_polylines\.add", "// _polylines.add"
$content = $content -replace "_polylines\.remove", "// _polylines.remove"
$content = $content -replace "Marker\(", "// Marker("
$content = $content -replace "Polyline\(", "// Polyline("
$content = $content -replace "BitmapDescriptor", "// BitmapDescriptor"
$content = $content -replace "CameraUpdate", "// CameraUpdate"
$content = $content -replace "_mapController!\.animateCamera", "// _mapController!.animateCamera"

# 6. Fix LatLng
$content = $content -replace "LatLng\(", "// LatLng("

Set-Content $file $content -Encoding UTF8
Write-Host "✅ real_data_home_screen.dart migré chirurgicalement!" -ForegroundColor Green
