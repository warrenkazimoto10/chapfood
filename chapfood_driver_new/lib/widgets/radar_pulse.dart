import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class RadarPulse extends StatefulWidget {
  final bool isOnline;
  const RadarPulse({super.key, required this.isOnline});

  @override
  State<RadarPulse> createState() => _RadarPulseState();
}

class _RadarPulseState extends State<RadarPulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOnline) return const SizedBox.shrink();

    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: 100 + (_controller.value * 200),
            height: 100 + (_controller.value * 200),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.3 * (1 - _controller.value)),
            ),
          );
        },
      ),
    );
  }
}
