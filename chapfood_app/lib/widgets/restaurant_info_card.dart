import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/app_colors.dart';
import '../utils/text_styles.dart';
import '../services/address_service.dart';

class RestaurantInfoCard extends StatefulWidget {
  const RestaurantInfoCard({super.key});

  @override
  State<RestaurantInfoCard> createState() => _RestaurantInfoCardState();
}

class _RestaurantInfoCardState extends State<RestaurantInfoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurantInfo = AddressService.getRestaurantInfo();
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.getBorderColor(context),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec logo et nom
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.getPrimaryColor(context),
                          AppColors.getSecondaryColor(context),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.utensils,
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
                          restaurantInfo['name'],
                          style: AppTextStyles.foodItemTitle.copyWith(
                            fontSize: 22,
                            color: AppColors.getTextColor(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Restaurant & Livraison',
                          style: AppTextStyles.foodItemDescription.copyWith(
                            fontSize: 14,
                            color: AppColors.getSecondaryTextColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Ouvert',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Informations de contact
              _buildInfoSection(
                icon: FontAwesomeIcons.locationDot,
                title: 'Adresse',
                content: restaurantInfo['address'],
                action: 'Voir sur carte',
                onActionTap: () => _showMapDialog(context),
              ),
              
              const SizedBox(height: 16),
              
              _buildInfoSection(
                icon: FontAwesomeIcons.phone,
                title: 'Téléphone',
                content: restaurantInfo['phone'],
                action: 'Appeler',
                onActionTap: () => _makePhoneCall(restaurantInfo['phone']),
              ),
              
              const SizedBox(height: 16),
              
              // Horaires d'ouverture
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.getLightCardBackground(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.getBorderColor(context),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.clock,
                          size: 16,
                          color: AppColors.getPrimaryColor(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Horaires d\'ouverture',
                          style: AppTextStyles.foodItemTitle.copyWith(
                            fontSize: 16,
                            color: AppColors.getTextColor(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._buildHoursList(restaurantInfo['hours']),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Services
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.getSecondaryColor(context).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.getSecondaryColor(context).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.star,
                          size: 16,
                          color: AppColors.getSecondaryColor(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Nos Services',
                          style: AppTextStyles.foodItemTitle.copyWith(
                            fontSize: 16,
                            color: AppColors.getTextColor(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (restaurantInfo['services'] as List<String>)
                          .map((service) => _buildServiceChip(service))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String content,
    required String action,
    required VoidCallback onActionTap,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.getPrimaryColor(context).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FaIcon(
            icon,
            size: 16,
            color: AppColors.getPrimaryColor(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.foodItemDescription.copyWith(
                  fontSize: 12,
                  color: AppColors.getSecondaryTextColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: AppTextStyles.foodItemTitle.copyWith(
                  fontSize: 14,
                  color: AppColors.getTextColor(context),
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onActionTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.getPrimaryColor(context).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.getPrimaryColor(context).withOpacity(0.3),
              ),
            ),
            child: Text(
              action,
              style: TextStyle(
                color: AppColors.getPrimaryColor(context),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildHoursList(Map<String, String> hours) {
    final today = DateTime.now().weekday;
    final dayNames = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
    final dayKeys = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    
    return dayKeys.asMap().entries.map((entry) {
      final index = entry.key;
      final key = entry.value;
      final isToday = index + 1 == today;
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dayNames[index].substring(0, 1).toUpperCase() + dayNames[index].substring(1),
              style: AppTextStyles.foodItemDescription.copyWith(
                fontSize: 13,
                color: isToday 
                    ? AppColors.getPrimaryColor(context)
                    : AppColors.getSecondaryTextColor(context),
                fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            Text(
              hours[key] ?? 'Fermé',
              style: AppTextStyles.foodItemDescription.copyWith(
                fontSize: 13,
                color: isToday 
                    ? AppColors.getPrimaryColor(context)
                    : AppColors.getSecondaryTextColor(context),
                fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildServiceChip(String service) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.getSecondaryColor(context).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getSecondaryColor(context).withOpacity(0.4),
        ),
      ),
      child: Text(
        service,
        style: TextStyle(
          color: AppColors.getSecondaryColor(context),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showMapDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getCardColor(context),
        title: Text(
          'Localisation du restaurant',
          style: TextStyle(color: AppColors.getTextColor(context)),
        ),
        content: Text(
          'ChapFood\n${AddressService.getRestaurantInfo()['address']}',
          style: TextStyle(color: AppColors.getSecondaryTextColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fermer',
              style: TextStyle(color: AppColors.getSecondaryTextColor(context)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Ouvrir carte avec position du restaurant
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.getPrimaryColor(context),
            ),
            child: const Text('Voir sur carte', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _makePhoneCall(String phone) {
    // TODO: Implémenter l'appel téléphonique
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Appel vers $phone'),
        backgroundColor: AppColors.getPrimaryColor(context),
      ),
    );
  }
}
