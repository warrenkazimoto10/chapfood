import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config/osm_config.dart';
import '../constants/app_colors.dart';
import '../services/address_service.dart';
import '../services/photon_geocoding_service.dart';
import '../widgets/address_search_widget.dart';

class MapSelectionScreen extends StatefulWidget {
  final String? initialAddress;
  final Function(String address, double latitude, double longitude)?
  onAddressSelected;

  const MapSelectionScreen({
    super.key,
    this.initialAddress,
    this.onAddressSelected,
  });

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  final MapController _mapController = MapController();
  bool _isMapLoading = true;
  geo.Position? _currentPosition;
  String _selectedAddress = '';
  double? _selectedLatitude;
  double? _selectedLongitude;
  Timer? _updateTimer;
  DateTime? _lastReverseGeocodeTime;

  @override
  void initState() {
    super.initState();
    _selectedAddress = widget.initialAddress ?? '';
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      await _getCurrentLocation();
    } else if (status.isDenied) {
      _showPermissionDialog();
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getCardColor(context),
        title: Text(
          'Permission requise',
          style: TextStyle(color: AppColors.getTextColor(context)),
        ),
        content: Text(
          'La localisation est nécessaire pour sélectionner votre position sur la carte.',
          style: TextStyle(color: AppColors.getSecondaryTextColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: AppColors.getSecondaryTextColor(context)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _requestLocationPermission();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.getPrimaryColor(context),
            ),
            child: const Text(
              'Autoriser',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool isEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!isEnabled) {
        await geo.Geolocator.openLocationSettings();
        return;
      }

      final position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _selectedLatitude = position.latitude;
        _selectedLongitude = position.longitude;
        _isMapLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _initMapCenter();
      });

