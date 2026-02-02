#!/usr/bin/env dart

import 'dart:io';

void main() async {
  print('🧪 Test des améliorations de validation\n');
  
  // Test 1: Validation email
  print('📧 Test validation email:');
  await _testEmailValidation();
  
  // Test 2: Validation téléphone
  print('\n📱 Test validation téléphone:');
  await _testPhoneValidation();
  
  // Test 3: Validation mot de passe
  print('\n🔐 Test validation mot de passe:');
  await _testPasswordValidation();
  
  print('\n✅ Tous les tests de validation sont terminés !');
}

Future<void> _testEmailValidation() async {
  final testEmails = [
    'user@example.com',      // Valide
    'test.email@domain.co',  // Valide
    'invalid-email',         // Invalide
    '',                      // Vide
    'user@',                 // Invalide
    '@domain.com',           // Invalide
  ];
  
  final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  
  for (final email in testEmails) {
    final isValid = emailRegex.hasMatch(email);
    final status = isValid ? '✅' : '❌';
    print('  $status $email -> ${isValid ? 'Valide' : 'Invalide'}');
  }
}

Future<void> _testPhoneValidation() async {
  final testPhones = [
    '0711111111',            // Valide (format local)
    '0511111111',            // Valide (format local)
    '0111111111',            // Valide (format local)
    '+2250711111111',        // Valide (format international complet)
    '+2250511111111',        // Valide (format international complet)
    '2250711111111',         // Valide (format international sans +)
    '07 11 11 11 11',        // Valide (avec espaces)
    '07-11-11-11-11',        // Valide (avec tirets)
    '123456789',             // Invalide (pas le bon préfixe)
    '071234567',             // Invalide (trop court)
    '07123456789',           // Invalide (trop long)
    '+123456789',            // Invalide (mauvais pays)
    '',                      // Vide
  ];
  
  final localRegex = RegExp(r'^(07|05|01)[0-9]{8}$'); // Format local: 07xxxxxxxx
  final internationalRegex = RegExp(r'^(\+225|225)(07|05|01)[0-9]{8}$'); // Format international
  
  for (final phone in testPhones) {
    final cleanPhone = phone.replaceAll(' ', '').replaceAll('-', '');
    final isValid = localRegex.hasMatch(cleanPhone) || internationalRegex.hasMatch(cleanPhone);
    final status = isValid ? '✅' : '❌';
    print('  $status $phone -> ${isValid ? 'Valide' : 'Invalide'}');
  }
}

Future<void> _testPasswordValidation() async {
  final testPasswords = [
    'password123',           // Valide (6+ caractères)
    'abc',                   // Invalide (< 6 caractères)
    'verylongpassword12345678901234567890', // Valide
    '',                      // Vide
    '123456',                // Valide (exactement 6)
  ];
  
  for (final password in testPasswords) {
    bool isValid = true;
    List<String> errors = [];
    
    if (password.isEmpty) {
      isValid = false;
      errors.add('Obligatoire');
    } else if (password.length < 6) {
      isValid = false;
      errors.add('Trop court');
    } else if (password.length > 50) {
      isValid = false;
      errors.add('Trop long');
    }
    
    final status = isValid ? '✅' : '❌';
    final errorText = errors.isNotEmpty ? ' (${errors.join(', ')})' : '';
    print('  $status "${password.isEmpty ? '[VIDE]' : password}" -> ${isValid ? 'Valide' : 'Invalide'}$errorText');
  }
}
