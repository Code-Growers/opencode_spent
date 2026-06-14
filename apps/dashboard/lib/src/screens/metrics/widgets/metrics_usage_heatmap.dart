import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../theme/dashboard_colors.dart';
import '../../dashboard/widgets/dashboard_surface.dart';
import '../metrics_utils.dart';

class MetricsUsageHeatmap extends StatelessWidget {
  const MetricsUsageHeatmap({
    super.key,
    required this.visibleDays,
    required this.dayData,
    required this.stats,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final List<DateTime> visibleDays;
  final List<HeatmapDayData> dayData;
  final HeatmapStats stats;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    if (visibleDays.isEmpty || dayData.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return DashboardSurface(
      key: const Key('metrics-usage-heatmap-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Text(l10n.metricsActivity, style: textTheme.titleMedium),
              _Legend(),
            ],
          ),
          const SizedBox(height: 16),
          _StatGrid(stats: stats),
          const SizedBox(height: 16),
          _HeatmapGrid(
            dayData: dayData,
            selectedDay: selectedDay,
            onDaySelected: onDaySelected,
          ),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});

  final HeatmapStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = DashboardSpacing.nestedPanelPadding;
        const minCardWidth = 170.0;
        var crossAxisCount = (constraints.maxWidth / minCardWidth).floor();
        if (crossAxisCount < 1) {
          crossAxisCount = 1;
        }
        if (crossAxisCount > 4) {
          crossAxisCount = 4;
        }

        final width =
            (constraints.maxWidth - ((crossAxisCount - 1) * spacing)) /
                crossAxisCount -
            0.1;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            _StatCard(
              key: const Key('metrics-heatmap-active-days'),
              width: width,
              label: l10n.metricsActiveDays,
              value: stats.activeDays.toString(),
            ),
            _StatCard(
              key: const Key('metrics-heatmap-current-streak'),
              width: width,
              label: l10n.metricsCurrentStreak,
              value: l10n.metricsDayCountCompact(stats.currentStreak),
            ),
            _StatCard(
              key: const Key('metrics-heatmap-longest-streak'),
              width: width,
              label: l10n.metricsLongestStreak,
              value: l10n.metricsDayCountCompact(stats.longestStreak),
            ),
            _StatCard(
              key: const Key('metrics-heatmap-peak-day'),
              width: width,
              label: l10n.metricsPeakDay,
              value: stats.peakDay == null
                  ? l10n.metricsKpiNotAvailable
                  : formatDayChipLabel(context, stats.peakDay!),
              detail: stats.peakDaySessionCount > 0
                  ? l10n.metricsPeakDayDetail(stats.peakDaySessionCount)
                  : null,
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    super.key,
    required this.width,
    required this.label,
    required this.value,
    this.detail,
  });

  final double width;
  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: width,
      child: DashboardSurface(
        padding: const EdgeInsets.all(DashboardSpacing.nestedPanelPadding),
        backgroundColor: dashboardSurfaceElevatedColor,
        borderColor: dashboardBorderColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: dashboardSecondaryTextColor,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: textTheme.titleLarge?.copyWith(
                color: dashboardPrimaryTextColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 6),
              Text(
                detail!,
                style: textTheme.bodySmall?.copyWith(
                  color: dashboardSecondaryTextColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  const _HeatmapGrid({
    required this.dayData,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final List<HeatmapDayData> dayData;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  static const _weekdayLabels = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final firstWeekdayOffset = dayData.first.day.weekday - 1;
    final padded = List<HeatmapDayData?>.filled(
      firstWeekdayOffset,
      null,
      growable: true,
    )..addAll(dayData);
    final weekCount = (padded.length / 7).ceil();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Column(
            children: _weekdayLabels
                .map(
                  (label) => SizedBox(
                    width: 14,
                    height: 16,
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: dashboardSecondaryTextColor,
                            fontSize: 9,
                          ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SingleChildScrollView(
            key: const Key('metrics-heatmap-grid'),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(weekCount, (columnIndex) {
                return Padding(
                  padding: EdgeInsets.only(right: columnIndex == weekCount - 1 ? 0 : 4),
                  child: Column(
                    children: List.generate(7, (rowIndex) {
                      final paddedIndex = (columnIndex * 7) + rowIndex;
                      final cell = paddedIndex < padded.length ? padded[paddedIndex] : null;
                      return Padding(
                        padding: EdgeInsets.only(bottom: rowIndex == 6 ? 0 : 4),
                        child: _HeatmapCell(
                          data: cell,
                          isSelected: cell != null &&
                              selectedDay != null &&
                              isSameUtcDay(cell.day, selectedDay!),
                          onTap: cell == null ? null : () => onDaySelected(cell.day),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeatmapCell extends StatelessWidget {
  const _HeatmapCell({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  final HeatmapDayData? data;
  final bool isSelected;
  final VoidCallback? onTap;

  Color _resolveColor() {
    if (data == null) {
      return Colors.transparent;
    }

    return switch (data!.level) {
      0 => dashboardSurfaceHighlightColor,
      1 => dashboardAccentColor.withValues(alpha: 0.28),
      2 => dashboardAccentColor.withValues(alpha: 0.45),
      3 => dashboardAccentColor.withValues(alpha: 0.68),
      _ => dashboardAccentColor,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const SizedBox(width: 14, height: 14);
    }

    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      label: l10n.metricsHeatmapCellLabel(
        formatDayChipLabel(context, data!.day),
        data!.sessionCount,
        compactNumber(data!.tokenCount.toDouble()),
      ),
      selected: isSelected,
      button: true,
      child: Tooltip(
        message: l10n.metricsHeatmapCellTooltip(
          formatDayChipLabel(context, data!.day),
          data!.sessionCount,
          compactNumber(data!.tokenCount.toDouble()),
        ),
        child: InkWell(
          key: Key('metrics-heatmap-cell-${data!.day.toIso8601String()}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(3),
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: dashboardPrimaryTextColor.withValues(alpha: 0.08),
          hoverColor: dashboardPrimaryTextColor.withValues(alpha: 0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: _resolveColor(),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: isSelected
                    ? dashboardPrimaryTextColor
                    : data!.level == 0
                        ? dashboardBorderColor
                        : _resolveColor(),
                width: isSelected ? 1.5 : 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.metricsHeatmapLegendLow,
          style: textTheme.bodySmall?.copyWith(color: dashboardSecondaryTextColor),
        ),
        const SizedBox(width: 8),
        for (final level in [0, 1, 2, 3, 4]) ...[
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: switch (level) {
                0 => dashboardSurfaceHighlightColor,
                1 => dashboardAccentColor.withValues(alpha: 0.28),
                2 => dashboardAccentColor.withValues(alpha: 0.45),
                3 => dashboardAccentColor.withValues(alpha: 0.68),
                _ => dashboardAccentColor,
              },
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: dashboardBorderColor),
            ),
          ),
        ],
        const SizedBox(width: 4),
        Text(
          l10n.metricsHeatmapLegendHigh,
          style: textTheme.bodySmall?.copyWith(color: dashboardSecondaryTextColor),
        ),
      ],
    );
  }
}
