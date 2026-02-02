import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;

import '../services/cart_service.dart';
import '../services/order_service.dart';
import 'order_confirmation_screen.dart';
import '../services/session_service.dart';
import 'login_screen.dart';
import '../utils/text_styles.dart';
import '../constants/app_colors.dart';
import '../models/enums.dart';
import '../widgets/address_selection_modal.dart';
import '../screens/map_selection_screen.dart';
import '../services/address_service.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  List<CartItem> _cartItems = [];
  bool _isLoading = true;
  String _deliveryType = 'pickup';
  String _customerName = '';
  String _customerPhone = '';
  String _deliveryAddress = '';
  geo.Position? _currentPosition;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();

    _loadCartItems();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadCartItems() async {
    setState(() => _isLoading = true);

    try {
      final items = await CartService.getCartItems();
      setState(() {
        _cartItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement du panier: $e'),
          backgroundColor: AppColors.primaryRed,
        ),
      );
    }
  }

  Future<void> _loadUserData() async {
    try {
      print('🔍 Chargement des données utilisateur...');
      final user = await SessionService.getCurrentUser();
      print('👤 Utilisateur récupéré: ${user?.email ?? "null"}');

      if (user != null) {
        print('✅ Utilisateur trouvé:');
        print('  - Nom: ${user.fullName}');
        print('  - Téléphone: ${user.phone}');
        print('  - Email: ${user.email}');

        setState(() {
          _customerName = user.fullName ?? '';
          _customerPhone = user.phone ?? '';
          _nameController.text = _customerName;
          _phoneController.text = _customerPhone;
        });

        print('📝 Champs mis à jour:');
        print('  - _customerName: $_customerName');
        print('  - _customerPhone: $_customerPhone');
      } else {
        print('❌ Aucun utilisateur trouvé');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des données utilisateur: $e');
    }
  }

  Future<void> _loadPreferredAddress() async {
    try {
      print('🔍 Chargement de l\'adresse préférée...');
      final address = await AddressService.getPreferredAddress();
      final position = await AddressService.getPreferredPosition();

      if (address != null || position != null) {
        print('✅ Adresse préférée trouvée:');
        print('  - Adresse: $address');
        print('  - Position: $position');

        setState(() {
          _deliveryAddress = address ?? 'Position sauvegardée';
          if (position != null) {
            _currentPosition = geo.Position(
              latitude: position['latitude'] as double,
              longitude: position['longitude'] as double,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              altitudeAccuracy: 0,
              heading: 0,
              headingAccuracy: 0,
              speed: 0,
              speedAccuracy: 0,
            );
          }
        });

        print('📝 Adresse pré-sélectionnée: $_deliveryAddress');
      } else {
        print('❌ Aucune adresse préférée trouvée');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement de l\'adresse préférée: $e');
    }
  }

  Future<void> _showAddressSelectionModal() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AddressSelectionModal(
        onAddressSelected: (address, latitude, longitude) async {
          if (address == 'new_address') {
            // Ouvrir l'écran de sélection de carte
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MapSelectionScreen(
                  onAddressSelected:
                      (selectedAddress, selectedLat, selectedLng) {
                        setState(() {
                          _deliveryAddress = selectedAddress;
                          _currentPosition = geo.Position(
                            latitude: selectedLat,
                            longitude: selectedLng,
                            timestamp: DateTime.now(),
                            accuracy: 0,
                            altitude: 0,
                            altitudeAccuracy: 0,
                            heading: 0,
                            headingAccuracy: 0,
                            speed: 0,
                            speedAccuracy: 0,
                          );
                        });
                      },
                ),
              ),
            );
          } else {
            // Utiliser l'adresse préférée
            setState(() {
              _deliveryAddress = address;
              _currentPosition = latitude != null && longitude != null
                  ? geo.Position(
                      latitude: latitude,
                      longitude: longitude,
                      timestamp: DateTime.now(),
                      accuracy: 0,
                      altitude: 0,
                      altitudeAccuracy: 0,
                      heading: 0,
                      headingAccuracy: 0,
                      speed: 0,
                      speedAccuracy: 0,
                    )
                  : null;
            });
          }
        },
      ),
    );
  }

  Future<void> _placeOrder() async {
    print('=== DÉBUT DE LA CRÉATION DE COMMANDE ===');

    if (_customerName.isEmpty || _customerPhone.isEmpty) {
      print('❌ Erreur: Champs obligatoires manquants');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: AppColors.primaryRed,
        ),
      );
      return;
    }

    print('✅ Informations client: $_customerName - $_customerPhone');
    print('📦 Type de livraison: $_deliveryType');
    print('📍 Adresse de livraison: $_deliveryAddress');

    // En mode livraison: si l'adresse (quartier) est vide, on utilise la position GPS
    if (_deliveryType == 'delivery' && _deliveryAddress.isEmpty) {
      if (_currentPosition != null) {
        _deliveryAddress =
            'GPS: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Adresse définie via votre position GPS'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Veuillez sélectionner une adresse de livraison',
            ),
            backgroundColor: AppColors.getPrimaryColor(context),
          ),
        );
        return;
      }
    }

    // Afficher une animation/overlay de chargement pendant 3 secondes
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          width: 120,
          height: 120,
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
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 3));

    // Créer la commande dans Supabase
    try {
      print('💰 Calcul des prix...');
      final subtotal = _cartItems.fold(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );
      final deliveryFee = _deliveryType == 'delivery' ? 500.0 : 0.0;
      final totalAmount = subtotal + deliveryFee;

      print('📊 Prix calculés:');
      print('  - Sous-total: $subtotal FCFA');
      print('  - Frais de livraison: $deliveryFee FCFA');
      print('  - Total: $totalAmount FCFA');

      // Récupérer l'utilisateur actuel
      print('👤 Récupération de l\'utilisateur actuel...');
      final currentUser = await SessionService.getCurrentUser();

      if (currentUser == null) {
        print('❌ ERREUR: Aucun utilisateur connecté');
        throw Exception('Aucun utilisateur connecté');
      }

      print('✅ Utilisateur trouvé:');
      print('  - ID: ${currentUser.id}');
      print('  - Email: ${currentUser.email}');
      print('  - Nom: ${currentUser.fullName}');
      print('  - Type ID: ${currentUser.id.runtimeType}');

      print('🛒 Création de la commande...');
      final order = await OrderService.createOrder(
        userId: currentUser.id,
        customerName: _customerName,
        customerPhone: _customerPhone,
        deliveryType: _deliveryType == 'delivery'
            ? DeliveryType.delivery
            : DeliveryType.pickup,
        deliveryAddress: _deliveryAddress.isNotEmpty ? _deliveryAddress : null,
        deliveryLat: _currentPosition?.latitude,
        deliveryLng: _currentPosition?.longitude,
        paymentMethod: PaymentMethod.cash,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        totalAmount: totalAmount,
        items: _cartItems,
      );

      print('✅ Commande créée avec succès!');
      print('  - ID commande: ${order.id}');
      print('  - Statut: ${order.status}');
      print('  - Total: ${order.totalAmount} FCFA');

      if (!mounted) return;
      Navigator.pop(context); // fermer le loader
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderConfirmationScreen(order: order),
        ),
      );
    } catch (e) {
      print('❌ ERREUR lors de la création de la commande:');
      print('  - Type d\'erreur: ${e.runtimeType}');
      print('  - Message: $e');
      print('  - Stack trace: ${StackTrace.current}');

      Navigator.pop(context); // fermer le loader si erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la création de la commande: $e'),
          backgroundColor: AppColors.primaryRed,
        ),
      );
    }

    print('=== FIN DE LA CRÉATION DE COMMANDE ===');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getSurfaceColor(context),
      appBar: AppBar(
        title: Text(
          'Finaliser la commande',
          style: TextStyle(color: AppColors.getTextColor(context)),
        ),
        backgroundColor: AppColors.getCardColor(context),
        foregroundColor: AppColors.getTextColor(context),
        elevation: 0,
        actions: [
          // Bouton de débogage temporaire pour vider la session
          IconButton(
            icon: Icon(Icons.bug_report, color: Colors.red),
            onPressed: () async {
              await SessionService.clearSession();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Session vidée - Reconnectez-vous'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            tooltip: 'Vider la session (débogage)',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
          ? _buildEmptyCart()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDeliveryTypeSelection(),
                  const SizedBox(height: 24),
                  if (_deliveryType == 'delivery') _buildDeliverySection(),
                  if (_deliveryType == 'pickup') _buildRestaurantInfoSection(),
                  const SizedBox(height: 24),
                  _buildCustomerInfo(),
                  const SizedBox(height: 24),
                  _buildOrderSummary(),
                  const SizedBox(height: 24),
                  _buildPlaceOrderButton(),
                ],
              ),
            ),
    );
  }

  /// ================= Widgets UI =================
  Widget _buildEmptyCart() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FaIcon(
          FontAwesomeIcons.shoppingCart,
          size: 64,
          color: AppColors.getSecondaryTextColor(context),
        ),
        const SizedBox(height: 24),
        Text(
          'Votre panier est vide',
          style: AppTextStyles.foodItemTitle.copyWith(
            fontSize: 24,
            color: AppColors.getTextColor(context),
          ),
        ),
      ],
    ),
  );

  Widget _buildDeliveryTypeSelection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorderColor(context), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mode de récupération',
            style: AppTextStyles.foodItemTitle.copyWith(
              fontSize: 18,
              color: AppColors.getTextColor(context),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _deliveryType = 'pickup');
                    // Vider l'adresse quand on choisit pickup
                    _deliveryAddress = '';
                    _currentPosition = null;
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _deliveryType == 'pickup'
                          ? AppColors.getPrimaryColor(context).withOpacity(0.1)
                          : AppColors.getLightCardBackground(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _deliveryType == 'pickup'
                            ? AppColors.getPrimaryColor(context)
                            : AppColors.getBorderColor(context),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.store,
                          color: _deliveryType == 'pickup'
                              ? AppColors.getPrimaryColor(context)
                              : AppColors.getSecondaryTextColor(context),
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Venir au restaurant',
                          style: AppTextStyles.foodItemTitle.copyWith(
                            fontSize: 14,
                            color: _deliveryType == 'pickup'
                                ? AppColors.getPrimaryColor(context)
                                : AppColors.getSecondaryTextColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _deliveryType = 'delivery');
                    // Charger automatiquement l'adresse préférée
                    _loadPreferredAddress();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _deliveryType == 'delivery'
                          ? AppColors.getPrimaryColor(context).withOpacity(0.1)
                          : AppColors.getLightCardBackground(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _deliveryType == 'delivery'
                            ? AppColors.getPrimaryColor(context)
                            : AppColors.getBorderColor(context),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.motorcycle,
                          color: _deliveryType == 'delivery'
                              ? AppColors.getPrimaryColor(context)
                              : AppColors.getSecondaryTextColor(context),
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Se faire livrer',
                          style: AppTextStyles.foodItemTitle.copyWith(
                            fontSize: 14,
                            color: _deliveryType == 'delivery'
                                ? AppColors.getPrimaryColor(context)
                                : AppColors.getSecondaryTextColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorderColor(context), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FontAwesomeIcons.store,
                color: AppColors.getPrimaryColor(context),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Informations du restaurant',
                style: AppTextStyles.foodItemTitle.copyWith(
                  fontSize: 18,
                  color: AppColors.getTextColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Nom du restaurant
          _buildInfoRow(
            icon: FontAwesomeIcons.store,
            title: 'ChapFood Restaurant',
            subtitle: 'Cuisine africaine authentique',
            color: AppColors.getPrimaryColor(context),
          ),

          const SizedBox(height: 16),

          // Adresse
          _buildInfoRow(
            icon: FontAwesomeIcons.locationDot,
            title: 'Adresse',
            subtitle: 'Abidjan, Côte d\'Ivoire',
            color: AppColors.getSecondaryTextColor(context),
            onTap: () {
              // Action pour voir sur carte
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ouverture de la carte...'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Téléphone
          _buildInfoRow(
            icon: FontAwesomeIcons.phone,
            title: 'Téléphone',
            subtitle: '+225 XX XX XX XX',
            color: AppColors.getSecondaryTextColor(context),
            onTap: () {
              // Action pour appeler
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ouverture de l\'appel...'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Horaires d'ouverture
          _buildHoursSection(),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: onTap != null
              ? AppColors.getPrimaryColor(context).withOpacity(0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: onTap != null
              ? Border.all(
                  color: AppColors.getPrimaryColor(context).withOpacity(0.2),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.foodItemTitle.copyWith(
                      fontSize: 14,
                      color: AppColors.getTextColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.foodItemDescription.copyWith(
                      fontSize: 13,
                      color: AppColors.getSecondaryTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.getSecondaryTextColor(context),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoursSection() {
    final now = DateTime.now();
    final dayNames = [
      'lundi',
      'mardi',
      'mercredi',
      'jeudi',
      'vendredi',
      'samedi',
      'dimanche',
    ];
    final hours = {
      'monday': '08:00 - 22:00',
      'tuesday': '08:00 - 22:00',
      'wednesday': '08:00 - 22:00',
      'thursday': '08:00 - 22:00',
      'friday': '08:00 - 22:00',
      'saturday': '08:00 - 23:00',
      'sunday': '09:00 - 21:00',
    };

    final today = now.weekday; // 1 = lundi, 7 = dimanche
    final todayKey = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ][today - 1];
    final isOpen = _isRestaurantOpen(now, hours[todayKey]!);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getLightCardBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getBorderColor(context)),
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
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOpen
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOpen
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isOpen ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOpen ? 'Ouvert' : 'Fermé',
                      style: TextStyle(
                        color: isOpen ? Colors.green[700] : Colors.red[700],
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...hours.entries.map((entry) {
            final dayIndex = [
              'monday',
              'tuesday',
              'wednesday',
              'thursday',
              'friday',
              'saturday',
              'sunday',
            ].indexOf(entry.key);
            final dayName = dayNames[dayIndex];
            final isToday = entry.key == todayKey;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _capitalizeFirstLetter(dayName),
                    style: AppTextStyles.foodItemDescription.copyWith(
                      fontSize: 13,
                      color: isToday
                          ? AppColors.getPrimaryColor(context)
                          : AppColors.getSecondaryTextColor(context),
                      fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  Text(
                    entry.value,
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
          }).toList(),
        ],
      ),
    );
  }

  bool _isRestaurantOpen(DateTime now, String hoursString) {
    try {
      final parts = hoursString.split(' - ');
      if (parts.length != 2) return false;

      final openTime = parts[0].split(':');
      final closeTime = parts[1].split(':');

      final openHour = int.parse(openTime[0]);
      final openMinute = int.parse(openTime[1]);
      final closeHour = int.parse(closeTime[0]);
      final closeMinute = int.parse(closeTime[1]);

      final nowMinutes = now.hour * 60 + now.minute;
      final openMinutes = openHour * 60 + openMinute;
      final closeMinutes = closeHour * 60 + closeMinute;

      return nowMinutes >= openMinutes && nowMinutes <= closeMinutes;
    } catch (e) {
      return false;
    }
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    if (text.length == 1) return text.toUpperCase();
    return text.substring(0, 1).toUpperCase() + text.substring(1);
  }

  Widget _buildDeliverySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorderColor(context), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: AppColors.getPrimaryColor(context),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Adresse de livraison',
                style: AppTextStyles.foodItemTitle.copyWith(
                  fontSize: 18,
                  color: AppColors.getTextColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bouton pour sélectionner l'adresse
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showAddressSelectionModal,
              icon: const Icon(Icons.location_searching, size: 20),
              label: Text(
                _deliveryAddress.isEmpty
                    ? 'Choisir une adresse de livraison'
                    : 'Modifier l\'adresse',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getPrimaryColor(context),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),

          // Affichage de l'adresse sélectionnée
          if (_deliveryAddress.isNotEmpty) ...[
            const SizedBox(height: 16),
            // Message informatif
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.getPrimaryColor(context).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.getPrimaryColor(context).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.getPrimaryColor(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Votre adresse enregistrée a été automatiquement sélectionnée. Vous pouvez la modifier en cliquant sur le bouton ci-dessus.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.getTextColor(context),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.getPrimaryColor(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.getPrimaryColor(context).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.getPrimaryColor(context),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 14,
                              color: AppColors.getPrimaryColor(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Adresse pré-sélectionnée',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.getPrimaryColor(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _deliveryAddress,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.getTextColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Note d'information
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Frais de livraison: 500 FCFA',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
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

  Widget _buildCustomerInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorderColor(context), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations de contact',
            style: AppTextStyles.foodItemTitle.copyWith(
              fontSize: 18,
              color: AppColors.getTextColor(context),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            style: TextStyle(color: AppColors.getTextColor(context)),
            decoration: InputDecoration(
              labelText: 'Nom complet *',
              labelStyle: TextStyle(
                color: AppColors.getSecondaryTextColor(context),
              ),
              hintText: 'Votre nom complet',
              hintStyle: TextStyle(
                color: AppColors.getSecondaryTextColor(context),
              ),
              filled: true,
              fillColor: AppColors.getLightCardBackground(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.getBorderColor(context),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.getBorderColor(context),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.getPrimaryColor(context),
                  width: 2,
                ),
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: FaIcon(
                  FontAwesomeIcons.user,
                  size: 16,
                  color: AppColors.getPrimaryColor(context),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onChanged: (val) => _customerName = val,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: AppColors.getTextColor(context)),
            decoration: InputDecoration(
              labelText: 'Numéro de téléphone *',
              labelStyle: TextStyle(
                color: AppColors.getSecondaryTextColor(context),
              ),
              hintText: 'Votre numéro de téléphone',
              hintStyle: TextStyle(
                color: AppColors.getSecondaryTextColor(context),
              ),
              filled: true,
              fillColor: AppColors.getLightCardBackground(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.getBorderColor(context),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.getBorderColor(context),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.getPrimaryColor(context),
                  width: 2,
                ),
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: FaIcon(
                  FontAwesomeIcons.phone,
                  size: 16,
                  color: AppColors.getPrimaryColor(context),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onChanged: (val) => _customerPhone = val,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    final subtotal = _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    final deliveryFee = _deliveryType == 'delivery' ? 500.0 : 0.0;
    final total = subtotal + deliveryFee;
    final itemCount = _cartItems.fold(0, (sum, item) => sum + item.quantity);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorderColor(context), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Résumé de la commande',
            style: AppTextStyles.foodItemTitle.copyWith(
              fontSize: 18,
              color: AppColors.getTextColor(context),
            ),
          ),
          const SizedBox(height: 16),
          ..._cartItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.menuItem.imageUrl ??
                          'https://via.placeholder.com/300x200',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[300],
                        child: const Icon(Icons.restaurant, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.menuItem.name,
                          style: AppTextStyles.foodItemTitle.copyWith(
                            fontSize: 14,
                            color: AppColors.getTextColor(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Quantité: ${item.quantity}',
                          style: AppTextStyles.foodItemDescription.copyWith(
                            fontSize: 12,
                            color: AppColors.getSecondaryTextColor(context),
                          ),
                        ),
                        // Afficher les garnitures
                        if (item.selectedGarnitures.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Garnitures: ${item.selectedGarnitures.map((g) => g.name).join(', ')}',
                            style: AppTextStyles.foodItemDescription.copyWith(
                              fontSize: 11,
                              color: AppColors.getSecondaryTextColor(context),
                            ),
                          ),
                        ],
                        // Afficher les extras
                        if (item.selectedExtras.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Extras: ${item.selectedExtras.map((e) => e.name).join(', ')}',
                            style: AppTextStyles.foodItemDescription.copyWith(
                              fontSize: 11,
                              color: AppColors.getSecondaryTextColor(context),
                            ),
                          ),
                        ],
                        // Afficher les instructions si présentes
                        if (item.instructions.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Instructions: ${item.instructions}',
                            style: AppTextStyles.foodItemDescription.copyWith(
                              fontSize: 11,
                              color: AppColors.getSecondaryTextColor(context),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    '${item.totalPrice.toStringAsFixed(0)} FCFA',
                    style: AppTextStyles.foodItemPrice.copyWith(
                      fontSize: 14,
                      color: AppColors.getPrimaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(color: AppColors.getBorderColor(context)),
          // Sous-total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sous-total',
                style: AppTextStyles.foodItemDescription.copyWith(
                  color: AppColors.getSecondaryTextColor(context),
                ),
              ),
              Text(
                '${subtotal.toStringAsFixed(0)} FCFA',
                style: AppTextStyles.foodItemDescription.copyWith(
                  color: AppColors.getSecondaryTextColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Frais de livraison
          if (deliveryFee > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Frais de livraison',
                  style: AppTextStyles.foodItemDescription.copyWith(
                    color: AppColors.getSecondaryTextColor(context),
                  ),
                ),
                Text(
                  '+ ${deliveryFee.toStringAsFixed(0)} FCFA',
                  style: AppTextStyles.foodItemDescription.copyWith(
                    color: AppColors.getSecondaryTextColor(context),
                  ),
                ),
              ],
            ),
          if (deliveryFee > 0) const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total ($itemCount article${itemCount > 1 ? 's' : ''})',
                style: AppTextStyles.foodItemTitle.copyWith(
                  fontSize: 16,
                  color: AppColors.getTextColor(context),
                ),
              ),
              Text(
                '${total.toStringAsFixed(0)} FCFA',
                style: AppTextStyles.foodItemPrice.copyWith(
                  fontSize: 20,
                  color: AppColors.getPrimaryColor(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceOrderButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _placeOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.getPrimaryColor(context),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: AppColors.getPrimaryColor(context).withOpacity(0.3),
        ),
        child: const Text(
          'Passer la commande',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
