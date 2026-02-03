import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../config/osm_config.dart';

/// Service de calcul d'itinéraires via l'API OSRM (OpenStreetMap).
/// Retourne des points pour affichage polyline sur flutter_map.
class OsrmRoutingService {
  /// Calcule un itinéraire entre deux points.
  /// Retourne la liste des points [[lat, lng], ...] ou null en cas d'erreur.
  static Future<List<List<double>>?> getRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String profile = OsmConfig.defaultRoutingProfile,
  }) async {
    final result = await getRouteWithInfo(
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
      profile: profile,
    );
    return result?.points;
  }

  /// Calcule un itinéraire et retourne points + distance + durée (compatibilité RouteInfo).
  static Future<OsrmRouteInfo?> getRouteWithInfo({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String profile = OsmConfig.defaultRoutingProfile,
  }) async {
    final coords = '$originLng,$originLat;$destLng,$destLat';
    final url =
        '${OsmConfig.osrmBaseUrl}/route/v1/$profile/$coords?overview=full&geometries=geojson';

    try {
      final response = await http
          .get(Uri.parse(url), headers: {'User-Agent': OsmConfig.userAgent})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;

      final route = routes.first as Map<String, dynamic>;
      final distance = (route['distance'] as num?)?.toDouble() ?? 0.0;
      final duration = (route['duration'] as num?)?.toDouble() ?? 0.0;
      final geometry = route['geometry'] as Map<String, dynamic>?;
      final coordsList = geometry?['coordinates'] as List<dynamic>?;
      if (coordsList == null || coordsList.isEmpty) return null;

      final points = coordsList.map((c) {
        final list = c as List<dynamic>;
        final lng = list.isNotEmpty && list[0] is num
            ? (list[0] as num).toDouble()
            : 0.0;
        final lat = list.length > 1 && list[1] is num
            ? (list[1] as num).toDouble()
            : 0.0;
        return LatLng(lat, lng);
      }).toList();

      return OsrmRouteInfo(
        coordinates: points,
        distance: distance,
        duration: duration,
      );
    } catch (e) {
      return null;
    }
  }
}

/// Informations d'itinéraire OSRM (compatibles avec l'UI RouteInfo).
class OsrmRouteInfo {
  final List<LatLng> coordinates;
  final double distance;
  final double duration;

  OsrmRouteInfo({
    required this.coordinates,
    required this.distance,
    required this.duration,
  });

  /// Points au format [[lat, lng], ...] pour compatibilité getRoute().
  List<List<double>> get points =>
      coordinates.map((l) => [l.latitude, l.longitude]).toList();

  String get formattedDistance {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
  }

  String get formattedDuration {
    final minutes = (duration / 60).round();
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}min';
    }
  }
}
