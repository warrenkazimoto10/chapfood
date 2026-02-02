import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../services/auth_service.dart';
import 'splash_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SessionCheckScreen extends StatefulWidget {
  const SessionCheckScreen({super.key});

  @override
  State<SessionCheckScreen> createState() => _SessionCheckScreenState();
}

class _SessionCheckScreenState extends State<SessionCheckScreen> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkUserSession();
  }

  Future<void> _checkUserSession() async {
    try {
      // Attendre un peu pour l'effet visuel
      await Future.delayed(const Duration(seconds: 1));
      
      final isLoggedIn = await SessionService.isUserLoggedIn();
      
      if (mounted) {
        if (isLoggedIn) {
          // Utilisateur connecté, aller à la page d'accueil
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          // Utilisateur non connecté, aller à la page de connexion
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      print('Erreur lors de la vérification de session: $e');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo ChapFood
            Image.asset(
              'assets/images/logo-chapfood.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 30),
            
            // Indicateur de chargement
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            ),
            const SizedBox(height: 20),
            
            // Texte de chargement
            Text(
              'Vérification de votre session...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
