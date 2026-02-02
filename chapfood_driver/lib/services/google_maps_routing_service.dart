import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapsRoutingService {
  // ⚠️ IMPORTANT: Cette clé doit avoir Directions API activée et autorisée depuis n'importe quelle IP
  // Si vous obtenez REQUEST_DENIED, créez une clé API serveur dans Google Cloud Console
  // Voir GOOGLE_MAPS_API_SETUP.md pour les instructions détaillées
  static const String _apiKey = 'AIzaSyCVdrU9NVG_OgPGTFe7rCbNBBW5RjcR7Bw';
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  /// Calcule un itinéraire réaliste entre deux points
  static Future<RouteInfo?> getRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      print('🗺️ Calcul de l\'itinéraire Google Maps...');
      print('📍 Origine: $startLat, $startLng');
      print('📍 Destination: $endLat, $endLng');

      // Utiliser overview=full ET steps=true pour obtenir tous les détails de la route
      final url =
          '$_baseUrl?origin=$startLat,$startLng&destination=$endLat,$endLng'
          '&key=$_apiKey'
          '&mode=driving'
          '&alternatives=false'
          '&overview=full'
          '&steps=true';

      print('📡 URL de routage: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'] as String?;
        final errorMessage = data['error_message'] as String?;

        print('📊 Réponse API Google Maps: $status');
        if (errorMessage != null) {
          print('❌ Message d\'erreur API: $errorMessage');
        }

        if (status == 'OK' &&
            data['routes'] != null &&
            data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          final duration = leg['duration']['value']?.toDouble() ?? 0.0;
          final distance = leg['distance']['value']?.toDouble() ?? 0.0;

          print(
            '✅ Itinéraire calculé: ${distance.toStringAsFixed(0)}m, ${(duration / 60).toStringAsFixed(1)}min',
          );

          // Décoder toutes les polylines des steps pour obtenir une route très détaillée
          final polylinePoints = PolylinePoints();
          final allCoordinates = <LatLng>[];

          // PRIORITÉ 1: Utiliser les steps détaillés si disponibles (route la plus précise)
          if (leg['steps'] != null && (leg['steps'] as List).isNotEmpty) {
            print(
              '🔍 Utilisation des steps détaillés pour une route précise...',
            );
            for (final step in leg['steps']) {
              final stepPolyline = step['polyline']['points'] as String;
              final decodedStepPoints = polylinePoints.decodePolyline(
                stepPolyline,
              );

              // Ajouter tous les points de cette étape
              for (final point in decodedStepPoints) {
                allCoordinates.add(LatLng(point.latitude, point.longitude));
              }
            }
            print(
              '🔍 Points décodés depuis steps: ${allCoordinates.length} points',
            );
          }

          // PRIORITÉ 2: Si pas de steps disponibles, utiliser overview_polyline
          if (allCoordinates.isEmpty) {
            final overviewPolyline =
                route['overview_polyline']['points'] as String;
            final decodedPoints = polylinePoints.decodePolyline(
              overviewPolyline,
            );

            print(
              '🔍 Utilisation de overview_polyline: ${decodedPoints.length} points',
            );

            // Convertir en liste de LatLng
            for (final point in decodedPoints) {
              allCoordinates.add(LatLng(point.latitude, point.longitude));
            }
          }

          // Éliminer uniquement les doublons exacts (points identiques)
          // Ne pas supprimer les points proches car ils sont nécessaires pour la courbe
          final coordinates = <LatLng>[];
          for (int i = 0; i < allCoordinates.length; i++) {
            if (i == 0 ||
                (allCoordinates[i].latitude != allCoordinates[i - 1].latitude ||
                    allCoordinates[i].longitude !=
                        allCoordinates[i - 1].longitude)) {
              coordinates.add(allCoordinates[i]);
            }
          }

          print(
            '🔍 Points finaux après nettoyage: ${coordinates.length} points (sur ${allCoordinates.length} initiaux)',
          );

          if (coordinates.isEmpty) {
            print('❌ Aucune coordonnée extraite de la polyline');
            return null;
          }

          // Utiliser overview_polyline pour le stockage
          final overviewPolyline =
              route['overview_polyline']['points'] as String;

          return RouteInfo(
            coordinates: coordinates,
            distance: distance,
            duration: duration,
            polyline: overviewPolyline,
          );
        } else {
          final status = data['status'] as String?;
          final errorMessage = data['error_message'] as String?;
          print(
            '❌ Erreur API Google Maps: $status - ${errorMessage ?? 'Aucun message d\'erreur'}',
          );

          // Messages d'aide selon le type d'erreur
          if (status == 'REQUEST_DENIED') {
            print(
              '⚠️ La clé API est peut-être invalide ou Directions API n\'est pas activée',
            );
            print(
              '   Vérifiez dans Google Cloud Console que Directions API est activée',
            );
          } else if (status == 'OVER_QUERY_LIMIT') {
            print('⚠️ Quota API dépassé');
          } else if (status == 'ZERO_RESULTS') {
            print('⚠️ Aucun itinéraire trouvé entre ces points');
          }

          return null;
        }
      } else {
        print('❌ Erreur HTTP: ${response.statusCode}');
        print('📄 Réponse: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Erreur calcul itinéraire: $e');
      return null;
    }
  }

  /// Calcule un itinéraire détaillé avec toutes les étapes
  static Future<DetailedRouteInfo?> getDetailedRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      print('🗺️ Calcul de l\'itinéraire détaillé Google Maps...');

      final url =
          '$_baseUrl?origin=$startLat,$startLng&destination=$endLat,$endLng'
          '&key=$_apiKey'
          '&mode=driving'
          '&overview=full';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'] as String?;

        if (status == 'OK' &&
            data['routes'] != null &&
            data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          final duration = leg['duration']['value']?.toDouble() ?? 0.0;
          final distance = leg['distance']['value']?.toDouble() ?? 0.0;
          final overviewPolyline =
              route['overview_polyline']['points'] as String;

          // Extraire les étapes détaillées
          final steps = <RouteStep>[];
          if (leg['steps'] != null) {
            for (final step in leg['steps']) {
              final stepPolyline = step['polyline']['points'] as String;
              final polylinePoints = PolylinePoints();
              final decodedPoints = polylinePoints.decodePolyline(stepPolyline);

              steps.add(
                RouteStep(
                  instruction: step['html_instructions'] as String? ?? '',
                  distance: (step['distance']['value'] ?? 0).toDouble(),
                  duration: (step['duration']['value'] ?? 0).toDouble(),
                  coordinates: decodedPoints
                      .map((point) => LatLng(point.latitude, point.longitude))
                      .toList(),
                ),
              );
            }
          }

          // Décoder la polyline complète
          final polylinePoints = PolylinePoints();
          final decodedPoints = polylinePoints.decodePolyline(overviewPolyline);
          final coordinates = decodedPoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

          return DetailedRouteInfo(
            coordinates: coordinates,
            distance: distance,
            duration: duration,
            polyline: overviewPolyline,
            steps: steps,
          );
        }
      }

      return null;
    } catch (e) {
      print('❌ Erreur calcul itinéraire détaillé: $e');
      return null;
    }
  }

  /// Calcule un itinéraire avec plusieurs points de passage
  static Future<RouteInfo?> getRouteWithWaypoints({
    required List<LatLng> waypoints,
  }) async {
    if (waypoints.length < 2) return null;

    try {
      final origin = '${waypoints.first.latitude},${waypoints.first.longitude}';
      final destination =
          '${waypoints.last.latitude},${waypoints.last.longitude}';
      final waypointStr = waypoints
          .skip(1)
          .take(waypoints.length - 2)
          .map((point) => '${point.latitude},${point.longitude}')
          .join('|');

      final url =
          '$_baseUrl?origin=$origin&destination=$destination'
          '&waypoints=$waypointStr'
          '&key=$_apiKey'
          '&mode=driving'
          '&overview=full';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' &&
            data['routes'] != null &&
            data['routes'].isNotEmpty) {
          final route = data['routes'][0];

          // Calculer distance et durée totales
          double totalDistance = 0.0;
          double totalDuration = 0.0;

          for (final leg in route['legs']) {
            totalDistance += (leg['distance']['value'] ?? 0).toDouble();
            totalDuration += (leg['duration']['value'] ?? 0).toDouble();
          }

          final overviewPolyline =
              route['overview_polyline']['points'] as String;
          final polylinePoints = PolylinePoints();
          final decodedPoints = polylinePoints.decodePolyline(overviewPolyline);

          final coordinates = decodedPoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

          return RouteInfo(
            coordinates: coordinates,
            distance: totalDistance,
            duration: totalDuration,
            polyline: overviewPolyline,
          );
        }
      }

      return null;
    } catch (e) {
      print('❌ Erreur calcul itinéraire avec waypoints: $e');
      return null;
    }
  }
}

class RouteInfo {
  final List<LatLng> coordinates;
  final double distance; // en mètres
  final double duration; // en secondes
  final String polyline; // Polyline encodée

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
      return '${minutes} min';
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
  final double distance; // en mètres
  final double duration; // en secondes
  final List<LatLng> coordinates;

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
    return '${minutes} min';
  }
}
