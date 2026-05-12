import 'package:flutter/material.dart';

class DashboardPairedRow extends StatelessWidget {
  const DashboardPairedRow({
    super.key,
    required this.firstChild,
    required this.secondChild,
    this.spacing = 24.0,
  });

  final Widget firstChild;
  final Widget secondChild;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: firstChild),
          SizedBox(width: spacing),
          Expanded(child: secondChild),
        ],
      ),
    );
  }
}
