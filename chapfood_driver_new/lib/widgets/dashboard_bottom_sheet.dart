import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import '../services/driver_stats_service.dart';

class DashboardBottomSheet extends StatefulWidget {
  final Function(bool)? onStatusChanged;
  const DashboardBottomSheet({super.key, this.onStatusChanged});

  @override
  State<DashboardBottomSheet> createState() => _DashboardBottomSheetState();
}

class _DashboardBottomSheetState extends State<DashboardBottomSheet> {
  String _driverName = 'Chargement...';
  String _driverPhone = '';
  bool _isOnline = false;
  bool _isLoading = true;
  int? _driverId;
  
  // Stats
  int _totalOrders = 0;
  double _totalEarnings = 0.0;
  double _hoursOnline = 0.0;

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
        _driverPhone = driverInfo['phone'] ?? '';
        _isOnline = driverInfo['is_available'] ?? false;
        _driverId = driverInfo['id'] as int?;
        _isLoading = false;
      });
      
      // Charger les statistiques
      if (_driverId != null) {
        _loadStats();
      }
      
      // Notifier le parent du statut initial
      widget.onStatusChanged?.call(_isOnline);
    } else if (mounted) {
      setState(() {
        _driverName = 'Livreur';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadStats() async {
    if (_driverId == null) return;
    
    final stats = await DriverStatsService.getDriverStats(_driverId!);
    if (mounted) {
      setState(() {
        _totalOrders = stats['total_orders'] ?? 0;
        _totalEarnings = stats['total_earnings'] ?? 0.0;
        _hoursOnline = stats['hours_online'] ?? 0.0;
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
        widget.onStatusChanged?.call(value);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Si c'est une erreur de session, rediriger vers login
        if (e.toString().contains('AuthRetryableFetchException') || 
            e.toString().contains('missing destination name oauth_client_id')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expirée. Veuillez vous reconnecter.'),
              backgroundColor: Colors.red,
            ),
          );
          
          // Rediriger vers login après 2 secondes
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              context.go('/login');
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors de la mise à jour du statut')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Driver Info & Status
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.person, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _driverName,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_driverPhone.isNotEmpty)
                        Text(
                          _driverPhone,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      Text(
                        _isOnline ? 'En ligne' : 'Hors ligne',
                        style: GoogleFonts.poppins(
                          color: _isOnline ? AppColors.success : Colors.grey,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  Switch(
                    value: _isOnline,
                    onChanged: _toggleStatus,
                    activeColor: AppColors.success,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
