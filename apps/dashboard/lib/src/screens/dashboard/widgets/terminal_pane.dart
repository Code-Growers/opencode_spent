import 'package:flutter/material.dart';

import '../../../theme/dashboard_colors.dart';
import 'dashboard_surface.dart';

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

    return DashboardSurface(
      padding: const EdgeInsets.all(16),
      backgroundColor: dashboardSurfaceElevatedColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleMedium),
          const SizedBox(height: 16),
          DashboardSurface(
            backgroundColor: dashboardBackgroundColor,
            radius: 14,
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < lines.length; index++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: index == lines.length - 1 ? 0 : 6,
                      ),
                      child: Text(
                        lines[index],
                        style: textTheme.bodyLarge?.merge(
                          index < (lineStyles?.length ?? 0)
                              ? lineStyles![index]
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
