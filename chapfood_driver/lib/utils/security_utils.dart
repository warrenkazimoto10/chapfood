import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Utilitaires de sécurité pour le hachage et la validation des mots de passe
class SecurityUtils {
  /// Hache un mot de passe avec SHA-256 et un salt
  ///
  /// NOTE: En production, il faudrait utiliser bcrypt ou argon2
  /// via un package natif ou une fonction Edge Supabase
  static String hashPassword(String password, {String? salt}) {
    final effectiveSalt = salt ?? _generateSalt();
    final bytes = utf8.encode(password + effectiveSalt);
    final digest = sha256.convert(bytes);
    return '$effectiveSalt:$digest';
  }

  /// Vérifie si un mot de passe correspond au hash
  static bool verifyPassword(String password, String hashedPassword) {
    try {
      final parts = hashedPassword.split(':');
      if (parts.length != 2) return false;

      final salt = parts[0];
      final hash = parts[1];

      final newHash = hashPassword(password, salt: salt);
      return newHash == hashedPassword;
    } catch (e) {
      return false;
    }
  }

  /// Génère un salt aléatoire
  static String _generateSalt() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = (timestamp.hashCode ^ DateTime.now().microsecondsSinceEpoch)
        .toString();
    return sha256.convert(utf8.encode(random)).toString().substring(0, 16);
  }

  /// Valide la force d'un mot de passe
  static PasswordStrength checkPasswordStrength(String password) {
    if (password.length < 6) {
      return PasswordStrength.weak;
    }

    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecialCharacters = password.contains(
      RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
    );

    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (hasUppercase) strength++;
    if (hasLowercase) strength++;
    if (hasDigits) strength++;
    if (hasSpecialCharacters) strength++;

    if (strength <= 2) return PasswordStrength.weak;
    if (strength <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }
}

enum PasswordStrength { weak, medium, strong }

