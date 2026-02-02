import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget pour afficher les instructions de navigation style Uber/Glovo
class NavigationCard extends StatelessWidget {
  final String instruction;
  final double distanceToNext; // en mètres
  final IconData? icon;

  const NavigationCard({
    super.key,
    required this.instruction,
    required this.distanceToNext,
    this.icon,
  });

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  IconData _getIconFromInstruction(String instruction) {
    final lower = instruction.toLowerCase();
    if (lower.contains('gauche')) return Icons.turn_left;
    if (lower.contains('droite')) return Icons.turn_right;
    if (lower.contains('tout droit') || lower.contains('continuer')) {
      return Icons.straight;
    }
    if (lower.contains('u-turn') || lower.contains('demi-tour')) {
      return Icons.u_turn_left;
    }
    return Icons.navigation;
  }

  @override
  Widget build(BuildContext context) {
    final displayIcon = icon ?? _getIconFromInstruction(instruction);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(displayIcon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instruction.replaceAll(
                    RegExp(r'<[^>]*>'),
                    '',
                  ), // Enlever les balises HTML
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dans ${_formatDistance(distanceToNext)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
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
