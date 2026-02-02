// Script de test pour le nouveau système d'authentification directe
// À exécuter dans un environnement de test

import 'package:flutter_test/flutter_test.dart';
import 'lib/services/auth_service.dart';
import 'lib/services/session_service.dart';

void main() {
  group('Test Authentification Directe', () {
    
    test('Test inscription avec email', () async {
      try {
        final result = await AuthService.signUpWithEmail(
          'test@example.com',
          'password123',
          'Test User',
          phone: '+225123456789'
        );
        
        expect(result['success'], true);
        expect(result['user'], isNotNull);
        expect(result['message'], 'Compte créé avec succès');
        
        print('✅ Test inscription réussi');
      } catch (e) {
        print('❌ Test inscription échoué: $e');
        fail('Inscription échouée');
      }
    });
    
    test('Test connexion avec email', () async {
      try {
        final result = await AuthService.signInWithEmail(
          'test@example.com',
          'password123'
        );
        
        expect(result['success'], true);
        expect(result['user'], isNotNull);
        expect(result['message'], 'Connexion réussie');
        
        print('✅ Test connexion réussi');
      } catch (e) {
        print('❌ Test connexion échoué: $e');
        fail('Connexion échouée');
      }
    });
    
    test('Test connexion avec téléphone', () async {
      try {
        final result = await AuthService.signInWithPhone(
          '+225123456789',
          'password123'
        );
        
        expect(result['success'], true);
        expect(result['user'], isNotNull);
        expect(result['message'], 'Connexion réussie');
        
        print('✅ Test connexion téléphone réussi');
      } catch (e) {
        print('❌ Test connexion téléphone échoué: $e');
        fail('Connexion téléphone échouée');
      }
    });
    
    test('Test récupération utilisateur après connexion', () async {
      try {
        final user = await SessionService.getCurrentUser();
        
        expect(user, isNotNull);
        expect(user?.email, 'test@example.com');
        expect(user?.fullName, 'Test User');
        expect(user?.phone, '+225123456789');
        
        print('✅ Test récupération utilisateur réussi');
      } catch (e) {
        print('❌ Test récupération utilisateur échoué: $e');
        fail('Récupération utilisateur échouée');
      }
    });
    
    test('Test gestion des erreurs - email déjà utilisé', () async {
      try {
        await AuthService.signUpWithEmail(
          'test@example.com',
          'password123',
          'Test User 2'
        );
        
        fail('Devrait lever une exception pour email déjà utilisé');
      } catch (e) {
        expect(e.toString(), contains('Un compte avec cet email existe déjà'));
        print('✅ Test gestion erreur email déjà utilisé réussi');
      }
    });
    
    test('Test gestion des erreurs - mot de passe incorrect', () async {
      try {
        await AuthService.signInWithEmail(
          'test@example.com',
          'mauvais_mot_de_passe'
        );
        
        fail('Devrait lever une exception pour mot de passe incorrect');
      } catch (e) {
        expect(e.toString(), contains('Mot de passe incorrect'));
        print('✅ Test gestion erreur mot de passe incorrect réussi');
      }
    });
    
    test('Test déconnexion', () async {
      try {
        await AuthService.signOut();
        
        final user = await SessionService.getCurrentUser();
        expect(user, isNull);
        
        print('✅ Test déconnexion réussi');
      } catch (e) {
        print('❌ Test déconnexion échoué: $e');
        fail('Déconnexion échouée');
      }
    });
  });
}

// Fonction utilitaire pour exécuter les tests manuellement
void runManualTests() async {
  print('🧪 Démarrage des tests d\'authentification directe...\n');
  
  try {
    // Test 1: Inscription
    print('1. Test inscription...');
    final signupResult = await AuthService.signUpWithEmail(
      'manual@test.com',
      'password123',
      'Manual Test User',
      phone: '+225987654321'
    );
    print('   Résultat: ${signupResult['success'] ? '✅ Succès' : '❌ Échec'}\n');
    
    // Test 2: Connexion email
    print('2. Test connexion email...');
    final loginEmailResult = await AuthService.signInWithEmail(
      'manual@test.com',
      'password123'
    );
    print('   Résultat: ${loginEmailResult['success'] ? '✅ Succès' : '❌ Échec'}\n');
    
    // Test 3: Connexion téléphone
    print('3. Test connexion téléphone...');
    final loginPhoneResult = await AuthService.signInWithPhone(
      '+225987654321',
      'password123'
    );
    print('   Résultat: ${loginPhoneResult['success'] ? '✅ Succès' : '❌ Échec'}\n');
    
    // Test 4: Vérification session
    print('4. Test vérification session...');
    final currentUser = await SessionService.getCurrentUser();
    print('   Utilisateur connecté: ${currentUser?.email ?? 'Aucun'}\n');
    
    // Test 5: Déconnexion
    print('5. Test déconnexion...');
    await AuthService.signOut();
    final userAfterLogout = await SessionService.getCurrentUser();
    print('   Utilisateur après déconnexion: ${userAfterLogout?.email ?? 'Aucun'}\n');
    
    print('🎉 Tous les tests manuels terminés!');
    
  } catch (e) {
    print('❌ Erreur lors des tests manuels: $e');
  }
}

