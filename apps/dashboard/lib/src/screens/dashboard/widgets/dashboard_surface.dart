import 'package:flutter/material.dart';
import '../../../theme/dashboard_colors.dart';

class DashboardSpacing {
  static const double shellGutter = 24.0;
  static const double primaryPanelPadding = 20.0;
  static const double nestedPanelPadding = 16.0;
  static const double controlGap = 12.0;
  static const double majorSectionGap = 24.0;
}

class DashboardSurface extends StatelessWidget {
  const DashboardSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.borderColor = dashboardBorderColor,
    this.backgroundColor = dashboardSurfaceColor,
    this.highlight = false,
    this.radius = 18.0,
    this.showGlow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color borderColor;
  final Color backgroundColor;
  final bool highlight;
  final double radius;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final effectiveBackground = highlight
        ? dashboardSurfaceHighlightColor
        : backgroundColor;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: highlight ? 0.36 : 0.24),
            blurRadius: highlight ? 28.0 : 18.0,
            offset: const Offset(0, 12),
          ),
          if (showGlow)
            BoxShadow(
              color: dashboardGlowColor.withValues(alpha: 0.18),
              blurRadius: 36,
              spreadRadius: -8,
            ),
        ],
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: effectiveBackground,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              effectiveBackground.withValues(alpha: 0.98),
              Color.alphaBlend(
                dashboardAccentColor.withValues(alpha: showGlow ? 0.10 : 0.03),
                effectiveBackground,
              ),
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}
