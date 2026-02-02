import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../services/theme_service.dart';
import '../services/driver_location_tracker.dart';
import '../services/session_service.dart';
import '../screens/profile_screen.dart';
import '../widgets/home/parallax_header.dart';
import '../widgets/home/driver_status_card.dart';
import '../widgets/home/enhanced_map_section.dart';
import '../widgets/home/quick_actions_section.dart';
import '../widgets/home/stats_section.dart';
import '../widgets/home/animated_bottom_nav.dart';
import '../widgets/home/notification_section.dart';
import '../widgets/home/order_notification_card.dart';
import '../widgets/responsive/responsive_layout.dart';
import '../widgets/loading/loading_states.dart';

class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen> {
  int _currentNavIndex = 0;
  bool _isDriverAvailable = true;
  bool _isDarkMode = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Services
  final DriverLocationTracker _locationTracker = DriverLocationTracker();
  int? _currentDriverId;

  // Données simulées - à remplacer par les vraies données
  final String _driverName = "Jean Kouassi";
  final String _vehicleType = "Moto";
  final double _rating = 4.8;
  final int _totalDeliveries = 156;
  final double _totalRevenue = 125000.0;
  final int _todayDeliveries = 8;
  final double _todayRevenue = 6500.0;

  // Données de notifications simulées
  final List<Map<String, dynamic>> _notifications = [
    {
      'type': 'info',
      'title': 'Bienvenue !',
      'message': 'Votre compte est maintenant actif',
      'time': 'Il y a 2 heures',
      'isRead': true,
    },
    {
      'type': 'success',
      'title': 'Livraison terminée',
      'message': 'Commande #1234 livrée avec succès',
      'time': 'Il y a 1 heure',
      'isRead': false,
    },
  ];

