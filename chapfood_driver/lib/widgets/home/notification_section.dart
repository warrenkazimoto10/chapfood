import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../widgets/animations/fade_in_animation.dart';
import '../../widgets/animations/scale_animation.dart';

class NotificationSection extends StatefulWidget {
  final List<Map<String, dynamic>> notifications;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onClearAll;

  const NotificationSection({
    super.key,
    required this.notifications,
    this.onNotificationTap,
    this.onClearAll,
  });

  @override
  State<NotificationSection> createState() => _NotificationSectionState();
}

class _NotificationSectionState extends State<NotificationSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didUpdateWidget(NotificationSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.notifications.length > oldWidget.notifications.length) {
      _slideController.forward();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    return FadeInUpAnimation(
      delay: const Duration(milliseconds: 1100),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header des notifications
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (widget.notifications.length > 1)
                  TextButton(
                    onPressed: widget.onClearAll,
                    child: Text(
                      'Tout effacer',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.primaryRed,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Liste des notifications
            ...widget.notifications.asMap().entries.map((entry) {
              final index = entry.key;
              final notification = entry.value;
              return SlideTransition(
                position: _slideAnimation,
                child: _buildNotificationCard(notification, index),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, int index) {
    final type = notification['type'] as String? ?? 'info';
    final title = notification['title'] as String? ?? 'Notification';
    final message = notification['message'] as String? ?? '';
    final time = notification['time'] as String? ?? '';
    final isRead = notification['isRead'] as bool? ?? false;

    Color cardColor;
    IconData icon;

    switch (type) {
      case 'order':
        cardColor = AppColors.primaryRed;
        icon = Icons.shopping_bag;
        break;
      case 'success':
        cardColor = AppColors.successGreen;
        icon = Icons.check_circle;
        break;
      case 'warning':
        cardColor = AppColors.warningYellow;
        icon = Icons.warning;
        break;
      case 'error':
        cardColor = AppColors.errorRed;
        icon = Icons.error;
        break;
      default:
        cardColor = AppColors.accentBlue;
        icon = Icons.info;
    }

    return ScaleAnimation(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? AppColors.borderLight : cardColor.withOpacity(0.3),
            width: isRead ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              widget.onNotificationTap?.call();
              // Marquer comme lu
              setState(() {
                notification['isRead'] = true;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icône de notification
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: cardColor,
                      size: 24,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Contenu de la notification
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        if (message.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            message,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (time.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            time,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Indicateur de type
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
