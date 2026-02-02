import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeocodingService {
  static final String _accessToken = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';

  /// Convertir des coordonnées en adresse (Reverse Geocoding)
  static Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final url = Uri.parse(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$longitude,$latitude.json?access_token=$_accessToken&language=fr',
      );

      // ignore: avoid_print
      print('🗺️ Reverse geocoding: $latitude, $longitude');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;

        if (features.isNotEmpty) {
          final placeName = features[0]['place_name'] as String;
          // ignore: avoid_print
          print('✅ Adresse trouvée: $placeName');
          return placeName;
        }
      } else {
        // ignore: avoid_print
        print('❌ Erreur geocoding: ${response.statusCode}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Erreur geocoding: $e');
    }

    return null;
  }

  /// Obtenir une adresse courte (sans pays, région, etc.)
  static Future<String?> getShortAddress(
    double latitude,
    double longitude,
  ) async {
    try {
      final fullAddress = await getAddressFromCoordinates(latitude, longitude);
      
      if (fullAddress != null) {
        // Extraire juste la rue et la ville (avant la première virgule)
        final parts = fullAddress.split(',');
        if (parts.length >= 2) {
          return '${parts[0]}, ${parts[1]}';
        }
        return parts[0];
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Erreur short address: $e');
    }

    return null;
  }
}
