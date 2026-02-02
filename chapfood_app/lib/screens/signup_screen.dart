import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../utils/text_styles.dart';
import '../services/auth_service.dart';
import 'services_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final fullName = _fullNameController.text.trim();
        final email = _emailController.text.trim();
        final phone = _phoneController.text.trim();
        final password = _passwordController.text;

        // Inscription avec email
        final result = await AuthService.signUpWithEmail(email, password, fullName, phone: phone);

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (result['success'] == true) {
            // Afficher un message de succès
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Compte créé avec succès !'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );

            // Navigation vers la page des services
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ServicesScreen()),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          // Afficher l'erreur
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la création du compte: ${e.toString()}'),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getSurfaceColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
                            width: 100,
                            height: 100,
                            fit: BoxFit.contain,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Titre
                        Text(
                          AppStrings.signupTitle,
                          style: AppTextStyles.loginTitle,
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 10),

                        // Sous-titre
                        Text(
                          AppStrings.signupSubtitle,
                          style: AppTextStyles.loginSubtitle,
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 30),

                        // Champ Nom complet
                        TextFormField(
                          controller: _fullNameController,
                          style: AppTextStyles.inputText,
                          decoration: InputDecoration(
                            hintText: AppStrings.signupFullNameHint,
                            hintStyle: AppTextStyles.inputHint,
                            prefixIcon: const Icon(
                              Icons.person_outline,
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
                              return 'Veuillez entrer votre nom complet';
                            }
                            if (value.length < 2) {
                              return 'Le nom doit contenir au moins 2 caractères';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Champ Email
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: AppTextStyles.inputText,
                          decoration: InputDecoration(
                            hintText: AppStrings.signupEmailHint,
                            hintStyle: AppTextStyles.inputHint,
                            prefixIcon: const Icon(
                              Icons.email_outlined,
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
                              return 'Veuillez entrer votre adresse email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Veuillez entrer une adresse email valide';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Champ Téléphone
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: AppTextStyles.inputText,
                          decoration: InputDecoration(
                            hintText: AppStrings.signupPhoneHint,
                            hintStyle: AppTextStyles.inputHint,
                            prefixIcon: const Icon(
                              Icons.phone_outlined,
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
                              return 'Veuillez entrer votre numéro de téléphone';
                            }
                            if (value.length < 8) {
                              return 'Le numéro de téléphone doit contenir au moins 8 chiffres';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Champ Mot de passe
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: AppTextStyles.inputText,
                          decoration: InputDecoration(
                            hintText: AppStrings.signupPasswordHint,
                            hintStyle: AppTextStyles.inputHint,
                            prefixIcon: const Icon(
                              Icons.lock_outline,
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
                              return 'Veuillez entrer un mot de passe';
                            }
                            if (value.length < 6) {
                              return 'Le mot de passe doit contenir au moins 6 caractères';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Champ Confirmation mot de passe
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          style: AppTextStyles.inputText,
                          decoration: InputDecoration(
                            hintText: AppStrings.signupConfirmPasswordHint,
                            hintStyle: AppTextStyles.inputHint,
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: AppColors.primaryRed,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppColors.primaryRed,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
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
                              return 'Veuillez confirmer votre mot de passe';
                            }
                            if (value != _passwordController.text) {
                              return 'Les mots de passe ne correspondent pas';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 30),

                        // Bouton d'inscription
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signup,
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
                                    : Text(
                                        AppStrings.signupButton,
                                        style: AppTextStyles.buttonText,
                                      ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Lien de connexion
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            AppStrings.signupLoginText,
                            style: AppTextStyles.loginRegister,
                          ),
                        ),

                        const SizedBox(height: 15),

                        // Footer
                        Text(
                          AppStrings.signupFooter,
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
