import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';
import '../utils/security_utils.dart';
import 'session_service.dart';
import 'secure_storage_service.dart';

class AuthService {
  static SupabaseClient get _client => SupabaseConfig.client;
  static const _uuid = Uuid();

  // Obtenir l'utilisateur actuel
  static User? get currentUser => _client.auth.currentUser;

  // Vérifier si l'utilisateur est connecté
  static Future<bool> get isLoggedIn async =>
      await SessionService.isUserLoggedIn();

  // Écouter les changements d'authentification
  static Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  // Connexion avec email et mot de passe (directe avec la table users)
  static Future<Map<String, dynamic>> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      print('🔐 Tentative de connexion pour: $email');

      // Validation des données d'entrée
      final validationErrors = _validateLoginData(email, password);
      if (validationErrors.isNotEmpty) {
        throw Exception(validationErrors.join('; '));
      }

      // Rechercher l'utilisateur dans la table users
      final response = await _client
          .from('users')
          .select()
          .eq('email', email)
          .eq('is_active', true)
          .single();

      // La méthode .single() lève déjà une exception si aucun résultat n'est trouvé

      // Vérifier le mot de passe
      final passwordHash = response['password'] ?? response['password_hash'];

      if (passwordHash == null) {
        throw Exception('Erreur de configuration du compte');
      }

      // Si c'est un hash (contient ':'), utiliser verify
      bool isPasswordValid;
      if (passwordHash.toString().contains(':')) {
        isPasswordValid = SecurityUtils.verifyPassword(password, passwordHash);
      } else {
        // Fallback pour les anciens comptes non migrés
        isPasswordValid = passwordHash == password;
      }

      if (!isPasswordValid) {
        throw Exception('Mot de passe incorrect');
      }

      print('✅ Connexion réussie pour: ${response['email']}');

      // Créer un UserModel
      final userModel = UserModel.fromJson(response);

      // Sauvegarder la session
      await SessionService.saveUserSession(userModel);
      print('💾 Session sauvegardée avec succès');

