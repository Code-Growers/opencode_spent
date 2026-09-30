import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:openspent_core/openspent_core.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../theme/dashboard_colors.dart';
import 'metrics_chart_widgets.dart';
import '../metrics_utils.dart';
import '../../dashboard/widgets/dashboard_surface.dart';
import '../../dashboard/widgets/dashboard_paired_row.dart';

class _InlineActionText extends StatefulWidget {
  const _InlineActionText({
    super.key,
    required this.text,
    required this.style,
    required this.onTap,
  });

  final String text;
  final TextStyle? style;
  final VoidCallback onTap;

  @override
  State<_InlineActionText> createState() => _InlineActionTextState();
}

class _InlineActionTextState extends State<_InlineActionText> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: true,
      child: FocusableActionDetector(
        onShowFocusHighlight: (v) => setState(() => _isFocused = v),
        mouseCursor: SystemMouseCursors.click,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => widget.onTap(),
          ),
        },
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: _isFocused
                  ? dashboardPrimaryTextColor.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.zero,
            ),
            child: Text(widget.text, style: widget.style),
          ),
        ),
      ),
    );
  }
}

class MetricsTextSummary extends StatelessWidget {
  const MetricsTextSummary({
    super.key,
    required this.visibleDays,
    required this.metrics,
    required this.priorMetrics,
    required this.displayCurrency,
    required this.selectedDay,
    required this.selectedModelFilter,
    required this.onModelSelected,
    this.from,
    this.to,
  });

  final List<DateTime> visibleDays;
  final MonetizedAggregatedMetrics metrics;
  final MonetizedAggregatedMetrics? priorMetrics;
  final String displayCurrency;
  final DateTime? selectedDay;
  final String? selectedModelFilter;
  final ValueChanged<String?> onModelSelected;
  final DateTime? from;
  final DateTime? to;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final base = metrics.baseMetrics;
    final totalTokensValue = totalTokens(
      base.totalInputTokens,
      base.totalOutputTokens,
    );
    final selectedDaily = selectedDay == null
        ? null
        : findDailyMetricsForDay(metrics.dailyBreakdown, selectedDay!);
    final selectedHourEntries = selectedDay == null
        ? const <MonetizedHourlyMetrics>[]
        : findHourlyMetricsForDay(metrics.hourlyBreakdown, selectedDay!);

    MonetizedHourlyMetrics? peakHour;
    for (final hourMetrics in selectedHourEntries) {
      if (peakHour == null ||
          hourMetrics.displayTotalCost > peakHour.displayTotalCost) {
        peakHour = hourMetrics;
      }
    }

    final selectedInputTokens = selectedDaily?.baseMetrics.inputTokens ?? 0;
    final selectedOutputTokens = selectedDaily?.baseMetrics.outputTokens ?? 0;
    final selectedTotalTokens = totalTokens(
      selectedInputTokens,
      selectedOutputTokens,
    );

    final rollingCostSeries = buildVisibleDailyCostSeries(
      metrics.dailyBreakdown,
      visibleDays,
    );
    final rollingTokenSeries = buildVisibleDailyTokenSeries(
      metrics.dailyBreakdown,
      visibleDays,
    );
    final rollingAvgCost = averageDoubleSeries(rollingCostSeries);
    final rollingAvgTokens = averageIntSeries(rollingTokenSeries);
    final paceForecast = rollingAvgCost * 7;

    String topMoverName = '';
    double topMoverDelta = 0.0;

    String compareDriverName = '';
    double compareDriverDelta = 0.0;
    if (priorMetrics != null) {
      final allModels = {
        ...metrics.perModelDailyBreakdown.keys,
        ...priorMetrics!.perModelDailyBreakdown.keys,
      };
      for (final model in allModels) {
        final currentCost =
            metrics.perModelDailyBreakdown[model]?.fold<double>(
              0.0,
              (sum, entry) => sum + entry.displayTotalCost,
            ) ??
            0.0;
        final previousCost =
            priorMetrics!.perModelDailyBreakdown[model]?.fold<double>(
              0.0,
              (sum, entry) => sum + entry.displayTotalCost,
            ) ??
            0.0;
        final delta = currentCost - previousCost;
        if (delta.abs() > compareDriverDelta.abs()) {
          compareDriverDelta = delta;
          compareDriverName = model;
        }
      }
    }

