import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static Future<void> signInWithPhone(String phone, String password) async {
    // Note: Supabase Auth with Phone usually requires OTP.
    // If you are using email/password auth but with phone as identifier (custom),
    // you might need to adapt this.
    // Assuming standard email/password for now or custom logic.
    
    // If your old app used a custom table 'drivers' and manual password check:
    // We should replicate that or migrate to Supabase Auth properly.
    // The LoginScreen code suggests it checks 'drivers' table first.
    
    // Let's assume standard Supabase Auth for now:
    await Supabase.instance.client.auth.signInWithPassword(
      email: "$phone@chapfood.com", // Hack if using phone as email
      password: password,
    );
  }

  static Future<void> registerDriver(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    try {
      // ignore: avoid_print
      print('📝 Starting driver registration...');
      print('   Name: $name');
      print('   Email: $email');
      print('   Phone: $phone');
      
      // Register with Supabase Auth using phone as email (same as login)
      // Cela permet de se connecter avec le téléphone ensuite
      final authEmail = '$phone@chapfood.com';
      
      final response = await Supabase.instance.client.auth.signUp(
        email: authEmail,
        password: password,
      );

      // ignore: avoid_print
      print('✅ Auth user created: ${response.user?.id}');

      if (response.user != null) {
        // Create driver record in drivers table
        // Note: 'id' is auto-incrementing integer in DB, so we don't send the Auth UUID.
        // The link is made via email/phone.
        
        final driverData = {
          'name': name,
          'email': email, // Stocker le vrai email dans la table drivers
          'phone': phone,
          'is_active': true,
          'is_available': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        // ignore: avoid_print
        print('📊 Inserting driver data: $driverData');
        
        final insertResponse = await Supabase.instance.client
            .from('drivers')
            .insert(driverData)
            .select();
        
        // ignore: avoid_print
        print('✅ Driver inserted successfully: $insertResponse');
      } else {
        // ignore: avoid_print
        print('❌ Auth user creation failed: no user returned');
        throw Exception('Failed to create auth user');
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error during driver registration: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getDriverInfo() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.email == null) return null;

    try {
      // Check if email is a phone hack (ends with @chapfood.com)
      String searchField;
      String searchValue;
      
      if (user.email!.endsWith('@chapfood.com')) {
        // Extract phone from email hack
        searchField = 'phone';
        searchValue = user.email!.replaceAll('@chapfood.com', '');
      } else {
        searchField = 'email';
        searchValue = user.email!;
      }

      final response = await Supabase.instance.client
          .from('drivers')
          .select()
          .eq(searchField, searchValue)
          .maybeSingle();
      return response;
    } catch (e) {
      // ignore: avoid_print
      print('Error getting driver info: $e');
      return null;
    }
  }

  static Future<void> updateDriverStatus(bool isAvailable) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.email == null) {
      // ignore: avoid_print
      print('❌ Cannot update status: user or email is null');
      return;
    }

    try {
      // Check if email is a phone hack (ends with @chapfood.com)
      String searchField;
      String searchValue;
      
      if (user.email!.endsWith('@chapfood.com')) {
        // Extract phone from email hack
        searchField = 'phone';
        searchValue = user.email!.replaceAll('@chapfood.com', '');
      } else {
        searchField = 'email';
        searchValue = user.email!;
      }

      // ignore: avoid_print
      print('🔄 Updating driver status: $searchField = $searchValue, is_available = $isAvailable');

      final response = await Supabase.instance.client
          .from('drivers')
          .update({'is_available': isAvailable})
          .eq(searchField, searchValue)
          .select();
      
      // ignore: avoid_print
      print('✅ Status updated successfully: $response');
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error updating driver status: $e');
      
      // Si c'est une erreur d'authentification, déconnecter l'utilisateur
      if (e.toString().contains('AuthRetryableFetchException') || 
          e.toString().contains('missing destination name oauth_client_id')) {
        // ignore: avoid_print
        print('🔒 Session expirée, déconnexion...');
        await Supabase.instance.client.auth.signOut();
      }
      
      rethrow;
    }
  }
}
