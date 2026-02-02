import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gif/gif.dart';
import '../constants/app_colors.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _showPasswordField = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    // Écouter les changements du champ téléphone
    _phoneController.addListener(() {
      if (_phoneController.text.trim().isEmpty && _showPasswordField) {
        setState(() {
          _showPasswordField = false;
          _passwordController.clear();
        });
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkPhoneNumber() async {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer votre numéro de téléphone'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Vérifier si le numéro existe dans la base de données
      final phoneNumber = _phoneController.text.trim();

      // Appel à Supabase pour vérifier si le numéro existe
      final response = await Supabase.instance.client
          .from('drivers')
          .select('id, phone')
          .eq('phone', phoneNumber)
          .maybeSingle();

      if (response != null) {
        // Numéro existe dans la base de données, afficher le champ mot de passe
        setState(() {
          _showPasswordField = true;
        });
      } else {
        // Numéro n'existe pas, rediriger vers l'inscription avec le numéro prérempli
        context.go(
          '/signup-wizard?phone=${Uri.encodeComponent(_phoneController.text.trim())}',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _goBackToPhoneVerification() {
    setState(() {
      _showPasswordField = false;
      _passwordController.clear();
    });
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final phone = _phoneController.text.trim();
      final password = _passwordController.text;

      await AuthService.signInWithPhone(phone, password);

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de connexion: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: size.height - MediaQuery.of(context).padding.top,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Illustration en haut
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.topCenter,
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Expanded(
                          child: Center(
                            child: Container(
                              width: double.infinity,
                              height: 280,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Gif(
                                  image: const AssetImage(
                                    'assets/animations/gif-elephant.gif',
                                  ),
                                  fit: BoxFit.cover,
                                  autostart: Autostart.loop,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Formulaire de connexion
                Expanded(
                  flex: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 4),

                            // Titre d'accueil
                            Text(
                              "Bienvenue dans",
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "ChapFood Livreur",
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryRed,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Champ numéro de téléphone
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE6E6E8),
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0A000000),
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: 'Numéro de téléphone',
                                  hintStyle: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.phone,
                                    color: AppColors.primaryRed,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Veuillez entrer votre numéro';
                                  }
                                  return null;
                                },
                              ),
                            ),

                            // Champ mot de passe (apparaît conditionnellement)
                            if (_showPasswordField) ...[
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE6E6E8),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x0A000000),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: _passwordController,
                                  obscureText: !_isPasswordVisible,
                                  decoration: InputDecoration(
                                    hintText: 'Mot de passe',
                                    hintStyle: GoogleFonts.poppins(
                                      color: Colors.grey[600],
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.lock,
                                      color: AppColors.primaryRed,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: AppColors.primaryRed,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible =
                                              !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez entrer votre mot de passe';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Bouton retour
                              SizedBox(
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: _goBackToPhoneVerification,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF1F1F3),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(40),
                                    ),
                                    side: BorderSide.none,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.arrow_back,
                                        color: AppColors.primaryRed,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Retour à la vérification",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryRed,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),

                            // Bouton principal
                            SizedBox(
                              height: 64,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : (_showPasswordField
                                          ? _login
                                          : _checkPhoneNumber),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                  elevation: 2,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        _showPasswordField
                                            ? "Connexion"
                                            : "Vérifier le numéro",
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Version app en bas
                            Center(
                              child: Text(
                                "ChapFood Livreur v1.0.0",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
