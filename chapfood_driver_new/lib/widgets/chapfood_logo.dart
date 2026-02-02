import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class ChapFoodLogoLarge extends StatelessWidget {
  const ChapFoodLogoLarge({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.delivery_dining,
          size: 80,
          color: AppColors.primaryRed,
        ),
        const SizedBox(height: 8),
        Text(
          'ChapFood',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryRed,
          ),
        ),
      ],
    );
  }
}
