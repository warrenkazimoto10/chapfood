import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget pour afficher les informations du livreur style Uber/Glovo
class DriverInfoCard extends StatelessWidget {
  final String driverName;
  final String driverPhone;
  final String? driverPhoto;
  final double? rating;
  final String? vehicleInfo;

  const DriverInfoCard({
    super.key,
    required this.driverName,
    required this.driverPhone,
    this.driverPhoto,
    this.rating,
    this.vehicleInfo,
  });

  Future<void> _callDriver(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Photo du livreur
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue[100],
              image: driverPhoto != null
                  ? DecorationImage(
                      image: NetworkImage(driverPhoto!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: driverPhoto == null
                ? Icon(Icons.person, color: Colors.blue[700], size: 30)
                : null,
          ),
          const SizedBox(width: 16),
          // Informations
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (rating != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < rating!.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        rating!.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
                if (vehicleInfo != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    vehicleInfo!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Bouton d'appel
          Container(
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.phone, color: Colors.white),
              onPressed: () => _callDriver(driverPhone),
              tooltip: 'Appeler le livreur',
            ),
          ),
        ],
      ),
    );
  }
}
