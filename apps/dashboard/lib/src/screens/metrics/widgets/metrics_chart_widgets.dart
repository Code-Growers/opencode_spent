import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:openspent_core/openspent_core.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../theme/dashboard_colors.dart';
import '../metrics_utils.dart';
import '../../dashboard/widgets/dashboard_surface.dart';

class SpendTrendChart extends StatelessWidget {
  const SpendTrendChart({
    super.key,
    required this.displayCurrency,
    required this.dailyBreakdown,
    required this.visibleDays,
  });

  final String displayCurrency;
  final List<MonetizedDailyMetrics> dailyBreakdown;
  final List<DateTime> visibleDays;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (dailyBreakdown.isEmpty || visibleDays.isEmpty) {
      return DashboardSurface(
        child: Center(
          child: Text(
            l10n.spendTrendUnavailable,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: dashboardSecondaryTextColor),
          ),
        ),
      );
    }

    double sumCost = 0.0;
    double maxCost = 0.0;
    int peakIndex = -1;
    final values = List<double>.filled(visibleDays.length, 0.0);
    for (final day in dailyBreakdown) {
      for (int i = 0; i < visibleDays.length; i++) {
        if (isSameUtcDay(day.baseMetrics.date, visibleDays[i])) {
          values[i] = day.displayTotalCost;
        }
      }
    }
    for (int i = 0; i < values.length; i++) {
      sumCost += values[i];
      if (values[i] > maxCost) {
        maxCost = values[i];
        peakIndex = i;
      }
    }
    final avgCost = visibleDays.isEmpty ? 0.0 : sumCost / visibleDays.length;
    final maxY = math.max(maxCost * 1.2, 0.1);
    final barWidth = visibleDays.length > 31 ? 4.0 : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (avgCost > 0)
          Text(
            l10n.spendDailyAvgLabel(
              displayCurrency,
              avgCost.toStringAsFixed(2),
            ),
            key: const Key('metrics-spend-daily-avg-label'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: dashboardSecondaryTextColor,
              fontSize: 10,
            ),
          ),
        SizedBox(
          key: const Key('metrics-spend-daily-chart'),
          height: 320,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(enabled: false),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  if (avgCost > 0)
                    HorizontalLine(
                      y: avgCost,
                      color: dashboardBorderColor,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                ],
              ),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= visibleDays.length) {
                        return const SizedBox.shrink();
                      }
                      final val = values[index];
                      if (val == 0) {
                        return const SizedBox.shrink();
                      }
                      final isPeak = index == peakIndex;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          isPeak
                              ? l10n.spendDailyPeakLabel(
                                  displayCurrency,
                                  val.toStringAsFixed(2),
                                )
                              : val.toStringAsFixed(2),
                          key: isPeak
                              ? const Key('metrics-spend-daily-peak-label')
                              : null,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontSize: 10,
                                color: isPeak
                                    ? dashboardPrimaryTextColor
                                    : dashboardSecondaryTextColor,
                                fontWeight: isPeak
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: [
                for (int i = 0; i < visibleDays.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: values[i],
                        color: i == peakIndex
                            ? dashboardPrimaryTextColor
                            : dashboardSecondaryTextColor,
                        width: barWidth,
                        borderRadius: BorderRadius.zero,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class HourlySpendChart extends StatelessWidget {
  const HourlySpendChart({
    super.key,
    required this.displayCurrency,
    required this.hourlyBreakdown,
    required this.selectedDay,
    this.selectedUtcHour,
    this.onHourSelected,
    this.title,
    this.chartKey,
  });

  final String displayCurrency;
  final String? title;
  final Key? chartKey;
  final List<MonetizedHourlyMetrics> hourlyBreakdown;
  final DateTime selectedDay;
  final int? selectedUtcHour;
  final ValueChanged<int>? onHourSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    double sumCost = 0.0;
    double maxCost = 0.0;
    int peakIndex = -1;
    final values = List<double>.filled(24, 0.0);
    for (final hourly in findHourlyMetricsForDay(
      hourlyBreakdown,
      selectedDay,
    )) {
      final hour = hourly.baseMetrics.hour.hour;
      values[hour] = hourly.displayTotalCost;
    }
    for (int i = 0; i < values.length; i++) {
      sumCost += values[i];
      if (values[i] > maxCost) {
        maxCost = values[i];
        peakIndex = i;
      }
    }
    final avgCost = sumCost / 24;
    final maxY = math.max(maxCost * 1.2, 0.1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title ?? l10n.hourlySpendTitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (avgCost > 0)
              Text(
                l10n.spendHourlyAvgLabel(
                  displayCurrency,
                  avgCost.toStringAsFixed(2),
                ),
                key: const Key('metrics-spend-hourly-avg-label'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: dashboardSecondaryTextColor,
                  fontSize: 10,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          key: chartKey ?? const Key('metrics-spend-hourly-chart'),
          height: 320,
          child: Stack(
            children: [
              BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      if (avgCost > 0)
                        HorizontalLine(
                          y: avgCost,
                          color: dashboardBorderColor,
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        ),
                    ],
                  ),
                  barTouchData: BarTouchData(
                    enabled: onHourSelected != null,
                    handleBuiltInTouches: false,
                    touchCallback: (event, barTouchResponse) {
                      if (!event.isInterestedForInteractions ||
                          barTouchResponse == null ||
                          barTouchResponse.spot == null) {
                        return;
                      }
                      if (event is FlTapUpEvent) {
                        final index =
                            barTouchResponse.spot!.touchedBarGroupIndex;
                        onHourSelected?.call(index);
                      }
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        getTitlesWidget: (value, meta) {
                          final hour = value.toInt();
                          if (hour != peakIndex || values[hour] == 0) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            l10n.spendHourlyPeakLabel(
                              displayCurrency,
                              values[hour].toStringAsFixed(2),
                            ),
                            key: const Key('metrics-spend-hourly-peak-label'),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontSize: 10,
                                  color: dashboardPrimaryTextColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        interval: 6,
                        getTitlesWidget: (value, meta) {
                          final hour = value.toInt();
                          if (hour < 0 || hour > 23) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            formatHourLabel(hour),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontSize: 10,
                                  color: dashboardSecondaryTextColor,
                                ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    for (int i = 0; i < values.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: values[i],
                            color: i == selectedUtcHour
                                ? dashboardPrimaryTextColor
                                : (i == peakIndex
                                      ? dashboardPrimaryTextColor.withValues(
                                          alpha: 0.7,
                                        )
                                      : dashboardSecondaryTextColor),
                            width: 8,
                            borderRadius: BorderRadius.zero,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (onHourSelected != null)
                Positioned.fill(
                  child: Row(
                    children: List.generate(24, (index) {
                      return _HourTarget(
                        index: index,
                        isSelected: index == selectedUtcHour,
                        onTap: () => onHourSelected!(index),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class TokenTrendChart extends StatelessWidget {
  const TokenTrendChart({
    super.key,
    required this.dailyBreakdown,
    required this.visibleDays,
  });

  final List<MonetizedDailyMetrics> dailyBreakdown;
  final List<DateTime> visibleDays;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (dailyBreakdown.isEmpty || visibleDays.isEmpty) {
      return DashboardSurface(
        child: Center(
          child: Text(
            l10n.tokenTrendUnavailable,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: dashboardSecondaryTextColor),
          ),
        ),
      );
    }

    final values = List<double>.filled(visibleDays.length, 0.0);
    for (final day in dailyBreakdown) {
      for (int i = 0; i < visibleDays.length; i++) {
        if (isSameUtcDay(day.baseMetrics.date, visibleDays[i])) {
          values[i] = totalTokens(
            day.baseMetrics.inputTokens,
            day.baseMetrics.outputTokens,
          ).toDouble();
        }
      }
    }

    double maxTokens = 0.0;
    for (final value in values) {
      if (value > maxTokens) {
        maxTokens = value;
      }
    }
    final maxY = math.max(maxTokens * 1.2, 0.1);
    final barWidth = visibleDays.length > 31 ? 4.0 : 16.0;

    return SizedBox(
      key: const Key('metrics-tokens-daily-chart'),
      height: 320,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= visibleDays.length) {
                    return const SizedBox.shrink();
                  }
                  final val = values[index];
                  if (val == 0) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    compactNumber(val),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: dashboardSecondaryTextColor,
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            for (int i = 0; i < visibleDays.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i],
                    color: dashboardSecondaryTextColor,
                    width: barWidth,
                    borderRadius: BorderRadius.zero,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class HourlyTokenChart extends StatelessWidget {
  const HourlyTokenChart({
    super.key,
    this.title,
    this.chartKey,
    required this.hourlyBreakdown,
    required this.selectedDay,
    this.selectedUtcHour,
    this.onHourSelected,
  });

  final List<MonetizedHourlyMetrics> hourlyBreakdown;
  final DateTime selectedDay;
  final int? selectedUtcHour;
  final ValueChanged<int>? onHourSelected;
  final String? title;
  final Key? chartKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final values = List<double>.filled(24, 0.0);
    for (final hourly in findHourlyMetricsForDay(
      hourlyBreakdown,
      selectedDay,
    )) {
      final hour = hourly.baseMetrics.hour.hour;
      values[hour] = totalTokens(
        hourly.baseMetrics.inputTokens,
        hourly.baseMetrics.outputTokens,
      ).toDouble();
    }

    double maxTokens = 0.0;
    for (final value in values) {
      if (value > maxTokens) {
        maxTokens = value;
      }
    }
    final maxY = math.max(maxTokens * 1.2, 0.1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title ?? l10n.hourlyTokensTitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              l10n.tokenLegend,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: dashboardSecondaryTextColor,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          key: chartKey ?? const Key('metrics-tokens-hourly-chart'),
          height: 320,
          child: Stack(
            children: [
              BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    enabled: onHourSelected != null,
                    handleBuiltInTouches: false,
                    touchCallback: (event, barTouchResponse) {
                      if (!event.isInterestedForInteractions ||
                          barTouchResponse == null ||
                          barTouchResponse.spot == null) {
                        return;
                      }
                      if (event is FlTapUpEvent) {
                        final index =
                            barTouchResponse.spot!.touchedBarGroupIndex;
                        onHourSelected?.call(index);
                      }
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        interval: 6,
                        getTitlesWidget: (value, meta) {
                          final hour = value.toInt();
                          if (hour < 0 || hour > 23) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            formatHourLabel(hour),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontSize: 10,
                                  color: dashboardSecondaryTextColor,
                                ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    for (int i = 0; i < values.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: values[i],
                            color: i == selectedUtcHour
                                ? dashboardPrimaryTextColor
                                : dashboardSecondaryTextColor,
                            width: 8,
                            borderRadius: BorderRadius.zero,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (onHourSelected != null)
                Positioned.fill(
                  child: Row(
                    children: List.generate(24, (index) {
                      return _HourTarget(
                        index: index,
                        isSelected: index == selectedUtcHour,
                        onTap: () => onHourSelected!(index),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class ModelSpendChart extends StatelessWidget {
  const ModelSpendChart({
    super.key,
    required this.perModelDailyBreakdown,
    this.perModelHourlyBreakdown,
    required this.currencyCode,
    required this.grandTotalCost,
    this.selectedModelFilter,
    required this.onModelSelected,
    required this.visibleDays,
    this.selectedDay,
  });

  final Map<String, List<MonetizedDailyMetrics>> perModelDailyBreakdown;
  final Map<String, List<MonetizedHourlyMetrics>>? perModelHourlyBreakdown;
  final String currencyCode;
  final double grandTotalCost;
  final String? selectedModelFilter;
  final ValueChanged<String?> onModelSelected;
  final List<DateTime> visibleDays;
  final DateTime? selectedDay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (perModelDailyBreakdown.isEmpty) {
      return DashboardSurface(
        child: Center(
          child: Text(
            l10n.modelSpendUnavailable,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: dashboardSecondaryTextColor),
          ),
        ),
      );
    }

    final aggregated = <_ModelData>[];
    for (final entry in perModelDailyBreakdown.entries) {
      double totalCost = 0.0;
      int totalTokenCount = 0;
      int totalSessions = 0;
      double? selectedDayCost;
      int? selectedDayTokens;
      int? selectedDaySessions;

      for (final metrics in entry.value) {
        totalCost += metrics.displayTotalCost;
        totalTokenCount +=
            metrics.baseMetrics.inputTokens + metrics.baseMetrics.outputTokens;
        totalSessions += metrics.baseMetrics.sessionCount;

        if (selectedDay != null &&
            isSameUtcDay(metrics.baseMetrics.date, selectedDay!)) {
          selectedDayCost = metrics.displayTotalCost;
          selectedDayTokens =
              metrics.baseMetrics.inputTokens +
              metrics.baseMetrics.outputTokens;
          selectedDaySessions = metrics.baseMetrics.sessionCount;
        }
      }

      final trendDaysCount = visibleDays.length >= 3 ? 3 : visibleDays.length;
      final trendDays = visibleDays.length > 3
          ? visibleDays.sublist(visibleDays.length - 3)
          : visibleDays;

      final trendCosts = <double>[];
      for (final day in trendDays) {
        final metricForDay = entry.value
            .where((metrics) => isSameUtcDay(metrics.baseMetrics.date, day))
            .firstOrNull;
        trendCosts.add(metricForDay?.displayTotalCost ?? 0.0);
      }
      final trend = l10n.modelTrend(
        trendDaysCount,
        trendCosts.map((cost) => cost.toStringAsFixed(2)).join('/'),
      );

      aggregated.add(
        _ModelData(
          entry.key,
          totalCost,
          trend,
          totalTokenCount,
          totalSessions,
          selectedDayCost: selectedDayCost,
          selectedDayTokens: selectedDayTokens,
          selectedDaySessions: selectedDaySessions,
        ),
      );
    }

    aggregated.sort((a, b) {
      final costCompare = b.totalCost.compareTo(a.totalCost);
      if (costCompare != 0) {
        return costCompare;
      }
      return a.name.compareTo(b.name);
    });

    final usageByModel = <String, int>{};
    for (final item in aggregated) {
      usageByModel[item.name] = item.totalTokens;
    }

    return Column(
      key: const Key('metrics-model-detail-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ModelUsagePieChart(
          usageByModel: usageByModel,
          chartKey: const Key('metrics-model-usage-pie'),
          expanded: true,
        ),
        const SizedBox(height: 16),
        for (final item in aggregated) _buildItem(context, item),
      ],
    );
  }

  Widget _buildItem(BuildContext context, _ModelData item) {
    final l10n = AppLocalizations.of(context)!;
    final isSelected = selectedModelFilter == item.name;
    final share = grandTotalCost > 0
        ? (item.totalCost / grandTotalCost * 100).round()
        : 0;
    final costPerMillion = item.totalTokens > 0
        ? '$currencyCode ${(item.totalCost / (item.totalTokens / 1000000)).toStringAsFixed(2)}/1M TOK'
        : l10n.modelCostPerMillionTokensUnavailable(currencyCode);
    final modelHourly = perModelHourlyBreakdown?[item.name];
    final showSelectedModelHourlyCharts =
        isSelected &&
        selectedDay != null &&
        modelHourly != null &&
        findHourlyMetricsForDay(modelHourly, selectedDay!).isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        selected: isSelected,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: Key('model-filter-${item.name}'),
            onTap: () => onModelSelected(isSelected ? null : item.name),
            hoverColor: dashboardPrimaryTextColor.withValues(alpha: 0.05),
            focusColor: dashboardPrimaryTextColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.zero,
            child: DashboardSurface(
              padding: const EdgeInsets.all(12),
              highlight: isSelected,
              backgroundColor: Colors.transparent,
              borderColor: isSelected
                  ? dashboardPrimaryTextColor
                  : dashboardBorderColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '[ ${item.name} ]',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isSelected
                          ? dashboardPrimaryTextColor
                          : dashboardSecondaryTextColor,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.modelCostShareTrend(
                      currencyCode,
                      item.totalCost.toStringAsFixed(2),
                      share,
                      item.trend,
                    ),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isSelected
                          ? dashboardPrimaryTextColor
                          : dashboardSecondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.modelTokensSessions(
                      compactNumber(item.totalTokens.toDouble()),
                      compactNumber(item.totalSessions.toDouble()),
                    ),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isSelected
                          ? dashboardPrimaryTextColor
                          : dashboardSecondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    costPerMillion,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isSelected
                          ? dashboardPrimaryTextColor
                          : dashboardSecondaryTextColor,
                    ),
                  ),
                  if (selectedDay != null && item.selectedDayCost != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.modelSelectedDayMetrics(
                        currencyCode,
                        item.selectedDayCost!.toStringAsFixed(2),
                        compactNumber((item.selectedDayTokens ?? 0).toDouble()),
                        compactNumber(
                          (item.selectedDaySessions ?? 0).toDouble(),
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isSelected
                            ? dashboardPrimaryTextColor
                            : dashboardSecondaryTextColor,
                      ),
                    ),
                    if (showSelectedModelHourlyCharts) ...[
                      const SizedBox(height: 12),
                      HourlySpendChart(
                        hourlyBreakdown: modelHourly,
                        selectedDay: selectedDay!,
                        title: l10n.metricsModelHourlySpend,
                        chartKey: const Key('metrics-model-hourly-spend-chart'),
                        displayCurrency: currencyCode,
                      ),
                      const SizedBox(height: 16),
                      HourlyTokenChart(
                        hourlyBreakdown: modelHourly,
                        selectedDay: selectedDay!,
                        title: l10n.metricsModelHourlyTokens,
                        chartKey: const Key(
                          'metrics-model-hourly-tokens-chart',
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ModelUsagePieChart extends StatelessWidget {
  const ModelUsagePieChart({
    super.key,
    required this.usageByModel,
    this.chartKey,
    this.expanded = false,
  });
  final Map<String, int> usageByModel;
  final Key? chartKey;
  final bool expanded;

  List<Color> _deriveMonochromeShades(int count) {
    if (count <= 0) return [];
    final colors = <Color>[
      dashboardAccentColor,
      dashboardPrimaryTextColor,
      dashboardSecondaryTextColor,
      dashboardSecondaryTextColor.withValues(alpha: 0.7),
      dashboardSecondaryTextColor.withValues(alpha: 0.5),
      dashboardBorderColor,
      dashboardSurfaceHighlightColor,
    ];
    if (count <= colors.length) return colors.sublist(0, count);

    final result = List<Color>.from(colors);
    for (var i = colors.length; i < count; i++) {
      result.add(dashboardBorderColor.withValues(alpha: 0.5 - (0.1 * (i % 3))));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (usageByModel.isEmpty) return const SizedBox.shrink();

    final sorted = usageByModel.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold<int>(0, (sum, e) => sum + e.value);

    final colors = _deriveMonochromeShades(sorted.length);
    final l10n = AppLocalizations.of(context)!;

    final maxLegendItems = 5;
    final showOverflow = sorted.length > maxLegendItems;
    final legendItems = showOverflow
        ? sorted.sublist(0, maxLegendItems)
        : sorted;
    final overflowCount = showOverflow ? sorted.length - maxLegendItems : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        final height = expanded
            ? (isNarrow ? 400.0 : 360.0)
            : (isNarrow ? 300.0 : 240.0);
        final radius = expanded
            ? (isNarrow ? 60.0 : 100.0)
            : (isNarrow ? 45.0 : 70.0);
        final centerSpaceRadius = expanded
            ? (isNarrow ? 40.0 : 80.0)
            : (isNarrow ? 30.0 : 50.0);

        final pieWidget = PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: centerSpaceRadius,
            sections: List.generate(sorted.length, (i) {
              final entry = sorted[i];
              final value = entry.value;
              final percentage = total == 0 ? 0.0 : (value / total) * 100;
              return PieChartSectionData(
                color: colors[i],
                value: percentage,
                title: percentage > 5
                    ? '${percentage.toStringAsFixed(0)}%'
                    : '',
                radius: radius,
                titleStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: dashboardBackgroundColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              );
            }),
          ),
        );

        final legendWidget = SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...List.generate(legendItems.length, (i) {
                final entry = legendItems[i];
                final percentage = total == 0
                    ? 0.0
                    : (entry.value / total) * 100;
                final formattedValue = compactNumber(entry.value.toDouble());
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: colors[i],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: dashboardPrimaryTextColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${percentage.toStringAsFixed(1)}% • $formattedValue',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: dashboardSecondaryTextColor,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (showOverflow)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    l10n.pieLegendOverflow(overflowCount),
                    key: const Key('metrics-pie-legend-overflow'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: dashboardSecondaryTextColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        );

        return DashboardSurface(
          key: chartKey,
          child: SizedBox(
            height: height,
            child: isNarrow
                ? Column(
                    children: [
                      Expanded(child: pieWidget),
                      const SizedBox(height: 16),
                      Expanded(child: legendWidget),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(flex: 2, child: pieWidget),
                      const SizedBox(width: 24),
                      Expanded(flex: 3, child: legendWidget),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _ModelData {
  _ModelData(
    this.name,
    this.totalCost,
    this.trend,
    this.totalTokens,
    this.totalSessions, {
    this.selectedDayCost,
    this.selectedDayTokens,
    this.selectedDaySessions,
  });

  final String name;
  final double totalCost;
  final String trend;
  final int totalTokens;
  final int totalSessions;
  final double? selectedDayCost;
  final int? selectedDayTokens;
  final int? selectedDaySessions;
}

class _HourTarget extends StatelessWidget {
  const _HourTarget({
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        selected: isSelected,
        value: formatHourLabel(index),
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: Key('metrics-hour-test-$index'),
            onTap: onTap,
            hoverColor: dashboardPrimaryTextColor.withValues(alpha: 0.05),
            focusColor: dashboardPrimaryTextColor.withValues(alpha: 0.1),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class ProvidersUsageChart extends StatelessWidget {
  const ProvidersUsageChart({super.key, required this.providerBreakdowns});

  final Map<String, MonetizedUsageBreakdown> providerBreakdowns;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    final usageByProvider = <String, int>{};
    for (final entry in providerBreakdowns.entries) {
      final base = entry.value.baseMetrics;
      final tokens = totalTokens(base.inputTokens, base.outputTokens);
      if (tokens > 0) {
        usageByProvider[entry.key] = tokens;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.providersUsageChartTitle, style: textTheme.bodyMedium),
        const SizedBox(height: 12),
        ModelUsagePieChart(
          usageByModel: usageByProvider,
          chartKey: const Key('metrics-providers-usage-pie'),
          expanded: true,
        ),
      ],
    );
  }
}

class ProvidersPriceChart extends StatelessWidget {
  const ProvidersPriceChart({
    super.key,
    required this.providerBreakdowns,
    required this.displayCurrency,
  });

  final Map<String, MonetizedUsageBreakdown> providerBreakdowns;
  final String displayCurrency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    final validCostsByProvider = <String, double>{};
    final missingProviders = <String>[];

    for (final entry in providerBreakdowns.entries) {
      final cost = entry.value.displayTotalCost;
      if (cost != null) {
        if (cost > 0) {
          validCostsByProvider[entry.key] = cost;
        }
      } else {
        missingProviders.add(entry.key);
      }
    }

    final usageByCostInt = <String, int>{};
    for (final entry in validCostsByProvider.entries) {
      usageByCostInt[entry.key] = (entry.value * 100).round();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.providersPriceChartTitle, style: textTheme.bodyMedium),
        const SizedBox(height: 12),
        if (usageByCostInt.isNotEmpty)
          ModelUsagePieChart(
            usageByModel: usageByCostInt,
            chartKey: const Key('metrics-providers-price-pie'),
            expanded: true,
          ),
        if (missingProviders.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final provider in missingProviders)
            Text(
              l10n.providersPriceUnavailable(provider),
              style: textTheme.bodyLarge,
            ),
        ],
      ],
    );
  }
}

class CompactDashboardLineChart extends StatelessWidget {
  const CompactDashboardLineChart({
    super.key,
    required this.title,
    required this.values,
    this.xLabels,
    this.yLabelFormatter,
    this.xAxisTitle,
    this.yAxisTitle,
  });

  final String title;
  final List<num> values;
  final List<String>? xLabels;
  final String Function(double)? yLabelFormatter;
  final String? xAxisTitle;
  final String? yAxisTitle;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return DashboardSurface(
        child: SizedBox(
          height: 140,
          child: Center(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: dashboardSecondaryTextColor,
              ),
            ),
          ),
        ),
      );
    }

    final double maxVal = values.isEmpty
        ? 0.0
        : values.map((v) => v.toDouble()).reduce(math.max);
    final double maxY = maxVal > 0 ? maxVal * 1.2 : 1.0;

    final spots = List<FlSpot>.generate(
      values.length,
      (index) => FlSpot(index.toDouble(), values[index].toDouble()),
    );

    return DashboardSurface(
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: dashboardSecondaryTextColor,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (values.length - 1 > 0 ? values.length - 1 : 1)
                      .toDouble(),
                  minY: 0,
                  maxY: maxY,
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: yAxisTitle != null
                          ? Text(
                              yAxisTitle!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontSize: 10,
                                    color: dashboardSecondaryTextColor,
                                  ),
                            )
                          : null,
                      axisNameSize: yAxisTitle != null ? 16 : 0,
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          if (value == maxY || value == 0 && maxY > 0) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            yLabelFormatter?.call(value) ??
                                compactNumber(value),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontSize: 10,
                                  color: dashboardSecondaryTextColor,
                                ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: xAxisTitle != null
                          ? Text(
                              xAxisTitle!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontSize: 10,
                                    color: dashboardSecondaryTextColor,
                                  ),
                            )
                          : null,
                      axisNameSize: xAxisTitle != null ? 16 : 0,
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: xLabels != null
                            ? math.max(1, (xLabels!.length / 4).floorToDouble())
                            : 1.0,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (xLabels == null ||
                              index < 0 ||
                              index >= xLabels!.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              xLabels![index],
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontSize: 10,
                                    color: dashboardSecondaryTextColor,
                                  ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: const LineTouchData(enabled: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.1,
                      color: dashboardPrimaryTextColor,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: dashboardPrimaryTextColor.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
