import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ColorDemoWidget extends StatelessWidget {
  const ColorDemoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Démonstration des couleurs adaptatives',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextColor(context),
            ),
          ),
          const SizedBox(height: 20),
          
          // Couleurs principales
          _buildColorRow(
            context,
            'Couleur primaire',
            AppColors.getPrimaryColor(context),
            'Rouge en mode clair, Jaune en mode sombre',
          ),
          
          _buildColorRow(
            context,
            'Couleur secondaire',
            AppColors.getSecondaryColor(context),
            'Jaune en mode clair, Rouge en mode sombre',
          ),
          
          // Gradients
          const SizedBox(height: 20),
          Text(
            'Gradients adaptatifs',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextColor(context),
            ),
          ),
          const SizedBox(height: 10),
          
          Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: AppColors.getButtonGradient(context),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: Text(
                'Gradient bouton',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 10),
          Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: AppColors.getSeparatorGradient(context),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: Text(
                'Gradient séparateur',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Couleurs de fond
          const SizedBox(height: 20),
          Text(
            'Couleurs de fond',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextColor(context),
            ),
          ),
          const SizedBox(height: 10),
          
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.getCardColor(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.getBorderColor(context)),
            ),
            child: Center(
              child: Text(
                'Carte adaptative',
                style: TextStyle(
                  color: AppColors.getTextColor(context),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 10),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.getLightCardBackground(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'Fond de carte léger',
                style: TextStyle(
                  color: AppColors.getTextColor(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildColorRow(BuildContext context, String label, Color color, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.getBorderColor(context)),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextColor(context),
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getSecondaryTextColor(context),
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
