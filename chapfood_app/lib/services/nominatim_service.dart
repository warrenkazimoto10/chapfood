import 'dart:convert';
import 'package:http/http.dart' as http;

/// Résultat de recherche Nominatim
class NominatimResult {
  final int placeId;
  final String displayName;
  final double latitude;
  final double longitude;
  final String type;
  final String? icon;
  final Map<String, dynamic>? addressDetails;

  NominatimResult({
    required this.placeId,
    required this.displayName,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.icon,
    this.addressDetails,
  });

  factory NominatimResult.fromJson(Map<String, dynamic> json) {
    return NominatimResult(
      placeId: json['place_id'] ?? 0,
      displayName: json['display_name'] ?? '',
      latitude: double.tryParse(json['lat']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['lon']?.toString() ?? '0') ?? 0.0,
      type: json['type'] ?? json['class'] ?? 'lieu',
      icon: json['icon'],
      addressDetails: json['address'],
    );
  }

  /// Extrait un nom court depuis le display_name
  String getShortName() {
    final parts = displayName.split(',');

    // Si c'est un point d'intérêt, prendre le premier élément (nom du lieu)
    if (type == 'pharmacy' ||
        type == 'restaurant' ||
        type == 'hotel' ||
        type == 'bank' ||
        type == 'hospital' ||
        type == 'school') {
      return parts[0].trim();
    }

    if (parts.length > 2) {
      // Prendre les 2 premières parties (nom, quartier)
      return parts.take(2).join(', ').trim();
    }
    return displayName;
  }

  /// Formate l'adresse pour l'affichage
  String getFormattedAddress() {
    // Extraire le nom du lieu depuis display_name (ex: "Pharmacie Wassia")
    final displayParts = displayName.split(',');
    String? placeName;

    // Si c'est un point d'intérêt (pharmacie, restaurant, etc.), prendre le premier élément
    if (type == 'pharmacy' ||
        type == 'restaurant' ||
        type == 'hotel' ||
        type == 'bank' ||
        type == 'hospital' ||
        type == 'school') {
      placeName = displayParts[0].trim();
    }

    if (addressDetails != null) {
      final parts = <String>[];

      // Ajouter le nom du lieu en premier si disponible
      if (placeName != null && placeName.isNotEmpty) {
        parts.add(placeName);
      }

      // Ajouter la route/voie
      if (addressDetails!['road'] != null) {
        final road = addressDetails!['road'];
        if (road != null && !parts.contains(road)) {
          parts.add(road);
        }
      }

      // Ajouter le quartier/neighbourhood
      if (addressDetails!['suburb'] != null ||
          addressDetails!['neighbourhood'] != null) {
        final quartier =
            addressDetails!['suburb'] ?? addressDetails!['neighbourhood'];
        if (quartier != null && !parts.contains(quartier)) {
          parts.add(quartier);
        }
      }

      // Ajouter la ville en dernier (toujours Grand-Bassam)
      if (!parts.contains('Grand-Bassam')) {
        parts.add('Grand-Bassam');
      }

      if (parts.isNotEmpty) {
        return parts.join(', ');
      }
    }

    // Si pas de détails d'adresse, utiliser display_name mais formaté
    // Prendre les 2-3 premières parties pour avoir: "Pharmacie Wassia, Quartier, Grand-Bassam"
    if (displayParts.length >= 2) {
      // Prendre le nom du lieu (premier élément) et le quartier (2ème ou 3ème)
      final result = <String>[];
      if (displayParts[0].trim().isNotEmpty) {
        result.add(displayParts[0].trim());
      }
      // Chercher le quartier ou la ville
      for (int i = 1; i < displayParts.length && result.length < 3; i++) {
        final part = displayParts[i].trim();
        if (part.isNotEmpty &&
            !part.toLowerCase().contains('côte') &&
            !part.toLowerCase().contains('comoé') &&
            !part.toLowerCase().contains('sud')) {
          result.add(part);
        }
      }
      if (result.isNotEmpty) {
        return result.join(', ');
      }
    }

    // Fallback: utiliser le display_name complet mais limité
    return displayParts.take(3).join(', ').trim();
  }
}

