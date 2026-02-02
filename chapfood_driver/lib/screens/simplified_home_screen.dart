import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../services/theme_service.dart';
import '../services/session_service.dart';
import '../models/driver_model.dart';

class SimplifiedHomeScreen extends StatefulWidget {
  const SimplifiedHomeScreen({super.key});

  @override
  State<SimplifiedHomeScreen> createState() => _SimplifiedHomeScreenState();
}

class _SimplifiedHomeScreenState extends State<SimplifiedHomeScreen> {
  DriverModel? _currentDriver;
  bool _isLoading = true;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
    _loadThemeMode();
  }

  void _loadThemeMode() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    setState(() {
      _isDarkMode = themeService.isDarkMode;
    });
  }

  Future<void> _loadDriverData() async {
    try {
      final driver = await SessionService.getCurrentDriver();
      setState(() {
        _currentDriver = driver;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement driver: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryRed,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          // Header avec infos du client
          _buildHeader(),
          // Carte Mapbox full screen
          Expanded(
            child: _buildMapSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Logo et titre
            Row(
              children: [
                Image.asset(
                  'assets/images/logo-chapfood.png',
                  height: 40,
                  width: 40,
                ),
                const SizedBox(width: 12),
                Text(
                  'ChapFood Livreur',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  onPressed: () {
                    // Notifications
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Infos du livreur
            if (_currentDriver != null) _buildDriverInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              _currentDriver!.name.substring(0, 1).toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentDriver!.name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentDriver!.vehicleType ?? 'Moto',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                if (_currentDriver!.rating != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _currentDriver!.rating!.toStringAsFixed(1),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Statut
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'En ligne',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _buildMapPlaceholder(),
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryRed.withOpacity(0.1),
            AppColors.primaryOrange.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map,
              size: 64,
              color: AppColors.primaryRed.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Carte Mapbox',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intégration en cours...',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
