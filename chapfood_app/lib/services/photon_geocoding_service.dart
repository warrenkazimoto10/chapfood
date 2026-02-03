import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/osm_config.dart';

/// Résultat Photon compatible avec l'interface utilisée par AddressSearchWidget
/// (getFormattedAddress, getShortName, latitude, longitude, type).
class PhotonResult {
  final int placeId;
  final String displayName;
  final double latitude;
  final double longitude;
  final String type;
  final String? icon;
  final Map<String, dynamic>? properties;

  PhotonResult({
    required this.placeId,
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.type = 'lieu',
    this.icon,
    this.properties,
  });

  String getShortName() {
    final name = properties?['name'] as String? ?? displayName;
    final parts = name.split(',');
    if (parts.length > 2) return parts.take(2).join(', ').trim();
    return name.trim();
  }

  String getFormattedAddress() {
    final p = properties ?? {};
    final parts = <String>[];
    if (p['name'] != null && (p['name'] as String).trim().isNotEmpty) {
      parts.add((p['name'] as String).trim());
    }
    if (p['street'] != null && (p['street'] as String).trim().isNotEmpty) {
      parts.add((p['street'] as String).trim());
    }
    if (p['city'] != null && (p['city'] as String).trim().isNotEmpty) {
      parts.add((p['city'] as String).trim());
    }
    if (p['state'] != null && (p['state'] as String).trim().isNotEmpty) {
      parts.add((p['state'] as String).trim());
    }
    if (p['country'] != null && (p['country'] as String).trim().isNotEmpty) {
      parts.add((p['country'] as String).trim());
    }
    if (parts.isEmpty) return displayName;
    return parts.join(', ');
  }
}

/// Service de géocodage basé sur l'API Photon (OpenStreetMap).
class PhotonGeocodingService {
  static final _headers = {
    'User-Agent': OsmConfig.userAgent,
    'Accept': 'application/json',
  };

  /// Recherche d'adresses (forward geocoding).
  static Future<List<PhotonResult>> search(
    String query, {
    int limit = 10,
    String? lon,
    String? lat,
    String? bbox,
  }) async {
    final params = <String, String>{
      'q': query,
      'limit': limit.toString(),
      'lang': 'fr',
    };
    if (lon != null) params['lon'] = lon;
    if (lat != null) params['lat'] = lat;
    if (bbox != null) params['bbox'] = bbox;

    try {
      final uri = Uri.parse(
        '${OsmConfig.photonBaseUrl}/',
      ).replace(queryParameters: params);
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode != 200) return [];

      final data = json.decode(response.body) as Map<String, dynamic>;
      final features = data['features'] as List<dynamic>? ?? [];

      return features
          .map((f) {
            final feature = f as Map<String, dynamic>;
            final geom = feature['geometry'] as Map<String, dynamic>?;
            final coords = geom?['coordinates'] as List<dynamic>?;
            final lng = (coords != null && coords.length >= 2)
                ? (coords[0] is num ? (coords[0] as num).toDouble() : 0.0)
                : 0.0;
            final lat = (coords != null && coords.length >= 2)
                ? (coords[1] is num ? (coords[1] as num).toDouble() : 0.0)
                : 0.0;
            final props = feature['properties'] as Map<String, dynamic>? ?? {};
            final name = (props['name'] ?? props['street'] ?? '') as String;
            final displayName = name.isNotEmpty
                ? name
                : [
                    props['street'],
                    props['city'],
                    props['country'],
                  ].whereType<String>().join(', ');
            final id = feature['properties']?['osm_id'] ?? feature['id'] ?? 0;
            final placeId = id is int ? id : int.tryParse(id.toString()) ?? 0;
            final type =
                (props['osm_value'] ?? props['type'] ?? 'lieu') as String;

            return PhotonResult(
              placeId: placeId,
              displayName: displayName.isNotEmpty ? displayName : '$lat, $lng',
              latitude: lat,
              longitude: lng,
              type: type,
              properties: props,
            );
          })
          .where((r) => _isValidCoordinates(r.latitude, r.longitude))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Reverse geocoding (coordonnées -> adresse).
  static Future<PhotonResult?> reverse(
    double latitude,
    double longitude,
  ) async {
    try {
      final uri = Uri.parse('${OsmConfig.photonBaseUrl}/reverse').replace(
        queryParameters: {
          'lat': latitude.toString(),
          'lon': longitude.toString(),
          'lang': 'fr',
        },
      );
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final features = data['features'] as List<dynamic>? ?? [];
      if (features.isEmpty) return null;

      final feature = features.first as Map<String, dynamic>;
      final geom = feature['geometry'] as Map<String, dynamic>?;
      final coords = geom?['coordinates'] as List<dynamic>?;
      final lng = (coords != null && coords.length >= 2)
          ? (coords[0] is num ? (coords[0] as num).toDouble() : longitude)
          : longitude;
      final lat = (coords != null && coords.length >= 2)
          ? (coords[1] is num ? (coords[1] as num).toDouble() : latitude)
          : latitude;
      final props = feature['properties'] as Map<String, dynamic>? ?? {};
      final parts = <String>[];
      for (final k in ['name', 'street', 'city', 'state', 'country']) {
        final v = props[k];
        if (v != null && v.toString().trim().isNotEmpty) {
          parts.add(v.toString().trim());
        }
      }
      final displayName = parts.isNotEmpty ? parts.join(', ') : 'Grand-Bassam';
      final id = feature['properties']?['osm_id'] ?? feature['id'] ?? 0;
      final placeId = id is int ? id : int.tryParse(id.toString()) ?? 0;
      final type = (props['osm_value'] ?? props['type'] ?? 'lieu') as String;

      return PhotonResult(
        placeId: placeId,
        displayName: displayName,
        latitude: lat,
        longitude: lng,
        type: type,
        properties: props,
      );
    } catch (e) {
      return null;
    }
  }

  static bool _isValidCoordinates(double lat, double lng) {
    return lat >= 5.0 && lat <= 5.4 && lng >= -3.9 && lng <= -3.5;
  }
}
