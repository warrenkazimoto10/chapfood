import 'package:flutter/material.dart';

/// Widget pour gérer la responsivité de l'application
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return mobile;
        } else if (constraints.maxWidth < 1200) {
          return tablet ?? mobile;
        } else {
          return desktop ?? tablet ?? mobile;
        }
      },
    );
  }
}

/// Extension pour accéder facilement aux breakpoints
extension ResponsiveBreakpoints on BuildContext {
  bool get isMobile => MediaQuery.of(this).size.width < 600;
  bool get isTablet => MediaQuery.of(this).size.width >= 600 && MediaQuery.of(this).size.width < 1200;
  bool get isDesktop => MediaQuery.of(this).size.width >= 1200;
  
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  
  EdgeInsets get safeAreaPadding => MediaQuery.of(this).padding;
}

/// Widget pour adapter le padding selon la taille d'écran
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobilePadding;
  final EdgeInsets? tabletPadding;
  final EdgeInsets? desktopPadding;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: Padding(
        padding: mobilePadding ?? const EdgeInsets.all(16),
        child: child,
      ),
      tablet: Padding(
        padding: tabletPadding ?? const EdgeInsets.all(24),
        child: child,
      ),
      desktop: Padding(
        padding: desktopPadding ?? const EdgeInsets.all(32),
        child: child,
      ),
    );
  }
}

/// Widget pour adapter le nombre de colonnes selon la taille d'écran
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildGrid(context, mobileColumns ?? 1),
      tablet: _buildGrid(context, tabletColumns ?? 2),
      desktop: _buildGrid(context, desktopColumns ?? 3),
    );
  }

  Widget _buildGrid(BuildContext context, int columns) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: children.map((child) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - (spacing * (columns - 1))) / columns,
          child: child,
        );
      }).toList(),
    );
  }
}

/// Widget pour adapter la taille de police selon la taille d'écran
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      ),
      tablet: Text(
        text,
        style: style?.copyWith(
          fontSize: (style?.fontSize ?? 14) * 1.1,
        ),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      ),
      desktop: Text(
        text,
        style: style?.copyWith(
          fontSize: (style?.fontSize ?? 14) * 1.2,
        ),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}

