import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Card de statut pour le header du dashboard
class StatusCard extends StatelessWidget {
  final bool isAvailable;
  final bool isOnDelivery;
  final ValueChanged<bool>? onToggle;
  final bool canToggle;

  const StatusCard({
    super.key,
    required this.isAvailable,
    this.isOnDelivery = false,
    this.onToggle,
    this.canToggle = true,
  });

  @override
  Widget build(BuildContext context) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (isOnDelivery) {
      statusText = 'En livraison';
      statusColor = Colors.blue;
      statusIcon = Icons.delivery_dining;
    } else if (isAvailable) {
      statusText = 'Disponible';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else {
      statusText = 'Indisponible';
      statusColor = Colors.orange;
      statusIcon = Icons.pause_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          if (canToggle && !isOnDelivery && onToggle != null) ...[
            const SizedBox(width: 8),
            Switch(
              value: isAvailable,
              onChanged: onToggle,
              activeColor: Colors.green,
            ),
          ],
        ],
      ),
    );
  }
}