/// Service pour interroger l'API Nominatim (OpenStreetMap)
/// Gratuit et sans limite de requêtes (avec rate limiting respecté)
class NominatimService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  static const String _userAgent = 'ChapFood/1.0';
  static DateTime? _lastRequestTime;
  static const Duration _minRequestInterval = Duration(seconds: 1);

  /// Recherche d'adresses avec Nominatim
  static Future<List<NominatimResult>> search(
    String query, {
    int limit = 10,
    String countryCodes = 'ci',
    String? viewbox,
  }) async {
    // Rate limiting : respecter 1 requête par seconde
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _minRequestInterval) {
        await Future.delayed(_minRequestInterval - timeSinceLastRequest);
      }
    }

    // Viewbox pour Grand-Bassam et environs
    final defaultViewbox = viewbox ?? '-3.9,5.0,-3.5,5.4';

    // Améliorer la requête pour inclure "Grand-Bassam" si ce n'est pas déjà présent
    String enhancedQuery = query.toLowerCase();
    if (!enhancedQuery.contains('grand') && !enhancedQuery.contains('bassam')) {
      enhancedQuery = '$query, Grand-Bassam';
    }

    final params = {
      'q': enhancedQuery,
      'format': 'json',
      'limit': limit.toString(),
      'countrycodes': countryCodes,
      'viewbox': defaultViewbox,
      'bounded':
          '0', // 0 pour permettre des résultats légèrement en dehors de la viewbox
      'addressdetails': '1',
      'accept-language': 'fr',
      'extratags': '1', // Inclure les tags supplémentaires
    };

    try {
      _lastRequestTime = DateTime.now();

      final uri = Uri.parse(
        '$_baseUrl/search',
      ).replace(queryParameters: params);
      final response = await http.get(
        uri,
        headers: {'User-Agent': _userAgent, 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final results = data
            .map((json) => NominatimResult.fromJson(json))
            .where((result) {
              // Filtrer pour Grand-Bassam mais être plus permissif
              return _isValidGPSCoordinates(result.latitude, result.longitude);
            })
            .toList();

        // Trier par importance (plus important = meilleur résultat)
        results.sort((a, b) {
          // Les pharmacies, restaurants, etc. en premier
          final aIsPOI =
              a.type == 'pharmacy' ||
              a.type == 'restaurant' ||
              a.type == 'hotel' ||
              a.type == 'bank';
          final bIsPOI =
              b.type == 'pharmacy' ||
              b.type == 'restaurant' ||
              b.type == 'hotel' ||
              b.type == 'bank';

          if (aIsPOI && !bIsPOI) return -1;
          if (!aIsPOI && bIsPOI) return 1;
          return 0;
        });

        return results;
      } else {
        print('Erreur Nominatim: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Erreur lors de la recherche Nominatim: $e');
      return [];
    }
  }

  /// Recherche inversée (coordonnées -> adresse)
  static Future<NominatimResult?> reverse(
    double latitude,
    double longitude,
  ) async {
    // Rate limiting
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _minRequestInterval) {
        await Future.delayed(_minRequestInterval - timeSinceLastRequest);
      }
    }

    final params = {
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'format': 'json',
      'accept-language': 'fr',
      'addressdetails': '1',
    };

    try {
      _lastRequestTime = DateTime.now();

      final uri = Uri.parse(
        '$_baseUrl/reverse',
      ).replace(queryParameters: params);
      final response = await http.get(
        uri,
        headers: {'User-Agent': _userAgent, 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final result = NominatimResult.fromJson(data);
        return _isValidGPSCoordinates(result.latitude, result.longitude)
            ? result
            : null;
      } else {
        print('Erreur Nominatim reverse: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Erreur lors du reverse geocoding: $e');
      return null;
    }
  }

  /// Valide que les coordonnées sont dans la zone de Grand-Bassam
  static bool _isValidGPSCoordinates(double latitude, double longitude) {
    return latitude >= 5.0 &&
        latitude <= 5.4 &&
        longitude >= -3.9 &&
        longitude <= -3.5;
  }
}
