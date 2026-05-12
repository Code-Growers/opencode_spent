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
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color borderColor;
  final Color backgroundColor;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: highlight ? dashboardSurfaceHighlightColor : backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(4.0),
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8.0,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
