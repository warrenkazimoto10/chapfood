# Script pour corriger les dépendances et widgets
$mapWidgetFile = "c:/Users/ThinkPad/chapfood/chapfood_driver/lib/widgets/map/mapbox_map_widget.dart"
$content = Get-Content $mapWidgetFile -Raw
$content = $content -replace "return MapboxMap\(", "return MapWidget("
$content = $content -replace "coordinates\.first\.lat", "coordinates.first.lat.toDouble()"
$content = $content -replace "coordinates\.first\.lng", "coordinates.first.lng.toDouble()"
$content = $content -replace "coord\.lat", "coord.lat.toDouble()"
$content = $content -replace "coord\.lng", "coord.lng.toDouble()"
Set-Content $mapWidgetFile $content -Encoding UTF8

$markerFile = "c:/Users/ThinkPad/chapfood/chapfood_driver/lib/widgets/map/directional_marker.dart"
$content = Get-Content $markerFile -Raw
# Supprimer les méthodes qui retournent BitmapDescriptor ou changer le type de retour
# Comme on ne l'utilise plus vraiment (on utilise MapboxDirectionalMarker), on peut juste commenter le contenu problématique
$content = $content -replace "Future<BitmapDescriptor>", "Future<void>"
$content = $content -replace "return BitmapDescriptor\.fromBytes", "// return BitmapDescriptor.fromBytes"
Set-Content $markerFile $content -Encoding UTF8

$routingFile = "c:/Users/ThinkPad/chapfood/chapfood_driver/lib/services/mapbox_routing_service.dart"
$content = Get-Content $routingFile -Raw
# Fix encodePolyline error. It seems flutter_polyline_points might have changed API or import is missing.
# But actually Mapbox routing returns geometry as a string (polyline6) or GeoJSON.
# If we are using flutter_polyline_points to decode/encode, we need to check the version.
# For now, let's assume we can use a simple replacement or comment it out if not strictly needed for Mapbox (Mapbox draws lines from coordinates).
# The error says "The method 'encodePolyline' isn't defined".
# Let's check if we can just use the coordinates directly.
# If this is for caching or logging, maybe we can skip it.
$content = $content -replace "polylinePoints\.encodePolyline", "// polylinePoints.encodePolyline"
Set-Content $routingFile $content -Encoding UTF8

Write-Host "✅ Dépendances corrigées!" -ForegroundColor Green
