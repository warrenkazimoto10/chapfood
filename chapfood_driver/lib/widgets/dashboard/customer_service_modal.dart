import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';

/// Modal de service client
class CustomerServiceModal extends StatelessWidget {
  const CustomerServiceModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.buttonGradient,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.headset_mic, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Service Client',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Contenu
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Option Appeler
                _buildActionButton(
                  context,
                  icon: Icons.phone,
                  title: 'Appeler le support',
                  subtitle: 'Appelez-nous directement',
                  color: Colors.green,
                  onTap: () async {
                    const phoneNumber =
                        'tel:+225XXXXXXXXX'; // Remplacer par le vrai numéro
                    if (await canLaunchUrl(Uri.parse(phoneNumber))) {
                      await launchUrl(Uri.parse(phoneNumber));
                    }
                  },
                ),

                const SizedBox(height: 12),

                // Option Chat
                _buildActionButton(
                  context,
                  icon: Icons.chat_bubble,
                  title: 'Chat en direct',
                  subtitle: 'Discutez avec notre équipe',
                  color: Colors.blue,
                  onTap: () {
                    // TODO: Implémenter le chat
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fonctionnalité de chat à venir'),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Option Email
                _buildActionButton(
                  context,
                  icon: Icons.email,
                  title: 'Envoyer un email',
                  subtitle: 'support@chapfood.com',
                  color: Colors.orange,
                  onTap: () async {
                    final emailUri = Uri(
                      scheme: 'mailto',
                      path: 'support@chapfood.com',
                      query: 'subject=Support Livreur',
                    );
                    if (await canLaunchUrl(emailUri)) {
                      await launchUrl(emailUri);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
