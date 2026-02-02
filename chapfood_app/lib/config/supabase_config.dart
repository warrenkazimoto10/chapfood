import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://bxticpobvukefjtawjhi.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ4dGljcG9idnVrZWZqdGF3amhpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ0Nzc0NTMsImV4cCI6MjA3MDA1MzQ1M30.JJ_TvTyetZWB42Ef4971Iaa2PxzyqjBhFMOUDXX7bDA';
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      // Configuration pour améliorer la robustesse réseau
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
      ),
    );
  }
  
  static SupabaseClient get client => Supabase.instance.client;
}
