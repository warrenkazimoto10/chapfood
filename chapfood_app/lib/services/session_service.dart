import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';

class SessionService {
  static const String _userSessionKey = 'user_session';
  static const String _userEmailKey = 'user_email';
  static const String _userPhoneKey = 'user_phone';
  static const String _isLoggedInKey = 'is_logged_in';

  // Vérifier si l'utilisateur est connecté
  static Future<bool> isUserLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      
      if (isLoggedIn) {
        // Vérifier si nous avons un utilisateur sauvegardé
        final userJson = prefs.getString(_userSessionKey);
        if (userJson != null && userJson.isNotEmpty) {
          return true;
        } else {
          // Pas d'utilisateur sauvegardé, déconnecter
          await logout();
          return false;
        }
      }
      return false;
    } catch (e) {
      print('Erreur lors de la vérification de la session: $e');
      return false;
    }
  }

  // Sauvegarder la session utilisateur
  static Future<void> saveUserSession(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_userEmailKey, user.email ?? '');
      await prefs.setString(_userPhoneKey, user.phone ?? '');
      await prefs.setString(_userSessionKey, jsonEncode(user.toJson()));
      print('Session utilisateur sauvegardée: ${user.email}');
    } catch (e) {
      print('Erreur lors de la sauvegarde de la session: $e');
    }
  }

  // Récupérer les informations de l'utilisateur connecté
  static Future<UserModel?> getCurrentUser() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      
      if (isLoggedIn) {
        final userJson = prefs.getString(_userSessionKey);
        if (userJson != null && userJson.isNotEmpty) {
          print('JSON utilisateur récupéré: $userJson'); // Debug
          
          // Nettoyer le JSON si nécessaire
          String cleanedJson = userJson.trim();
          
          // Vérifier si le JSON commence par { et finit par }
          if (!cleanedJson.startsWith('{') || !cleanedJson.endsWith('}')) {
            print('Format JSON invalide, nettoyage...');
            // Si le JSON n'est pas au bon format, essayer de le corriger
            if (cleanedJson.startsWith('{id:') && cleanedJson.endsWith('}')) {
              // Remplacer les : par ":" et ajouter des guillemets autour des clés
              cleanedJson = cleanedJson
                  .replaceAll('{id:', '{"id":')
                  .replaceAll('full_name:', '"full_name":')
                  .replaceAll('phone:', '"phone":')
                  .replaceAll('address:', '"address":')
                  .replaceAll('email:', '"email":')
                  .replaceAll('avatar_url:', '"avatar_url":')
                  .replaceAll('is_active:', '"is_active":')
                  .replaceAll('created_at:', '"created_at":')
                  .replaceAll('updated_at:', '"updated_at":');
              
              // Ajouter des guillemets autour des valeurs string
              cleanedJson = _fixJsonStringValues(cleanedJson);
            }
          }
          
          print('JSON nettoyé: $cleanedJson'); // Debug
          
          // Désérialiser l'utilisateur depuis le JSON sauvegardé
          final userMap = jsonDecode(cleanedJson);
          return UserModel.fromJson(userMap);
        }
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'utilisateur: $e');
      if (prefs != null) {
        print('JSON problématique: ${prefs.getString(_userSessionKey)}');
      }
      
      // En cas d'erreur, nettoyer la session
      await logout();
      return null;
    }
  }
  
  // Méthode pour corriger les valeurs string dans le JSON
  static String _fixJsonStringValues(String json) {
    // Cette méthode corrige les valeurs string qui ne sont pas entre guillemets
    // Exemple: {id: user_123, name: camara} -> {"id": "user_123", "name": "camara"}
    
    // Remplacer les valeurs qui ne sont pas entre guillemets
    json = json.replaceAllMapped(
      RegExp(r':\s*([a-zA-Z0-9_@.-]+)(?=[,\s}])'),
      (match) {
        final value = match.group(1)!;
        // Si la valeur n'est pas déjà entre guillemets et n'est pas un booléen/null
        if (!value.startsWith('"') && value != 'true' && value != 'false' && value != 'null') {
          return ': "$value"';
        }
        return ': $value';
      },
    );
    
    return json;
  }

  // Déconnecter l'utilisateur
  static Future<void> logout() async {
    try {
      // Supprimer les données locales
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_isLoggedInKey);
      await prefs.remove(_userEmailKey);
      await prefs.remove(_userPhoneKey);
      await prefs.remove(_userSessionKey);
      print('Utilisateur déconnecté avec succès');
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
    }
  }
  
  // Nettoyer complètement la session (en cas de problème)
  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Supprime toutes les données
      print('Session complètement nettoyée');
    } catch (e) {
      print('Erreur lors du nettoyage de la session: $e');
    }
  }

  // Récupérer l'email sauvegardé
  static Future<String?> getSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userEmailKey);
    } catch (e) {
      print('Erreur lors de la récupération de l\'email: $e');
      return null;
    }
  }

  // Récupérer le téléphone sauvegardé
  static Future<String?> getSavedPhone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userPhoneKey);
    } catch (e) {
      print('Erreur lors de la récupération du téléphone: $e');
      return null;
    }
  }
}