  Map<String, dynamic>? _currentOrderNotification = {
    'id': 1234,
    'customer_name': 'Marie Kouassi',
    'total_amount': 8500.0,
    'delivery_address': 'Cocody, Abidjan',
    'delivery_fee': 1500.0,
  };

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    _initializeLocationTracking();
  }

  /// Initialise le suivi de géolocalisation
  Future<void> _initializeLocationTracking() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Initialiser le tracker de position
      final initialized = await _locationTracker.initialize();
      if (!initialized) {
        setState(() {
          _errorMessage = 'Impossible d\'initialiser la géolocalisation';
          _isLoading = false;
        });
        return;
      }

      final driverId = SessionService.getCurrentDriverId();
      if (driverId == null) {
        setState(() {
          _errorMessage =
              'Impossible de récupérer votre identifiant. Veuillez vous reconnecter.';
          _isLoading = false;
        });
        return;
      }

      _currentDriverId = driverId;

      // Démarrer le suivi automatique
      await _locationTracker.startTracking(_currentDriverId!);

      setState(() {
        _isLoading = false;
      });

      print(
        '✅ Suivi de géolocalisation démarré pour le livreur $_currentDriverId',
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de l\'initialisation: $e';
        _isLoading = false;
      });
      print('❌ Erreur lors de l\'initialisation: $e');
    }
  }

  void _loadThemeMode() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    setState(() {
      _isDarkMode = themeService.isDarkMode;
    });
  }

  void _toggleDriverStatus() async {
    final newStatus = !_isDriverAvailable;

    // Mettre à jour le statut via le service
    final success = await _locationTracker.updateDriverStatus(newStatus);

    if (success) {
      setState(() {
        _isDriverAvailable = newStatus;
      });
      print(
        '✅ Statut du livreur mis à jour: ${newStatus ? "disponible" : "indisponible"}',
      );
    } else {
      print('❌ Échec de la mise à jour du statut');
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });

    // Navigation vers les autres écrans
    switch (index) {
      case 0:
        // Accueil - déjà là
        break;
      case 1:
        // Naviguer vers historique
        print('📋 Navigation vers historique');
        break;
      case 2:
        // Naviguer vers revenus
        print('💰 Navigation vers revenus');
        break;
      case 3:
        // Naviguer vers profil
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
    }
  }

  void _onLocationTap() {
    // Centrer sur la position actuelle
    print('📍 Centrage sur la position actuelle');
  }

  void _onHistoryTap() {
    print('📋 Navigation vers historique');
  }

  void _onProfileTap() {
    print('👤 Navigation vers profil');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  void _onStatsTap() {
    print('💰 Navigation vers revenus');
  }

  void _onSettingsTap() {
    print('⚙️ Navigation vers paramètres');
  }

  void _onAcceptOrder() {
    print('✅ Commande acceptée');
    setState(() {
      _currentOrderNotification = null;
    });
  }

  void _onDeclineOrder() {
    print('❌ Commande refusée');
    setState(() {
      _currentOrderNotification = null;
    });
  }

  void _onNotificationTap() {
    print('🔔 Notification tapée');
  }

  void _onClearAllNotifications() {
    setState(() {
      _notifications.clear();
    });
  }

  @override
  void dispose() {
    _locationTracker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _isDarkMode
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        body: const LoadingState(message: 'Chargement de vos données...'),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: _isDarkMode
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        body: ErrorState(
          message: _errorMessage!,
          onRetry: () {
            setState(() {
              _errorMessage = null;
              _isLoading = true;
            });
            // Simuler le rechargement
            Future.delayed(const Duration(seconds: 2), () {
              setState(() {
                _isLoading = false;
              });
            });
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: _isDarkMode
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(),
        tablet: _buildTabletLayout(),
        desktop: _buildDesktopLayout(),
      ),
      bottomNavigationBar: context.isMobile
          ? AnimatedBottomNav(currentIndex: _currentNavIndex, onTap: _onNavTap)
          : null,
    );
  }

  Widget _buildMobileLayout() {
    return CustomScrollView(
      slivers: [
        // Header avec effet parallaxe
        ParallaxHeader(
          title: 'ChapFood Livreur',
          subtitle: 'Livraisons rapides et sécurisées',
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              // Menu drawer
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () {
                // Notifications
              },
            ),
          ],
        ),

        // Section de statut du livreur
        SliverToBoxAdapter(
          child: DriverStatusCard(
            isAvailable: _isDriverAvailable,
            onToggle: _toggleDriverStatus,
            driverName: _driverName,
            vehicleType: _vehicleType,
            rating: _rating,
          ),
        ),

        // Notification de commande (si disponible)
        if (_currentOrderNotification != null)
          SliverToBoxAdapter(
            child: OrderNotificationCard(
              order: _currentOrderNotification!,
              onAccept: _onAcceptOrder,
              onDecline: _onDeclineOrder,
            ),
          ),

        // Section de la carte
        SliverToBoxAdapter(
          child: EnhancedMapSection(
            mapWidget: _buildMapPlaceholder(),
            onLocationTap: _onLocationTap,
            isDrivingMode: false,
          ),
        ),

        // Section des actions rapides
        SliverToBoxAdapter(
          child: QuickActionsSection(
            onHistoryTap: _onHistoryTap,
            onProfileTap: _onProfileTap,
            onStatsTap: _onStatsTap,
            onSettingsTap: _onSettingsTap,
          ),
        ),

        // Section des notifications
        SliverToBoxAdapter(
          child: NotificationSection(
            notifications: _notifications,
            onNotificationTap: _onNotificationTap,
            onClearAll: _onClearAllNotifications,
          ),
        ),

        // Section des statistiques
        SliverToBoxAdapter(
          child: StatsSection(
            totalDeliveries: _totalDeliveries,
            totalRevenue: _totalRevenue,
            rating: _rating,
            todayDeliveries: _todayDeliveries,
            todayRevenue: _todayRevenue,
          ),
        ),

        // Espace en bas pour la navigation
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        // Sidebar pour tablette
        Container(
          width: 250,
          color: _isDarkMode ? AppColors.cardBackgroundDark : Colors.white,
          child: Column(
            children: [
              // Header compact
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: Column(
                  children: [
                    Text(
                      'ChapFood',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Livreur',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              // Navigation
              Expanded(
                child: ListView(
                  children: [
                    _buildTabletNavItem(Icons.home, 'Accueil', 0),
                    _buildTabletNavItem(Icons.history, 'Historique', 1),
                    _buildTabletNavItem(Icons.attach_money, 'Revenus', 2),
                    _buildTabletNavItem(Icons.person, 'Profil', 3),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Contenu principal
        Expanded(child: _buildMobileLayout()),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return _buildTabletLayout(); // Même layout que tablette pour l'instant
  }

  Widget _buildTabletNavItem(IconData icon, String label, int index) {
    final isActive = _currentNavIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primaryRed.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? AppColors.primaryRed : AppColors.textTertiary,
        ),
        title: Text(
          label,
          style: GoogleFonts.poppins(
            color: isActive ? AppColors.primaryRed : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () => _onNavTap(index),
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryRed.withOpacity(0.1),
            AppColors.accentBlue.withOpacity(0.1),
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intégration en cours...',
              style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
