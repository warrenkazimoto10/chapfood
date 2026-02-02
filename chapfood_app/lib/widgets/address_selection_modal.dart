import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/app_colors.dart';
import '../utils/text_styles.dart';
import '../services/address_service.dart';

class AddressSelectionModal extends StatefulWidget {
  final Function(String address, double? latitude, double? longitude)? onAddressSelected;

  const AddressSelectionModal({
    super.key,
    this.onAddressSelected,
  });

  @override
  State<AddressSelectionModal> createState() => _AddressSelectionModalState();
}

class _AddressSelectionModalState extends State<AddressSelectionModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  String? _preferredAddress;
  Map<String, dynamic>? _preferredPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _loadAddressData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAddressData() async {
    try {
      final address = await AddressService.getPreferredAddress();
      final position = await AddressService.getPreferredPosition();
      
      setState(() {
        _preferredAddress = address;
        _preferredPosition = position;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _selectMyAddress() {
    if (_preferredAddress != null || _preferredPosition != null) {
      final address = _preferredAddress ?? 'Ma position sauvegardée';
      final latitude = _preferredPosition?['latitude'] as double?;
      final longitude = _preferredPosition?['longitude'] as double?;
      
      if (widget.onAddressSelected != null) {
        widget.onAddressSelected!(address, latitude, longitude);
      }
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Aucune adresse sauvegardée. Veuillez sélectionner une nouvelle adresse.'),
          backgroundColor: AppColors.getPrimaryColor(context),
        ),
      );
    }
  }

  void _selectNewAddress() {
    Navigator.pop(context);
    // L'écran parent gérera l'ouverture de la carte
    if (widget.onAddressSelected != null) {
      widget.onAddressSelected!('new_address', null, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.getCardColor(context),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.getBorderColor(context),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.getPrimaryColor(context).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Icon(
                                Icons.location_on,
                                size: 32,
                                color: AppColors.getPrimaryColor(context),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Choisir une adresse',
                              style: AppTextStyles.foodItemTitle.copyWith(
                                fontSize: 20,
                                color: AppColors.getTextColor(context),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Comment souhaitez-vous recevoir votre commande ?',
                              style: AppTextStyles.foodItemDescription.copyWith(
                                fontSize: 14,
                                color: AppColors.getSecondaryTextColor(context),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      
                      // Options
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            if (_isLoading)
                              const Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(),
                              )
                            else ...[
                              // Mon adresse
                              _buildAddressOption(
                                icon: FontAwesomeIcons.house,
                                title: 'Mon adresse',
                                subtitle: _preferredAddress != null 
                                    ? _preferredAddress!
                                    : (_preferredPosition != null 
                                        ? 'Position sauvegardée'
                                        : 'Aucune adresse sauvegardée'),
                                isEnabled: _preferredAddress != null || _preferredPosition != null,
                                onTap: _selectMyAddress,
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Nouvelle adresse
                              _buildAddressOption(
                                icon: FontAwesomeIcons.mapLocationDot,
                                title: 'Nouvelle adresse',
                                subtitle: 'Sélectionner une nouvelle position',
                                isEnabled: true,
                                onTap: _selectNewAddress,
                                isPrimary: true,
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Bouton annuler
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: AppColors.getBorderColor(context),
                                ),
                              ),
                            ),
                            child: Text(
                              'Annuler',
                              style: TextStyle(
                                color: AppColors.getSecondaryTextColor(context),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAddressOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isEnabled,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isPrimary 
                ? AppColors.getPrimaryColor(context).withOpacity(0.1)
                : AppColors.getLightCardBackground(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary 
                  ? AppColors.getPrimaryColor(context)
                  : AppColors.getBorderColor(context),
              width: isPrimary ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPrimary 
                      ? AppColors.getPrimaryColor(context)
                      : (isEnabled 
                          ? AppColors.getSecondaryColor(context)
                          : Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(
                  icon,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.foodItemTitle.copyWith(
                        fontSize: 16,
                        color: isEnabled 
                            ? AppColors.getTextColor(context)
                            : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.foodItemDescription.copyWith(
                        fontSize: 14,
                        color: isEnabled 
                            ? AppColors.getSecondaryTextColor(context)
                            : Colors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isEnabled 
                    ? AppColors.getSecondaryTextColor(context)
                    : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
