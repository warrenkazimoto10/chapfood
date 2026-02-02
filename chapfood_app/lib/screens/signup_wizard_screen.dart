import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../constants/app_colors.dart';
import '../utils/text_styles.dart';
import '../services/auth_service.dart';
import '../widgets/animated_success_dialog.dart';
import 'services_screen.dart';
import 'map_selection_screen.dart';
import '../services/address_service.dart';
import '../widgets/custom_snackbar.dart';

class SignupWizardScreen extends StatefulWidget {
  const SignupWizardScreen({super.key});

  @override
  State<SignupWizardScreen> createState() => _SignupWizardScreenState();
}

class _SignupWizardScreenState extends State<SignupWizardScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentStep = 0;
  final int _totalSteps = 5; // Ajout de l'étape adresse

  // Contrôleurs pour les champs
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Variables d'état
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _acceptTerms = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _animationController.reset();
      _animationController.forward();
    }
  }

  bool _validateCurrentStep({bool showErrors = false}) {
    switch (_currentStep) {
      case 0: // Informations personnelles
        final nameValid =
            _fullNameController.text.trim().isNotEmpty &&
            _fullNameController.text.trim().length >= 2;
        if (!nameValid && showErrors) {
          _showValidationError(
            'Le nom complet doit contenir au moins 2 caractères',
          );
        }
        return nameValid;

      case 1: // Contact
        final email = _emailController.text.trim();
        final phone = _phoneController.text.trim();

        final emailValid =
            email.isNotEmpty &&
            RegExp(
              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
            ).hasMatch(email);

        if (!emailValid) {
          if (showErrors) {
            _showValidationError('Veuillez saisir un email valide');
          }
          return false;
        }

        if (phone.isNotEmpty) {
          final cleanPhone = phone.replaceAll(' ', '').replaceAll('-', '');
          final localRegex = RegExp(
            r'^(07|05|01)[0-9]{8}$',
          ); // Format local: 07xxxxxxxx
          final internationalRegex = RegExp(
            r'^(\+225|225)(07|05|01)[0-9]{8}$',
          ); // Format international
          final phoneValid =
              localRegex.hasMatch(cleanPhone) ||
              internationalRegex.hasMatch(cleanPhone);

          if (!phoneValid) {
            if (showErrors) {
              _showValidationError(
                'Format de téléphone invalide (ex: 0711111111 ou +2250711111111)',
              );
            }
            return false;
          }
        }
        return true;

      case 2: // Adresse (optionnelle)
        return true; // Toujours valide car optionnelle

      case 3: // Sécurité
        final password = _passwordController.text;
        final confirmPassword = _confirmPasswordController.text;

        if (password.isEmpty) {
          if (showErrors) {
            _showValidationError('Le mot de passe est obligatoire');
          }
          return false;
        }
        if (password.length < 6) {
          if (showErrors) {
            _showValidationError(
              'Le mot de passe doit contenir au moins 6 caractères',
            );
          }
          return false;
        }
        if (password != confirmPassword) {
          if (showErrors) {
            _showValidationError('Les mots de passe ne correspondent pas');
          }
          return false;
        }
        return true;

      case 4: // Conditions
        if (!_acceptTerms) {
          if (showErrors) {
            _showValidationError(
              'Vous devez accepter les conditions d\'utilisation',
            );
          }
        }
        return _acceptTerms;

      default:
        return false;
    }
  }

  void _showValidationError(String message) {
    // Utiliser addPostFrameCallback pour éviter l'erreur "showSnackBar during build"
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        CustomSnackBar.showError(
          context,
          title: 'Erreur de validation',
          message: message,
        );
      }
    });
  }

  // Méthodes pour analyser les erreurs d'inscription
  String _getSignupErrorTitle(String error) {
    if (error.contains('Un compte avec cet email existe déjà')) {
      return 'Email déjà utilisé';
    } else if (error.contains(
      'Un compte avec ce numéro de téléphone existe déjà',
    )) {
      return 'Téléphone déjà utilisé';
    } else if (error.contains('Format d\'email invalide')) {
      return 'Email invalide';
    } else if (error.contains('Format de téléphone invalide')) {
      return 'Téléphone invalide';
    } else if (error.contains('Le mot de passe doit contenir au moins')) {
      return 'Mot de passe trop court';
    } else if (error.contains('Failed host lookup') ||
        error.contains('SocketException')) {
      return 'Problème de connexion';
    } else if (error.contains('timeout') ||
        error.contains('TimeoutException')) {
      return 'Connexion expirée';
    } else {
      return 'Erreur d\'inscription';
    }
  }

  String _getSignupErrorMessage(String error) {
    if (error.contains('Un compte avec cet email existe déjà')) {
      return 'Un compte existe déjà avec cet email. Utilisez un autre email ou connectez-vous.';
    } else if (error.contains(
      'Un compte avec ce numéro de téléphone existe déjà',
    )) {
      return 'Un compte existe déjà avec ce numéro de téléphone. Utilisez un autre numéro.';
    } else if (error.contains('Format d\'email invalide')) {
      return 'Veuillez saisir un email valide (ex: utilisateur@exemple.com).';
    } else if (error.contains('Format de téléphone invalide')) {
      return 'Format de téléphone invalide. Utilisez le format: 0711111111 ou +2250711111111';
    } else if (error.contains('Le mot de passe doit contenir au moins')) {
      return 'Le mot de passe doit contenir au moins 6 caractères.';
    } else if (error.contains('Failed host lookup') ||
        error.contains('SocketException')) {
      return 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
    } else if (error.contains('timeout') ||
        error.contains('TimeoutException')) {
      return 'La connexion a expiré. Veuillez réessayer.';
    } else if (error.contains('Exception:')) {
      // Extraire le message d'erreur après "Exception: "
      final parts = error.split('Exception: ');
      if (parts.length > 1) {
        return parts[1].trim();
      }
    }
    return 'Une erreur inattendue s\'est produite lors de l\'inscription. Veuillez réessayer.';
  }

  Future<void> _openMapSelection() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapSelectionScreen(
          initialAddress: _addressController.text,
          onAddressSelected: (address, latitude, longitude) {
            // Mettre à jour le champ adresse avec l'adresse sélectionnée
            setState(() {
              _addressController.text = address;
            });
          },
        ),
      ),
    );
  }

  Future<void> _completeSignup() async {
    if (!_validateCurrentStep()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final fullName = _fullNameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();
      final address = _addressController.text.trim();
      final password = _passwordController.text;

      final result = await AuthService.signUpWithEmail(
        email,
        password,
        fullName,
        phone: phone,
        address: address,
      );

      // Sauvegarder l'adresse dans le service d'adresses si elle n'est pas vide
      if (address.isNotEmpty) {
        await AddressService.savePreferredAddress(address);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success'] == true) {
          // Message de succès personnalisé
          final user = result['user'];
          final userName = user?.fullName ?? 'Utilisateur';

          // Utiliser addPostFrameCallback pour éviter l'erreur "showSnackBar during build"
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              CustomSnackBar.showSuccess(
                context,
                title: 'Inscription réussie !',
                message:
                    'Bienvenue $userName, votre compte a été créé avec succès',
              );
            }
          });

          // Animation de succès après un délai
          Future.delayed(const Duration(milliseconds: 1500), () {
            _showSuccessAnimation();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Analyser l'erreur et afficher un message personnalisé
        String errorMessage = _getSignupErrorMessage(e.toString());
        String errorTitle = _getSignupErrorTitle(e.toString());

        // Utiliser addPostFrameCallback pour éviter l'erreur "showSnackBar during build"
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            CustomSnackBar.showError(
              context,
              title: errorTitle,
              message: errorMessage,
              onRetry: () => _completeSignup(),
            );
          }
        });
      }
    }
  }

  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AnimatedSuccessDialog(
        userName: _fullNameController.text.split(' ').first,
        onContinue: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ServicesScreen()),
          );
        },
      ),
    );
  }

  // Méthode pour créer des boutons uniformes
  Widget _buildButton({
    required String text,
    required VoidCallback? onPressed,
    bool isSecondary = false,
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: isSecondary
                ? const BorderSide(color: Colors.white)
                : BorderSide.none,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: !isSecondary && onPressed != null
                ? AppColors.getButtonGradient(context)
                : null,
            color: isSecondary
                ? Colors.transparent
                : (onPressed == null ? Colors.grey.withOpacity(0.3) : null),
            borderRadius: const BorderRadius.all(Radius.circular(25)),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    text,
                    style: TextStyle(
                      color: isSecondary ? Colors.white : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // Méthode pour afficher les messages d'erreur
  String? _getFieldError(String field, String value) {
    switch (field) {
      case 'fullName':
        if (value.isEmpty) return 'Le nom est requis';
        if (value.length < 2)
          return 'Le nom doit contenir au moins 2 caractères';
        break;
      case 'email':
        if (value.isEmpty) return 'L\'email est requis';
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Format d\'email invalide';
        }
        break;
      case 'phone':
        if (value.isEmpty) return 'Le téléphone est requis';
        if (value.length < 8)
          return 'Le téléphone doit contenir au moins 8 chiffres';
        break;
      case 'password':
        if (value.isEmpty) return 'Le mot de passe est requis';
        if (value.length < 6)
          return 'Le mot de passe doit contenir au moins 6 caractères';
        break;
      case 'confirmPassword':
        if (value.isEmpty) return 'Confirmez votre mot de passe';
        if (value != _passwordController.text)
          return 'Les mots de passe ne correspondent pas';
        break;
    }
    return null;
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
          child: Column(
            children: [
              // Header personnalisé avec bouton retour
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    Text(
                      'Étape ${_currentStep + 1}/$_totalSteps',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // Équilibre visuel
                  ],
                ),
              ),
              // Indicateur de progression
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: List.generate(_totalSteps, (index) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 4,
                        decoration: BoxDecoration(
                          color: index <= _currentStep
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Contenu du wizard
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                    });
                    _animationController.reset();
                    _animationController.forward();
                  },
                  children: [
                    _buildPersonalInfoStep(),
                    _buildContactStep(),
                    _buildAddressStep(),
                    _buildSecurityStep(),
                    _buildTermsStep(),
                  ],
                ),
              ),

              // Boutons de navigation
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    if (_currentStep > 0) ...[
                      Expanded(
                        child: _buildButton(
                          text: 'Précédent',
                          onPressed: _previousStep,
                          isSecondary: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: _buildButton(
                        text: _currentStep == _totalSteps - 1
                            ? 'Créer mon compte'
                            : 'Suivant',
                        onPressed: _isLoading
                            ? null
                            : () {
                                if (_validateCurrentStep(showErrors: true)) {
                                  if (_currentStep == _totalSteps - 1) {
                                    _completeSignup();
                                  } else {
                                    _nextStep();
                                  }
                                }
                              },
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_outline, size: 80, color: Colors.white),
              const SizedBox(height: 30),
              Text(
                'Informations personnelles',
                style: AppTextStyles.loginTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Commençons par votre nom',
                style: AppTextStyles.loginSubtitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextFormField(
                controller: _fullNameController,
                style: AppTextStyles.inputText,
                onChanged: (value) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Votre nom complet',
                  hintStyle: AppTextStyles.inputHint,
                  prefixIcon: Icon(
                    Icons.person,
                    color: AppColors.getPrimaryColor(context),
                  ),
                  filled: true,
                  fillColor: AppColors.getLightCardBackground(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  errorText: _getFieldError(
                    'fullName',
                    _fullNameController.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactStep() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.contact_mail_outlined,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 30),
              Text(
                'Informations de contact',
                style: AppTextStyles.loginTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Comment pouvons-nous vous contacter ?',
                style: AppTextStyles.loginSubtitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: AppTextStyles.inputText,
                onChanged: (value) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Votre adresse email',
                  hintStyle: AppTextStyles.inputHint,
                  prefixIcon: Icon(
                    Icons.email,
                    color: AppColors.getPrimaryColor(context),
                  ),
                  filled: true,
                  fillColor: AppColors.getLightCardBackground(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  errorText: _getFieldError('email', _emailController.text),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: AppTextStyles.inputText,
                onChanged: (value) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Votre numéro de téléphone',
                  hintStyle: AppTextStyles.inputHint,
                  prefixIcon: Icon(
                    Icons.phone,
                    color: AppColors.getPrimaryColor(context),
                  ),
                  filled: true,
                  fillColor: AppColors.getLightCardBackground(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  errorText: _getFieldError('phone', _phoneController.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressStep() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 30),
              Text(
                'Adresse de livraison',
                style: AppTextStyles.loginTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Optionnel - Vous pourrez l\'ajouter plus tard',
                style: AppTextStyles.loginSubtitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                style: AppTextStyles.inputText,
                onChanged: (value) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Votre adresse complète (optionnel)',
                  hintStyle: AppTextStyles.inputHint,
                  prefixIcon: Icon(
                    Icons.home,
                    color: AppColors.getPrimaryColor(context),
                  ),
                  filled: true,
                  fillColor: AppColors.getLightCardBackground(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Bouton pour sélectionner sur carte
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openMapSelection(),
                  icon: const Icon(Icons.map, size: 18),
                  label: const Text('📍 Sélectionner sur carte'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.getSecondaryColor(context),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Vous pouvez ignorer cette étape et ajouter votre adresse lors de votre première commande.',
                        style: TextStyle(color: Colors.blue[200], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityStep() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.security_outlined,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 30),
              Text(
                'Sécurité de votre compte',
                style: AppTextStyles.loginTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Choisissez un mot de passe sécurisé',
                style: AppTextStyles.loginSubtitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                style: AppTextStyles.inputText,
                onChanged: (value) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Mot de passe (min. 6 caractères)',
                  hintStyle: AppTextStyles.inputHint,
                  prefixIcon: Icon(
                    Icons.lock,
                    color: AppColors.getPrimaryColor(context),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.getPrimaryColor(context),
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: AppColors.getLightCardBackground(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  errorText: _getFieldError(
                    'password',
                    _passwordController.text,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                style: AppTextStyles.inputText,
                onChanged: (value) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Confirmer le mot de passe',
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
                      color: AppColors.getPrimaryColor(context),
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: AppColors.getLightCardBackground(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  errorText: _getFieldError(
                    'confirmPassword',
                    _confirmPasswordController.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsStep() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 30),
              Text(
                'Conditions d\'utilisation',
                style: AppTextStyles.loginTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Dernière étape avant de commencer',
                style: AppTextStyles.loginSubtitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.lightCardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'En créant un compte ChapFood, vous acceptez :',
                      style: AppTextStyles.inputText,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      '• Nos conditions d\'utilisation\n'
                      '• Notre politique de confidentialité\n'
                      '• De recevoir des notifications sur vos commandes\n'
                      '• De partager vos données de livraison avec nos livreurs',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Checkbox(
                    value: _acceptTerms,
                    onChanged: (value) {
                      setState(() {
                        _acceptTerms = value ?? false;
                      });
                    },
                    activeColor: AppColors.primaryRed,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _acceptTerms = !_acceptTerms;
                        });
                      },
                      child: Text(
                        'J\'accepte les conditions d\'utilisation',
                        style: AppTextStyles.inputText,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
