import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../config/mapbox_config.dart';

class RouteInfo {
  final List<Position> coordinates;
  final double distance; // meters
  final double duration; // seconds
  final String formattedDistance;
  final String formattedDuration;

  RouteInfo({
    required this.coordinates,
    required this.distance,
    required this.duration,
    required this.formattedDistance,
    required this.formattedDuration,
  });
}

class MapboxRoutingService {
  static const String _baseUrl = 'https://api.mapbox.com/directions/v5/mapbox';

  static Future<RouteInfo?> getRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String profile = 'driving', // driving, walking, cycling
  }) async {
    try {
      final String accessToken = MapboxConfig.accessToken;
      
      // Coordinates format: longitude,latitude;longitude,latitude
      final String coordinates = '$startLng,$startLat;$endLng,$endLat';
      
      final Uri url = Uri.parse(
        '$_baseUrl/$profile/$coordinates?geometries=geojson&access_token=$accessToken&overview=full',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'] == null || (data['routes'] as List).isEmpty) {
          return null;
        }

        final route = data['routes'][0];
        final geometry = route['geometry'];
        final List<dynamic> coords = geometry['coordinates'];
        
        final List<Position> routeCoordinates = coords
            .map((c) => Position(c[0] as num, c[1] as num))
            .toList();

        final double distance = (route['distance'] as num).toDouble();
        final double duration = (route['duration'] as num).toDouble();

        return RouteInfo(
          coordinates: routeCoordinates,
          distance: distance,
          duration: duration,
          formattedDistance: _formatDistance(distance),
          formattedDuration: _formatDuration(duration),
        );
      } else {
        // ignore: avoid_print
        print('Error fetching route: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Exception fetching route: $e');
      return null;
    }
  }

  static String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  static String _formatDuration(double seconds) {
    final int minutes = (seconds / 60).round();
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final int hours = minutes ~/ 60;
      final int remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}min';
    }
  }
}
