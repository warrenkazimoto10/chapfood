import 'package:flutter/material.dart';

class ChapFoodLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const ChapFoodLogo({
    super.key,
    this.size = 24,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo officiel avec image PNG
        Image.asset(
          'assets/images/logo-chapfood.png',
          width: 80, // Réduit de 150 à 80
          height: size,
          fit: BoxFit.contain,
        ),
        
        if (showText) ...[
          const SizedBox(width: 8),
          // Texte du logo
          Text(
            'ChapFood',
            style: TextStyle(
              color: Colors.black,
              fontSize: size * 0.8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}

class ChapFoodLogoLarge extends StatelessWidget {
  const ChapFoodLogoLarge({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo officiel avec image PNG - sans style
        Image.asset(
          'assets/images/logo-chapfood.png',
          width: 150,
          height: 150,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}