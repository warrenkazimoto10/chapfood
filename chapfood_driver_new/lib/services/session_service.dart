import 'package:supabase_flutter/supabase_flutter.dart';

class SessionService {
  static User? get currentUser => Supabase.instance.client.auth.currentUser;

  static bool get isLoggedIn => currentUser != null;

  static Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }
}
