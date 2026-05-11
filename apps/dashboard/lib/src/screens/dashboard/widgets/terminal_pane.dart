import 'package:flutter/material.dart';

import '../../../theme/dashboard_colors.dart';

class TerminalPane extends StatelessWidget {
  const TerminalPane({
    super.key,
    required this.title,
    required this.lines,
    this.lineStyles,
  });

  final String title;
  final List<String> lines;
  final List<TextStyle?>? lineStyles;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dashboardSurfaceColor,
        border: Border.all(color: dashboardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleMedium),
          const SizedBox(height: 12),
          for (var index = 0; index < lines.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                lines[index],
                style: textTheme.bodyLarge?.merge(
                  index < (lineStyles?.length ?? 0) ? lineStyles![index] : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
