import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/text_styles.dart';
import '../models/order_model.dart';
import '../constants/app_colors.dart';
import 'order_detail_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final OrderModel order;

  const OrderConfirmationScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getSurfaceColor(context),
      body: Stack(
        children: [
          // Bandeau décoratif
          Container(
            height: 260,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF3B30), Color(0xFFFFA726)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'Commande confirmée',
                    style: AppTextStyles.foodItemTitle.copyWith(
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Numéro: #${order.id}',
                    style: AppTextStyles.foodItemDescription.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Carte centrale avec animation
                  Expanded(
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.9, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutBack,
                        builder: (context, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.getCardColor(context),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.getBorderColor(context),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Détails de la commande',
                                  style: AppTextStyles.foodItemTitle.copyWith(
                                    fontSize: 18,
                                    color: AppColors.getTextColor(context),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ...order.orderItems.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl:
                                                item.menuItem?.imageUrl ??
                                                'https://via.placeholder.com/300x200',
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Container(
                                                  width: 50,
                                                  height: 50,
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                    Icons.image,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Container(
                                                      width: 50,
                                                      height: 50,
                                                      color: Colors.grey[300],
                                                      child: const Icon(
                                                        Icons.restaurant,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.itemName,
                                                style: AppTextStyles
                                                    .foodItemTitle
                                                    .copyWith(fontSize: 14),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                'Quantité: ${item.quantity}',
                                                style: AppTextStyles
                                                    .foodItemDescription
                                                    .copyWith(fontSize: 12),
                                              ),
                                              // Afficher les garnitures si présentes
                                              if (item
                                                  .selectedGarnitures
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Garnitures: ${item.selectedGarnitures.join(', ')}',
                                                  style: AppTextStyles
                                                      .foodItemDescription
                                                      .copyWith(fontSize: 11),
                                                ),
                                              ],
                                              // Afficher les extras si présents
                                              if (item
                                                  .selectedExtras
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Extras: ${item.selectedExtras.join(', ')}',
                                                  style: AppTextStyles
                                                      .foodItemDescription
                                                      .copyWith(fontSize: 11),
                                                ),
                                              ],
                                              // Afficher les instructions si présentes
                                              if (item
                                                      .instructions
                                                      ?.isNotEmpty ==
                                                  true) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Instructions: ${item.instructions}',
                                                  style: AppTextStyles
                                                      .foodItemDescription
                                                      .copyWith(
                                                        fontSize: 11,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '${item.totalPrice.toStringAsFixed(0)} FCFA',
                                          style: AppTextStyles.foodItemPrice
                                              .copyWith(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Divider(),
                                _buildSummaryRow(
                                  'Sous-total:',
                                  '${(order.subtotal ?? 0).toStringAsFixed(0)} FCFA',
                                ),
                                if ((order.deliveryFee ?? 0) > 0)
                                  _buildSummaryRow(
                                    'Frais de livraison:',
                                    '${(order.deliveryFee ?? 0).toStringAsFixed(0)} FCFA',
                                  ),
                                const Divider(),
                                _buildSummaryRow(
                                  'Total:',
                                  '${(order.totalAmount ?? 0).toStringAsFixed(0)} FCFA',
                                  isTotal: true,
                                ),
                                const SizedBox(height: 24),
                                QrImageView(
                                  data: 'order:${order.id}',
                                  version: QrVersions.auto,
                                  size: 180.0,
                                  gapless: true,
                                  errorStateBuilder: (cxt, err) {
                                    return const Center(
                                      child: Text(
                                        "Impossible de générer le QR Code",
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Rediriger vers la page de détails de la commande
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) =>
                                OrderDetailScreen(order: order),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B30),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Fermer',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? AppTextStyles.foodItemTitle.copyWith(fontSize: 18)
                : AppTextStyles.foodItemDescription.copyWith(fontSize: 14),
          ),
          Text(
            value,
            style: isTotal
                ? AppTextStyles.foodItemPrice.copyWith(fontSize: 20)
                : AppTextStyles.foodItemTitle.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
