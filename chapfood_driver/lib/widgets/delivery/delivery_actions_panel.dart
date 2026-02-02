import 'package:flutter/material.dart';

/// Panneau d'actions pour la livraison
class DeliveryActionsPanel extends StatelessWidget {
  final bool hasPickedUp;
  final bool hasArrived;
  final VoidCallback? onMarkPickedUp;
  final VoidCallback? onMarkArrived;
  final VoidCallback? onCompleteDelivery;

  const DeliveryActionsPanel({
    super.key,
    this.hasPickedUp = false,
    this.hasArrived = false,
    this.onMarkPickedUp,
    this.onMarkArrived,
    this.onCompleteDelivery,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!hasPickedUp)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onMarkPickedUp,
                  icon: const Icon(Icons.restaurant),
                  label: const Text('Récupérer'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            if (hasPickedUp && !hasArrived) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onMarkArrived,
                  icon: const Icon(Icons.location_on),
                  label: const Text('Je suis arrivé'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
            if (hasArrived) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onCompleteDelivery,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Finaliser la livraison'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
