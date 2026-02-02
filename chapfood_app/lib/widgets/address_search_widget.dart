import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../services/nominatim_service.dart';

/// Widget de recherche d'adresses avec autocomplete utilisant Nominatim
class AddressSearchWidget extends StatefulWidget {
  final Function(String address, double latitude, double longitude)?
  onAddressSelected;
  final String? hintText;
  final bool showResultsBelow;

  const AddressSearchWidget({
    super.key,
    this.onAddressSelected,
    this.hintText,
    this.showResultsBelow = true,
  });

  @override
  State<AddressSearchWidget> createState() => _AddressSearchWidgetState();
}

class _AddressSearchWidgetState extends State<AddressSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;
  List<NominatimResult> _results = [];
  bool _isSearching = false;
  bool _showResults = false;
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Masquer les résultats après un court délai pour permettre le clic
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              _showResults = false;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();

    if (query.length < 2) {
      setState(() {
        _results = [];
        _showResults = false;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showResults = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    try {
      print('🔍 Recherche Nominatim: "$query"');
      final results = await NominatimService.search(
        query,
        limit: 10, // Augmenter à 10 résultats
        countryCodes: 'ci',
      );

      print('✅ ${results.length} résultats trouvés');
      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
          _selectedIndex = -1;
        });
      }
    } catch (e) {
      print('❌ Erreur de recherche: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
          _results = [];
        });
      }
    }
  }

  void _selectResult(NominatimResult result) {
    _searchController.text = result.getFormattedAddress();
    _focusNode.unfocus();

    setState(() {
      _showResults = false;
      _results = [];
    });

    if (widget.onAddressSelected != null) {
      widget.onAddressSelected!(
        result.getFormattedAddress(),
        result.latitude,
        result.longitude,
      );
    }
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (!_showResults || _results.isEmpty) return;

    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % _results.length;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedIndex = _selectedIndex <= 0
              ? _results.length - 1
              : _selectedIndex - 1;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_selectedIndex >= 0 && _selectedIndex < _results.length) {
          _selectResult(_results[_selectedIndex]);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: _handleKeyEvent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barre de recherche
          Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: AppColors.getCardColor(context),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.getCardColor(context),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: _onSearchChanged,
                style: TextStyle(
                  color: AppColors.getTextColor(context),
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText ?? 'Rechercher une adresse...',
                  hintStyle: TextStyle(
                    color: AppColors.getSecondaryTextColor(context),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.getPrimaryColor(context),
                  ),
                  suffixIcon: _isSearching
                      ? Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.getPrimaryColor(context),
                            ),
                          ),
                        )
                      : _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: AppColors.getSecondaryTextColor(context),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _results = [];
                              _showResults = false;
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.getLightCardBackground(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),

          // Résultats de recherche - avec z-index élevé
          if (_showResults && _results.isNotEmpty)
            Material(
              elevation: 12,
              borderRadius: BorderRadius.circular(12),
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                constraints: const BoxConstraints(
                  maxHeight: 400,
                ), // Augmenter la hauteur
                decoration: BoxDecoration(
                  color: AppColors.getCardColor(context),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: AppColors.getBorderColor(context),
                  ),
                  itemBuilder: (context, index) {
                    final result = _results[index];
                    final isSelected = index == _selectedIndex;

                    return InkWell(
                      onTap: () => _selectResult(result),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        color: isSelected
                            ? AppColors.getPrimaryColor(
                                context,
                              ).withOpacity(0.1)
                            : Colors.transparent,
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: AppColors.getPrimaryColor(context),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    result.getShortName(),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.getTextColor(context),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    result.getFormattedAddress(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.getSecondaryTextColor(
                                        context,
                                      ),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.getPrimaryColor(
                                  context,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                result.type,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.getPrimaryColor(context),
                                  fontWeight: FontWeight.w500,
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
            ),

          // Message si aucun résultat
          if (_showResults &&
              !_isSearching &&
              _results.isEmpty &&
              _searchController.text.length >= 2)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.getCardColor(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.getSecondaryTextColor(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Aucun résultat trouvé pour "${_searchController.text}"',
                      style: TextStyle(
                        color: AppColors.getSecondaryTextColor(context),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
