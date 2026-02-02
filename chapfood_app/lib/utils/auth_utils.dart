import '../services/session_service.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';

class AuthUtils {
  /// Vérifie l'état d'authentification avec fallback robuste
  static Future<UserModel?> getCurrentUserRobust() async {
    try {
      print('🔍 AuthUtils.getCurrentUserRobust() - Début...');
      
      // 1. Essayer SessionService (cache local)
      print('📱 Tentative SessionService...');
      var user = await SessionService.getCurrentUser();
      if (user != null) {
        print('✅ Utilisateur trouvé dans SessionService: ${user.email}');
        return user;
      }
      
      // 2. Essayer AuthService (avec fallback Supabase)
      print('🔐 Tentative AuthService...');
      user = await AuthService.getUserProfile();
      if (user != null) {
        print('✅ Utilisateur trouvé dans AuthService: ${user.email}');
        return user;
      }
      
      // 3. Essayer SupabaseService (direct Supabase)
      print('☁️ Tentative SupabaseService...');
      user = await SupabaseService.getCurrentUser();
      if (user != null) {
        print('✅ Utilisateur trouvé dans SupabaseService: ${user.email}');
        // Sauvegarder en local pour la prochaine fois
        await SessionService.saveUserSession(user);
        return user;
      }
      
      print('❌ Aucun utilisateur trouvé dans aucun service');
      return null;
    } catch (e) {
      print('❌ Erreur dans getCurrentUserRobust: $e');
      return null;
    }
  }
  
  /// Vérifie si l'utilisateur est authentifié
  static Future<bool> isUserAuthenticated() async {
    final user = await getCurrentUserRobust();
    return user != null;
  }
  
  /// Force la synchronisation de la session
  static Future<void> syncUserSession() async {
    try {
      print('🔄 Synchronisation de la session...');
      
      // Récupérer depuis Supabase
      final user = await SupabaseService.getCurrentUser();
      if (user != null) {
        // Sauvegarder en local
        await SessionService.saveUserSession(user);
        print('✅ Session synchronisée: ${user.email}');
      } else {
        print('❌ Impossible de synchroniser - aucun utilisateur Supabase');
      }
    } catch (e) {
      print('❌ Erreur lors de la synchronisation: $e');
    }
  }
}