      _mapController.move(LatLng(position.latitude, position.longitude), 16.0);
    } catch (e) {
      print('Erreur lors de la récupération de la position: $e');
      setState(() {
        _isMapLoading = false;
        _selectedLatitude = OsmConfig.defaultLat;
        _selectedLongitude = OsmConfig.defaultLng;
        _selectedAddress = 'Grand-Bassam';
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _initMapCenter();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de localisation: $e'),
          backgroundColor: AppColors.getPrimaryColor(context),
        ),
      );
    }
  }

  void _onPositionChanged(MapPosition position, bool hasGesture) {
    if (!mounted) return;
    final center = position.center;
    if (center == null) return;
    setState(() {
      _selectedLatitude = center.latitude;
      _selectedLongitude = center.longitude;
      if (_selectedAddress.isEmpty ||
          _selectedAddress.contains('Position sélectionnée') ||
          _selectedAddress.contains('(')) {
        _selectedAddress = 'Chargement de l\'adresse...';
      }
    });
    final now = DateTime.now();
    if (_lastReverseGeocodeTime == null ||
        now.difference(_lastReverseGeocodeTime!).inSeconds >= 2) {
      _lastReverseGeocodeTime = now;
      _updateAddressFromCoordinates(center.latitude, center.longitude);
    }
  }

  void _initMapCenter() {
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        16.0,
      );
      setState(() {
        _selectedLatitude = _currentPosition!.latitude;
        _selectedLongitude = _currentPosition!.longitude;
        _selectedAddress = 'Chargement de l\'adresse...';
      });
      _updateAddressFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
    } else {
      _mapController.move(
        LatLng(OsmConfig.defaultLat, OsmConfig.defaultLng),
        OsmConfig.defaultZoom,
      );
    }
  }

  /// Met à jour l'adresse à partir des coordonnées GPS
  Future<void> _updateAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    if (!mounted) return;

    try {
      final reverseResult = await PhotonGeocodingService.reverse(
        latitude,
        longitude,
      );

      if (reverseResult != null && mounted) {
        var address = reverseResult.getFormattedAddress();
        if (address.isEmpty ||
            address == 'Grand-Bassam' ||
            address.trim().length < 5) {
          address = reverseResult.displayName;
          if (address.isEmpty) address = 'Grand-Bassam';
        }
        if (mounted && address.isNotEmpty) {
          setState(() {
            _selectedAddress = address;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _selectedAddress = 'Grand-Bassam';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedAddress = 'Grand-Bassam';
        });
      }
    }
  }

  Future<void> _selectCurrentMapCenter() async {
    // Enregistrer automatiquement la position et rediriger vers le wizard
    if (_selectedLatitude != null && _selectedLongitude != null) {
      // Afficher un indicateur de chargement rapide
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.getCardColor(context),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: AppColors.getPrimaryColor(context),
                ),
                const SizedBox(height: 16),
                Text(
                  'Enregistrement...',
                  style: TextStyle(
                    color: AppColors.getTextColor(context),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // S'assurer que l'adresse est à jour
      if (_selectedAddress.isEmpty ||
          _selectedAddress.contains('Position sélectionnée') ||
          _selectedAddress.contains('(') ||
          _selectedAddress == 'Chargement de l\'adresse...') {
        await _updateAddressFromCoordinates(
          _selectedLatitude!,
          _selectedLongitude!,
        );
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Sauvegarder la position
      AddressService.savePreferredPosition(
        latitude: _selectedLatitude!,
        longitude: _selectedLongitude!,
        address: _selectedAddress,
      );

      // Retourner à l'écran précédent avec l'adresse
      if (mounted) {
        Navigator.pop(context); // Fermer le dialog de chargement

        if (widget.onAddressSelected != null) {
          // S'assurer que l'adresse ne contient pas de coordonnées
          final addressToReturn =
              _selectedAddress.isNotEmpty &&
                  !_selectedAddress.contains('(') &&
                  !_selectedAddress.contains('Position sélectionnée') &&
                  _selectedAddress != 'Chargement de l\'adresse...'
              ? _selectedAddress
              : 'Grand-Bassam';

          widget.onAddressSelected!(
            addressToReturn,
            _selectedLatitude!,
            _selectedLongitude!,
          );
        }

        // Rediriger vers le wizard
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Position en cours de chargement...'),
          backgroundColor: AppColors.getPrimaryColor(context),
        ),
      );
    }
  }

  /// Gère la sélection d'une adresse depuis la recherche
  Future<void> _onAddressSelectedFromSearch(
    String address,
    double latitude,
    double longitude,
  ) async {
    setState(() {
      _selectedLatitude = latitude;
      _selectedLongitude = longitude;
      _selectedAddress = address; // Utiliser l'adresse de la recherche d'abord
    });

    _mapController.move(LatLng(latitude, longitude), 17.0);

    // Améliorer l'adresse avec reverse geocoding pour plus de détails
    await _updateAddressFromCoordinates(latitude, longitude);
  }

  Future<void> _goToMyLocation() async {
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        16.0,
      );
    } else {
      await _getCurrentLocation();
    }
  }

  Future<void> _selectPosition() async {
    if (_selectedLatitude != null && _selectedLongitude != null) {
      // Afficher l'animation de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.getCardColor(context),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: AppColors.getPrimaryColor(context),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sélection en cours...',
                  style: TextStyle(
                    color: AppColors.getTextColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // S'assurer que l'adresse est à jour avant de retourner
      // Si l'adresse contient encore des coordonnées, faire un reverse geocoding
      if (_selectedAddress.isEmpty ||
          _selectedAddress.contains('Position sélectionnée') ||
          _selectedAddress.contains('(') ||
          _selectedAddress == 'Chargement de l\'adresse...') {
        // Faire un reverse geocoding immédiat
        await _updateAddressFromCoordinates(
          _selectedLatitude!,
          _selectedLongitude!,
        );
        // Attendre un peu pour que l'adresse soit mise à jour
        await Future.delayed(const Duration(milliseconds: 800));
      }

      // Simuler un délai pour l'animation
      await Future.delayed(const Duration(milliseconds: 200));

      // Sauvegarder la position dans le service
      AddressService.savePreferredPosition(
        latitude: _selectedLatitude!,
        longitude: _selectedLongitude!,
        address: _selectedAddress,
      );

      // Remplacer par une animation de succès
      if (mounted) {
        Navigator.pop(context);
        _showSuccessDialog();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Veuillez sélectionner une position sur la carte',
          ),
          backgroundColor: AppColors.getPrimaryColor(context),
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.getCardColor(context),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.getPrimaryColor(context).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.getPrimaryColor(context),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Position sélectionnée !',
                style: TextStyle(
                  color: AppColors.getTextColor(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Redirection en cours...',
                style: TextStyle(
                  color: AppColors.getSecondaryTextColor(context),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Fermer le dialog après 1.5 secondes et rediriger
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.pop(context);
        // Retourner à l'écran précédent avec les données
        if (widget.onAddressSelected != null) {
          // S'assurer que l'adresse ne contient pas de coordonnées
          final addressToReturn =
              _selectedAddress.isNotEmpty &&
                  !_selectedAddress.contains('(') &&
                  !_selectedAddress.contains('Position sélectionnée') &&
                  _selectedAddress != 'Chargement de l\'adresse...'
              ? _selectedAddress
              : 'Grand-Bassam';

          widget.onAddressSelected!(
            addressToReturn,
            _selectedLatitude!,
            _selectedLongitude!,
          );
        }
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(
          'Sélectionner ma position',
          style: TextStyle(color: AppColors.getTextColor(context)),
        ),
        backgroundColor: AppColors.getCardColor(context),
        foregroundColor: AppColors.getTextColor(context),
        elevation: 0,
        actions: [
          if (_selectedLatitude != null && _selectedLongitude != null)
            TextButton(
              onPressed: _selectPosition,
              child: Text(
                'Sélectionner',
                style: TextStyle(
                  color: AppColors.getPrimaryColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Carte d'abord (en arrière-plan)
          if (_isMapLoading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.getPrimaryColor(context),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chargement de la carte...',
                    style: TextStyle(color: AppColors.getTextColor(context)),
                  ),
                ],
              ),
            )
          else
            Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition != null
                        ? LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          )
                        : LatLng(OsmConfig.defaultLat, OsmConfig.defaultLng),
                    initialZoom: OsmConfig.defaultZoom,
                    onPositionChanged: _onPositionChanged,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: OsmConfig.tileUrlTemplate,
                      userAgentPackageName: 'com.chapfood.app',
                      maxZoom: 19,
                    ),
                    RichAttributionWidget(
                      animationConfig: const ScaleRAWA(),
                      showFlutterMapAttribution: false,
                      attributions: [
                        TextSourceAttribution(
                          'OpenStreetMap contributors',
                          prependCopyright: true,
                        ),
                      ],
                    ),
                  ],
                ),
                // Curseur fixe au centre de la carte
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Curseur principal
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.getPrimaryColor(context),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.getPrimaryColor(
                                context,
                              ).withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      // Pointe du curseur
                      Transform.translate(
                        offset: const Offset(0, -2),
                        child: Container(
                          width: 0,
                          height: 0,
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: Colors.transparent,
                                width: 8,
                              ),
                              right: BorderSide(
                                color: Colors.transparent,
                                width: 8,
                              ),
                              top: BorderSide(
                                color: AppColors.getPrimaryColor(context),
                                width: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Overlay d'instruction au centre de la carte
                if (_selectedAddress.isEmpty)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Déplacez la carte pour sélectionner votre position',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

          // Barre de recherche PAR-DESSUS la carte (z-index élevé)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: AddressSearchWidget(
                  hintText: 'Rechercher une adresse, quartier, pharmacie...',
                  onAddressSelected: _onAddressSelectedFromSearch,
                ),
              ),
            ),
          ),

          // Boutons de contrôle
          Positioned(
            right: 16,
            bottom: 120,
            child: Column(
              children: [
                // Bouton sélectionner position
                FloatingActionButton(
                  heroTag: 'select_position',
                  backgroundColor: AppColors.getSecondaryColor(context),
                  onPressed: _selectCurrentMapCenter,
                  child: const Icon(Icons.location_on, color: Colors.white),
                ),
                const SizedBox(height: 8),
                // Bouton retour à ma position
                FloatingActionButton(
                  heroTag: 'my_location',
                  backgroundColor: AppColors.getPrimaryColor(context),
                  onPressed: _goToMyLocation,
                  child: const Icon(Icons.my_location, color: Colors.white),
                ),
              ],
            ),
          ),

          // Adresse sélectionnée en bas (simplifié)
          if (_selectedAddress.isNotEmpty && _selectedLatitude != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.getCardColor(context),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Adresse sélectionnée',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.getSecondaryTextColor(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedAddress,
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.getTextColor(context),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
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
