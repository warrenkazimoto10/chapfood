import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class DriverStatusToggle extends StatelessWidget {
  final bool isAvailable;
  final Function(bool) onToggle;

  const DriverStatusToggle({
    super.key,
    required this.isAvailable,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Icône de statut
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isAvailable 
                  ? AppColors.successColor.withOpacity(0.1)
                  : AppColors.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isAvailable ? Icons.check_circle : Icons.cancel,
              color: isAvailable ? AppColors.successColor : AppColors.errorColor,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Texte de statut
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAvailable ? 'Disponible' : 'Indisponible',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isAvailable ? AppColors.successColor : AppColors.errorColor,
                  ),
                ),
                Text(
                  isAvailable 
                      ? 'Vous recevez des notifications'
                      : 'Aucune notification',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Toggle switch
          Switch(
            value: isAvailable,
            onChanged: onToggle,
            activeColor: AppColors.successColor,
            inactiveThumbColor: AppColors.errorColor,
            activeTrackColor: AppColors.successColor.withOpacity(0.3),
            inactiveTrackColor: AppColors.errorColor.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}