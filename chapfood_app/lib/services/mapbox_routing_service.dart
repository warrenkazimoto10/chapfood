import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class MapboxRoutingService {
  static const String _baseUrl = 'https://api.mapbox.com/directions/v5/mapbox/driving';
  // Token Mapbox : utiliser .env (MAPBOX_ACCESS_TOKEN) ou --dart-define en build
  static String get _accessToken =>
      const String.fromEnvironment('MAPBOX_ACCESS_TOKEN', defaultValue: '');

  /// Calcule l'itinéraire entre deux points
  static Future<MapboxRouteResponse?> getRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final url = '$_baseUrl/$startLng,$startLat;$endLng,$endLat?access_token=$_accessToken&geometries=polyline&overview=full&steps=true';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MapboxRouteResponse.fromJson(data);
      } else {
        print('Erreur API Mapbox: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Erreur lors du calcul de l\'itinéraire: $e');
      return null;
    }
  }

  /// Calcule la distance et le temps de trajet
  static Future<RouteInfo?> getRouteInfo({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final url = '$_baseUrl/$startLng,$startLat;$endLng,$endLat?access_token=$_accessToken&overview=false';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          return RouteInfo(
            distance: route['distance']?.toDouble() ?? 0.0,
            duration: route['duration']?.toDouble() ?? 0.0,
          );
        }
      }
      return null;
    } catch (e) {
      print('Erreur lors du calcul des informations de route: $e');
      return null;
    }
  }
}

class MapboxRouteResponse {
  final List<MapboxRoute> routes;
  final String code;

  MapboxRouteResponse({
    required this.routes,
    required this.code,
  });

  factory MapboxRouteResponse.fromJson(Map<String, dynamic> json) {
    return MapboxRouteResponse(
      routes: (json['routes'] as List?)
          ?.map((route) => MapboxRoute.fromJson(route))
          .toList() ?? [],
      code: json['code'] ?? '',
    );
  }
}

class MapboxRoute {
  final String geometry;
  final double distance;
  final double duration;
  final List<MapboxStep> steps;

  MapboxRoute({
    required this.geometry,
    required this.distance,
    required this.duration,
    required this.steps,
  });

  factory MapboxRoute.fromJson(Map<String, dynamic> json) {
    return MapboxRoute(
      geometry: json['geometry'] ?? '',
      distance: (json['distance'] ?? 0).toDouble(),
      duration: (json['duration'] ?? 0).toDouble(),
      steps: (json['legs'] as List?)
          ?.expand((leg) => leg['steps'] as List)
          .map((step) => MapboxStep.fromJson(step))
          .toList() ?? [],
    );
  }
}

class MapboxStep {
  final String instruction;
  final double distance;
  final double duration;

  MapboxStep({
    required this.instruction,
    required this.distance,
    required this.duration,
  });

  factory MapboxStep.fromJson(Map<String, dynamic> json) {
    return MapboxStep(
      instruction: json['maneuver']?['instruction'] ?? '',
      distance: (json['distance'] ?? 0).toDouble(),
      duration: (json['duration'] ?? 0).toDouble(),
    );
  }
}

class RouteInfo {
  final double distance; // en mètres
  final double duration; // en secondes

  RouteInfo({
    required this.distance,
    required this.duration,
  });

  String get formattedDistance {
    if (distance < 1000) {
      return '${distance.round()} m';
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
