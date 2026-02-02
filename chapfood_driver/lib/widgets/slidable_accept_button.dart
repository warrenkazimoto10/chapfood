import 'package:flutter/material.dart';

/// Bouton slidable pour accepter une commande
class SlidableAcceptButton extends StatefulWidget {
  final VoidCallback onAccept;
  final String text;

  const SlidableAcceptButton({
    super.key,
    required this.onAccept,
    this.text = 'Glisser pour accepter',
  });

  @override
  State<SlidableAcceptButton> createState() => _SlidableAcceptButtonState();
}

class _SlidableAcceptButtonState extends State<SlidableAcceptButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double _dragPosition = 0.0;
  bool _isAccepted = false;
  VoidCallback? _animationListener;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details, double maxWidth) {
    if (_isAccepted) return;

    setState(() {
      _dragPosition += details.delta.dx;
      // Limiter le glissement entre 0 et la largeur du bouton
      _dragPosition = _dragPosition.clamp(0.0, maxWidth - 60);
    });

    // Si on a glissé assez loin, accepter
    if (_dragPosition >= maxWidth - 80) {
      _accept();
    }
  }

  void _onPanEnd(DragEndDetails details, double maxWidth) {
    if (_isAccepted) return;

    // Si on n'a pas glissé assez loin, revenir à la position initiale
    if (_dragPosition < maxWidth - 80) {
      final startPosition = _dragPosition;
      _animationController.reset();

      // Retirer l'ancien listener s'il existe
      if (_animationListener != null) {
        _animationController.removeListener(_animationListener!);
      }

      // Créer un nouveau listener
      _animationListener = () {
        if (mounted) {
          setState(() {
            _dragPosition = startPosition * (1 - _animationController.value);
          });
        }
      };

      _animationController.addListener(_animationListener!);
      _animationController.forward().then((_) {
        if (mounted) {
          setState(() {
            _dragPosition = 0.0;
          });
          if (_animationListener != null) {
            _animationController.removeListener(_animationListener!);
            _animationListener = null;
          }
          _animationController.reset();
        }
      });
    }
  }

  void _accept() {
    if (_isAccepted) return;
    setState(() {
      _isAccepted = true;
    });
    widget.onAccept();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final progress = maxWidth > 60 ? _dragPosition / (maxWidth - 60) : 0.0;
        final isNearComplete = progress > 0.7;

        return Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(28),
          ),
          child: Stack(
            children: [
              // Fond de progression
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: _dragPosition + 60,
                decoration: BoxDecoration(
                  color: isNearComplete
                      ? const Color(0xFF4CAF50) // Vert quand presque complet
                      : const Color(0xFFFF6B35), // Orange par défaut
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              // Texte
              Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: _dragPosition > 0 ? Colors.white : Colors.grey[400],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  child: Text(
                    isNearComplete
                        ? 'Relâchez pour accepter'
                        : _isAccepted
                        ? 'Accepté ✓'
                        : widget.text,
                  ),
                ),
              ),
              // Bouton glissant
              Positioned(
                left: _dragPosition,
                child: GestureDetector(
                  onPanUpdate: (details) => _onPanUpdate(details, maxWidth),
                  onPanEnd: (details) => _onPanEnd(details, maxWidth),
                  child: Container(
                    width: 60,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: isNearComplete
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFFF6B35),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
