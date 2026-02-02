import 'package:flutter/material.dart';

/// Widget pour optimiser les listes avec lazy loading
class OptimizedList extends StatefulWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final int? itemCount;
  final IndexedWidgetBuilder? itemBuilder;
  final Widget? separator;

  const OptimizedList({
    super.key,
    required this.children,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
    this.itemCount,
    this.itemBuilder,
    this.separator,
  });

  @override
  State<OptimizedList> createState() => _OptimizedListState();
}

class _OptimizedListState extends State<OptimizedList> {
  late ScrollController _scrollController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
      
      // Simuler le chargement
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemBuilder != null) {
      return ListView.separated(
        controller: _scrollController,
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics,
        padding: widget.padding,
        itemCount: (widget.itemCount ?? 0) + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == widget.itemCount) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return widget.itemBuilder!(context, index);
        },
        separatorBuilder: (context, index) => widget.separator ?? const SizedBox.shrink(),
      );
    }

    return ListView(
      controller: _scrollController,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      padding: widget.padding,
      children: [
        ...widget.children,
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}

/// Widget pour optimiser les images avec cache
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? const Center(
          child: CircularProgressIndicator(),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? const Icon(Icons.error);
      },
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
    );
  }
}

/// Widget pour optimiser les animations
class OptimizedAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final bool autoStart;
  final VoidCallback? onComplete;

  const OptimizedAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.autoStart = true,
    this.onComplete,
  });

  @override
  State<OptimizedAnimation> createState() => _OptimizedAnimationState();
}

class _OptimizedAnimationState extends State<OptimizedAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    if (widget.autoStart) {
      _controller.forward().then((_) {
        widget.onComplete?.call();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.scale(
            scale: 0.8 + (0.2 * _animation.value),
            child: widget.child,
          ),
        );
      },
    );
  }
}

