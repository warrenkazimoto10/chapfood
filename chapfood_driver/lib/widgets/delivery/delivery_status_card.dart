import 'package:flutter/material.dart';
import '../../models/order_model.dart';

/// Widget pour afficher le statut de la livraison
class DeliveryStatusCard extends StatelessWidget {
  final OrderModel order;
  final bool hasPickedUp;
  final bool hasArrived;

  const DeliveryStatusCard({
    super.key,
    required this.order,
    this.hasPickedUp = false,
    this.hasArrived = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Statut de la livraison',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatusStep(
              context,
              'Étape 1 : Aller au restaurant',
              hasPickedUp, // Complétée quand récupéré
              Icons.restaurant,
              hasPickedUp ? Colors.green : Colors.orange,
              isCurrent: !hasPickedUp,
            ),
            _buildStatusStep(
              context,
              'Étape 2 : Récupérer le repas',
              hasPickedUp,
              Icons.local_shipping,
              hasPickedUp ? Colors.green : Colors.grey,
              isCurrent: false, // L'action se fait via le bouton
            ),
            _buildStatusStep(
              context,
              'Étape 3 : Aller chez le client',
              hasArrived, // Complétée quand arrivé
              Icons.directions_car,
              hasPickedUp && !hasArrived ? Colors.orange : (hasArrived ? Colors.green : Colors.grey),
              isCurrent: hasPickedUp && !hasArrived,
            ),
            _buildStatusStep(
              context,
              'Étape 4 : Arrivé au point de livraison',
              order.status.value == 'delivered', // Complétée quand livré
              Icons.location_on,
              hasArrived ? Colors.orange : Colors.grey,
              isCurrent: hasArrived && order.status.value != 'delivered',
            ),
            _buildStatusStep(
              context,
              'Étape 5 : Livraison finalisée',
              order.status.value == 'delivered',
              Icons.check_circle_outline,
              order.status.value == 'delivered' ? Colors.green : Colors.grey,
              isCurrent: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusStep(
    BuildContext context,
    String label,
    bool isCompleted,
    IconData icon,
    Color color, {
    bool isCurrent = false,
  }) {
    // Déterminer si c'est l'étape actuelle (en cours)
    final isCurrentStep = isCurrent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCurrentStep ? color.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isCurrentStep ? Border.all(color: color, width: 2) : null,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isCompleted || isCurrentStep ? Colors.black87 : Colors.grey,
                    fontWeight: (isCompleted || isCurrentStep) ? FontWeight.w600 : FontWeight.normal,
                    decoration: isCompleted
                        ? TextDecoration.none
                        : (isCurrentStep ? TextDecoration.none : TextDecoration.lineThrough),
                  ),
                ),
                if (isCurrentStep)
                  Text(
                    'En cours...',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          if (isCompleted)
            Icon(Icons.check, color: Colors.green, size: 20),
          if (isCurrentStep && !isCompleted)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
        ],
      ),
    );
  }
}
