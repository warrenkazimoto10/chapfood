import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../models/order_model.dart';
import '../constants/restaurant_config.dart';
import '../constants/app_colors.dart';
import '../services/geocoding_service.dart';
import 'slidable_accept_button.dart';

class OrderNotificationSheet extends StatefulWidget {
  final OrderModel order;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const OrderNotificationSheet({
    super.key,
    required this.order,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<OrderNotificationSheet> createState() => _OrderNotificationSheetState();
}

class _OrderNotificationSheetState extends State<OrderNotificationSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Timer _countdownTimer;
  int _secondsRemaining = 60;
  String? _resolvedAddress;
  bool _isResolvingAddress = false;

  @override
  void initState() {
    super.initState();

    // Vibration au démarrage
    HapticFeedback.vibrate();

    // Animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();

    // Timer countdown
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        _handleReject();
      }
    });
    
    // Résoudre l'adresse si elle est vide
    _resolveAddressIfNeeded();
  }
  
  Future<void> _resolveAddressIfNeeded() async {
    if ((widget.order.deliveryAddress == null || widget.order.deliveryAddress!.isEmpty) &&
        widget.order.deliveryLat != null &&
        widget.order.deliveryLng != null) {
      setState(() {
        _isResolvingAddress = true;
      });
      
      final address = await GeocodingService.getShortAddress(
        widget.order.deliveryLat!,
        widget.order.deliveryLng!,
      );
      
      if (mounted) {
        setState(() {
          _resolvedAddress = address;
          _isResolvingAddress = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _countdownTimer.cancel();
    super.dispose();
  }

  Future<void> _handleAccept() async {
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
      widget.onAccept();
    }
  }

  void _handleReject() {
    _countdownTimer.cancel();
    Navigator.of(context).pop();
    widget.onReject();
  }

  Color _getTimerColor() {
    if (_secondsRemaining > 30) return Colors.green;
    if (_secondsRemaining > 10) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Empêcher la fermeture par swipe
        return false;
      },
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Contenu scrollable
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Commande #${widget.order.id}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.secondary,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      'Nouvelle',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Icône + Timer
                              Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[800],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.notifications_active,
                                      color: AppColors.secondary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '00:${_secondsRemaining.toString().padLeft(2, '0')}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _getTimerColor(),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Restaurant Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildInfoRow(
                                  icon: Icons.restaurant,
                                  label: 'Restaurant',
                                  value: RestaurantConfig.name,
                                  iconColor: Colors.orange[300]!,
                                ),
                                const Divider(color: Colors.grey, height: 24),
                                _buildInfoRow(
                                  icon: Icons.location_on_outlined,
                                  label: 'Adresse restaurant',
                                  value: RestaurantConfig.address,
                                  iconColor: Colors.red[300]!,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Client Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildInfoRow(
                                  icon: Icons.person_outline,
                                  label: 'Client',
                                  value: widget.order.customerName ??
                                      widget.order.customerPhone,
                                  iconColor: Colors.blue[300]!,
                                ),
                                const Divider(color: Colors.grey, height: 24),
                                _buildInfoRow(
                                  icon: Icons.location_on_outlined,
                                  label: 'Adresse de livraison',
                                  value: _isResolvingAddress
                                      ? 'Chargement...'
                                      : _resolvedAddress ??
                                          widget.order.deliveryAddress ??
                                          (widget.order.deliveryLat != null && widget.order.deliveryLng != null
                                              ? 'Lat: ${widget.order.deliveryLat!.toStringAsFixed(4)}, Lng: ${widget.order.deliveryLng!.toStringAsFixed(4)}'
                                              : 'Non spécifiée'),
                                  iconColor: Colors.green[300]!,
                                  maxLines: 2,
                                ),
                                const Divider(color: Colors.grey, height: 24),
                                _buildInfoRow(
                                  icon: Icons.attach_money,
                                  label: 'Montant total',
                                  value:
                                      '${widget.order.totalAmount.toStringAsFixed(0)} FCFA',
                                  iconColor: AppColors.secondary,
                                  valueColor: AppColors.secondary,
                                  isBold: true,
                                ),
                                if (widget.order.deliveryFee != null) ...[
                                  const Divider(color: Colors.grey, height: 24),
                                  _buildInfoRow(
                                    icon: Icons.delivery_dining,
                                    label: 'Frais de livraison',
                                    value:
                                        '${widget.order.deliveryFee!.toStringAsFixed(0)} FCFA',
                                    iconColor: Colors.yellow[700]!,
                                    valueColor: Colors.yellow[700]!,
                                    isBold: true,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Bouton Glisser pour accepter
                          SlidableAcceptButton(
                            onAccept: _handleAccept,
                            text: 'Glisser pour accepter',
                          ),
                          const SizedBox(height: 16),

                          // Bouton Refuser
                          Center(
                            child: TextButton(
                              onPressed: _handleReject,
                              child: Text(
                                'Refuser',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    Color? valueColor,
    int maxLines = 1,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  color: valueColor ?? Colors.black87,
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
