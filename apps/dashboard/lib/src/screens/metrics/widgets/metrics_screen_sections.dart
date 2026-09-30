import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../theme/dashboard_colors.dart';
import '../../dashboard/widgets/dashboard_chip_button.dart';
import '../../dashboard/widgets/dashboard_surface.dart';
import '../metrics_utils.dart';

class MetricsWindowControls extends StatelessWidget {
  const MetricsWindowControls({
    super.key,
    required this.selectedWindow,
    required this.onWindowSelected,
    required this.onCustomWindowRequested,
  });

  final TimeWindow selectedWindow;
  final ValueChanged<TimeWindow> onWindowSelected;
  final VoidCallback onCustomWindowRequested;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: DashboardSpacing.controlGap,
      runSpacing: DashboardSpacing.controlGap,
      children: [
        Text(l10n.metricsTitle, style: textTheme.titleMedium),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: DashboardSpacing.controlGap,
          runSpacing: DashboardSpacing.controlGap,
          children: [
            DashboardChipButton(
              key: const Key('metrics-window-7d'),
              label: l10n.windowAction7d,
              isSelected: selectedWindow == TimeWindow.days7,
              onTap: () => onWindowSelected(TimeWindow.days7),
            ),
            DashboardChipButton(
              key: const Key('metrics-window-30d'),
              label: l10n.windowAction30d,
              isSelected: selectedWindow == TimeWindow.days30,
              onTap: () => onWindowSelected(TimeWindow.days30),
            ),
            DashboardChipButton(
              key: const Key('metrics-window-90d'),
              label: l10n.windowAction90d,
              isSelected: selectedWindow == TimeWindow.days90,
              onTap: () => onWindowSelected(TimeWindow.days90),
            ),
            DashboardChipButton(
              key: const Key('metrics-window-all'),
              label: l10n.windowActionAll,
              isSelected: selectedWindow == TimeWindow.all,
              onTap: () => onWindowSelected(TimeWindow.all),
            ),
            DashboardChipButton(
              key: const Key('metrics-window-custom'),
              label: l10n.windowActionCustom,
              isSelected: selectedWindow == TimeWindow.custom,
              onTap: onCustomWindowRequested,
            ),
          ],
        ),
      ],
    );
  }
}

class MetricsVisibleWindowLine extends StatelessWidget {
  const MetricsVisibleWindowLine({
    super.key,
    required this.selectedWindow,
    this.from,
    this.to,
  });

  final TimeWindow selectedWindow;
  final DateTime? from;
  final DateTime? to;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: DashboardSpacing.nestedPanelPadding,
      ),
      child: Text(
        l10n.lineVisibleWindow(
          formatWindowLabel(context, selectedWindow, from, to),
        ),
        key: const Key('metrics-window-line'),
        style: textTheme.bodyLarge,
      ),
    );
  }
}

class MetricsDayPickerButton extends StatelessWidget {
  const MetricsDayPickerButton({
    super.key,
    required this.selectedDay,
    required this.visibleDays,
    required this.onDaySelected,
  });

  final DateTime selectedDay;
  final List<DateTime> visibleDays;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (visibleDays.isEmpty) {
      return const SizedBox.shrink();
    }

    final firstDate = visibleDays.first;
    final lastDate = visibleDays.last;

    return Semantics(
      button: true,
      value: formatDayChipLabel(context, selectedDay),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('metrics-day-picker-button'),
          borderRadius: BorderRadius.zero,
          hoverColor: dashboardPrimaryTextColor.withValues(alpha: 0.05),
          focusColor: dashboardPrimaryTextColor.withValues(alpha: 0.1),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDay,
              firstDate: firstDate,
              lastDate: lastDate,
            );
            if (picked != null) {
              final utcDay = DateTime.utc(
                picked.year,
                picked.month,
                picked.day,
              );
              if (containsUtcDay(visibleDays, utcDay)) {
                onDaySelected(utcDay);
              }
            }
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: dashboardBorderColor),
              borderRadius: BorderRadius.zero,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: dashboardSecondaryTextColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '[ ${formatDayChipLabel(context, selectedDay)} ]',
                  style: textTheme.bodyMedium?.copyWith(
                    color: dashboardPrimaryTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MetricsViewTabs extends StatelessWidget {
  const MetricsViewTabs({
    super.key,
    required this.selectedViewIndex,
    required this.onViewSelected,
  });

  final int selectedViewIndex;
  final ValueChanged<int> onViewSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      alignment: WrapAlignment.end,
      spacing: DashboardSpacing.controlGap,
      runSpacing: DashboardSpacing.controlGap,
      children: [
        DashboardChipButton(
          key: const Key('metrics-tab-text'),
          label: l10n.textTab,
          isSelected: selectedViewIndex == 0,
          onTap: () => onViewSelected(0),
        ),
        DashboardChipButton(
          key: const Key('metrics-tab-spend'),
          label: l10n.spendTab,
          isSelected: selectedViewIndex == 1,
          onTap: () => onViewSelected(1),
        ),
        DashboardChipButton(
          key: const Key('metrics-tab-tokens'),
          label: l10n.tokensTab,
          isSelected: selectedViewIndex == 2,
          onTap: () => onViewSelected(2),
        ),
        DashboardChipButton(
          key: const Key('metrics-tab-models'),
          label: l10n.modelsTab,
          isSelected: selectedViewIndex == 3,
          onTap: () => onViewSelected(3),
        ),
        DashboardChipButton(
          key: const Key('metrics-tab-providers'),
          label: l10n.metricsProvidersTab,
          isSelected: selectedViewIndex == 4,
          onTap: () => onViewSelected(4),
        ),
      ],
    );
  }
}

class MetricsViewSection extends StatelessWidget {
  const MetricsViewSection({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const Key('metrics-view-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [child],
      ),
    );
  }
}
