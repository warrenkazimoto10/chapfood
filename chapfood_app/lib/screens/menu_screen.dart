import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../utils/text_styles.dart';
import '../models/category_model.dart';
import '../models/menu_item_model.dart';
import '../services/supabase_service.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<CategoryModel> _categories = [];
  List<MenuItemModel> _menuItems = [];
  int? _selectedCategoryId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Charger les catégories
      final categories = await SupabaseService.getCategories();
      
      // Charger tous les plats
      final menuItems = await SupabaseService.getMenuItems();

      setState(() {
        _categories = categories;
        _menuItems = menuItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  List<MenuItemModel> get _filteredMenuItems {
    if (_selectedCategoryId == null) {
      return _menuItems;
    }
    return _menuItems.where((item) => item.categoryId == _selectedCategoryId).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        title: Text(
          'Menu ChapFood',
          style: AppTextStyles.logoText.copyWith(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filtres par catégorie
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildCategoryChip(
                          'Tous',
                          null,
                          _selectedCategoryId == null,
                        );
                      }
                      
                      final category = _categories[index - 1];
                      return _buildCategoryChip(
                        category.name,
                        category.id,
                        _selectedCategoryId == category.id,
                      );
                    },
                  ),
                ),
                
                // Liste des plats
                Expanded(
                  child: _filteredMenuItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.restaurant_menu,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun plat disponible',
                                style: AppTextStyles.serviceCardDescription.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredMenuItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredMenuItems[index];
                            return _buildMenuItemCard(item);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryChip(String name, int? categoryId, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(name),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategoryId = selected ? categoryId : null;
          });
        },
        selectedColor: AppColors.primaryRed.withOpacity(0.2),
        checkmarkColor: AppColors.primaryRed,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primaryRed : Colors.grey[600],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildMenuItemCard(MenuItemModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image du plat
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: item.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.restaurant,
                            color: Colors.grey[400],
                            size: 32,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.restaurant,
                      color: Colors.grey[400],
                      size: 32,
                    ),
            ),
            
            const SizedBox(width: 16),
            
            // Informations du plat
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.serviceCardTitle,
                  ),
                  
                  if (item.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description!,
                      style: AppTextStyles.serviceCardDescription.copyWith(
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Text(
                        '${item.price.toStringAsFixed(0)} FCFA',
                        style: AppTextStyles.serviceCardAction.copyWith(
                          color: AppColors.primaryRed,
                          fontSize: 16,
                        ),
                      ),
                      
                      if (item.isPopular == true) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryYellow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Populaire',
                            style: AppTextStyles.serviceCardStatus.copyWith(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Bouton d'ajout au panier
            IconButton(
              onPressed: () {
                // TODO: Ajouter au panier
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item.name} ajouté au panier'),
                    backgroundColor: AppColors.successColor,
                  ),
                );
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
