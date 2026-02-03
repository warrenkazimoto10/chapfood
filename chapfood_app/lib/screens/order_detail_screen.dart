import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/text_styles.dart';
import '../models/order_model.dart';
import '../models/enums.dart';
import '../constants/app_colors.dart';
import '../services/delivery_code_service.dart';
import '../services/delivery_tracking_service.dart';
import '../widgets/realtime_map_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? _deliveryCodeStatus;
  Timer? _codeTimer;
  bool _isGeneratingCode = false;
  bool? _hasAssignedDriver; // État local pour vérifier l'assignation du livreur
  OrderModel? _currentOrder; // Ordre mis à jour avec l'assignation

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _loadDeliveryCodeStatus();
    _checkDriverAssignment();
  }

  @override
  void dispose() {
    _codeTimer?.cancel();
    super.dispose();
  }

  /// Vérifie si un livreur est assigné à la commande
  Future<void> _checkDriverAssignment() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('order_driver_assignments')
          .select('driver_id')
          .eq('order_id', widget.order.id)
          .maybeSingle();

      // Vérifier que delivered_at est null (livraison non terminée)
      final hasDriver =
          response != null &&
          response['driver_id'] != null &&
          (response['delivered_at'] == null);

      if (mounted) {
        setState(() {
          _hasAssignedDriver = hasDriver;
          // Mettre à jour l'ordre avec l'information d'assignation
          if (hasDriver) {
            _currentOrder = OrderModel(
              id: widget.order.id,
              userId: widget.order.userId,
              customerPhone: widget.order.customerPhone,
              customerName: widget.order.customerName,
              deliveryType: widget.order.deliveryType,
              deliveryAddress: widget.order.deliveryAddress,
              deliveryLat: widget.order.deliveryLat,
              deliveryLng: widget.order.deliveryLng,
              paymentMethod: widget.order.paymentMethod,
              paymentNumber: widget.order.paymentNumber,
              subtotal: widget.order.subtotal,
              deliveryFee: widget.order.deliveryFee,
              totalAmount: widget.order.totalAmount,
              status: widget.order.status,
              instructions: widget.order.instructions,
              estimatedDeliveryTime: widget.order.estimatedDeliveryTime,
              actualDeliveryTime: widget.order.actualDeliveryTime,
              createdAt: widget.order.createdAt,
              updatedAt: widget.order.updatedAt,
              preparationTime: widget.order.preparationTime,
              kitchenNotes: widget.order.kitchenNotes,
              acceptedAt: widget.order.acceptedAt,
              rejectedAt: widget.order.rejectedAt,
              readyAt: widget.order.readyAt,
              driverId: response['driver_id'] as int?,
              hasAssignedDriver: true,
              orderItems: widget.order.orderItems,
            );
          }
        });
      }
    } catch (e) {
      print('Erreur lors de la vérification de l\'assignation du livreur: $e');
      if (mounted) {
        setState(() {
          _hasAssignedDriver = false;
        });
      }
    }
  }

  Future<void> _loadDeliveryCodeStatus() async {
    final status = await DeliveryCodeService.getDeliveryCodeStatus(
      widget.order.id,
    );
    if (mounted) {
      setState(() {
        _deliveryCodeStatus = status;
      });

      // Si le code est actif, démarrer le timer pour les mises à jour
      if (status?['status'] == 'active') {
        _startCodeTimer();
      }
    }
  }

  void _startCodeTimer() {
    _codeTimer?.cancel();
    _codeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_deliveryCodeStatus?['secondsUntilExpiry'] != null) {
            _deliveryCodeStatus!['secondsUntilExpiry'] =
                _deliveryCodeStatus!['secondsUntilExpiry'] - 1;

            if (_deliveryCodeStatus!['secondsUntilExpiry'] <= 0) {
              _deliveryCodeStatus!['status'] = 'expired';
              timer.cancel();
            }
          }
        });
      }
    });
  }

  Future<void> _generateDeliveryCode() async {
    setState(() {
      _isGeneratingCode = true;
    });

    try {
      final result = await DeliveryCodeService.generateDeliveryCode(
        widget.order.id,
      );

      if (result['success'] == true) {
        await _loadDeliveryCodeStatus();
        _startCodeTimer();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Code généré: ${result['deliveryCode']}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingCode = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getSurfaceColor(context),
      appBar: AppBar(
        title: Text(
          'Commande #${widget.order.id}',
          style: TextStyle(color: AppColors.getTextColor(context)),
        ),
        backgroundColor: AppColors.getCardColor(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.getTextColor(context)),
        titleTextStyle: AppTextStyles.foodItemTitle.copyWith(
          fontSize: 18,
          color: AppColors.getTextColor(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de la commande
            _buildOrderHeader(),
            const SizedBox(height: 16),

            // Informations de livraison
            _buildDeliveryInfo(),
            const SizedBox(height: 16),

            // Détails des articles
            _buildOrderItems(),
            const SizedBox(height: 16),

            // Résumé des prix
            _buildPriceSummary(),
            const SizedBox(height: 24),

            // QR Code
            _buildQRCode(),
            const SizedBox(height: 24),

            // Code de livraison
            _buildDeliveryCodeSection(),
            const SizedBox(height: 16),

            // Statut de la commande
            _buildOrderStatus(),
            const SizedBox(height: 16),

            // Bouton de suivi (si en transit)
            if (_canTrackOrder()) _buildTrackingButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
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
                  color: AppColors.primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: AppColors.primaryRed,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commande #${widget.order.id}',
                      style: AppTextStyles.foodItemTitle.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Passée le ${_formatDate(widget.order.createdAt ?? DateTime.now())}',
                      style: AppTextStyles.foodItemDescription,
                    ),
                  ],
                ),
              ),
              _buildStatusChip(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.order.deliveryType == DeliveryType.delivery
                    ? Icons.delivery_dining
                    : Icons.store,
                color: AppColors.primaryRed,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.order.deliveryType == DeliveryType.delivery
                    ? 'Livraison'
                    : 'À emporter',
                style: AppTextStyles.foodItemTitle.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.order.deliveryAddress != null &&
              widget.order.deliveryAddress!.isNotEmpty)
            Text(
              widget.order.deliveryAddress!,
              style: AppTextStyles.foodItemDescription,
            ),
          const SizedBox(height: 8),
          Text(
            '${widget.order.customerName} • ${widget.order.customerPhone}',
            style: AppTextStyles.foodItemDescription,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Articles commandés',
            style: AppTextStyles.foodItemTitle.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ...widget.order.orderItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl:
                          item.menuItem?.imageUrl ??
                          'https://via.placeholder.com/300x200',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 60,
                        height: 60,
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
                          item.itemName,
                          style: AppTextStyles.foodItemTitle.copyWith(
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Quantité: ${item.quantity}',
                          style: AppTextStyles.foodItemDescription.copyWith(
                            fontSize: 12,
                          ),
                        ),
                        if (item.selectedGarnitures.isNotEmpty)
                          Text(
                            'Garnitures: ${item.selectedGarnitures.join(', ')}',
                            style: AppTextStyles.foodItemDescription.copyWith(
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (item.selectedExtras.isNotEmpty)
                          Text(
                            'Suppléments: ${item.selectedExtras.join(', ')}',
                            style: AppTextStyles.foodItemDescription.copyWith(
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '${item.totalPrice.toStringAsFixed(0)} FCFA',
                    style: AppTextStyles.foodItemPrice.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            'Sous-total:',
            '${widget.order.subtotal.toStringAsFixed(0)} FCFA',
          ),
          if (widget.order.deliveryFee != null && widget.order.deliveryFee! > 0)
            _buildSummaryRow(
              'Frais de livraison:',
              '${widget.order.deliveryFee!.toStringAsFixed(0)} FCFA',
            ),
          const Divider(),
          _buildSummaryRow(
            'Total:',
            '${widget.order.totalAmount.toStringAsFixed(0)} FCFA',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildQRCode() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Code QR de la commande',
            style: AppTextStyles.foodItemTitle.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 16),
          QrImageView(
            data: 'order:${widget.order.id}',
            version: QrVersions.auto,
            size: 200.0,
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
          const SizedBox(height: 12),
          Text(
            'Montrez ce code au restaurant pour récupérer votre commande',
            style: AppTextStyles.foodItemDescription.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCodeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: AppColors.primaryRed, size: 20),
              const SizedBox(width: 8),
              Text(
                'Code de confirmation de livraison',
                style: AppTextStyles.foodItemTitle.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_deliveryCodeStatus == null) ...[
            const Center(child: CircularProgressIndicator()),
          ] else if (_deliveryCodeStatus!['status'] == 'no_code') ...[
            _buildNoCodeState(),
          ] else if (_deliveryCodeStatus!['status'] == 'active') ...[
            _buildActiveCodeState(),
          ] else if (_deliveryCodeStatus!['status'] == 'expired') ...[
            _buildExpiredCodeState(),
          ] else if (_deliveryCodeStatus!['status'] == 'confirmed') ...[
            _buildConfirmedCodeState(),
          ],
        ],
      ),
    );
  }

  Widget _buildNoCodeState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              Icon(Icons.qr_code, size: 48, color: Colors.grey[600]),
              const SizedBox(height: 8),
              Text(
                'Aucun code généré',
                style: AppTextStyles.foodItemDescription.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Générez un code pour que le livreur puisse confirmer la livraison',
                style: AppTextStyles.foodItemDescription.copyWith(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isGeneratingCode ? null : _generateDeliveryCode,
            icon: _isGeneratingCode
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            label: Text(
              _isGeneratingCode ? 'Génération...' : 'Générer un code',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveCodeState() {
    final code = _deliveryCodeStatus!['deliveryCode'] as String;
    final secondsUntilExpiry =
        _deliveryCodeStatus!['secondsUntilExpiry'] as int;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 48, color: Colors.green[600]),
              const SizedBox(height: 12),
              Text(
                'Code actif',
                style: AppTextStyles.foodItemTitle.copyWith(
                  color: Colors.green[700],
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer, size: 16, color: Colors.orange[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Expire dans: ${DeliveryCodeService.formatTimeUntilExpiry(secondsUntilExpiry)}',
                    style: AppTextStyles.foodItemDescription.copyWith(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Donnez ce code au livreur pour confirmer la livraison',
                  style: AppTextStyles.foodItemDescription.copyWith(
                    fontSize: 12,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpiredCodeState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Column(
            children: [
              Icon(Icons.timer_off, size: 48, color: Colors.red[600]),
              const SizedBox(height: 8),
              Text(
                'Code expiré',
                style: AppTextStyles.foodItemTitle.copyWith(
                  color: Colors.red[700],
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Le code a expiré. Générez un nouveau code.',
                style: AppTextStyles.foodItemDescription.copyWith(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isGeneratingCode ? null : _generateDeliveryCode,
            icon: _isGeneratingCode
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: Text(
              _isGeneratingCode ? 'Génération...' : 'Générer un nouveau code',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmedCodeState() {
    final confirmedAt = _deliveryCodeStatus!['confirmedAt'] as String;
    final confirmedBy = _deliveryCodeStatus!['confirmedBy'] as String;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline, size: 48, color: Colors.green[600]),
          const SizedBox(height: 8),
          Text(
            'Livraison confirmée',
            style: AppTextStyles.foodItemTitle.copyWith(
              color: Colors.green[700],
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Confirmée le ${_formatDate(DateTime.parse(confirmedAt))}',
            style: AppTextStyles.foodItemDescription.copyWith(fontSize: 12),
          ),
          if (confirmedBy.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Par: $confirmedBy',
              style: AppTextStyles.foodItemDescription.copyWith(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statut de la commande',
            style: AppTextStyles.foodItemTitle.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatusChip(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getStatusDescription(),
                  style: AppTextStyles.foodItemDescription,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    Color statusColor;
    switch (widget.order.status) {
      case OrderStatus.pending:
        statusColor = Colors.orange;
        break;
      case OrderStatus.accepted:
        statusColor = Colors.blue;
        break;
      case OrderStatus.readyForDelivery:
        statusColor = Colors.purple;
        break;
      case OrderStatus.pickedUp:
        statusColor = Colors.green;
        break;
      case OrderStatus.inTransit:
        statusColor = Colors.green;
        break;
      case OrderStatus.delivered:
        statusColor = Colors.green;
        break;
      case OrderStatus.cancelled:
        statusColor = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Text(
        _getStatusText(),
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? AppTextStyles.foodItemTitle.copyWith(fontSize: 16)
                : AppTextStyles.foodItemDescription.copyWith(fontSize: 14),
          ),
          Text(
            value,
            style: isTotal
                ? AppTextStyles.foodItemPrice.copyWith(fontSize: 18)
                : AppTextStyles.foodItemTitle.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getStatusText() {
    switch (widget.order.status) {
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.accepted:
        return 'Acceptée';
      case OrderStatus.readyForDelivery:
        return 'Prête à être livrée';
      case OrderStatus.pickedUp:
        return 'Repas récupéré';
      case OrderStatus.inTransit:
        return 'En route';
      case OrderStatus.delivered:
        return 'Livrée';
      case OrderStatus.cancelled:
        return 'Annulée';
    }
  }

  String _getStatusDescription() {
    switch (widget.order.status) {
      case OrderStatus.pending:
        return 'Votre commande est en cours de traitement';
      case OrderStatus.accepted:
        return 'Votre commande a été acceptée par le restaurant';
      case OrderStatus.readyForDelivery:
        return 'Votre commande est prête pour la livraison';
      case OrderStatus.pickedUp:
        return 'Le livreur a récupéré votre commande et vient vers vous';
      case OrderStatus.inTransit:
        return 'Votre commande est en cours de livraison';
      case OrderStatus.delivered:
        return 'Votre commande a été livrée';
      case OrderStatus.cancelled:
        return 'Votre commande a été annulée';
    }
  }

  bool _canTrackOrder() {
    final order = _currentOrder ?? widget.order;
    final hasDriver =
        _hasAssignedDriver ??
        order.hasAssignedDriver ??
        (order.driverId != null);
    return (order.status == OrderStatus.readyForDelivery ||
            order.status == OrderStatus.pickedUp ||
            order.status == OrderStatus.inTransit) &&
        order.deliveryType == DeliveryType.delivery &&
        hasDriver;
  }

  Widget _buildTrackingButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
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
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.track_changes,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suivi en temps réel',
                      style: AppTextStyles.foodItemTitle.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Suivez votre livreur en direct',
                      style: AppTextStyles.foodItemDescription,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _navigateToRealtimeMap,
              icon: const Icon(Icons.location_on, size: 20),
              label: const Text('Suivre ma commande'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToRealtimeMap() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final deliveryData = await DeliveryTrackingService.getDeliveryDetails(
        widget.order.id,
      );

      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (deliveryData != null && context.mounted) {
        final orderData = deliveryData['order'] as OrderModel;
        final driver = deliveryData['driver'];

        double customerLat = 5.3700;
        double customerLng = -4.0200;
        if (orderData.deliveryLat != null &&
            orderData.deliveryLng != null &&
            orderData.deliveryLat!.isFinite &&
            orderData.deliveryLng!.isFinite) {
          customerLat = orderData.deliveryLat!;
          customerLng = orderData.deliveryLng!;
        }

        double driverLat = 5.3563;
        double driverLng = -4.0363;
        if (driver?.currentLat != null &&
            driver?.currentLng != null &&
            driver!.currentLat!.isFinite &&
            driver.currentLng!.isFinite) {
          driverLat = driver.currentLat!;
          driverLng = driver.currentLng!;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RealtimeMapWidget(
              orderId: widget.order.id.toString(),
              customerName: widget.order.customerName ?? 'Client',
              customerLatitude: customerLat,
              customerLongitude: customerLng,
              orderStatus: widget.order.status.value,
              driverName: driver?.name ?? 'Livreur ChapFood',
              driverPhone: driver?.phone ?? '+225 XX XX XX XX',
              driverLatitude: driverLat,
              driverLongitude: driverLng,
              onClose: () => Navigator.pop(context),
            ),
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Impossible de charger les informations de livraison',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
