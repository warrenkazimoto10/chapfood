import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../utils/text_styles.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../widgets/custom_snackbar.dart';
import 'services_screen.dart';
import 'signup_wizard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final savedEmail = await SessionService.getSavedEmail();
      final savedPhone = await SessionService.getSavedPhone();
      
      if (savedEmail != null && savedEmail.isNotEmpty) {
        _emailController.text = savedEmail;
      } else if (savedPhone != null && savedPhone.isNotEmpty) {
        _emailController.text = savedPhone;
      }
    } catch (e) {
      print('Erreur lors du chargement des identifiants: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text;

        // Vérifier si c'est un email ou un numéro de téléphone
        Map<String, dynamic> result;
        if (email.contains('@')) {
          // Connexion par email
          print('Tentative de connexion par email: $email');
          result = await AuthService.signInWithEmail(email, password);
        } else {
          // Connexion par téléphone
          print('Tentative de connexion par téléphone: $email');
          result = await AuthService.signInWithPhone(email, password);
        }

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (result['success'] == true) {
          print('Connexion réussie, navigation vers ServicesScreen');
            
            // Afficher un message de succès personnalisé
            final user = result['user'];
            final userName = user?.fullName ?? user?.email?.split('@')[0] ?? 'Utilisateur';
            
            // Utiliser addPostFrameCallback pour éviter l'erreur "showSnackBar during build"
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                CustomSnackBar.showSuccess(
                  context,
                  title: 'Connexion réussie !',
                  message: 'Bienvenue $userName',
                );
              }
            });
            
            // Navigation vers la page des services après un délai
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ServicesScreen()),
          );
              }
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          // Analyser l'erreur et afficher un message personnalisé
          String errorMessage = _getErrorMessage(e.toString());
          String errorTitle = _getErrorTitle(e.toString());
          
          // Utiliser addPostFrameCallback pour éviter l'erreur "showSnackBar during build"
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              CustomSnackBar.showError(
                context,
                title: errorTitle,
                message: errorMessage,
                onRetry: () => _login(),
              );
            }
          });
        }
      }
    }
  }

  // Méthode pour analyser les erreurs et retourner des messages personnalisés
  String _getErrorTitle(String error) {
    if (error.contains('Aucun compte trouvé')) {
      return 'Compte introuvable';
    } else if (error.contains('Mot de passe incorrect')) {
      return 'Mot de passe incorrect';
    } else if (error.contains('L\'email est obligatoire') || error.contains('Le mot de passe est obligatoire')) {
      return 'Champ obligatoire manquant';
    } else if (error.contains('Format d\'email invalide')) {
      return 'Email invalide';
    } else if (error.contains('Format de téléphone invalide')) {
      return 'Téléphone invalide';
    } else if (error.contains('Failed host lookup') || error.contains('SocketException')) {
      return 'Problème de connexion';
    } else if (error.contains('timeout') || error.contains('TimeoutException')) {
      return 'Connexion expirée';
    } else {
      return 'Erreur de connexion';
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('Aucun compte trouvé')) {
      return 'Aucun compte n\'existe avec ces identifiants. Vérifiez votre email ou téléphone.';
    } else if (error.contains('Mot de passe incorrect')) {
      return 'Le mot de passe saisi est incorrect. Vérifiez votre mot de passe.';
    } else if (error.contains('L\'email est obligatoire')) {
      return 'Veuillez saisir votre email.';
    } else if (error.contains('Le mot de passe est obligatoire')) {
      return 'Veuillez saisir votre mot de passe.';
    } else if (error.contains('Format d\'email invalide')) {
      return 'Veuillez saisir un email valide (ex: utilisateur@exemple.com).';
    } else if (error.contains('Format de téléphone invalide')) {
      return 'Format de téléphone invalide. Utilisez le format: 0711111111 ou +2250711111111';
    } else if (error.contains('Failed host lookup') || error.contains('SocketException')) {
      return 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
    } else if (error.contains('timeout') || error.contains('TimeoutException')) {
      return 'La connexion a expiré. Veuillez réessayer.';
    } else if (error.contains('Exception:')) {
      // Extraire le message d'erreur après "Exception: "
      final parts = error.split('Exception: ');
      if (parts.length > 1) {
        return parts[1].trim();
      }
    }
    return 'Une erreur inattendue s\'est produite. Veuillez réessayer.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getSurfaceColor(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2D2D2D),
              Color(0xFF4A1A1A),
              AppColors.primaryRed,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C34),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo ChapFood
                        Center(
                          child: Image.asset(
                            'assets/images/logo-chapfood.png',
                            width: 120,
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Titre de bienvenue
                        Text(
                          AppStrings.loginTitle,
                          style: AppTextStyles.loginTitle,
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 10),

                        // Sous-titre
                        Text(
                          AppStrings.loginSubtitle,
                          style: AppTextStyles.loginSubtitle,
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 10),

                        // Champ Email/Téléphone
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: AppTextStyles.inputText,
                          decoration: InputDecoration(
                            hintText: AppStrings.loginEmailHint,
                            hintStyle: AppTextStyles.inputHint,
                            prefixIcon: const Icon(
                              Icons.person,
                              color: AppColors.primaryRed,
                            ),
                            filled: true,
                            fillColor: AppColors.lightCardBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre email ou numéro de téléphone';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 8),

                        

                        const SizedBox(height: 20),

                        // Champ Mot de passe
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: AppTextStyles.inputText,
                          decoration: InputDecoration(
                            hintText: AppStrings.loginPasswordHint,
                            hintStyle: AppTextStyles.inputHint,
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
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: AppColors.lightCardBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre mot de passe';
                            }
                            if (value.length < 6) {
                              return 'Le mot de passe doit contenir au moins 6 caractères';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 30),

                        // Bouton de connexion
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: _isLoading
                                    ? null
                                    : AppColors.getButtonGradient(context),
                                color: _isLoading
                                    ? Colors.grey.withOpacity(0.3)
                                    : null,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(25),
                                ),
                              ),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    :                                         Text(
                                          AppStrings.loginButton,
                                          style: AppTextStyles.buttonText,
                                        ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Lien d'inscription
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SignupWizardScreen(),
                              ),
                            );
                          },
                          child: Text(
                            AppStrings.loginRegisterText,
                            style: AppTextStyles.loginRegister,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Footer
                        Text(
                          AppStrings.loginFooter,
                          style: AppTextStyles.loginFooter,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
