import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/osm_config.dart';

/// Service de calcul d'itinéraires via l'API OSRM (OpenStreetMap).
/// Retourne une liste de points [lat, lng] pour affichage polyline sur flutter_map.
class OsrmRoutingService {
  /// Calcule un itinéraire entre deux points.
  /// [originLat], [originLng]: départ.
  /// [destLat], [destLng]: arrivée.
  /// [profile]: driving, walking, cycling.
  /// Retourne la liste des points [[lat, lng], ...] ou null en cas d'erreur.
  static Future<List<List<double>>?> getRoute({
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
      final geometry = route['geometry'] as Map<String, dynamic>?;
      final coordsList = geometry?['coordinates'] as List<dynamic>?;
      if (coordsList == null || coordsList.isEmpty) return null;

      return coordsList.map((c) {
        final list = c as List<dynamic>;
        final lng = list.isNotEmpty && list[0] is num
            ? (list[0] as num).toDouble()
            : 0.0;
        final lat = list.length > 1 && list[1] is num
            ? (list[1] as num).toDouble()
            : 0.0;
        return [lat, lng];
      }).toList();
    } catch (e) {
      return null;
    }
  }

  /// Retourne les points au format LatLng (lat, lng) pour flutter_map.
  /// Chaque élément est [latitude, longitude].
  static Future<List<List<double>>?> getRoutePoints({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String profile = OsmConfig.defaultRoutingProfile,
  }) async {
    return getRoute(
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
      profile: profile,
    );
  }
}
