import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

/// Service pour stocker les données sensibles de manière sécurisée
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Clés de stockage
  static const String _userSessionKey = 'user_session_secure';
  static const String _authTokenKey = 'auth_token_secure';
  static const String _refreshTokenKey = 'refresh_token_secure';
  static const String _sessionExpiryKey = 'session_expiry';

  /// Sauvegarder la session utilisateur de manière sécurisée
  static Future<void> saveUserSession(Map<String, dynamic> userData) async {
    try {
      final jsonData = jsonEncode(userData);
      await _storage.write(key: _userSessionKey, value: jsonData);

      // Définir l'expiration de session à 7 jours
      final expiry = DateTime.now().add(const Duration(days: 7));
      await _storage.write(
        key: _sessionExpiryKey,
        value: expiry.toIso8601String(),
      );
    } catch (e) {
      print('❌ Erreur sauvegarde session sécurisée: $e');
      rethrow;
    }
  }

  /// Récupérer la session utilisateur
  static Future<Map<String, dynamic>?> getUserSession() async {
    try {
      // Vérifier l'expiration
      if (!await isSessionValid()) {
        await clearSession();
        return null;
      }

      final jsonData = await _storage.read(key: _userSessionKey);
      if (jsonData == null) return null;

      return jsonDecode(jsonData) as Map<String, dynamic>;
    } catch (e) {
      print('❌ Erreur récupération session: $e');
      return null;
    }
  }

  /// Vérifier si la session est valide (non expirée)
  static Future<bool> isSessionValid() async {
    try {
      final expiryStr = await _storage.read(key: _sessionExpiryKey);
      if (expiryStr == null) return false;

      final expiry = DateTime.parse(expiryStr);
      return DateTime.now().isBefore(expiry);
    } catch (e) {
      return false;
    }
  }

  /// Sauvegarder le token d'authentification
  static Future<void> saveAuthToken(String token) async {
    await _storage.write(key: _authTokenKey, value: token);
  }

  /// Récupérer le token d'authentification
  static Future<String?> getAuthToken() async {
    return await _storage.read(key: _authTokenKey);
  }

  /// Sauvegarder le refresh token
  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  /// Récupérer le refresh token
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Nettoyer complètement la session
  static Future<void> clearSession() async {
    try {
      await _storage.delete(key: _userSessionKey);
      await _storage.delete(key: _authTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _sessionExpiryKey);
    } catch (e) {
      print('❌ Erreur nettoyage session: $e');
    }
  }

  /// Supprimer toutes les données
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

