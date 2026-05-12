import 'package:flutter/material.dart';
import '../../../theme/dashboard_colors.dart';

class DashboardChipButton extends StatefulWidget {
  const DashboardChipButton({
    super.key,
    required this.label,
    this.onTap,
    this.isSelected = false,
    this.isEmphasized = false,
    this.activeColor = dashboardAccentColor,
    this.autofocus = false,
  }) : assert(
         !(isSelected && isEmphasized),
         'A chip cannot be both selected and emphasized.',
       );

  final String label;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isEmphasized;
  final Color activeColor;
  final bool autofocus;

  @override
  State<DashboardChipButton> createState() => _DashboardChipButtonState();
}

class _DashboardChipButtonState extends State<DashboardChipButton> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final Color borderColor;
    final Color backgroundColor;
    final Color textColor;
    final List<BoxShadow>? boxShadow;

    if (widget.isEmphasized) {
      backgroundColor = widget.activeColor.withValues(alpha: 0.1);
      borderColor = widget.activeColor.withValues(alpha: 0.5);
      textColor = widget.activeColor;
    } else if (widget.isSelected) {
      backgroundColor = widget.activeColor.withValues(alpha: 0.1);
      borderColor = widget.activeColor.withValues(alpha: 0.5);
      textColor = widget.activeColor;
    } else if (_isFocused) {
      backgroundColor = Colors.transparent;
      borderColor = dashboardAccentColor;
      textColor = dashboardPrimaryTextColor;
    } else if (_isHovered) {
      backgroundColor = dashboardSurfaceHighlightColor;
      borderColor = dashboardPrimaryTextColor;
      textColor = dashboardPrimaryTextColor;
    } else {
      backgroundColor = Colors.transparent;
      borderColor = dashboardBorderColor;
      textColor = dashboardSecondaryTextColor;
    }

    boxShadow = _isFocused
        ? [
            BoxShadow(
              color: dashboardAccentColor.withValues(alpha: 0.35),
              blurRadius: 0,
              spreadRadius: 1,
            ),
          ]
        : null;

    return Semantics(
      button: true,
      selected: widget.isSelected ? true : null,
      enabled: widget.onTap != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          autofocus: widget.autofocus,
          borderRadius: BorderRadius.circular(4.0),
          onHover: (hovered) => setState(() => _isHovered = hovered),
          onFocusChange: (focused) => setState(() => _isFocused = focused),
          mouseCursor: widget.onTap != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(4.0),
              boxShadow: boxShadow,
            ),
            child: Text(
              widget.label,
              style: textTheme.labelLarge?.copyWith(
                color: textColor,
                fontWeight: widget.isSelected || widget.isEmphasized
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
