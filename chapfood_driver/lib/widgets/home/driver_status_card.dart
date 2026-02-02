import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../widgets/animations/fade_in_animation.dart';

class DriverStatusCard extends StatefulWidget {
  final bool isAvailable;
  final VoidCallback onToggle;
  final String driverName;
  final String vehicleType;
  final double? rating;

  const DriverStatusCard({
    super.key,
    required this.isAvailable,
    required this.onToggle,
    required this.driverName,
    required this.vehicleType,
    this.rating,
  });

  @override
  State<DriverStatusCard> createState() => _DriverStatusCardState();
}

class _DriverStatusCardState extends State<DriverStatusCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.isAvailable) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(DriverStatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAvailable != oldWidget.isAvailable) {
      if (widget.isAvailable) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeInUpAnimation(
      delay: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: widget.isAvailable 
              ? AppColors.primaryGradient
              : const LinearGradient(
                  colors: [Color(0xFF6B7280), Color(0xFF4B5563)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (widget.isAvailable ? AppColors.primaryRed : Colors.grey)
                  .withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: widget.onToggle,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    // Icône animée avec pulsation
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: widget.isAvailable ? _pulseAnimation.value : 1.0,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              widget.isAvailable ? Icons.delivery_dining : Icons.pause_circle,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(width: 20),
                    
                    // Informations du livreur
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.driverName,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.vehicleType,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          if (widget.rating != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.rating!.toStringAsFixed(1),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Statut et indicateur
                    Column(
                      children: [
                        Text(
                          widget.isAvailable ? 'En ligne' : 'Hors ligne',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: widget.isAvailable ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (widget.isAvailable ? Colors.green : Colors.red)
                                  .withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
