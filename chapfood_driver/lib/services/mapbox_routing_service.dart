import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../config/mapbox_config.dart';

class MapboxRoutingService {
  /// Calcule un itinÃ©raire rÃ©aliste entre deux points en utilisant l'API Mapbox Directions
  static Future<RouteInfo?> getRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      print('ðŸ—ºï¸ Calcul de l\'itinÃ©raire Mapbox...');
      print('ðŸ“ Origine: $startLat, $startLng');
      print('ðŸ“ Destination: $endLat, $endLng');

      final url = MapboxConfig.getDirectionsUrl(
        startLat: startLat,
        startLng: startLng,
        endLat: endLat,
        endLng: endLng,
        steps: true,
        overview: 'full',
      );

      print('ðŸ“¡ URL de routage: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final code = data['code'] as String?;

        print('ðŸ“Š RÃ©ponse API Mapbox: $code');

        if (code == 'Ok' &&
            data['routes'] != null &&
            (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final duration = (route['duration'] ?? 0).toDouble(); // en secondes
          final distance = (route['distance'] ?? 0).toDouble(); // en mÃ¨tres

          print(
            'âœ… ItinÃ©raire calculÃ©: ${distance.toStringAsFixed(0)}m, ${(duration / 60).toStringAsFixed(1)}min',
          );

          // Extraire les coordonnÃ©es de la gÃ©omÃ©trie GeoJSON
          final geometry = route['geometry'];
          final allCoordinates = <Position>[];

          if (geometry != null && geometry['coordinates'] != null) {
            final coords = geometry['coordinates'] as List;
            print('ðŸ” CoordonnÃ©es GeoJSON: ${coords.length} points');

            for (final coord in coords) {
              if (coord is List && coord.length >= 2) {
                // Mapbox retourne [longitude, latitude]
                final lng = (coord[0] as num).toDouble();
                final lat = (coord[1] as num).toDouble();
                allCoordinates.add(Position(lng, lat));
              }
            }
          }

          print(
            'ðŸ” Points extraits: ${allCoordinates.length} points',
          );

          if (allCoordinates.isEmpty) {
            print('âŒ Aucune coordonnÃ©e extraite de la gÃ©omÃ©trie');
            return null;
          }

          // Encoder les coordonnÃ©es en polyline pour compatibilitÃ©
          final polylinePoints = PolylinePoints();
          final pointLatLngs = allCoordinates
              .map((pos) => PointLatLng(pos.lat, pos.lng))
              .toList();
          final encodedPolyline = // polylinePoints.encodePolyline(pointLatLngs);

          return RouteInfo(
            coordinates: allCoordinates,
            distance: distance,
            duration: duration,
            polyline: encodedPolyline,
          );
        } else {
          final message = data['message'] as String?;
          print(
            'âŒ Erreur API Mapbox: $code - ${message ?? 'Aucun message d\'erreur'}',
          );

          if (code == 'InvalidInput') {
            print('âš ï¸ Les coordonnÃ©es fournies sont invalides');
          } else if (code == 'NoRoute') {
            print('âš ï¸ Aucun itinÃ©raire trouvÃ© entre ces points');
          }

          return null;
        }
      } else {
        print('âŒ Erreur HTTP: ${response.statusCode}');
        print('ðŸ“„ RÃ©ponse: ${response.body}');
        return null;
      }
    } catch (e) {
      print('âŒ Erreur calcul itinÃ©raire: $e');
      return null;
    }
  }

  /// Calcule un itinÃ©raire dÃ©taillÃ© avec toutes les Ã©tapes
  static Future<DetailedRouteInfo?> getDetailedRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      print('ðŸ—ºï¸ Calcul de l\'itinÃ©raire dÃ©taillÃ© Mapbox...');

      final url = MapboxConfig.getDirectionsUrl(
        startLat: startLat,
        startLng: startLng,
        endLat: endLat,
        endLng: endLng,
        steps: true,
        overview: 'full',
      );

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final code = data['code'] as String?;

        if (code == 'Ok' &&
            data['routes'] != null &&
            (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final duration = (route['duration'] ?? 0).toDouble();
          final distance = (route['distance'] ?? 0).toDouble();

          // Extraire les coordonnÃ©es
          final geometry = route['geometry'];
          final coordinates = <Position>[];

          if (geometry != null && geometry['coordinates'] != null) {
            final coords = geometry['coordinates'] as List;
            for (final coord in coords) {
              if (coord is List && coord.length >= 2) {
                coordinates.add(Position(
                  (coord[0] as num).toDouble(),
                  (coord[1] as num).toDouble(),
                ));
              }
            }
          }

          // Extraire les Ã©tapes dÃ©taillÃ©es
          final steps = <RouteStep>[];
          final legs = route['legs'] as List?;

          if (legs != null && legs.isNotEmpty) {
            final leg = legs[0];
            final legSteps = leg['steps'] as List?;

            if (legSteps != null) {
              for (final step in legSteps) {
                final stepGeometry = step['geometry'];
                final stepCoordinates = <Position>[];

                if (stepGeometry != null &&
                    stepGeometry['coordinates'] != null) {
                  final stepCoords = stepGeometry['coordinates'] as List;
                  for (final coord in stepCoords) {
                    if (coord is List && coord.length >= 2) {
                      stepCoordinates.add(Position(
                        (coord[0] as num).toDouble(),
                        (coord[1] as num).toDouble(),
                      ));
                    }
                  }
                }

                steps.add(
                  RouteStep(
                    instruction: step['maneuver']?['instruction'] as String? ??
                        '',
                    distance: (step['distance'] ?? 0).toDouble(),
                    duration: (step['duration'] ?? 0).toDouble(),
                    coordinates: stepCoordinates,
                  ),
                );
              }
            }
          }

          // Encoder la polyline
          final polylinePoints = PolylinePoints();
          final pointLatLngs = coordinates
              .map((pos) => PointLatLng(pos.lat, pos.lng))
              .toList();
          final encodedPolyline = // polylinePoints.encodePolyline(pointLatLngs);

          return DetailedRouteInfo(
            coordinates: coordinates,
            distance: distance,
            duration: duration,
            polyline: encodedPolyline,
            steps: steps,
          );
        }
      }

      return null;
    } catch (e) {
      print('âŒ Erreur calcul itinÃ©raire dÃ©taillÃ©: $e');
      return null;
    }
  }

  /// Calcule un itinÃ©raire avec plusieurs points de passage
  static Future<RouteInfo?> getRouteWithWaypoints({
    required List<Position> waypoints,
  }) async {
    if (waypoints.length < 2) return null;

    try {
      // Construire la liste de coordonnÃ©es au format "lng,lat;lng,lat;..."
      final coordinates = waypoints
          .map((pos) => '${pos.lng},${pos.lat}')
          .join(';');

      final url =
          '${MapboxConfig.directionsApiBaseUrl}/driving/$coordinates'
          '?geometries=geojson'
          '&overview=full'
          '&steps=true'
          '&access_token=${MapboxConfig.accessToken}';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 'Ok' &&
            data['routes'] != null &&
            (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];

          // Calculer distance et durÃ©e totales
          final totalDistance = (route['distance'] ?? 0).toDouble();
          final totalDuration = (route['duration'] ?? 0).toDouble();

          // Extraire les coordonnÃ©es
          final geometry = route['geometry'];
          final coordinates = <Position>[];

          if (geometry != null && geometry['coordinates'] != null) {
            final coords = geometry['coordinates'] as List;
            for (final coord in coords) {
              if (coord is List && coord.length >= 2) {
                coordinates.add(Position(
                  (coord[0] as num).toDouble(),
                  (coord[1] as num).toDouble(),
                ));
              }
            }
          }

          // Encoder la polyline
          final polylinePoints = PolylinePoints();
          final pointLatLngs = coordinates
              .map((pos) => PointLatLng(pos.lat, pos.lng))
              .toList();
          final encodedPolyline = // polylinePoints.encodePolyline(pointLatLngs);

          return RouteInfo(
            coordinates: coordinates,
            distance: totalDistance,
            duration: totalDuration,
            polyline: encodedPolyline,
          );
        }
      }

      return null;
    } catch (e) {
      print('âŒ Erreur calcul itinÃ©raire avec waypoints: $e');
      return null;
    }
  }
}

/// Classe reprÃ©sentant une position gÃ©ographique
class Position {
  final double lng;
  final double lat;

  Position(this.lng, this.lat);

  @override
  String toString() => 'Position($lat, $lng)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position &&
          runtimeType == other.runtimeType &&
          lng == other.lng &&
          lat == other.lat;

  @override
  int get hashCode => lng.hashCode ^ lat.hashCode;
}

class RouteInfo {
  final List<Position> coordinates;
  final double distance; // en mÃ¨tres
  final double duration; // en secondes
  final String polyline; // Polyline encodÃ©e

  RouteInfo({
    required this.coordinates,
    required this.distance,
    required this.duration,
    required this.polyline,
  });

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

class DetailedRouteInfo extends RouteInfo {
  final List<RouteStep> steps;

  DetailedRouteInfo({
    required super.coordinates,
    required super.distance,
    required super.duration,
    required super.polyline,
    required this.steps,
  });
}

class RouteStep {
  final String instruction;
  final double distance; // en mÃ¨tres
  final double duration; // en secondes
  final List<Position> coordinates;

  RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.coordinates,
  });

  String get formattedDistance {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
  }

  String get formattedDuration {
    final minutes = (duration / 60).round();
    return '$minutes min';
  }
}