      return {
        'success': true,
        'user': userModel,
        'message': 'Connexion réussie',
      };
    } catch (e) {
      print('❌ Erreur de connexion: $e');
      rethrow;
    }
  }

  // Inscription avec email et mot de passe (directe dans la table users)
  static Future<Map<String, dynamic>> signUpWithEmail(
    String email,
    String password,
    String fullName, {
    String? phone,
    String? address,
  }) async {
    try {
      print('📝 Début de l\'inscription directe pour: $email');

      // Validation des données d'entrée
      final validationErrors = _validateSignupData(
        email,
        password,
        fullName,
        phone,
      );
      if (validationErrors.isNotEmpty) {
        throw Exception(validationErrors.join('; '));
      }

      // Vérifier si l'utilisateur existe déjà
      final existingUser = await _client
          .from('users')
          .select('id, email, phone')
          .or('email.eq.$email,phone.eq.$phone')
          .maybeSingle();

      if (existingUser != null) {
        if (existingUser['email'] == email) {
          throw Exception('Un compte avec cet email existe déjà');
        }
        if (existingUser['phone'] == phone &&
            phone != null &&
            phone.isNotEmpty) {
          throw Exception('Un compte avec ce numéro de téléphone existe déjà');
        }
      }

      // Générer un UUID pour l'utilisateur
      final userId = _generateUserId();

      // Hacher le mot de passe
      final passwordHash = SecurityUtils.hashPassword(password);

      // Créer l'utilisateur directement dans la table users
      final userData = {
        'id': userId,
        'email': email,
        'password':
            passwordHash, // Utiliser 'password' au lieu de 'password_hash'
        'full_name': fullName,
        'phone': phone,
        'address': address,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('👤 Création de l\'utilisateur dans la table users...');
      final response = await _client
          .from('users')
          .insert(userData)
          .select()
          .single();

      print('✅ Utilisateur créé avec succès: ${response['email']}');

      // Créer un UserModel pour la session
      final userModel = UserModel.fromJson(response);

      // Sauvegarder la session
      await SessionService.saveUserSession(userModel);
      print('💾 Session sauvegardée avec succès');

      return {
        'success': true,
        'user': userModel,
        'message': 'Compte créé avec succès',
      };
    } catch (e) {
      print('❌ Erreur d\'inscription: $e');
      rethrow;
    }
  }

  // Générer un UUID v4 pour l'utilisateur
  static String _generateUserId() {
    // Générer un vrai UUID v4
    return _uuid.v4();
  }

  // Connexion avec numéro de téléphone (directe avec la table users)
  static Future<Map<String, dynamic>> signInWithPhone(
    String phone,
    String password,
  ) async {
    try {
      print('📱 Tentative de connexion par téléphone: $phone');

      // Validation des données d'entrée
      final validationErrors = _validatePhoneLoginData(phone, password);
      if (validationErrors.isNotEmpty) {
        throw Exception(validationErrors.join('; '));
      }

      // Rechercher l'utilisateur par téléphone
      final response = await _client
          .from('users')
          .select()
          .eq('phone', phone)
          .eq('is_active', true)
          .single();

      // La méthode .single() lève déjà une exception si aucun résultat n'est trouvé

      // Vérifier le mot de passe
      final passwordHash = response['password'] ?? response['password_hash'];

      if (passwordHash == null) {
        throw Exception('Erreur de configuration du compte');
      }

      // Si c'est un hash (contient ':'), utiliser verify
      bool isPasswordValid;
      if (passwordHash.toString().contains(':')) {
        isPasswordValid = SecurityUtils.verifyPassword(password, passwordHash);
      } else {
        // Fallback pour les anciens comptes non migrés
        isPasswordValid = passwordHash == password;
      }

      if (!isPasswordValid) {
        throw Exception('Mot de passe incorrect');
      }

      print('✅ Connexion réussie pour: ${response['email']}');

      // Créer un UserModel
      final userModel = UserModel.fromJson(response);

      // Sauvegarder la session
      await SessionService.saveUserSession(userModel);
      print('💾 Session sauvegardée avec succès');

      return {
        'success': true,
        'user': userModel,
        'message': 'Connexion réussie',
      };
    } catch (e) {
      print('❌ Erreur de connexion par téléphone: $e');
      rethrow;
    }
  }

  // Déconnexion
  static Future<void> signOut() async {
    try {
      await SessionService.logout();
    } catch (e) {
      print('Erreur de déconnexion: $e');
      rethrow;
    }
  }

  // Obtenir les données du profil utilisateur
  static Future<UserModel?> getUserProfile() async {
    try {
      print('🔍 getUserProfile() - Début de la récupération...');

      // 1. Essayer d'abord de récupérer depuis Supabase directement
      final supabaseUser = _client.auth.currentUser;
      if (supabaseUser != null) {
        print('✅ Utilisateur Supabase trouvé: ${supabaseUser.email}');

        try {
          // Récupérer les données complètes depuis la base de données
          final response = await _client
              .from('users')
              .select()
              .eq('id', supabaseUser.id)
              .single();

          print(
            '✅ Données utilisateur récupérées depuis la base: ${response['email']}',
          );
          final userModel = UserModel.fromJson(response);

          // Sauvegarder en local pour la prochaine fois
          await SessionService.saveUserSession(userModel);

          return userModel;
        } catch (e) {
          print('❌ Erreur récupération depuis la base: $e');
          // Continuer avec le fallback
        }
      }

      // 2. Fallback: Utiliser SessionService pour récupérer l'utilisateur actuel
      print('🔄 Fallback vers SessionService...');
      final user = await SessionService.getCurrentUser();
      if (user != null) {
        print('✅ Utilisateur récupéré depuis SessionService: ${user.email}');
        return user;
      }

      print('❌ Aucun utilisateur connecté - ni Supabase ni SessionService');
      return null;
    } catch (e) {
      print('❌ Erreur récupération profil: $e');
      return null;
    }
  }

  // Mettre à jour le profil utilisateur
  static Future<UserModel?> updateUserProfile(
    Map<String, dynamic> updates,
  ) async {
    try {
      // Utiliser SessionService pour récupérer l'utilisateur actuel
      final user = await SessionService.getCurrentUser();
      if (user == null) {
        print('❌ Aucun utilisateur connecté');
        return null;
      }

      // Convertir l'ID si nécessaire (pas nécessaire car SessionService gère déjà les UUIDs)
      final userId = user.id;

      // Mettre à jour dans la base de données
      final response = await _client
          .from('users')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      // Mettre à jour la session locale
      final updatedUser = UserModel.fromJson(response);
      await SessionService.saveUserSession(updatedUser);

      print('✅ Profil utilisateur mis à jour');
      return updatedUser;
    } catch (e) {
      print('❌ Erreur mise à jour profil: $e');
      return null;
    }
  }

  // Réinitialiser le mot de passe
  static Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      print('Erreur réinitialisation mot de passe: $e');
      rethrow;
    }
  }

  // ========== MÉTHODES DE VALIDATION ==========

  // Validation des données d'inscription
  static List<String> _validateSignupData(
    String email,
    String password,
    String fullName,
    String? phone,
  ) {
    final errors = <String>[];

    // Validation email
    if (email.isEmpty) {
      errors.add('L\'email est obligatoire');
    } else if (!_isValidEmail(email)) {
      errors.add('Format d\'email invalide');
    }

    // Validation mot de passe
    if (password.isEmpty) {
      errors.add('Le mot de passe est obligatoire');
    } else if (password.length < 6) {
      errors.add('Le mot de passe doit contenir au moins 6 caractères');
    }

    // Validation nom complet
    if (fullName.isEmpty) {
      errors.add('Le nom complet est obligatoire');
    } else if (fullName.length < 2) {
      errors.add('Le nom doit contenir au moins 2 caractères');
    }

    // Validation téléphone (optionnel)
    if (phone != null && phone.isNotEmpty && !_isValidPhone(phone)) {
      errors.add(
        'Format de téléphone invalide (ex: 0711111111 ou +2250711111111)',
      );
    }

    return errors;
  }

  // Validation des données de connexion email
  static List<String> _validateLoginData(String email, String password) {
    final errors = <String>[];

    // Validation email
    if (email.isEmpty) {
      errors.add('L\'email est obligatoire');
    } else if (!_isValidEmail(email)) {
      errors.add('Format d\'email invalide');
    }

    // Validation mot de passe
    if (password.isEmpty) {
      errors.add('Le mot de passe est obligatoire');
    }

    return errors;
  }

  // Validation des données de connexion téléphone
  static List<String> _validatePhoneLoginData(String phone, String password) {
    final errors = <String>[];

    // Validation téléphone
    if (phone.isEmpty) {
      errors.add('Le numéro de téléphone est obligatoire');
    } else if (!_isValidPhone(phone)) {
      errors.add(
        'Format de téléphone invalide (ex: 0711111111 ou +2250711111111)',
      );
    }

    // Validation mot de passe
    if (password.isEmpty) {
      errors.add('Le mot de passe est obligatoire');
    }

    return errors;
  }

  // Vérification du format email
  static bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // Vérification du format téléphone
  static bool _isValidPhone(String phone) {
    // Nettoyer le numéro (supprimer espaces, tirets)
    final cleanPhone = phone.replaceAll(' ', '').replaceAll('-', '');

    // Formats acceptés:
    // - Format local: 0711111111 (commence par 07, 05, 01)
    // - Format international complet: +2250711111111
    // - Format international court: +225711111111
    final localRegex = RegExp(
      r'^(07|05|01)[0-9]{8}$',
    ); // Format local: 07xxxxxxxx
    final internationalRegex = RegExp(
      r'^(\+225|225)(07|05|01)[0-9]{8}$',
    ); // Format international

    return localRegex.hasMatch(cleanPhone) ||
        internationalRegex.hasMatch(cleanPhone);
  }
}
