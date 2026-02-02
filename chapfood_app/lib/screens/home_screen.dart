import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';
import '../utils/text_styles.dart';
import '../services/auth_service.dart';
import '../services/menu_service.dart';
import '../services/welcome_service.dart';
import '../services/cart_service.dart';
import '../models/category_model.dart';
import '../models/menu_item_model.dart';
import '../providers/theme_provider.dart';
import '../main.dart'; // Pour Consumer
import 'menu_screen.dart';
import 'food_detail_modal.dart';
import 'cart_screen.dart';
import 'my_orders_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  String _userName = "Camara";
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Nouveaux controllers pour les animations échelonnées
  late AnimationController _staggeredAnimationController;
  late List<Animation<double>> _cardScaleAnimations;
  late List<Animation<double>> _cardOpacityAnimations;
  late List<Animation<Offset>> _cardSlideAnimations;

  // Controllers pour les micro-interactions
  late Map<String, AnimationController> _cardInteractionControllers;
  late Map<String, Animation<double>> _cardScaleInteractions;

  // Controllers pour les effets de la section hero (simplifiés)
  late ScrollController _scrollController;

  // Données du menu
  List<CategoryModel> _categories = [];
  List<MenuItemModel> _menuItems = [];
  List<MenuItemModel> _filteredMenuItems = [];
  int _selectedCategoryIndex = 0;
  bool _isLoading = true;
  String _welcomeMessage = '';

  // Gestion du panier
  int _cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadMenuData();
    _setupAnimations();
    _setupMicroInteractions();
    _setupScrollController();
    _welcomeMessage = WelcomeService.getRandomMessage();
    _loadCartCount();
  }

  void _setupAnimations() {
    // Animation principale
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Animation échelonnée pour les cartes
    _staggeredAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _animationController.forward();

    // Initialiser le ScrollController
    // Le contrôleur de scroll est initialisé dans _setupScrollController
  }

  // Initialiser les micro-interactions
  void _setupMicroInteractions() {
    _cardInteractionControllers = {};
    _cardScaleInteractions = {};
  }

  // Initialiser le contrôleur de scroll (simplifié)
  void _setupScrollController() {
    _scrollController = ScrollController();
  }

  // Créer les animations échelonnées pour les cartes
  void _setupStaggeredAnimations() {
    _cardScaleAnimations = [];
    _cardOpacityAnimations = [];
    _cardSlideAnimations = [];

    for (int i = 0; i < _filteredMenuItems.length; i++) {
      // Délai progressif pour chaque carte (100ms d'intervalle)
      final delay = i * 0.1;
      final animationDuration = 0.6; // Durée de l'animation pour chaque carte

      // Animation de scale (effet de rebond)
      final scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggeredAnimationController,
          curve: Interval(
            delay,
            delay + animationDuration,
            curve: Curves.elasticOut,
          ),
        ),
      );

      // Animation d'opacité
      final opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggeredAnimationController,
          curve: Interval(
            delay,
            delay + animationDuration,
            curve: Curves.easeOut,
          ),
        ),
      );

      // Animation de slide (depuis le bas)
      final slideAnimation =
          Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
            CurvedAnimation(
              parent: _staggeredAnimationController,
              curve: Interval(
                delay,
                delay + animationDuration,
                curve: Curves.easeOutCubic,
              ),
            ),
          );

      _cardScaleAnimations.add(scaleAnimation);
      _cardOpacityAnimations.add(opacityAnimation);
      _cardSlideAnimations.add(slideAnimation);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _staggeredAnimationController.dispose();
    _scrollController.dispose();

    // Nettoyer les controllers de micro-interactions
    for (var controller in _cardInteractionControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = await AuthService.getUserProfile();
    if (user != null && user.fullName != null) {
      setState(() {
        _userName = user.fullName!.split(' ').first;
      });
    }
  }

  Future<void> _loadMenuData() async {
    try {
      final categories = await MenuService.getCategories();
      final menuItems = await MenuService.getAllMenuItems();

      setState(() {
        _categories = categories;
        _menuItems = menuItems;
        _isLoading = false;
      });

      // Trouver l'index de la catégorie "Menu Soutrali" ou utiliser la première
      int soutraliIndex = 0;
      for (int i = 0; i < categories.length; i++) {
        if (categories[i].name.toLowerCase().contains('soutrali') ||
            categories[i].name.toLowerCase().contains('menu')) {
          soutraliIndex = i;
          break;
        }
      }

      // Filtrer les plats par catégorie par défaut (Menu Soutrali)
      _filterMenuItemsByCategory(soutraliIndex);
    } catch (e) {
      print('🍽️ [HOME] ❌ Erreur lors du chargement des données: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Méthode de refresh pour le pull-to-refresh
  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    await Future.wait<void>([
      _loadUserData(),
      _loadMenuData(),
      _loadCartCount(),
    ]);

    setState(() {
      _isLoading = false;
    });
  }

  void _filterMenuItemsByCategory(int categoryIndex) {
    print('🍽️ [HOME] Filtrage par catégorie - Index: $categoryIndex');
    if (categoryIndex < _categories.length) {
      final categoryId = _categories[categoryIndex].id;
      final categoryName = _categories[categoryIndex].name;
      print(
        '🍽️ [HOME] Catégorie sélectionnée: $categoryName (ID: $categoryId)',
      );

      final filteredItems = _menuItems
          .where((item) => item.categoryId == categoryId)
          .toList();
      print('🍽️ [HOME] Plats filtrés trouvés: ${filteredItems.length}');
      for (int i = 0; i < filteredItems.length; i++) {
        print('🍽️ [HOME] Plat filtré $i: ${filteredItems[i].name}');
      }

      // Changement immédiat de catégorie (sans délai)
      setState(() {
        _selectedCategoryIndex = categoryIndex;
        _filteredMenuItems = filteredItems;
      });

      // Démarrer les animations échelonnées immédiatement
      _startStaggeredAnimations();

      print(
        '🍽️ [HOME] État mis à jour - Plats filtrés: ${_filteredMenuItems.length}',
      );
    } else {
      print(
        '🍽️ [HOME] ❌ Index de catégorie invalide: $categoryIndex (max: ${_categories.length - 1})',
      );
    }
  }

  // Démarrer les animations échelonnées
  void _startStaggeredAnimations() {
    if (_filteredMenuItems.isNotEmpty) {
      _setupStaggeredAnimations();
      _staggeredAnimationController.reset();
      _staggeredAnimationController.forward();
    }
  }

  // Obtenir ou créer un controller pour une carte spécifique
  AnimationController _getCardInteractionController(String cardId) {
    if (!_cardInteractionControllers.containsKey(cardId)) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 150),
        vsync: this,
      );

      final animation = Tween<double>(
        begin: 1.0,
        end: 0.95,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

      _cardInteractionControllers[cardId] = controller;
      _cardScaleInteractions[cardId] = animation;
    }

    return _cardInteractionControllers[cardId]!;
  }

  // Animation de pression sur une carte
  void _onCardTapDown(String cardId) {
    _getCardInteractionController(cardId).forward();
  }

  // Animation de relâchement sur une carte
  void _onCardTapUp(String cardId) {
    _getCardInteractionController(cardId).reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getSurfaceColor(context),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refreshData,
                        color: AppColors.getPrimaryColor(context),
                        backgroundColor: AppColors.getCardColor(context),
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  _buildWelcomeSection(),
                                  _buildHeroSection(),
                                ],
                              ),
                            ),
                            ..._buildMenuSlivers(),
                            const SliverToBoxAdapter(
                              child: SizedBox(
                                height: 100,
                              ), // Espace pour le bottom nav
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Logo ChapFood officiel
          Image.asset(
            'assets/images/logo-chapfood.png',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
          ),
          const Spacer(),
          // Icônes d'action
          Row(
            children: [
              _buildThemeToggleButton(),
              const SizedBox(width: 12),
              _buildCartButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryRed,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue, $_userName !',
                  style: AppTextStyles.serviceCardTitle.copyWith(
                    fontSize: 16,
                    color: AppColors.getTextColor(context),
                  ),
                ),
                Text(
                  'Que souhaitez-vous commander aujourd\'hui ?',
                  style: AppTextStyles.serviceCardDescription.copyWith(
                    fontSize: 12,
                    color: AppColors.getSecondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: 220,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.getPrimaryColor(context).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Image de fond statique
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl:
                    'https://chapfood.shop/wp-content/uploads/2024/10/IMG_3291.jpg',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.getSplashGradient(context),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.getSplashGradient(context),
                  ),
                ),
              ),
            ),
            // Overlay statique
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
            // Contenu principal statique
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    // Titre principal
                    Row(
                      children: [
                        Text(
                          'Chap',
                          style: AppTextStyles.heroTitle.copyWith(
                            fontSize: 28,
                            color: AppColors.getPrimaryColor(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Food',
                          style: AppTextStyles.heroTitle.copyWith(
                            fontSize: 28,
                            color: AppColors.getSecondaryColor(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FaIcon(
                          FontAwesomeIcons.utensils,
                          color: AppColors.getSecondaryColor(context),
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Sous-titre
                    Text(
                      'La meilleure cuisine africaine',
                      style: AppTextStyles.heroSubtitle.copyWith(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Message de bienvenue
                    Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.bowlFood,
                          color: AppColors.getSecondaryColor(context),
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _welcomeMessage,
                            style: AppTextStyles.heroSubtitle.copyWith(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Nouvelle méthode avec animations échelonnées et micro-interactions
  Widget _buildAnimatedFoodItemCard(MenuItemModel item, int index) {
    // Vérifier si les animations sont prêtes
    if (index >= _cardScaleAnimations.length) {
      return _buildFoodItemCardWithInteractions(item);
    }

    return AnimatedBuilder(
      animation: _staggeredAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardScaleAnimations[index].value,
          child: FadeTransition(
            opacity: _cardOpacityAnimations[index],
            child: SlideTransition(
              position: _cardSlideAnimations[index],
              child: _buildFoodItemCardWithInteractions(item),
            ),
          ),
        );
      },
    );
  }

  // Créer les slivers pour le menu (scroll unifié)
  List<Widget> _buildMenuSlivers() {
    return [
      // Titre du menu
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notre Menu',
                style: AppTextStyles.servicesTitle.copyWith(
                  fontSize: 20,
                  color: AppColors.getPrimaryColor(
                    context,
                  ), // Rouge en mode sombre
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const MenuScreen()),
                  );
                },
                child: Text(
                  'Voir tout',
                  style: AppTextStyles.serviceCardAction.copyWith(
                    color: AppColors.getPrimaryColor(context),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // Catégories horizontales
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          right: index < _categories.length - 1 ? 12 : 0,
                        ),
                        child: _buildCategoryChip(
                          category.name,
                          index == _selectedCategoryIndex,
                          onTap: () => _onCategorySelected(index),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),

      // Description
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.getLightCardBackground(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Le menu soutrali comme son nom l\'indique est un menu accessible à tous avec des prix bas et des plats déjà composés.',
              style: AppTextStyles.serviceCardDescription.copyWith(
                fontSize: 12,
                color: AppColors.getTextColor(context), // Texte adaptatif
              ),
            ),
          ),
        ),
      ),

      // Liste des plats avec SliverList
      _isLoading
          ? SliverToBoxAdapter(child: _buildShimmerLoading())
          : _filteredMenuItems.isEmpty
          ? SliverToBoxAdapter(
              child: Container(
                height: 120,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Aucun plat disponible dans cette catégorie',
                    style: AppTextStyles.foodItemDescription,
                  ),
                ),
              ),
            )
          : SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: const Duration(
                  milliseconds: 200,
                ), // Durée réduite pour plus de fluidité
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0), // Mouvement plus subtil
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _buildMenuItemsList(),
              ),
            ),
    ];
  }

  // Construire la liste des plats avec une clé unique pour AnimatedSwitcher
  Widget _buildMenuItemsList() {
    return Column(
      key: ValueKey(_selectedCategoryIndex),
      children: _filteredMenuItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: index < _filteredMenuItems.length - 1 ? 16 : 0,
          ),
          child: _buildAnimatedFoodItemCard(item, index),
        );
      }).toList(),
    );
  }

  void _onCategorySelected(int index) {
    _filterMenuItemsByCategory(index);
  }

  // Charger le nombre d'articles dans le panier
  Future<void> _loadCartCount() async {
    final cartItems = await CartService.getCartItems();
    setState(() {
      _cartItemCount = cartItems.fold(0, (sum, item) => sum + item.quantity);
    });
  }

  // Mettre à jour le compteur du panier
  void _updateCartCount() {
    _loadCartCount();
  }

  // Navigation vers le panier
  void _navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartScreen()),
    ).then((_) {
      // Recharger le compteur du panier après retour
      _loadCartCount();
    });
  }

  Widget _buildShimmerLoading() {
    return SizedBox(
      height: 400,
      child: ListView.builder(
        scrollDirection: Axis.vertical,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: index < 2 ? 16 : 0),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: double.infinity,
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Nouvelle méthode avec micro-interactions
  Widget _buildFoodItemCardWithInteractions(MenuItemModel item) {
    final cardId = 'card_${item.id}';
    _getCardInteractionController(cardId); // Initialiser le controller
    final scaleAnimation = _cardScaleInteractions[cardId]!;

    return GestureDetector(
      onTapDown: (_) => _onCardTapDown(cardId),
      onTapUp: (_) => _onCardTapUp(cardId),
      onTapCancel: () => _onCardTapUp(cardId),
      onTap: () => _showFoodDetailModal(item),
      child: AnimatedBuilder(
        animation: scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: scaleAnimation.value,
            child: _buildFoodItemCard(item),
          );
        },
      ),
    );
  }

  Widget _buildFoodItemCard(MenuItemModel item) {
    return GestureDetector(
      onTap: () => _showFoodDetailModal(item),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image du plat qui prend toute la largeur
            Hero(
              tag: 'food_image_${item.id}',
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: CachedNetworkImage(
                  imageUrl:
                      item.imageUrl ?? 'https://via.placeholder.com/300x200',
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.restaurant,
                      color: Colors.grey,
                      size: 50,
                    ),
                  ),
                ),
              ),
            ),
            // Contenu en dessous de l'image
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre et prix sur la même ligne
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: AppTextStyles.foodItemTitle.copyWith(
                            fontSize: 18,
                            color: AppColors.getTextColor(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${item.price.toStringAsFixed(0)} FCFA',
                        style: AppTextStyles.foodItemPrice.copyWith(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Description
                  if (item.description != null)
                    Text(
                      item.description!,
                      style: AppTextStyles.foodItemDescription.copyWith(
                        fontSize: 14,
                        color: AppColors.getSecondaryTextColor(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 12),
                  // Bouton d'ajout au panier avec micro-interaction
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showFoodDetailModal(item),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.getPrimaryColor(context),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.getPrimaryColor(
                                    context,
                                  ).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const FaIcon(
                              FontAwesomeIcons.plus,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFoodDetailModal(MenuItemModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FoodDetailModal(
        menuItem: item,
        onItemAdded:
            _updateCartCount, // Callback pour mettre à jour le compteur
      ),
    );
  }

  // Bouton de thème optimisé
  Widget _buildThemeToggleButton() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.getCardColor(context),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.getBorderColor(context),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: themeProvider.toggleTheme,
              child: Icon(
                themeProvider.themeIcon,
                color: AppColors.getPrimaryColor(
                  context,
                ), // Couleur adaptative pour l'icône
                size: 20,
              ),
            ),
          ),
        );
      },
    );
  }

  // Bouton de panier optimisé
  Widget _buildCartButton() {
    return GestureDetector(
      onTap: _navigateToCart,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.getCardColor(context),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.getBorderColor(context),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.shopping_bag_outlined,
                color: AppColors.getSecondaryColor(
                  context,
                ), // Couleur adaptative pour l'icône
                size: 20,
              ),
            ),
            if (_cartItemCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.getPrimaryColor(context),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.getCardColor(context),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.getPrimaryColor(
                          context,
                        ).withOpacity(0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _cartItemCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    String name,
    bool isSelected, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.getPrimaryColor(context)
                  : AppColors.getCardColor(context),
              borderRadius: BorderRadius.circular(20),
              border: isSelected
                  ? null
                  : Border.all(
                      color: AppColors.getBorderColor(context),
                      width: 1,
                    ),
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
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: AppTextStyles.serviceCardAction.copyWith(
                color: isSelected
                    ? Colors.white
                    : AppColors.getSecondaryTextColor(context),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              child: Text(name),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const MenuScreen()));
            return;
          }
          if (index == 2) {
            _navigateToCart();
            return;
          }
          if (index == 3) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const MyOrdersScreen()));
            return;
          }
          if (index == 4) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            return;
          }
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.getCardColor(context),
        selectedItemColor: AppColors.getPrimaryColor(context),
        unselectedItemColor: AppColors.getSecondaryTextColor(context),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryRed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shopping_bag,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                if (_cartItemCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.getCardColor(context),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.getPrimaryColor(context),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.getPrimaryColor(
                              context,
                            ).withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _cartItemCount.toString(),
                          style: TextStyle(
                            color: AppColors.getPrimaryColor(context),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Panier',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Mes commandes',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
