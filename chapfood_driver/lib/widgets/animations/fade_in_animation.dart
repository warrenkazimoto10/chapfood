import 'package:flutter/material.dart';

/// Animation de fondu d'entrée avec décalage
class FadeInAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final double beginOpacity;
  final double endOpacity;
  final Offset beginOffset;
  final Offset endOffset;

  const FadeInAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
    this.beginOpacity = 0.0,
    this.endOpacity = 1.0,
    this.beginOffset = const Offset(0, 20),
    this.endOffset = Offset.zero,
  });

  @override
  State<FadeInAnimation> createState() => _FadeInAnimationState();
}

class _FadeInAnimationState extends State<FadeInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: widget.beginOpacity,
      end: widget.endOpacity,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _offsetAnimation = Tween<Offset>(
      begin: widget.beginOffset,
      end: widget.endOffset,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    // Démarrer l'animation après le délai
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: _offsetAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Animation de fondu d'entrée depuis la gauche
class FadeInLeftAnimation extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const FadeInLeftAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  Widget build(BuildContext context) {
    return FadeInAnimation(
      delay: delay,
      duration: duration,
      beginOffset: const Offset(-50, 0),
      endOffset: Offset.zero,
      child: child,
    );
  }
}

/// Animation de fondu d'entrée depuis la droite
class FadeInRightAnimation extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const FadeInRightAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  Widget build(BuildContext context) {
    return FadeInAnimation(
      delay: delay,
      duration: duration,
      beginOffset: const Offset(50, 0),
      endOffset: Offset.zero,
      child: child,
    );
  }
}

/// Animation de fondu d'entrée depuis le bas
class FadeInUpAnimation extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const FadeInUpAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  Widget build(BuildContext context) {
    return FadeInAnimation(
      delay: delay,
      duration: duration,
      beginOffset: const Offset(0, 50),
      endOffset: Offset.zero,
      child: child,
    );
  }
}

/// Animation de fondu d'entrée depuis le haut
class FadeInDownAnimation extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const FadeInDownAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  Widget build(BuildContext context) {
    return FadeInAnimation(
      delay: delay,
      duration: duration,
      beginOffset: const Offset(0, -50),
      endOffset: Offset.zero,
      child: child,
    );
  }
}

