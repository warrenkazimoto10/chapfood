import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/driver_model.dart';
import '../config/supabase_config.dart';
import 'session_service.dart';

class AuthService {
  static SupabaseClient get _supabase => SupabaseConfig.client;

  // Connexion par email
  static Future<void> signInWithEmail(String email, String password) async {
    try {
      print('🔐 Tentative de connexion avec email: $email');
      
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      print('✅ Authentification réussie pour: ${response.user?.email}');
      print('🆔 ID utilisateur: ${response.user?.id}');

      if (response.user != null) {
        print('🔍 Recherche des données driver...');
        
        // Récupérer les informations du driver
        final driverData = await _supabase
            .from('drivers')
            .select()
            .eq('email', email)
            .eq('is_active', true)
            .single();

        if (driverData != null) {
          print('📋 Données driver trouvées: ${driverData['name']}');
          
          final driver = DriverModel.fromJson(driverData as Map<String, dynamic>);
          print('👤 Driver créé: ${driver.name}');
          
          await SessionService.saveDriverSession(driver);
          print('💾 Session sauvegardée avec succès');
        } else {
          print('❌ Aucun driver actif trouvé avec cet email');
          throw Exception('Aucun livreur actif trouvé avec cet email');
        }
      }
    } catch (e) {
      print('❌ Erreur de connexion: $e');
      throw Exception('Erreur de connexion: ${e.toString()}');
    }
  }

  // Connexion par téléphone
  static Future<void> signInWithPhone(String phone, String password) async {
    try {
      // Rechercher le driver par téléphone
      final driverData = await _supabase
          .from('drivers')
          .select()
          .eq('phone', phone)
          .eq('is_active', true)
          .single();

      if (driverData != null) {
        final driver = DriverModel.fromJson(driverData as Map<String, dynamic>);
        
        // Pour cette démo, on accepte n'importe quel mot de passe
        // En production, vous devriez utiliser une authentification sécurisée
        await SessionService.saveDriverSession(driver);
      } else {
        throw Exception('Aucun livreur trouvé avec ce numéro de téléphone');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: ${e.toString()}');
    }
  }

  // Inscription d'un nouveau driver
  static Future<void> registerDriver(String name, String email, String phone, String password) async {
    try {
      print('🚀 Début de l\'inscription pour: $email');
      
      // Créer le compte utilisateur
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      print('✅ Compte utilisateur créé avec ID: ${response.user?.id}');

      if (response.user != null) {
        // Créer le profil driver dans la base de données
        final driverData = {
          'name': name,
          'email': email,
          'phone': phone,
          'is_active': true,
          'is_available': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        print('📝 Données driver à insérer: $driverData');

        final insertResult = await _supabase.from('drivers').insert(driverData).select();
        print('✅ Driver inséré dans la base de données: $insertResult');

        // Récupérer l'ID généré par Supabase
        if (insertResult.isNotEmpty) {
          final insertedDriver = insertResult.first;
          print('🆔 Driver créé avec ID: ${insertedDriver['id']}');
          
          // Sauvegarder la session
          final driver = DriverModel.fromJson(insertedDriver);
          await SessionService.saveDriverSession(driver);
          print('💾 Session sauvegardée');
        }
      }
    } catch (e) {
      print('❌ Erreur lors de l\'inscription: $e');
      throw Exception('Erreur lors de l\'inscription: ${e.toString()}');
    }
  }

  // Déconnexion
  static Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      await SessionService.logout();
    } catch (e) {
      throw Exception('Erreur de déconnexion: ${e.toString()}');
    }
  }

  // Vérifier si l'utilisateur est connecté
  static bool get isSignedIn => _supabase.auth.currentUser != null;

  // Obtenir l'utilisateur actuel
  static User? get currentUser => _supabase.auth.currentUser;
}
