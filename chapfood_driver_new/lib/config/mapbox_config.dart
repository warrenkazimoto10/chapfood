import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapboxConfig {
  static String get accessToken {
    final token = dotenv.env['MAPBOX_ACCESS_TOKEN'];
    if (token == null || token.isEmpty) {
      throw Exception('MAPBOX_ACCESS_TOKEN not found in .env file');
    }
    return token;
  }

  static const String styleUrl = MapboxStyles.MAPBOX_STREETS;

  static void setAccessToken() {
    MapboxOptions.setAccessToken(accessToken);
  }
}
