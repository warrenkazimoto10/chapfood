import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../services/auth_service.dart';

class DriverStatusCard extends StatefulWidget {
  const DriverStatusCard({super.key});

  @override
  State<DriverStatusCard> createState() => _DriverStatusCardState();
}

class _DriverStatusCardState extends State<DriverStatusCard> {
  String _driverName = 'Chargement...';
  bool _isOnline = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDriverInfo();
  }

  Future<void> _loadDriverInfo() async {
    final driverInfo = await AuthService.getDriverInfo();
    if (mounted && driverInfo != null) {
      setState(() {
        _driverName = driverInfo['name'] ?? 'Livreur';
        _isOnline = driverInfo['is_available'] ?? false;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        _driverName = 'Livreur';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleStatus(bool value) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.updateDriverStatus(value);
      if (mounted) {
        setState(() {
          _isOnline = value;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la mise à jour du statut')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(Icons.person, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _driverName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _isOnline ? 'En ligne' : 'Hors ligne',
                    style: GoogleFonts.poppins(
                      color: _isOnline ? AppColors.success : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Switch(
                value: _isOnline,
                onChanged: _toggleStatus,
                activeColor: AppColors.success,
              ),
          ],
        ),
      ),
    );
  }
}
