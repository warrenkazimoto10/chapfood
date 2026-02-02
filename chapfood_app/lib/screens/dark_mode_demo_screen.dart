import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../providers/theme_provider.dart';
import '../main.dart';

class DarkModeDemoScreen extends StatelessWidget {
  const DarkModeDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getSurfaceColor(context),
      appBar: AppBar(
        title: Text(
          'Démonstration Mode Sombre',
          style: TextStyle(color: AppColors.getTextColor(context)),
        ),
        backgroundColor: AppColors.getCardColor(context),
        foregroundColor: AppColors.getTextColor(context),
        elevation: 0,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.themeIcon,
                  color: AppColors.getTextColor(context),
                ),
                onPressed: themeProvider.toggleTheme,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre principal
            Text(
              'Test du Mode Sombre',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.getPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 20),
            
            // Couleurs principales
            _buildColorSection(
              context,
              'Couleurs Principales',
              [
                _buildColorItem(context, 'Primaire', AppColors.getPrimaryColor(context)),
                _buildColorItem(context, 'Secondaire', AppColors.getSecondaryColor(context)),
                _buildColorItem(context, 'Accent', AppColors.getAccentColor(context)),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Couleurs de fond
            _buildColorSection(
              context,
              'Couleurs de Fond',
              [
                _buildColorItem(context, 'Surface', AppColors.getSurfaceColor(context)),
                _buildColorItem(context, 'Carte', AppColors.getCardColor(context)),
                _buildColorItem(context, 'Fond Léger', AppColors.getLightCardBackground(context)),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Couleurs de texte
            _buildColorSection(
              context,
              'Couleurs de Texte',
              [
                _buildColorItem(context, 'Texte Principal', AppColors.getTextColor(context)),
                _buildColorItem(context, 'Texte Secondaire', AppColors.getSecondaryTextColor(context)),
                _buildColorItem(context, 'Texte Sombre', AppColors.getTextDark(context)),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Gradients
            _buildGradientSection(context),
            
            const SizedBox(height: 20),
            
            // Boutons de test
            _buildButtonSection(context),
            
            const SizedBox(height: 20),
            
            // Cartes de test
            _buildCardSection(context),
            
            const SizedBox(height: 20),
            
            // Champ de texte
            _buildTextFieldSection(context),
            
            const SizedBox(height: 20),
            
            // Informations sur le thème actuel
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.getLightCardBackground(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.getBorderColor(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thème Actuel',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mode: ${themeProvider.themeName}',
                        style: TextStyle(
                          color: AppColors.getSecondaryTextColor(context),
                        ),
                      ),
                      Text(
                        'Icône: ${themeProvider.themeIcon}',
                        style: TextStyle(
                          color: AppColors.getSecondaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildColorSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextColor(context),
          ),
        ),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }
  
  Widget _buildColorItem(BuildContext context, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: AppColors.getTextColor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGradientSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gradients',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextColor(context),
          ),
        ),
        const SizedBox(height: 12),
        
        // Gradient bouton
        Container(
          height: 50,
          decoration: BoxDecoration(
            gradient: AppColors.getButtonGradient(context),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(
              'Gradient Bouton',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Gradient séparateur
        Container(
          height: 50,
          decoration: BoxDecoration(
            gradient: AppColors.getSeparatorGradient(context),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(
              'Gradient Séparateur',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildButtonSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Boutons',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextColor(context),
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.getPrimaryColor(context),
                  foregroundColor: Colors.white,
                ),
                child: Text('Bouton Primaire'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.getPrimaryColor(context),
                  side: BorderSide(color: AppColors.getPrimaryColor(context)),
                ),
                child: Text('Bouton Secondaire'),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildCardSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cartes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextColor(context),
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.getCardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exemple de Carte',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextColor(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ceci est un exemple de carte avec des couleurs adaptatives.',
                style: TextStyle(
                  color: AppColors.getSecondaryTextColor(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildTextFieldSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Champ de Texte',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextColor(context),
          ),
        ),
        const SizedBox(height: 12),
        
        TextField(
          decoration: InputDecoration(
            hintText: 'Tapez quelque chose...',
            hintStyle: TextStyle(color: AppColors.getSecondaryTextColor(context)),
            filled: true,
            fillColor: AppColors.getLightCardBackground(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.getBorderColor(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.getPrimaryColor(context)),
            ),
          ),
        ),
      ],
    );
  }
}
