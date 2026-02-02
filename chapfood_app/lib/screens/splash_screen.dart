import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../utils/text_styles.dart';
import '../widgets/chapfood_logo.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animation principale
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Animation de la barre de progression
    _progressController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    // Démarrer les animations
    _animationController.forward();
    _progressController.forward();

    // Navigation vers l'onboarding après 3 secondes
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getSurfaceColor(context),
      body: Container(
        decoration: BoxDecoration(
              gradient: AppColors.getSplashGradient(context),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo ChapFood officiel
                      const ChapFoodLogoLarge(),
                      
                      const SizedBox(height: 30),
                      
                      // Barre de progression animée
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return Container(
                            height: 4,
                            width: MediaQuery.of(context).size.width * 0.5,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(Radius.circular(2)),
                              color: Colors.grey[300],
                            ),
                            child: Stack(
                              children: [
                                // Partie jaune (1/3)
                                Container(
                                  height: 4,
                                  width: MediaQuery.of(context).size.width * 0.5 * 0.33 * _progressAnimation.value,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryYellow,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(2),
                                      bottomLeft: Radius.circular(2),
                                    ),
                                  ),
                                ),
                                // Partie rouge (2/3)
                                Positioned(
                                  left: MediaQuery.of(context).size.width * 0.5 * 0.33,
                                  child: Container(
                                    height: 4,
                                    width: MediaQuery.of(context).size.width * 0.5 * 0.67 * _progressAnimation.value,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryRed,
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(2),
                                        bottomRight: Radius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Texte de description
                      Column(
                        children: [
                          Text(
                            AppStrings.splashSubtitle,
                            style: AppTextStyles.splashSubtitle,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            AppStrings.splashLocation,
                            style: AppTextStyles.splashLocation,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