    if (visibleDays.isNotEmpty && metrics.perModelDailyBreakdown.isNotEmpty) {
      final anchorDay = visibleDays.last;
      final prevVisibleDay = visibleDays.length > 1
          ? visibleDays[visibleDays.length - 2]
          : null;

      for (final entry in metrics.perModelDailyBreakdown.entries) {
        final anchorMetric = entry.value
            .where((item) => isSameUtcDay(item.baseMetrics.date, anchorDay))
            .firstOrNull;
        final prevMetric = prevVisibleDay == null
            ? null
            : entry.value
                  .where(
                    (item) =>
                        isSameUtcDay(item.baseMetrics.date, prevVisibleDay),
                  )
                  .firstOrNull;

        final anchorCost = anchorMetric?.displayTotalCost ?? 0.0;
        final prevCost = prevMetric?.displayTotalCost ?? 0.0;
        final delta = anchorCost - prevCost;

        if (delta.abs() > topMoverDelta.abs()) {
          topMoverDelta = delta;
          topMoverName = entry.key;
        }
      }
    }

    final usageByModel = <String, int>{};
    for (final entry in metrics.perModelDailyBreakdown.entries) {
      int tokens = 0;
      for (final daily in entry.value) {
        tokens +=
            daily.baseMetrics.inputTokens + daily.baseMetrics.outputTokens;
      }
      if (tokens > 0) {
        usageByModel[entry.key] = tokens;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            if (!isNarrow) {
              return DashboardPairedRow(
                spacing: DashboardSpacing.nestedPanelPadding,
                firstChild: DashboardSurface(
                  key: const Key('metrics-summary-overview-surface'),
                  padding: const EdgeInsets.all(
                    DashboardSpacing.primaryPanelPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.overallSection, style: textTheme.bodyMedium),
                      const SizedBox(height: DashboardSpacing.controlGap),
                      Text(
                        l10n.lineTotalCost(
                          displayCurrency,
                          metrics.displayTotalCost.toStringAsFixed(2),
                        ),
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.lineRollingAvgCost(
                          displayCurrency,
                          rollingAvgCost.toStringAsFixed(2),
                        ),
                        key: const Key('metrics-rolling-cost-line'),
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.lineRollingAvgTokens(
                          compactNumber(rollingAvgTokens.toDouble()),
                        ),
                        key: const Key('metrics-rolling-tokens-line'),
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.linePaceForecast(
                          displayCurrency,
                          paceForecast.toStringAsFixed(2),
                        ),
                        key: const Key('metrics-pace-line'),
                        style: textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                secondChild: DashboardSurface(
                  key: const Key('metrics-summary-details-surface'),
                  padding: const EdgeInsets.all(
                    DashboardSpacing.primaryPanelPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.lineSessions(base.totalSessionCount),
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.lineInputTokens(
                          compactNumber(base.totalInputTokens.toDouble()),
                        ),
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.lineOutputTokens(
                          compactNumber(base.totalOutputTokens.toDouble()),
                        ),
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.lineTotalTokens(
                          compactNumber(totalTokensValue.toDouble()),
                        ),
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.lineAvgTokensPerSession(
                          formatAverageTokensPerSession(
                            totalTokensValue: totalTokensValue,
                            sessionCount: base.totalSessionCount,
                          ),
                        ),
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.lineCostPerMillionTokens(
                          displayCurrency,
                          formatCostPerMillion(
                            totalCost: metrics.displayTotalCost,
                            totalTokensValue: totalTokensValue,
                          ),
                        ),
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      if (topMoverName.isNotEmpty)
                        _InlineActionText(
                          key: const Key('metrics-top-mover-line'),
                          onTap: () => onModelSelected(
                            selectedModelFilter == topMoverName
                                ? null
                                : topMoverName,
                          ),
                          text: l10n.lineTopMover(
                            topMoverName,
                            topMoverDelta >= 0 ? '+' : '',
                            displayCurrency,
                            topMoverDelta.abs().toStringAsFixed(2),
                          ),
                          style: textTheme.bodyLarge?.copyWith(
                            color: selectedModelFilter == topMoverName
                                ? dashboardBorderColor
                                : dashboardAccentColor,
                          ),
                        )
                      else
                        Text(
                          l10n.lineTopMoverEmpty,
                          key: const Key('metrics-top-mover-line-empty'),
                          style: textTheme.bodyLarge,
                        ),
                    ],
                  ),
                ),
              );
            }
            return Flex(
              direction: Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 0,
                  child: DashboardSurface(
                    key: const Key('metrics-summary-overview-surface'),
                    padding: const EdgeInsets.all(
                      DashboardSpacing.primaryPanelPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.overallSection, style: textTheme.bodyMedium),
                        const SizedBox(height: DashboardSpacing.controlGap),
                        Text(
                          l10n.lineTotalCost(
                            displayCurrency,
                            metrics.displayTotalCost.toStringAsFixed(2),
                          ),
                          style: textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.lineRollingAvgCost(
                            displayCurrency,
                            rollingAvgCost.toStringAsFixed(2),
                          ),
                          key: const Key('metrics-rolling-cost-line'),
                          style: textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.lineRollingAvgTokens(
                            compactNumber(rollingAvgTokens.toDouble()),
                          ),
                          key: const Key('metrics-rolling-tokens-line'),
                          style: textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.linePaceForecast(
                            displayCurrency,
                            paceForecast.toStringAsFixed(2),
                          ),
                          key: const Key('metrics-pace-line'),
                          style: textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: DashboardSpacing.nestedPanelPadding),
                Expanded(
                  flex: 0,
                  child: DashboardSurface(
                    key: const Key('metrics-summary-details-surface'),
                    padding: const EdgeInsets.all(
                      DashboardSpacing.primaryPanelPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.lineSessions(base.totalSessionCount),
                          style: textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.lineInputTokens(
                            compactNumber(base.totalInputTokens.toDouble()),
                          ),
                          style: textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.lineOutputTokens(
                            compactNumber(base.totalOutputTokens.toDouble()),
                          ),
                          style: textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.lineTotalTokens(
                            compactNumber(totalTokensValue.toDouble()),
                          ),
                          style: textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.lineAvgTokensPerSession(
                            formatAverageTokensPerSession(
                              totalTokensValue: totalTokensValue,
                              sessionCount: base.totalSessionCount,
                            ),
                          ),
                          style: textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.lineCostPerMillionTokens(
                            displayCurrency,
                            formatCostPerMillion(
                              totalCost: metrics.displayTotalCost,
                              totalTokensValue: totalTokensValue,
                            ),
                          ),
                          style: textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        if (topMoverName.isNotEmpty)
                          _InlineActionText(
                            key: const Key('metrics-top-mover-line'),
                            onTap: () => onModelSelected(
                              selectedModelFilter == topMoverName
                                  ? null
                                  : topMoverName,
                            ),
                            text: l10n.lineTopMover(
                              topMoverName,
                              topMoverDelta >= 0 ? '+' : '',
                              displayCurrency,
                              topMoverDelta.abs().toStringAsFixed(2),
                            ),
                            style: textTheme.bodyLarge?.copyWith(
                              color: selectedModelFilter == topMoverName
                                  ? dashboardBorderColor
                                  : dashboardAccentColor,
                            ),
                          )
                        else
                          Text(
                            l10n.lineTopMoverEmpty,
                            key: const Key('metrics-top-mover-line-empty'),
                            style: textTheme.bodyLarge,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: DashboardSpacing.majorSectionGap),
        LayoutBuilder(
          key: const Key('metrics-overview-section'),
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 800;
            final double childWidth = isNarrow
                ? constraints.maxWidth
                : (constraints.maxWidth -
                          DashboardSpacing.nestedPanelPadding * 2) /
                      3;

            final dateLabels = visibleDays
                .map(
                  (d) => DateFormat.Md(
                    Localizations.localeOf(context).toString(),
                  ).format(d),
                )
                .toList();

            return Wrap(
              spacing: DashboardSpacing.nestedPanelPadding,
              runSpacing: DashboardSpacing.nestedPanelPadding,
              children: [
                SizedBox(
                  width: childWidth,
                  child: CompactDashboardLineChart(
                    key: const Key('metrics-overview-sessions-chart'),
                    title: l10n.metricsOverviewSessionsPerDay,
                    values: buildVisibleDailySessionsSeries(
                      metrics.dailyBreakdown,
                      visibleDays,
                    ),
                    xLabels: dateLabels,
                    xAxisTitle: l10n.axisLabelDate,
                    yAxisTitle: l10n.axisLabelSessions,
                    yLabelFormatter: (val) => compactNumber(val),
                  ),
                ),
                SizedBox(
                  width: childWidth,
                  child: CompactDashboardLineChart(
                    key: const Key('metrics-overview-avg-cost-chart'),
                    title: l10n.metricsOverviewAvgCostPerSession,
                    values: buildVisibleDailyAvgCostPerSessionSeries(
                      metrics.dailyBreakdown,
                      visibleDays,
                    ),
                    xLabels: dateLabels,
                    xAxisTitle: l10n.axisLabelDate,
                    yAxisTitle: l10n.axisLabelAvgCost,
                    yLabelFormatter: (val) => val.toStringAsFixed(2),
                  ),
                ),
                SizedBox(
                  width: childWidth,
                  child: CompactDashboardLineChart(
                    key: const Key('metrics-overview-avg-tokens-chart'),
                    title: l10n.metricsOverviewAvgTokensPerSession,
                    values: buildVisibleDailyAvgTokensPerSessionSeries(
                      metrics.dailyBreakdown,
                      visibleDays,
                    ),
                    xLabels: dateLabels,
                    xAxisTitle: l10n.axisLabelDate,
                    yAxisTitle: l10n.axisLabelAvgTokens,
                    yLabelFormatter: (val) => compactNumber(val),
                  ),
                ),
              ],
            );
          },
        ),
        if (usageByModel.isNotEmpty) ...[
          const SizedBox(height: DashboardSpacing.majorSectionGap),
          Text(l10n.modelsTab, style: textTheme.bodyMedium),
          const SizedBox(height: DashboardSpacing.controlGap),
          ModelUsagePieChart(
            expanded: true,
            usageByModel: usageByModel,
            chartKey: const Key('metrics-summary-model-pie'),
          ),
        ],
        if (from != null && to != null) ...[
          const SizedBox(height: DashboardSpacing.majorSectionGap),
          DashboardSurface(
            key: const Key('metrics-summary-compare-surface'),
            padding: const EdgeInsets.all(DashboardSpacing.primaryPanelPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (priorMetrics != null) ...[
                  Text(
                    l10n.comparePriorWindow(
                      '${formatDateKey(context, from!.subtract(Duration(days: to!.difference(from!).inDays + 1)))} - ${formatDateKey(context, from!.subtract(const Duration(days: 1)))}',
                    ),
                    key: const Key('metrics-compare-prior-window'),
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: DashboardSpacing.controlGap),
                  Text(
                    l10n.compareSummary(
                      (metrics.displayTotalCost -
                                  priorMetrics!.displayTotalCost) >=
                              0
                          ? '+'
                          : '-',
                      displayCurrency,
                      (metrics.displayTotalCost -
                              priorMetrics!.displayTotalCost)
                          .abs()
                          .toStringAsFixed(2),
                    ),
                    key: const Key('metrics-compare-total-line'),
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.compareDeltaSessions(
                      (metrics.baseMetrics.totalSessionCount -
                                  priorMetrics!
                                      .baseMetrics
                                      .totalSessionCount) >=
                              0
                          ? '+'
                          : '-',
                      (metrics.baseMetrics.totalSessionCount -
                              priorMetrics!.baseMetrics.totalSessionCount)
                          .abs(),
                    ),
                    key: const Key('metrics-compare-sessions-line'),
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.compareDeltaTokens(
                      (totalTokensValue -
                                  totalTokens(
                                    priorMetrics!.baseMetrics.totalInputTokens,
                                    priorMetrics!.baseMetrics.totalOutputTokens,
                                  )) >=
                              0
                          ? '+'
                          : '-',
                      (totalTokensValue -
                              totalTokens(
                                priorMetrics!.baseMetrics.totalInputTokens,
                                priorMetrics!.baseMetrics.totalOutputTokens,
                              ))
                          .abs(),
                    ),
                    key: const Key('metrics-compare-tokens-line'),
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final priorTokens = totalTokens(
                        priorMetrics!.baseMetrics.totalInputTokens,
                        priorMetrics!.baseMetrics.totalOutputTokens,
                      );
                      final decomp = decomposeCompareDelta(
                        currentSessions: metrics.baseMetrics.totalSessionCount,
                        currentTokens: totalTokensValue,
                        currentCost: metrics.displayTotalCost,
                        priorSessions:
                            priorMetrics!.baseMetrics.totalSessionCount,
                        priorTokens: priorTokens,
                        priorCost: priorMetrics!.displayTotalCost,
                      );

                      if (decomp == null) {
                        return Text(
                          l10n.compareSplitUnavailable,
                          key: const Key('metrics-compare-split-unavailable'),
                          style: textTheme.bodyLarge,
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.compareSplitSessions(
                              decomp.splitSessions >= 0 ? '+' : '-',
                              displayCurrency,
                              decomp.splitSessions.abs().toStringAsFixed(2),
                            ),
                            key: const Key(
                              'metrics-compare-split-sessions-line',
                            ),
                            style: textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.compareSplitAvg(
                              decomp.splitAvg >= 0 ? '+' : '-',
                              displayCurrency,
                              decomp.splitAvg.abs().toStringAsFixed(2),
                            ),
                            key: const Key('metrics-compare-split-avg-line'),
                            style: textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.compareSplitCost(
                              decomp.splitCost >= 0 ? '+' : '-',
                              displayCurrency,
                              decomp.splitCost.abs().toStringAsFixed(2),
                            ),
                            key: const Key('metrics-compare-split-cost-line'),
                            style: textTheme.bodyLarge,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  if (compareDriverName.isNotEmpty)
                    _InlineActionText(
                      key: const Key('metrics-compare-driver-line'),
                      onTap: () {
                        if (metrics.perModelDailyBreakdown.containsKey(
                          compareDriverName,
                        )) {
                          onModelSelected(
                            selectedModelFilter == compareDriverName
                                ? null
                                : compareDriverName,
                          );
                        }
                      },
                      text: l10n.compareSummaryDriver(
                        compareDriverName,
                        compareDriverDelta >= 0 ? '+' : '-',
                        displayCurrency,
                        compareDriverDelta.abs().toStringAsFixed(2),
                      ),
                      style: textTheme.bodyLarge?.copyWith(
                        color: selectedModelFilter == compareDriverName
                            ? dashboardBorderColor
                            : (metrics.perModelDailyBreakdown.containsKey(
                                    compareDriverName,
                                  )
                                  ? dashboardAccentColor
                                  : textTheme.bodyLarge?.color?.withValues(
                                      alpha: 0.5,
                                    )),
                      ),
                    )
                  else
                    Text(
                      l10n.compareSummaryNoDriver,
                      key: const Key('metrics-compare-driver-line-empty'),
                      style: textTheme.bodyLarge,
                    ),
                ] else ...[
                  Text(
                    l10n.compareUnavailableHelper,
                    key: const Key('metrics-compare-unavailable'),
                    style: textTheme.bodyLarge,
                  ),
                ],
              ],
            ),
          ),
        ],
        if (selectedDay != null) ...[
          const SizedBox(height: DashboardSpacing.majorSectionGap),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;
              if (!isNarrow) {
                return DashboardPairedRow(
                  spacing: DashboardSpacing.nestedPanelPadding,
                  firstChild: DashboardSurface(
                    key: const Key('metrics-summary-selected-day-surface'),
                    padding: const EdgeInsets.all(
                      DashboardSpacing.primaryPanelPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.selectedDaySection(
                            formatDateKey(context, selectedDay!),
                          ),
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(height: DashboardSpacing.controlGap),
                        Text(
                          l10n.lineTotalCost(
                            displayCurrency,
                            selectedDaily?.displayTotalCost.toStringAsFixed(
                                  2,
                                ) ??
                                '0.00',
                          ),
                          style: textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.lineSessions(
                            selectedDaily?.baseMetrics.sessionCount ?? 0,
                          ),
                          style: textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.lineInputTokens(
                            compactNumber(selectedInputTokens.toDouble()),
                          ),
                          style: textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.lineOutputTokens(
                            compactNumber(selectedOutputTokens.toDouble()),
                          ),
                          style: textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.lineTotalTokens(
                            compactNumber(selectedTotalTokens.toDouble()),
                          ),
                          style: textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  secondChild: DashboardSurface(
                    key: const Key('metrics-summary-peak-hour-surface'),
                    padding: const EdgeInsets.all(
                      DashboardSpacing.primaryPanelPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (peakHour != null) ...[
                          Text(
                            l10n.peakHourSection(
                              formatHourLabel(peakHour.baseMetrics.hour.hour),
                            ),
                            style: textTheme.bodyMedium,
                          ),
                          const SizedBox(height: DashboardSpacing.controlGap),
                          Text(
                            l10n.linePeakCost(
                              displayCurrency,
                              peakHour.displayTotalCost.toStringAsFixed(2),
                            ),
                            style: textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.lineSessions(
                              peakHour.baseMetrics.sessionCount,
                            ),
                            style: textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.linePeakTokensInOut(
                              compactNumber(
                                peakHour.baseMetrics.inputTokens.toDouble(),
                              ),
                              compactNumber(
                                peakHour.baseMetrics.outputTokens.toDouble(),
                              ),
                            ),
                            style: textTheme.bodyLarge,
                          ),
                        ] else ...[
                          Text(
                            l10n.peakHourEmptySection,
                            style: textTheme.bodyMedium,
                          ),
                          const SizedBox(height: DashboardSpacing.controlGap),
                          Text(l10n.lineNoActivity, style: textTheme.bodyLarge),
                        ],
                      ],
                    ),
                  ),
                );
              }
              return Flex(
                direction: Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 0,
                    child: DashboardSurface(
                      key: const Key('metrics-summary-selected-day-surface'),
                      padding: const EdgeInsets.all(
                        DashboardSpacing.primaryPanelPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.selectedDaySection(
                              formatDateKey(context, selectedDay!),
                            ),
                            style: textTheme.bodyMedium,
                          ),
                          const SizedBox(height: DashboardSpacing.controlGap),
                          Text(
                            l10n.lineTotalCost(
                              displayCurrency,
                              selectedDaily?.displayTotalCost.toStringAsFixed(
                                    2,
                                  ) ??
                                  '0.00',
                            ),
                            style: textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.lineSessions(
                              selectedDaily?.baseMetrics.sessionCount ?? 0,
                            ),
                            style: textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.lineInputTokens(
                              compactNumber(selectedInputTokens.toDouble()),
                            ),
                            style: textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.lineOutputTokens(
                              compactNumber(selectedOutputTokens.toDouble()),
                            ),
                            style: textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.lineTotalTokens(
                              compactNumber(selectedTotalTokens.toDouble()),
                            ),
                            style: textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: DashboardSpacing.nestedPanelPadding),
                  Expanded(
                    flex: 0,
                    child: DashboardSurface(
                      key: const Key('metrics-summary-peak-hour-surface'),
                      padding: const EdgeInsets.all(
                        DashboardSpacing.primaryPanelPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (peakHour != null) ...[
                            Text(
                              l10n.peakHourSection(
                                formatHourLabel(peakHour.baseMetrics.hour.hour),
                              ),
                              style: textTheme.bodyMedium,
                            ),
                            const SizedBox(height: DashboardSpacing.controlGap),
                            Text(
                              l10n.linePeakCost(
                                displayCurrency,
                                peakHour.displayTotalCost.toStringAsFixed(2),
                              ),
                              style: textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.lineSessions(
                                peakHour.baseMetrics.sessionCount,
                              ),
                              style: textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.linePeakTokensInOut(
                                compactNumber(
                                  peakHour.baseMetrics.inputTokens.toDouble(),
                                ),
                                compactNumber(
                                  peakHour.baseMetrics.outputTokens.toDouble(),
                                ),
                              ),
                              style: textTheme.bodyLarge,
                            ),
                          ] else ...[
                            Text(
                              l10n.peakHourEmptySection,
                              style: textTheme.bodyMedium,
                            ),
                            const SizedBox(height: DashboardSpacing.controlGap),
                            Text(
                              l10n.lineNoActivity,
                              style: textTheme.bodyLarge,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class MetricsTokensTopDrivers extends StatelessWidget {
  const MetricsTokensTopDrivers({
    super.key,
    required this.metrics,
    required this.selectedDay,
    required this.displayCurrency,
    required this.selectedModelFilter,
    required this.onModelSelected,
  });

  final MonetizedAggregatedMetrics metrics;
  final DateTime selectedDay;
  final String displayCurrency;
  final String? selectedModelFilter;
  final ValueChanged<String?> onModelSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    final modelsWithMetrics = <String, MonetizedDailyMetrics>{};
    for (final entry in metrics.perModelDailyBreakdown.entries) {
      final daily = findDailyMetricsForDay(entry.value, selectedDay);
      if (daily != null) {
        modelsWithMetrics[entry.key] = daily;
      }
    }

    if (modelsWithMetrics.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedEntries = modelsWithMetrics.entries.toList()
      ..sort((a, b) {
        final aTokens = totalTokens(
          a.value.baseMetrics.inputTokens,
          a.value.baseMetrics.outputTokens,
        );
        final bTokens = totalTokens(
          b.value.baseMetrics.inputTokens,
          b.value.baseMetrics.outputTokens,
        );
        final tokenCompare = bTokens.compareTo(aTokens);
        if (tokenCompare != 0) {
          return tokenCompare;
        }

        final costCompare = b.value.displayTotalCost.compareTo(
          a.value.displayTotalCost,
        );
        if (costCompare != 0) {
          return costCompare;
        }

        return a.key.compareTo(b.key);
      });

    final top3 = sortedEntries.take(3).toList();

    return Column(
      key: const Key('metrics-tokens-drivers-panel'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.metricsTokensTopDrivers, style: textTheme.bodyMedium),
        const SizedBox(height: 6),
        ...top3.map((entry) {
          final modelName = entry.key;
          final daily = entry.value;
          final tokenCount = totalTokens(
            daily.baseMetrics.inputTokens,
            daily.baseMetrics.outputTokens,
          );
          final isSelected = selectedModelFilter == modelName;

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _InlineActionText(
              key: Key('token-driver-model-$modelName'),
              onTap: () {
                if (selectedModelFilter == modelName) {
                  onModelSelected(null);
                } else {
                  onModelSelected(modelName);
                }
              },
              text: l10n.modelDriverRow(
                modelName,
                ''.padRight((16 - modelName.length).clamp(0, 16), '.'),
                displayCurrency,
                daily.displayTotalCost.toStringAsFixed(2),
                compactNumber(tokenCount.toDouble()),
                compactNumber(daily.baseMetrics.sessionCount.toDouble()),
              ),
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? dashboardPrimaryTextColor
                    : dashboardSecondaryTextColor,
              ),
            ),
          );
        }),
      ],
    );
  }
}
