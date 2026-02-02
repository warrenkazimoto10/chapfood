import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AddressService {
  static const String _addressKey = 'user_preferred_address';
  static const String _positionKey = 'user_preferred_position';

  /// Sauvegarde l'adresse préférée de l'utilisateur
  static Future<void> savePreferredAddress(String address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_addressKey, address);
      print('Adresse préférée sauvegardée: $address');
    } catch (e) {
      print('Erreur lors de la sauvegarde de l\'adresse: $e');
    }
  }

  /// Récupère l'adresse préférée de l'utilisateur
  static Future<String?> getPreferredAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_addressKey);
    } catch (e) {
      print('Erreur lors de la récupération de l\'adresse: $e');
      return null;
    }
  }

  /// Sauvegarde la position GPS préférée de l'utilisateur
  static Future<void> savePreferredPosition({
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final positionData = {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_positionKey, jsonEncode(positionData));
      print('Position préférée sauvegardée: $latitude, $longitude');
    } catch (e) {
      print('Erreur lors de la sauvegarde de la position: $e');
    }
  }

  /// Récupère la position GPS préférée de l'utilisateur
  static Future<Map<String, dynamic>?> getPreferredPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final positionJson = prefs.getString(_positionKey);
      if (positionJson != null) {
        return jsonDecode(positionJson) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de la position: $e');
      return null;
    }
  }

  /// Efface toutes les données d'adresse
  static Future<void> clearAddressData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_addressKey);
      await prefs.remove(_positionKey);
      print('Données d\'adresse effacées');
    } catch (e) {
      print('Erreur lors de l\'effacement des données: $e');
    }
  }

  /// Informations du restaurant ChapFood
  static Map<String, dynamic> getRestaurantInfo() {
    return {
      'name': 'ChapFood',
      'address': 'Abidjan, Côte d\'Ivoire',
      'phone': '+225 XX XX XX XX',
      'email': 'contact@chapfood.shop',
      'latitude': 5.3563,
      'longitude': -4.0363,
      'hours': {
        'monday': '08:00 - 22:00',
        'tuesday': '08:00 - 22:00',
        'wednesday': '08:00 - 22:00',
        'thursday': '08:00 - 22:00',
        'friday': '08:00 - 22:00',
        'saturday': '08:00 - 23:00',
        'sunday': '09:00 - 21:00',
      },
      'services': [
        'Retrait sur place',
        'Livraison à domicile',
        'Cuisine africaine authentique',
        'Commandes en ligne',
      ],
    };
  }

  /// Vérifie si l'utilisateur a une adresse sauvegardée
  static Future<bool> hasPreferredAddress() async {
    final address = await getPreferredAddress();
    final position = await getPreferredPosition();
    return address != null || position != null;
  }
}
