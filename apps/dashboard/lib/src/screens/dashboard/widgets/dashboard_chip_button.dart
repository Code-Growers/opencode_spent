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

    if (widget.isEmphasized) {
      backgroundColor = Colors.transparent;
      borderColor = widget.activeColor;
      textColor = widget.activeColor;
    } else if (widget.isSelected) {
      backgroundColor = dashboardSurfaceHighlightColor;
      borderColor = widget.activeColor;
      textColor = widget.activeColor;
    } else if (_isFocused) {
      backgroundColor = Colors.transparent;
      borderColor = dashboardAccentColor;
      textColor = dashboardPrimaryTextColor;
    } else if (_isHovered) {
      backgroundColor = dashboardPrimaryTextColor;
      borderColor = dashboardPrimaryTextColor;
      textColor = dashboardBackgroundColor;
    } else {
      backgroundColor = Colors.transparent;
      borderColor = dashboardBorderColor;
      textColor = dashboardSecondaryTextColor;
    }

    return Semantics(
      button: true,
      selected: widget.isSelected ? true : null,
      enabled: widget.onTap != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          autofocus: widget.autofocus,
          borderRadius: BorderRadius.zero,
          onHover: (hovered) => setState(() => _isHovered = hovered),
          onFocusChange: (focused) => setState(() => _isFocused = focused),
          mouseCursor: widget.onTap != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(color: borderColor, width: _isFocused ? 2 : 1),
              borderRadius: BorderRadius.zero,
            ),
            child: Text(
              widget.label,
              style: textTheme.labelLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
