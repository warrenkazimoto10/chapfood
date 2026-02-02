import 'package:flutter/material.dart';
import '../models/order_model.dart';
import 'slidable_accept_button.dart';

/// Composant bottom sheet pour afficher les notifications de commandes
class OrderNotificationBottomSheet extends StatefulWidget {
  final OrderModel order;
  final VoidCallback onAccept;
  final VoidCallback onCancel;

  const OrderNotificationBottomSheet({
    super.key,
    required this.order,
    required this.onAccept,
    required this.onCancel,
  });

  @override
  State<OrderNotificationBottomSheet> createState() =>
      _OrderNotificationBottomSheetState();
}

class _OrderNotificationBottomSheetState
    extends State<OrderNotificationBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 1), // Commence en bas
          end: Offset.zero, // Se termine en position normale
        ).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Démarrer l'animation d'entrée
    _animationController.forward();
  }

  Future<void> _handleAccept() async {
    // Animation de sortie avant d'accepter
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
      widget.onAccept();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Quand l'utilisateur ferme en glissant vers le bas
        widget.onCancel();
        return true;
      },
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1F1F1F), // Fond noir/gris foncé
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Indicateur de glissement (slide handle)
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Contenu de la notification (scrollable)
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
                          // En-tête avec ID de commande
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Commande #${widget.order.id}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFFF6B35,
                                      ).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFFF6B35),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Text(
                                      'Nouvelle',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFFF6B35),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Icône de notification
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.notifications_active,
                                  color: Color(0xFFFF6B35),
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Informations de la commande dans un card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey[800]!,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildInfoCard(
                                  icon: Icons.person_outline,
                                  label: 'Client',
                                  value:
                                      widget.order.customerName ??
                                      widget.order.customerPhone,
                                  iconColor: Colors.blue[300]!,
                                ),
                                const Divider(color: Colors.grey, height: 24),
                                _buildInfoCard(
                                  icon: Icons.location_on_outlined,
                                  label: 'Adresse de livraison',
                                  value:
                                      widget.order.deliveryAddress ??
                                      'Non spécifiée',
                                  iconColor: Colors.red[300]!,
                                  maxLines: 2,
                                ),
                                const Divider(color: Colors.grey, height: 24),
                                _buildInfoCard(
                                  icon: Icons.attach_money,
                                  label: 'Montant total',
                                  value:
                                      '${widget.order.totalAmount.toStringAsFixed(0)} FCFA',
                                  iconColor: const Color(0xFFFF6B35),
                                  valueColor: const Color(0xFFFF6B35),
                                  isBold: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Bouton Slidable Accepter
                          SlidableAcceptButton(
                            onAccept: _handleAccept,
                            text: 'Glisser pour accepter',
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

  Widget _buildInfoCard({
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
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  color: valueColor ?? Colors.white,
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
