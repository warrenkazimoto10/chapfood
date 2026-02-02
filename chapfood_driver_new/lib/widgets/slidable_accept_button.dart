import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SlidableAcceptButton extends StatefulWidget {
  final VoidCallback onAccept;
  final String text;
  final Color backgroundColor;
  final Color sliderColor;

  const SlidableAcceptButton({
    super.key,
    required this.onAccept,
    this.text = 'Glisser pour accepter',
    this.backgroundColor = const Color(0xFF2C2C2C),
    this.sliderColor = const Color(0xFFFF6B35),
  });

  @override
  State<SlidableAcceptButton> createState() => _SlidableAcceptButtonState();
}

class _SlidableAcceptButtonState extends State<SlidableAcceptButton>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isCompleted = false;
  late AnimationController _resetController;
  late Animation<double> _resetAnimation;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _resetAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOut),
    )..addListener(() {
        setState(() {
          _dragPosition = _resetAnimation.value;
        });
      });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (_isCompleted) return;

    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
    });

    // Feedback haptique léger pendant le glissement
    if (_dragPosition > 0 && _dragPosition < maxDrag) {
      HapticFeedback.selectionClick();
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details, double maxDrag) {
    if (_isCompleted) return;

    // Si glissé à plus de 90%, considérer comme accepté
    if (_dragPosition >= maxDrag * 0.9) {
      setState(() {
        _dragPosition = maxDrag;
        _isCompleted = true;
      });

      // Feedback haptique fort pour la validation
      HapticFeedback.heavyImpact();

      // Appeler le callback après une courte pause
      Future.delayed(const Duration(milliseconds: 200), () {
        widget.onAccept();
      });
    } else {
      // Animer le retour à la position initiale
      _resetAnimation = Tween<double>(
        begin: _dragPosition,
        end: 0.0,
      ).animate(
        CurvedAnimation(parent: _resetController, curve: Curves.easeOut),
      );

      _resetController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - 70; // 70 = slider width
        final progress = _dragPosition / maxDrag;

        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: widget.sliderColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              // Barre de progression en arrière-plan
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.sliderColor.withOpacity(0.2),
                    ),
                  ),
                ),
              ),

              // Texte central
              Center(
                child: Text(
                  _isCompleted ? '✓ Accepté !' : widget.text,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Slider glissant
              Positioned(
                left: _dragPosition,
                top: 5,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) =>
                      _onHorizontalDragUpdate(details, maxDrag),
                  onHorizontalDragEnd: (details) =>
                      _onHorizontalDragEnd(details, maxDrag),
                  child: Container(
                    width: 70,
                    height: 50,
                    decoration: BoxDecoration(
                      color: widget.sliderColor,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: widget.sliderColor.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isCompleted ? Icons.check : Icons.arrow_forward,
                      color: Colors.white,
                      size: 28,
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
