import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../widgets/animations/fade_in_animation.dart';
import '../../widgets/animations/scale_animation.dart';

class StatsSection extends StatelessWidget {
  final int totalDeliveries;
  final double totalRevenue;
  final double rating;
  final int todayDeliveries;
  final double todayRevenue;

  const StatsSection({
    super.key,
    required this.totalDeliveries,
    required this.totalRevenue,
    required this.rating,
    required this.todayDeliveries,
    required this.todayRevenue,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInUpAnimation(
      delay: const Duration(milliseconds: 900),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mes statistiques',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Statistiques principales
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Livraisons',
                    value: totalDeliveries.toString(),
                    subtitle: 'Total',
                    icon: Icons.local_shipping,
                    color: AppColors.accentBlue,
                    gradient: AppColors.blueGradient,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Revenus',
                    value: '${totalRevenue.toStringAsFixed(0)} FCFA',
                    subtitle: 'Total',
                    icon: Icons.attach_money,
                    color: AppColors.accentGreen,
                    gradient: AppColors.successGradient,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Statistiques du jour
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Aujourd\'hui',
                    value: todayDeliveries.toString(),
                    subtitle: 'Livraisons',
                    icon: Icons.today,
                    color: AppColors.accentOrange,
                    gradient: AppColors.orangeGradient,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Note',
                    value: rating.toStringAsFixed(1),
                    subtitle: 'Moyenne',
                    icon: Icons.star,
                    color: AppColors.accentPurple,
                    gradient: const LinearGradient(
                      colors: [AppColors.accentPurple, AppColors.primaryRed],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required LinearGradient gradient,
  }) {
    return ScaleAnimation(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

