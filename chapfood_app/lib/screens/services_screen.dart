import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../utils/text_styles.dart';
import '../widgets/theme_toggle_button.dart';
import 'home_screen.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getSurfaceColor(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec logo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo ChapFood
                  Image.asset(
                    'assets/images/logo-chapfood.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                  // Icône mode sombre
                  const ThemeToggleButton(),
                ],
              ),

              const SizedBox(height: 20),

              // Titre et sous-titre
              Text(
                AppStrings.servicesTitle,
                style: AppTextStyles.servicesTitle.copyWith(
                  color: AppColors.getTextDark(context),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                AppStrings.servicesSubtitle,
                style: AppTextStyles.servicesSubtitle.copyWith(
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 30),

              // Liste des services
              Expanded(
                child: ListView(
                  children: [
                    _buildServiceCard(
                      title: AppStrings.restaurantTitle,
                      description: AppStrings.restaurantDescription,
                      icon: Icons.restaurant,
                      backgroundColor: AppColors.restaurantColor,
                      iconColor: AppColors.primaryRed,
                      borderColor: AppColors.primaryRed,
                      actionText: AppStrings.restaurantAction,
                      actionColor: AppColors.primaryRed,
                      rightIcon: Icons.access_time,
                      rightIconText: '24 H',
                      isAvailable: true,
                    ),

                    const SizedBox(height: 16),

                    _buildServiceCard(
                      title: AppStrings.truckFoodTitle,
                      description: AppStrings.truckFoodDescription,
                      icon: Icons.local_shipping,
                      backgroundColor: AppColors.truckFoodColor,
                      iconColor: AppColors.primaryOrange,
                      borderColor: AppColors.primaryOrange,
                      actionText: AppStrings.truckFoodAction,
                      actionColor: AppColors.primaryOrange,
                      rightIcon: Icons.local_shipping,
                      rightIconText: '',
                      statusText: AppStrings.truckFoodStatus,
                      isAvailable: false,
                    ),

                    const SizedBox(height: 16),

                    _buildServiceCard(
                      title: AppStrings.supermarketTitle,
                      description: AppStrings.supermarketDescription,
                      icon: Icons.shopping_cart,
                      backgroundColor: AppColors.supermarketColor,
                      iconColor: AppColors.successColor,
                      borderColor: AppColors.successColor,
                      actionText: '',
                      actionColor: AppColors.successColor,
                      rightIcon: Icons.access_time,
                      rightIconText: '24 H',
                      statusText: AppStrings.supermarketStatus,
                      isAvailable: false,
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

  Widget _buildServiceCard({
    required String title,
    required String description,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required Color borderColor,
    required String actionText,
    required Color actionColor,
    required IconData rightIcon,
    required String rightIconText,
    String? statusText,
    required bool isAvailable,
  }) {
    return InkWell(
      onTap: isAvailable
          ? () {
              if (title == 'Restaurant') {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Accès à $title - Fonctionnalité à venir'),
                  ),
                );
              }
            }
          : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: isAvailable ? [
            BoxShadow(
              color: borderColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icône principale
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Titre et statut
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child:                             Text(
                              title,
                              style: AppTextStyles.serviceCardTitle,
                            ),
                        ),
                        if (statusText != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: borderColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child:                               Text(
                                statusText,
                                style: AppTextStyles.serviceCardStatus,
                              ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Icône de droite
              if (rightIconText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        rightIcon,
                        color: iconColor,
                        size: 16,
                      ),
                      if (rightIconText.isNotEmpty)
                        Text(
                          rightIconText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: iconColor,
                          ),
                        ),
                    ],
                  ),
                ),
              
              // Indicateur de clic (flèche)
              if (isAvailable)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: borderColor,
                    size: 12,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            description,
            style: AppTextStyles.serviceCardDescription.copyWith(
              color: AppColors.getTextDark(context).withOpacity(0.8),
            ),
          ),

          const SizedBox(height: 16),

          // Indicateur d'action (plus de bouton cliquable)
          if (actionText.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isAvailable
                      ? actionColor.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isAvailable
                        ? actionColor.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  actionText,
                  style: AppTextStyles.serviceCardAction.copyWith(
                    color: isAvailable ? actionColor : Colors.grey,
                  ),
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}
