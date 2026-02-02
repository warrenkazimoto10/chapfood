import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/menu_item_model.dart';
import '../models/supplement_model.dart';
import '../models/enums.dart';
import '../services/menu_service.dart';
import '../services/cart_service.dart';
import '../utils/text_styles.dart';
import '../constants/app_colors.dart';

class FoodDetailModal extends StatefulWidget {
  final MenuItemModel menuItem;
  final VoidCallback? onItemAdded;

  const FoodDetailModal({super.key, required this.menuItem, this.onItemAdded});

  @override
  State<FoodDetailModal> createState() => _FoodDetailModalState();
}

class _FoodDetailModalState extends State<FoodDetailModal>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _tabController;
  late Animation<Offset> _slideAnimation;

  int _quantity = 1;
  int _selectedTabIndex = 0; // Index valide entre 0 et 2
  List<SupplementModel> _garnitures = [];
  List<SupplementModel> _extras = [];
  List<SupplementModel> _selectedGarnitures = [];
  List<SupplementModel> _selectedExtras = [];
  String _instructions = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadSupplements();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _tabController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _slideController.forward();
  }

  Future<void> _loadSupplements() async {
    try {
      // Charger les garnitures et extras depuis la base de données
      final garnitures = await MenuService.getGarnitures();
      final extras = await MenuService.getExtras();

      setState(() {
        _garnitures = garnitures;
        _extras = extras;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des suppléments: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  double get _totalPrice {
    double total = widget.menuItem.price * _quantity;

    for (var garniture in _selectedGarnitures) {
      total += garniture.price * _quantity;
    }

    for (var extra in _selectedExtras) {
      total += extra.price * _quantity;
    }

    return total;
  }

  void _addToCart() async {
    try {
      await CartService.addToCart(
        menuItem: widget.menuItem,
        quantity: _quantity,
        selectedGarnitures: _selectedGarnitures,
        selectedExtras: _selectedExtras,
        instructions: _instructions,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.menuItem.name} ajouté au panier'),
            backgroundColor: AppColors.getPrimaryColor(context),
            action: SnackBarAction(
              label: 'Voir le panier',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Naviguer vers la page du panier
              },
            ),
          ),
        );
        // Appeler le callback pour mettre à jour le compteur
        widget.onItemAdded?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout au panier: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: screenHeight * 0.9,
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.getBorderColor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header avec image
            _buildHeader(),

            // Contenu principal
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        // Onglets
                        _buildTabBar(),

                        // Contenu des onglets
                        Expanded(child: _buildTabContent()),
                      ],
                    ),
            ),

            // Footer avec prix et bouton
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 250,
      child: Stack(
        children: [
          // Image du plat avec animation
          Positioned.fill(
            child: Hero(
              tag: 'food_image_${widget.menuItem.id}',
              child: CachedNetworkImage(
                imageUrl:
                    widget.menuItem.imageUrl ??
                    'https://via.placeholder.com/400x200',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.getBorderColor(context),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.getPrimaryColor(context),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.getBorderColor(context),
                  child: Icon(
                    Icons.restaurant,
                    size: 50,
                    color: AppColors.getTextColor(context),
                  ),
                ),
              ),
            ),
          ),

          // Overlay sombre
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
              ),
            ),
          ),

          // Bouton fermer
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.getCardColor(context).withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: AppColors.getTextColor(context),
                  size: 20,
                ),
              ),
            ),
          ),

          // Titre et prix
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.menuItem.name,
                  style: AppTextStyles.heroTitle.copyWith(
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.menuItem.price?.toStringAsFixed(0) ?? '0'} FCFA',
                  style: AppTextStyles.foodItemPrice.copyWith(
                    fontSize: 18,
                    color: AppColors.getSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.getLightCardBackground(context),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabButton('Quantité', 0, FontAwesomeIcons.hashtag),
          _buildTabButton('Garnitures', 1, FontAwesomeIcons.bowlFood),
          _buildTabButton('Instructions', 2, FontAwesomeIcons.stickyNote),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          // Validation de l'index avant l'assignation
          final safeIndex = index.clamp(0, 2);
          setState(() {
            _selectedTabIndex = safeIndex;
          });
          _tabController.forward().then((_) {
            _tabController.reverse();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.getPrimaryColor(context)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.getPrimaryColor(
                        context,
                      ).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: FaIcon(
                  icon,
                  key: ValueKey(isSelected),
                  size: 16,
                  color: isSelected
                      ? Colors.white
                      : AppColors.getSecondaryTextColor(context),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: AppTextStyles.categorySelected.copyWith(
                  color: isSelected
                      ? Colors.white
                      : AppColors.getSecondaryTextColor(context),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(title),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    // Validation de l'index pour éviter les erreurs de plage
    final safeIndex = _selectedTabIndex.clamp(0, 2);
    if (safeIndex != _selectedTabIndex) {
      setState(() {
        _selectedTabIndex = safeIndex;
      });
    }

    switch (safeIndex) {
      case 0:
        return _buildQuantityTab();
      case 1:
        return _buildSupplementsTab();
      case 2:
        return _buildInstructionsTab();
      default:
        return const SizedBox();
    }
  }

  Widget _buildQuantityTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Quantité',
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: 22,
              color: AppColors.getTextColor(context),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Bouton moins
              GestureDetector(
                onTap: () {
                  if (_quantity > 1) {
                    setState(() {
                      _quantity--;
                    });
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _quantity > 1
                        ? AppColors.getPrimaryColor(context)
                        : AppColors.getBorderColor(context),
                    shape: BoxShape.circle,
                    boxShadow: _quantity > 1
                        ? [
                            BoxShadow(
                              color: AppColors.primaryRed.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(Icons.remove, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 30),
              // Affichage de la quantité
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  key: ValueKey(_quantity),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.getPrimaryColor(context).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: AppColors.getPrimaryColor(
                        context,
                      ).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '$_quantity',
                    style: AppTextStyles.sectionTitle.copyWith(
                      fontSize: 28,
                      color: AppColors.getPrimaryColor(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 30),
              // Bouton plus
              GestureDetector(
                onTap: () {
                  setState(() {
                    _quantity++;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryRed.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupplementsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Garnitures
          Text(
            'Garnitures',
            style: AppTextStyles.sectionTitle.copyWith(
              color: AppColors.getTextColor(context),
            ),
          ),
          const SizedBox(height: 12),
          ..._garnitures.map(
            (garniture) => _buildSupplementItem(garniture, true),
          ),

          const SizedBox(height: 20),

          // Extras
          Text(
            'Extras',
            style: AppTextStyles.sectionTitle.copyWith(
              color: AppColors.getTextColor(context),
            ),
          ),
          const SizedBox(height: 12),
          ..._extras.map((extra) => _buildSupplementItem(extra, false)),
        ],
      ),
    );
  }

  Widget _buildSupplementItem(SupplementModel supplement, bool isGarniture) {
    final isSelected = isGarniture
        ? _selectedGarnitures.contains(supplement)
        : _selectedExtras.contains(supplement);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (value) {
              setState(() {
                if (isGarniture) {
                  if (value == true) {
                    _selectedGarnitures.add(supplement);
                  } else {
                    _selectedGarnitures.remove(supplement);
                  }
                } else {
                  if (value == true) {
                    _selectedExtras.add(supplement);
                  } else {
                    _selectedExtras.remove(supplement);
                  }
                }
              });
            },
            activeColor: AppColors.primaryRed,
          ),
          Expanded(
            child: Text(
              supplement.name,
              style: AppTextStyles.foodItemTitle.copyWith(
                color: AppColors.getTextColor(context),
              ),
            ),
          ),
          if (supplement.price! > 0)
            Text(
              '+${supplement.price!.toStringAsFixed(0)} FCFA',
              style: AppTextStyles.foodItemPrice.copyWith(
                fontSize: 12,
                color: AppColors.getSecondaryColor(context),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstructionsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Instructions spéciales (optionnel)',
            style: AppTextStyles.sectionTitle.copyWith(
              color: AppColors.getTextColor(context),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (value) {
              setState(() {
                _instructions = value;
              });
            },
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Ex: Sans piment, bien cuit, etc.',
              hintStyle: AppTextStyles.inputHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.getBorderColor(context),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.getPrimaryColor(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total',
                style: AppTextStyles.foodItemDescription.copyWith(
                  fontSize: 14,
                  color: AppColors.getSecondaryTextColor(context),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  '${_totalPrice.toStringAsFixed(0)} FCFA',
                  key: ValueKey(_totalPrice),
                  style: AppTextStyles.foodItemPrice.copyWith(
                    fontSize: 20,
                    color: AppColors.getPrimaryColor(context),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Expanded(
            flex: 2,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: ElevatedButton(
                onPressed: _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                  shadowColor: AppColors.primaryRed.withOpacity(0.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.basketShopping,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Ajouter au panier',
                      style: AppTextStyles.buttonText.copyWith(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
