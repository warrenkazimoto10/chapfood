import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/cart_service.dart';
import '../utils/text_styles.dart';
import '../constants/app_colors.dart';
import 'order_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> _cartItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final items = await CartService.getCartItems();
      setState(() {
        _cartItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement du panier: $e'),
          backgroundColor: AppColors.primaryRed,
        ),
      );
    }
  }

  Future<void> _updateQuantity(int index, int newQuantity) async {
    if (newQuantity <= 0) {
      await _removeItem(index);
    } else {
      await CartService.updateQuantity(index, newQuantity);
      await _loadCartItems();
    }
  }

  Future<void> _removeItem(int index) async {
    await CartService.removeFromCart(index);
    await _loadCartItems();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Article supprimé du panier'),
        backgroundColor: AppColors.primaryRed,
      ),
    );
  }

  Future<void> _clearCart() async {
    await CartService.clearCart();
    await _loadCartItems();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Panier vidé'),
        backgroundColor: AppColors.primaryRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getSurfaceColor(context),
      appBar: AppBar(
        title: Text(
          'Mon Panier',
          style: TextStyle(color: AppColors.getTextColor(context)),
        ),
        backgroundColor: AppColors.getCardColor(context),
        foregroundColor: AppColors.getTextColor(context),
        elevation: 0,
        actions: [
          if (_cartItems.isNotEmpty)
            IconButton(
              onPressed: _clearCart,
              icon: const FaIcon(
                FontAwesomeIcons.trash,
                color: AppColors.primaryRed,
                size: 20,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
              ? _buildEmptyCart()
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _cartItems.length,
                        itemBuilder: (context, index) {
                          return _buildCartItem(_cartItems[index], index);
                        },
                      ),
                    ),
                    _buildCartSummary(),
                  ],
                ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.getCardColor(context),
              shape: BoxShape.circle,
            ),
            child: const FaIcon(
              FontAwesomeIcons.shoppingCart,
              size: 64,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Votre panier est vide',
            style: AppTextStyles.foodItemTitle.copyWith(
              fontSize: 24,
              color: AppColors.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des plats délicieux à votre panier',
            style: AppTextStyles.foodItemDescription.copyWith(
              fontSize: 16,
              color: AppColors.getSecondaryTextColor(context),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Continuer mes achats',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getBorderColor(context),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Image du plat
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.menuItem.imageUrl ?? 'https://via.placeholder.com/300x200',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.restaurant, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Informations du plat
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.menuItem.name,
                        style: AppTextStyles.foodItemTitle.copyWith(
                          fontSize: 18,
                          color: AppColors.getTextColor(context),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.totalPrice.toStringAsFixed(0)} FCFA',
                        style: AppTextStyles.foodItemPrice.copyWith(
                          fontSize: 16,
                          color: AppColors.getPrimaryColor(context),
                        ),
                      ),
                      if (item.selectedGarnitures.isNotEmpty || item.selectedExtras.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item.selectedGarnitures.isNotEmpty)
                                ...item.selectedGarnitures.map((garniture) => Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    '• ${garniture.name}',
                                    style: AppTextStyles.foodItemDescription.copyWith(
                                      fontSize: 12,
                                      color: AppColors.getSecondaryTextColor(context),
                                    ),
                                  ),
                                )),
                              if (item.selectedExtras.isNotEmpty)
                                ...item.selectedExtras.map((extra) => Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    '• ${extra.name}',
                                    style: AppTextStyles.foodItemDescription.copyWith(
                                      fontSize: 12,
                                      color: AppColors.getSecondaryTextColor(context),
                                    ),
                                  ),
                                )),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                // Bouton de suppression
                IconButton(
                  onPressed: () => _removeItem(index),
                  icon: const FaIcon(
                    FontAwesomeIcons.trash,
                    color: Colors.red,
                    size: 16,
                  ),
                ),
              ],
            ),
            // Contrôles de quantité
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Boutons de quantité
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _updateQuantity(index, item.quantity - 1),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.getBorderColor(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.remove, 
                          size: 16,
                          color: AppColors.getTextColor(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      item.quantity.toString(),
                      style: AppTextStyles.foodItemTitle.copyWith(
                        fontSize: 18,
                        color: AppColors.getTextColor(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _updateQuantity(index, item.quantity + 1),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.getPrimaryColor(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
                // Prix total de l'article
                Text(
                  '${item.totalPrice.toStringAsFixed(0)} FCFA',
                  style: AppTextStyles.foodItemPrice.copyWith(
                    fontSize: 18,
                    color: AppColors.getPrimaryColor(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary() {
    final total = _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    final itemCount = _cartItems.fold(0, (sum, item) => sum + item.quantity);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        border: Border(
          top: BorderSide(
            color: AppColors.getBorderColor(context),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total ($itemCount article${itemCount > 1 ? 's' : ''})',
                style: AppTextStyles.foodItemTitle.copyWith(
                  fontSize: 18,
                  color: AppColors.getTextColor(context),
                ),
              ),
              Text(
                '${total.toStringAsFixed(0)} FCFA',
                style: AppTextStyles.foodItemPrice.copyWith(
                  fontSize: 24,
                  color: AppColors.getPrimaryColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OrderScreen()),
              );
            },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getPrimaryColor(context),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
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
          ),
        ],
      ),
    );
  }
}
