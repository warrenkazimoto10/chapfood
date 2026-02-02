import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../models/order_model.dart';

class DeliveryPanel extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onCallCustomer;
  final VoidCallback? onCompleteDelivery;
  final double? distance;
  final int? estimatedTime;

  const DeliveryPanel({
    super.key,
    required this.order,
    this.onCallCustomer,
    this.onCompleteDelivery,
    this.distance,
    this.estimatedTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header avec statut
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delivery_dining,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Livraison en cours',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryRed,
                        ),
                      ),
                      Text(
                        'Commande #${order.id}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Bouton d'appel
                IconButton(
                  onPressed: _callCustomer,
                  icon: const Icon(
                    Icons.phone,
                    color: AppColors.primaryRed,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primaryRed.withOpacity(0.1),
                    shape: const CircleBorder(),
                  ),
                ),
              ],
            ),
          ),

          // Informations de livraison
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Adresse de livraison
                _buildInfoRow(
                  icon: Icons.location_on,
                  title: 'Adresse de livraison',
                  content: order.deliveryAddress ?? 'Adresse non spécifiée',
                  iconColor: Colors.red,
                ),
                
                const SizedBox(height: 12),
                
                // Informations client
                _buildInfoRow(
                  icon: Icons.person,
                  title: 'Client',
                  content: order.customerName ?? 'Client',
                  iconColor: Colors.blue,
                ),
                
                const SizedBox(height: 12),
                
                // Informations de trajet
                if (distance != null || estimatedTime != null) ...[
                  Row(
                    children: [
                      if (distance != null) ...[
                        Expanded(
                          child: _buildInfoRow(
                            icon: Icons.route,
                            title: 'Distance',
                            content: '${distance!.toStringAsFixed(1)} km',
                            iconColor: Colors.green,
                            compact: true,
                          ),
                        ),
                      ],
                      if (estimatedTime != null) ...[
                        Expanded(
                          child: _buildInfoRow(
                            icon: Icons.access_time,
                            title: 'Temps estimé',
                            content: '${estimatedTime} min',
                            iconColor: Colors.orange,
                            compact: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Montant de la commande
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Montant total',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '${order.totalAmount.toStringAsFixed(0)} FCFA',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Bouton de finalisation
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onCompleteDelivery,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Marquer comme livrée',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String content,
    required Color iconColor,
    bool compact = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: compact ? 16 : 20,
          color: iconColor,
        ),
        SizedBox(width: compact ? 8 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: compact ? 11 : 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: GoogleFonts.poppins(
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _callCustomer() async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: order.customerPhone);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        print('❌ Impossible d\'ouvrir l\'application téléphone');
      }
    } catch (e) {
      print('❌ Erreur lors de l\'appel: $e');
    }
  }
}
