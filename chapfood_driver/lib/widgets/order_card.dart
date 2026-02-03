import 'package:flutter/material.dart';
import '../models/order_model.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;

  const OrderCard({super.key, required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec numéro de commande et statut
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '#${order.id}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(order.status),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      order.status.displayName,
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Informations client
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.customerName ?? 'Client',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    order.customerPhone,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Adresse de livraison
              if (order.deliveryAddress != null) ...[
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.deliveryAddress!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Informations de paiement et montant
              Row(
                children: [
                  Icon(
                    _getPaymentIcon(order.paymentMethod),
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    order.paymentMethod.displayName,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Text(
                    '${order.totalAmount.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE94560),
                    ),
                  ),
                ],
              ),

              // Instructions spéciales
              if (order.instructions != null &&
                  order.instructions!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.instructions!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Ouvrir les détails de la commande
                      },
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text('Détails'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE94560),
                        side: const BorderSide(color: Color(0xFFE94560)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Marquer comme récupérée/livrée selon le statut
                      },
                      icon: Icon(_getActionIcon(order.status), size: 16),
                      label: Text(_getActionText(order.status)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE94560),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.accepted:
        return Colors.blue;
      case OrderStatus.readyForDelivery:
        return Colors.green;
      case OrderStatus.pickedUp:
        return Colors.teal;
      case OrderStatus.inTransit:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green[700]!;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getPaymentIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.wave:
        return Icons.account_balance_wallet;
      case PaymentMethod.orangeMoney:
        return Icons.phone_android;
    }
  }

  IconData _getActionIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.readyForDelivery:
        return Icons.local_shipping;
      case OrderStatus.inTransit:
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  String _getActionText(OrderStatus status) {
    switch (status) {
      case OrderStatus.readyForDelivery:
        return 'Récupérer';
      case OrderStatus.inTransit:
        return 'Livrer';
      default:
        return 'Voir';
    }
  }
}
