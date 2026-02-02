import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../widgets/animations/fade_in_animation.dart';
import '../../widgets/animations/scale_animation.dart';

class EnhancedMapSection extends StatelessWidget {
  final Widget mapWidget;
  final VoidCallback? onLocationTap;
  final bool isDrivingMode;
  final String? routeInfo;

  const EnhancedMapSection({
    super.key,
    required this.mapWidget,
    this.onLocationTap,
    this.isDrivingMode = false,
    this.routeInfo,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInUpAnimation(
      delay: const Duration(milliseconds: 500),
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Carte principale
              SizedBox(
                height: 300,
                child: mapWidget,
              ),
              
              // Overlay avec gradient en haut
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              
              // Overlay avec gradient en bas
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              
              // Bouton de localisation flottant
              Positioned(
                top: 20,
                right: 20,
                child: ScaleAnimation(
                  child: _buildFloatingLocationButton(),
                ),
              ),
              
              // Informations de route (si en mode conduite)
              if (isDrivingMode && routeInfo != null)
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: _buildRouteInfoCard(routeInfo!),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingLocationButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryRed,
        shape: BoxShape.circle,
        boxShadow: AppColors.primaryShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: onLocationTap,
          child: Container(
            width: 50,
            height: 50,
            child: const Icon(
              Icons.my_location,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteInfoCard(String routeInfo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryRed.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions,
              color: AppColors.primaryRed,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              routeInfo,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

