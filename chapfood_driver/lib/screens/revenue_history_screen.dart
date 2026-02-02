import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../services/session_service.dart';
import '../services/revenue_service.dart';
import '../services/theme_service.dart';

class RevenueHistoryScreen extends StatefulWidget {
  const RevenueHistoryScreen({super.key});

  @override
  State<RevenueHistoryScreen> createState() => _RevenueHistoryScreenState();
}

class _RevenueHistoryScreenState extends State<RevenueHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _deliveryHistory = [];
  Map<String, dynamic> _revenueStats = {};
  int? _driverId;

  @override
  void initState() {
    super.initState();
    _loadDeliveryHistory();
  }

  Future<void> _loadDeliveryHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Récupérer l'ID du livreur connecté
      final driver = SessionService.currentDriver;
      if (driver == null) {
        print('❌ Aucun livreur connecté');
        return;
      }

      _driverId = driver.id;
      
      // Charger l'historique et les statistiques en parallèle
      final results = await Future.wait([
        RevenueService.getDriverDeliveryHistory(_driverId!),
        RevenueService.getDriverRevenueStats(_driverId!),
      ]);

      _deliveryHistory = results[0] as List<Map<String, dynamic>>;
      _revenueStats = results[1] as Map<String, dynamic>;

      print('📊 Données chargées: ${_deliveryHistory.length} livraisons, revenus: ${_revenueStats['totalRevenue']}');

    } catch (e) {
      print('❌ Erreur chargement historique: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: Text('Revenus & Historique', style: GoogleFonts.poppins(color: isDarkMode ? Colors.white : Colors.black)),
        backgroundColor: isDarkMode ? AppColors.darkBackground : Colors.white,
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
        elevation: 0.5,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            )
          : RefreshIndicator(
              onRefresh: _loadDeliveryHistory,
              color: AppColors.primaryRed,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Résumé des revenus
                    _buildRevenueSummary(isDarkMode),
                    const SizedBox(height: 24),

                    // Statistiques détaillées
                    _buildStatisticsCards(isDarkMode),
                    const SizedBox(height: 24),

                    // Historique des livraisons
                    _buildDeliveryHistory(isDarkMode),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRevenueSummary(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryRed, AppColors.primaryRed.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.attach_money,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revenus Totaux',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      '${(_revenueStats['totalRevenue'] as double? ?? 0.0).toStringAsFixed(0)} FCFA',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Livraisons', '${_revenueStats['totalDeliveries'] ?? 0}', Icons.local_shipping),
                _buildStatItem('Moyenne', '${(_revenueStats['averageDelivery'] as double? ?? 0.0).toStringAsFixed(0)} FCFA', Icons.trending_up),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 16),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatisticsCards(bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Cette Semaine',
            '${(_revenueStats['thisWeekRevenue'] as double? ?? 0.0).toStringAsFixed(0)} FCFA',
            Icons.calendar_today,
            isDarkMode,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Ce Mois',
            '${(_revenueStats['thisMonthRevenue'] as double? ?? 0.0).toStringAsFixed(0)} FCFA',
            Icons.calendar_month,
            isDarkMode,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardBackground : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryRed, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDarkMode ? AppColors.textSecondary : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.textPrimary : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryHistory(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Historique des Livraisons',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.textPrimary : AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        if (_deliveryHistory.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.cardBackground : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightGray),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.history,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune livraison effectuée',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
        else
          ..._deliveryHistory.map((delivery) => _buildDeliveryItem(delivery, isDarkMode)).toList(),
      ],
    );
  }

  Widget _buildDeliveryItem(Map<String, dynamic> delivery, bool isDarkMode) {
    final deliveredAt = DateTime.parse(delivery['delivered_at'] as String);
    final order = delivery['orders'] as Map<String, dynamic>;
    final customerName = order['customer_name'] as String? ?? 'Client';
    final deliveryFee = (order['delivery_fee'] as num?)?.toDouble() ?? 0.0;
    final orderId = order['id'] as int;
    
    return GestureDetector(
      onTap: () => _showDeliveryDetails(orderId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.cardBackground : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.primaryRed,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customerName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? AppColors.textPrimary : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Commande #$orderId • Livré le ${deliveredAt.day}/${deliveredAt.month}/${deliveredAt.year}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDarkMode ? AppColors.textSecondary : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${deliveryFee.toStringAsFixed(0)} FCFA',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryRed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Affiche les détails d'une livraison
  Future<void> _showDeliveryDetails(int orderId) async {
    try {
      final details = await RevenueService.getDeliveryDetails(orderId);
      if (details == null) return;

      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Détails de la livraison',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Commande', '#${details['id']}'),
              _buildDetailRow('Client', details['customer_name'] ?? 'N/A'),
              _buildDetailRow('Téléphone', details['customer_phone'] ?? 'N/A'),
              _buildDetailRow('Adresse', details['delivery_address'] ?? 'N/A'),
              _buildDetailRow('Montant total', '${(details['total_amount'] as num?)?.toStringAsFixed(0) ?? '0'} FCFA'),
              _buildDetailRow('Frais de livraison', '${(details['delivery_fee'] as num?)?.toStringAsFixed(0) ?? '0'} FCFA'),
              _buildDetailRow('Statut', details['status'] ?? 'N/A'),
              if (details['delivered_at'] != null)
                _buildDetailRow('Livré le', DateTime.parse(details['delivered_at']).toString().split(' ')[0]),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Fermer',
                style: GoogleFonts.poppins(color: AppColors.primaryRed),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      print('❌ Erreur affichage détails: $e');
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
