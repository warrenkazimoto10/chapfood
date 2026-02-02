import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants/app_colors.dart';
import '../utils/text_styles.dart';
import '../services/realtime_tracking_service.dart';

/// Widget de suivi en temps réel du livreur
class RealtimeDriverTrackingWidget extends StatefulWidget {
  final String orderId;
  final String driverName;
  final String driverPhone;
  final String? driverImageUrl;
  final VoidCallback? onCallDriver;
  final VoidCallback? onViewMap;

  const RealtimeDriverTrackingWidget({
    super.key,
    required this.orderId,
    required this.driverName,
    required this.driverPhone,
    this.driverImageUrl,
    this.onCallDriver,
    this.onViewMap,
  });

  @override
  State<RealtimeDriverTrackingWidget> createState() =>
      _RealtimeDriverTrackingWidgetState();
}

class _RealtimeDriverTrackingWidgetState
    extends State<RealtimeDriverTrackingWidget>
    with TickerProviderStateMixin {
  final RealtimeTrackingService _trackingService = RealtimeTrackingService();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  DriverPosition? _currentPosition;
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();

    // Animation de pulsation pour l'indicateur de statut
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);

    _startTracking();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _trackingService.stopTracking();
    super.dispose();
  }

  void _startTracking() {
    if (_isTracking) return;

    setState(() => _isTracking = true);
    _trackingService.startTracking();

    // Écouter les mises à jour de position
    _trackingService.positionStream.listen((position) {
      if (mounted) {
        setState(() => _currentPosition = position);
      }
    });
  }

  void _stopTracking() {
    setState(() => _isTracking = false);
    _trackingService.stopTracking();
  }

  void _toggleTracking() {
    if (_isTracking) {
      _stopTracking();
    } else {
      _startTracking();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorderColor(context), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec titre et contrôle
          Row(
            children: [
              Icon(
                FontAwesomeIcons.motorcycle,
                color: AppColors.getPrimaryColor(context),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Suivi du livreur',
                  style: AppTextStyles.foodItemTitle.copyWith(
                    fontSize: 18,
                    color: AppColors.getTextColor(context),
                  ),
                ),
              ),
              // Bouton play/pause
              GestureDetector(
                onTap: _toggleTracking,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isTracking
                        ? AppColors.getPrimaryColor(context).withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isTracking
                          ? AppColors.getPrimaryColor(context).withOpacity(0.3)
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  child: Icon(
                    _isTracking ? Icons.pause : Icons.play_arrow,
                    color: _isTracking
                        ? AppColors.getPrimaryColor(context)
                        : Colors.grey,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Informations du livreur
          _buildDriverInfo(),

          const SizedBox(height: 20),

          // Position et statut en temps réel
          if (_currentPosition != null) ...[
            _buildPositionInfo(),
            const SizedBox(height: 16),
            _buildStatusInfo(),
          ] else ...[
            _buildLoadingState(),
          ],

          const SizedBox(height: 20),

          // Actions
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildDriverInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getLightCardBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getBorderColor(context)),
      ),
      child: Row(
        children: [
          // Avatar du livreur
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.getPrimaryColor(context).withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: AppColors.getPrimaryColor(context),
                width: 2,
              ),
            ),
            child: widget.driverImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(23),
                    child: Image.network(
                      widget.driverImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultAvatar(),
                    ),
                  )
                : _buildDefaultAvatar(),
          ),

          const SizedBox(width: 16),

          // Informations du livreur
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.driverName,
                  style: AppTextStyles.foodItemTitle.copyWith(
                    fontSize: 16,
                    color: AppColors.getTextColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.driverPhone,
                  style: AppTextStyles.foodItemDescription.copyWith(
                    fontSize: 14,
                    color: AppColors.getSecondaryTextColor(context),
                  ),
                ),
                const SizedBox(height: 8),
                // Statut actif
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isTracking ? _pulseAnimation.value : 1.0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _isTracking ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isTracking ? 'En livraison' : 'Hors ligne',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isTracking
                            ? Colors.green[700]
                            : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Icon(
      FontAwesomeIcons.user,
      color: AppColors.getPrimaryColor(context),
      size: 24,
    );
  }

  Widget _buildPositionInfo() {
    if (_currentPosition == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getPrimaryColor(context).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getPrimaryColor(context).withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Vitesse et direction
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: FontAwesomeIcons.gauge,
                  label: 'Vitesse',
                  value: '${_currentPosition!.speed.toStringAsFixed(1)} km/h',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: FontAwesomeIcons.compass,
                  label: 'Direction',
                  value: '${_currentPosition!.heading.toStringAsFixed(0)}°',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Distance et progression
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: FontAwesomeIcons.route,
                  label: 'Distance',
                  value:
                      '${_currentPosition!.getDistanceToDestination().toStringAsFixed(1)} km',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: FontAwesomeIcons.chartLine,
                  label: 'Progression',
                  value:
                      '${(_currentPosition!.routeProgress * 100).toStringAsFixed(0)}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.getSecondaryTextColor(context)),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.getSecondaryTextColor(context),
                ),
              ),
              Text(
                value,
                style: AppTextStyles.foodItemTitle.copyWith(
                  fontSize: 13,
                  color: AppColors.getTextColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusInfo() {
    if (_currentPosition == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(FontAwesomeIcons.locationDot, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentPosition!.getDeliveryStatus(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Arrivée estimée: ${_currentPosition!.getEstimatedArrival()}',
                  style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            'Chargement de la position...',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: widget.onCallDriver,
            icon: const Icon(Icons.phone, size: 18),
            label: const Text('Appeler'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: widget.onViewMap,
            icon: const Icon(Icons.map, size: 18),
            label: const Text('Voir sur carte'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.getPrimaryColor(context),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
