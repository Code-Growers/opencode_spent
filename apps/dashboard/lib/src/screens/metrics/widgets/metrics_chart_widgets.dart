import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:openspent_core/openspent_core.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../theme/dashboard_colors.dart';
import '../metrics_utils.dart';

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
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          l10n.spendTrendUnavailable,
          style: Theme.of(context).textTheme.bodyLarge,
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
          height: 120,
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
          height: 120,
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
                      return Expanded(
                        child: GestureDetector(
                          key: Key('metrics-hour-test-$index'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onHourSelected!(index),
                          child: Container(),
                        ),
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
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          l10n.tokenTrendUnavailable,
          style: Theme.of(context).textTheme.bodyLarge,
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
      height: 120,
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
          height: 120,
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
                      return Expanded(
                        child: GestureDetector(
                          key: Key('metrics-hour-test-$index'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onHourSelected!(index),
                          child: Container(),
                        ),
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
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          l10n.modelSpendUnavailable,
          style: Theme.of(context).textTheme.bodyLarge,
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
      child: GestureDetector(
        key: Key('model-filter-${item.name}'),
        onTap: () => onModelSelected(isSelected ? null : item.name),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? dashboardBorderColor : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? dashboardPrimaryTextColor
                  : dashboardBorderColor,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '[ ${item.name} ]',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isSelected
                      ? dashboardPrimaryTextColor
                      : dashboardSecondaryTextColor,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
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
                l10n.modelTokensSessions(item.totalTokens, item.totalSessions),
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
                    item.selectedDayTokens ?? 0,
                    item.selectedDaySessions ?? 0,
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
                    chartKey: const Key('metrics-model-hourly-tokens-chart'),
                  ),
                ],
              ],
            ],
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
  });
  final Map<String, int> usageByModel;
  final Key? chartKey;

  @override
  Widget build(BuildContext context) {
    if (usageByModel.isEmpty) return const SizedBox.shrink();

    final sorted = usageByModel.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold<int>(0, (sum, e) => sum + e.value);

    // Pick distinct grays/monochrome colors
    final colors = [
      const Color(0xFFFFFFFF),
      const Color(0xFFD4D4D8),
      const Color(0xFFA1A1AA),
      const Color(0xFF71717A),
      const Color(0xFF52525B),
      const Color(0xFF3F3F46),
      const Color(0xFF27272A),
    ];

    return SizedBox(
      key: chartKey,
      height: 100,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 16,
                sections: List.generate(sorted.length, (i) {
                  final entry = sorted[i];
                  final value = entry.value;
                  final percentage = total == 0 ? 0.0 : (value / total) * 100;
                  return PieChartSectionData(
                    color: colors[i % colors.length],
                    value: percentage,
                    title: percentage > 5
                        ? '${percentage.toStringAsFixed(0)}%'
                        : '',
                    radius: 24,
                    titleStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF000000),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(math.min(sorted.length, 6), (i) {
                  final entry = sorted[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          color: colors[i % colors.length],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
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
