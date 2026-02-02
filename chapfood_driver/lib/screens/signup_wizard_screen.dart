import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';
import '../services/auth_service.dart';

class SignupWizardScreen extends StatefulWidget {
  const SignupWizardScreen({super.key});

  @override
  State<SignupWizardScreen> createState() => _SignupWizardScreenState();
}

class _SignupWizardScreenState extends State<SignupWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Contrôleurs pour les champs
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Données du formulaire
  String _phoneNumber = '';
  String _email = '';
  String _firstName = '';
  String _lastName = '';
  String _password = '';
  String _confirmPassword = '';
  String _vehicleType = '';

  final List<String> _vehicleTypes = ['Moto', 'Vélo', 'Voiture', 'À pied'];

  @override
  void dispose() {
    _pageController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Récupérer le numéro de téléphone depuis les paramètres de l'URL
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uri = Uri.parse(GoRouterState.of(context).uri.toString());
      final phoneParam = uri.queryParameters['phone'];
      if (phoneParam != null && phoneParam.isNotEmpty) {
        setState(() {
          _phoneNumber = phoneParam;
          _phoneController.text = phoneParam; // Pré-remplir le contrôleur
        });
      }
    });
  }

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Numéro de téléphone',
      'subtitle': 'Entrez votre numéro de téléphone',
      'icon': Icons.phone,
    },
    {
      'title': 'Adresse email',
      'subtitle': 'Entrez votre adresse email',
      'icon': Icons.email,
    },
    {
      'title': 'Informations personnelles',
      'subtitle': 'Votre nom et prénom',
      'icon': Icons.person,
    },
    {
      'title': 'Type de véhicule',
      'subtitle': 'Choisissez votre moyen de transport',
      'icon': Icons.directions_car,
    },
  ];

  Future<void> _nextStep() async {
    // Vérifier les informations avant de passer à l'étape suivante
    if (!_canProceed()) {
      return;
    }

    // Vérifier si les informations existent déjà dans la base de données
    bool canProceedToNextStep = true;

    if (_currentStep == 0) {
      // Vérifier si le numéro de téléphone existe déjà
      canProceedToNextStep = await _checkPhoneExists();
    } else if (_currentStep == 1) {
      // Vérifier si l'email existe déjà
      canProceedToNextStep = await _checkEmailExists();
    }

    if (!canProceedToNextStep) {
      return; // Ne pas passer à l'étape suivante si les informations existent
    }

    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeSignup();
    }
  }

  Future<bool> _checkPhoneExists() async {
    if (_phoneNumber.trim().isEmpty) {
      return false;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Supabase.instance.client
          .from('drivers')
          .select('id')
          .eq('phone', _phoneNumber.trim())
          .maybeSingle();

      if (response != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ce numéro de téléphone est déjà utilisé'),
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return false;
      }

      setState(() {
        _isLoading = false;
      });
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la vérification: ${e.toString()}'),
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
      return false;
    }
  }

  Future<bool> _checkEmailExists() async {
    if (_email.trim().isEmpty || !_email.contains('@')) {
      return false;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Vérifier dans la table drivers
      final driverResponse = await Supabase.instance.client
          .from('drivers')
          .select('id')
          .eq('email', _email.trim())
          .maybeSingle();

      if (driverResponse != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cet email est déjà utilisé')),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return false;
      }

      // Vérifier aussi dans auth.users (Supabase Auth) via la table users
      try {
        final userResponse = await Supabase.instance.client
            .from('users')
            .select('id')
            .eq('email', _email.trim())
            .maybeSingle();

        if (userResponse != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cet email est déjà utilisé')),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return false;
        }
      } catch (e) {
        // Si la table users n'existe pas ou erreur, on ignore cette vérification
        print('⚠️ Impossible de vérifier dans users: $e');
      }

      setState(() {
        _isLoading = false;
      });
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la vérification: ${e.toString()}'),
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
      return false;
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeSignup() async {
    // Récupérer les valeurs depuis les contrôleurs pour s'assurer qu'elles sont à jour
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validation du mot de passe
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un mot de passe')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le mot de passe doit contenir au moins 6 caractères'),
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les mots de passe ne correspondent pas')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.registerDriver(
        '$_firstName $_lastName',
        _email,
        _phoneNumber,
        password, // Utiliser la valeur du contrôleur
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Inscription réussie !')));
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _phoneNumber.trim().isNotEmpty && _phoneNumber.length >= 8;
      case 1:
        return _email.trim().isNotEmpty && _email.contains('@');
      case 2:
        return _firstName.trim().isNotEmpty && _lastName.trim().isNotEmpty;
      case 3:
        return _vehicleType.isNotEmpty;
      default:
        return false;
    }
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_steps.length, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;

          return Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive || isCompleted
                      ? AppColors.primaryRed
                      : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : Text(
                          '${index + 1}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
              if (index < _steps.length - 1)
                Container(
                  width: 40,
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: isCompleted ? AppColors.primaryRed : Colors.grey[300],
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    return Expanded(
      child: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentStep = index;
          });
        },
        children: [
          _buildPhoneStep(),
          _buildEmailStep(),
          _buildPersonalInfoStep(),
          _buildVehicleStep(),
        ],
      ),
    );
  }

  Widget _buildPhoneStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_steps[0]['icon'], size: 60, color: AppColors.primaryRed),
            const SizedBox(height: 24),
            Text(
              _steps[0]['title'],
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _steps[0]['subtitle'],
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE6E6E8)),
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
                  hintText: 'Ex: 0707559999',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
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
                onChanged: (value) {
                  setState(() {
                    _phoneNumber = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_steps[1]['icon'], size: 60, color: AppColors.primaryRed),
            const SizedBox(height: 24),
            Text(
              _steps[1]['title'],
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _steps[1]['subtitle'],
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE6E6E8)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Ex: livreur@chapfood.com',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                  prefixIcon: const Icon(
                    Icons.email,
                    color: AppColors.primaryRed,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _email = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_steps[2]['icon'], size: 60, color: AppColors.primaryRed),
            const SizedBox(height: 24),
            Text(
              _steps[2]['title'],
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _steps[2]['subtitle'],
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            // Prénom
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE6E6E8)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                decoration: InputDecoration(
                  hintText: 'Prénom',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                  prefixIcon: const Icon(
                    Icons.person,
                    color: AppColors.primaryRed,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _firstName = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            // Nom
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE6E6E8)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                decoration: InputDecoration(
                  hintText: 'Nom',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: AppColors.primaryRed,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _lastName = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            // Mot de passe
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE6E6E8)),
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
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Mot de passe',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                  prefixIcon: const Icon(
                    Icons.lock,
                    color: AppColors.primaryRed,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _password = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            // Confirmation mot de passe
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE6E6E8)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Confirmer le mot de passe',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppColors.primaryRed,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _confirmPassword = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_steps[3]['icon'], size: 60, color: AppColors.primaryRed),
            const SizedBox(height: 24),
            Text(
              _steps[3]['title'],
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _steps[3]['subtitle'],
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            // Sélection du véhicule
            ..._vehicleTypes.map((vehicle) {
              final isSelected = _vehicleType == vehicle;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _vehicleType = vehicle;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryRed.withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryRed
                            : const Color(0xFFE6E6E8),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getVehicleIcon(vehicle),
                          color: isSelected
                              ? AppColors.primaryRed
                              : Colors.grey[600],
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          vehicle,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primaryRed
                                : Colors.black,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: AppColors.primaryRed,
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  IconData _getVehicleIcon(String vehicle) {
    switch (vehicle.toLowerCase()) {
      case 'moto':
        return Icons.motorcycle;
      case 'vélo':
      case 'velo':
        return Icons.pedal_bike;
      case 'voiture':
        return Icons.directions_car;
      case 'à pied':
      case 'a pied':
        return Icons.directions_walk;
      default:
        return Icons.local_shipping;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (_currentStep > 0) {
              _previousStep();
            } else {
              context.go('/login');
            }
          },
        ),
        title: Text(
          'Inscription',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          _buildStepContent(),
          // Boutons de navigation
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        side: const BorderSide(color: Color(0xFFE6E6E8)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Précédent',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  flex: _currentStep == 0 ? 1 : 1,
                  child: ElevatedButton(
                    onPressed: _canProceed() && !_isLoading ? _nextStep : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                            _currentStep == _steps.length - 1
                                ? 'Valider l\'inscription'
                                : 'Suivant',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
