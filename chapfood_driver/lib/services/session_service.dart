import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/driver_model.dart';
import 'driver_location_tracker.dart';

class SessionService {
  static const String _driverKey = 'driver_data';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _selectedServiceKey = 'selected_service';
  static const String _savedEmailKey = 'saved_email';
  static const String _savedPhoneKey = 'saved_phone';

  static DriverModel? _currentDriver;
  static bool _isLoggedIn = false;
  static String? _selectedService;

  // Getters
  static DriverModel? get currentDriver => _currentDriver;
  static bool get isLoggedIn => _isLoggedIn;
  static String? get selectedService => _selectedService;

  // Initialiser la session
  static Future<void> initialize() async {
    try {
      print('🔧 Initialisation de SessionService...');
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      _selectedService = prefs.getString(_selectedServiceKey);

      // Charger le driver depuis les préférences si connecté
      if (_isLoggedIn) {
        await loadDriverFromPreferences();
      }

      print(
        '✅ SessionService initialisé - Connecté: $_isLoggedIn, Driver: ${_currentDriver?.name}',
      );
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation de la session: $e');
      _isLoggedIn = false;
      _selectedService = null;
      _currentDriver = null;
    }
  }

  // Sauvegarder la session du driver
  static Future<void> saveDriverSession(DriverModel driver) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convertir le driver en JSON et le sauvegarder
      final driverJson = jsonEncode(driver.toJson());

      await prefs.setString(_driverKey, driverJson);
      await prefs.setBool(_isLoggedInKey, true);

      _currentDriver = driver;
      _isLoggedIn = true;

      print('✅ Session driver sauvegardée: ${driver.name}');
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde de la session: $e');
    }
  }

  // Sauvegarder le service sélectionné
  static Future<void> saveSelectedService(String service) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedServiceKey, service);
    _selectedService = service;
  }

  // Sauvegarder l'email
  static Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedEmailKey, email);
  }

  // Sauvegarder le téléphone
  static Future<void> savePhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedPhoneKey, phone);
  }

  // Obtenir l'email sauvegardé
  static Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_savedEmailKey);
  }

  // Obtenir le téléphone sauvegardé
  static Future<String?> getSavedPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_savedPhoneKey);
  }

  // Mettre à jour les données du driver
  static Future<void> updateDriverData(DriverModel driver) async {
    await saveDriverSession(driver);
  }

  // Déconnexion
  static Future<void> logout() async {
    try {
      // Arrêter le suivi GPS avant de se déconnecter
      final locationTracker = DriverLocationTracker();
      await locationTracker.stopTracking();
      await locationTracker.dispose();

      print('✅ Suivi GPS arrêté lors de la déconnexion');
    } catch (e) {
      print('⚠️ Erreur lors de l\'arrêt du GPS: $e');
    }

    // Nettoyer les préférences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_driverKey);
    await prefs.remove(_selectedServiceKey);
    await prefs.setBool(_isLoggedInKey, false);

    _currentDriver = null;
    _isLoggedIn = false;
    _selectedService = null;

    print('✅ Déconnexion effectuée avec succès');
  }

  // Vérifier si la session est valide
  static bool isSessionValid() {
    return _isLoggedIn && _currentDriver != null;
  }

  // Obtenir l'ID du driver actuel
  static int? getCurrentDriverId() {
    return _currentDriver?.id;
  }

  // Obtenir le nom du driver actuel
  static String? getCurrentDriverName() {
    return _currentDriver?.name;
  }

  // Obtenir le téléphone du driver actuel
  static String? getCurrentDriverPhone() {
    return _currentDriver?.phone;
  }

  // Vérifier si le driver est disponible
  static bool isDriverAvailable() {
    return _currentDriver?.isAvailable ?? false;
  }

  // Obtenir la position actuelle du driver
  static Map<String, double?>? getCurrentDriverLocation() {
    if (_currentDriver?.currentLat != null &&
        _currentDriver?.currentLng != null) {
      return {
        'lat': _currentDriver!.currentLat,
        'lng': _currentDriver!.currentLng,
      };
    }
    return null;
  }

  // Obtenir le driver actuel (méthode async pour compatibilité)
  static Future<DriverModel?> getCurrentDriver() async {
    return _currentDriver;
  }

  // Charger le driver depuis les préférences
  static Future<void> loadDriverFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final driverData = prefs.getString(_driverKey);

      if (driverData != null && driverData.isNotEmpty) {
        // Vérifier si c'est du JSON ou du format URL
        if (driverData.startsWith('{')) {
          // Format JSON
          final driverJson = jsonDecode(driverData) as Map<String, dynamic>;
          _currentDriver = DriverModel.fromJson(driverJson);
          print('✅ Driver chargé depuis JSON: ${_currentDriver?.name}');
        } else if (driverData.contains('&')) {
          // Format URL - convertir en Map
          final Map<String, dynamic> driverMap = {};
          final pairs = driverData.split('&');

          for (final pair in pairs) {
            if (pair.contains('=')) {
              final keyValue = pair.split('=');
              if (keyValue.length == 2) {
                final key = Uri.decodeComponent(keyValue[0]);
                final value = Uri.decodeComponent(keyValue[1]);

                // Convertir les types appropriés
                if (key == 'id') {
                  driverMap[key] = int.tryParse(value);
                } else if (key == 'isAvailable') {
                  // Gérer différents formats de booléen
                  if (value.toLowerCase() == 'true' || value == '1') {
                    driverMap[key] = true;
                  } else if (value.toLowerCase() == 'false' || value == '0') {
                    driverMap[key] = false;
                  } else {
                    driverMap[key] = false; // Valeur par défaut
                  }
                } else if (key == 'currentLat' || key == 'currentLng') {
                  driverMap[key] = double.tryParse(value);
                } else if (key == 'rating') {
                  driverMap[key] = double.tryParse(value);
                } else if (key == 'vehicleType') {
                  driverMap[key] = value;
                } else if (key == 'name' || key == 'phone' || key == 'email') {
                  driverMap[key] = value;
                } else {
                  // Pour tous les autres champs, essayer de deviner le type
                  if (value.toLowerCase() == 'true' ||
                      value.toLowerCase() == 'false') {
                    driverMap[key] = value.toLowerCase() == 'true';
                  } else if (RegExp(r'^-?\d+$').hasMatch(value)) {
                    driverMap[key] = int.tryParse(value);
                  } else if (RegExp(r'^-?\d*\.?\d+$').hasMatch(value)) {
                    driverMap[key] = double.tryParse(value);
                  } else {
                    driverMap[key] = value;
                  }
                }
              }
            }
          }

          _currentDriver = DriverModel.fromJson(driverMap);
          print('✅ Driver chargé depuis format URL: ${_currentDriver?.name}');

          // Sauvegarder au format JSON pour la prochaine fois
          await saveDriverSession(_currentDriver!);
        } else {
          print('⚠️ Format de données driver non reconnu');
          _currentDriver = null;
          _isLoggedIn = false;
        }
      } else {
        print('⚠️ Aucune donnée driver trouvée dans les préférences');
        _currentDriver = null;
        _isLoggedIn = false;
      }
    } catch (e) {
      print('❌ Erreur lors du chargement du driver: $e');

      // En cas d'erreur, nettoyer les données corrompues
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_driverKey);
        await prefs.setBool(_isLoggedInKey, false);
        print('🧹 Données corrompues nettoyées');
      } catch (cleanupError) {
        print('❌ Erreur lors du nettoyage: $cleanupError');
      }

      _currentDriver = null;
      _isLoggedIn = false;
    }
  }
}
