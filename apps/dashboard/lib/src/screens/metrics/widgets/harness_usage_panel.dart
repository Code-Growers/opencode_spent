import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:openspent_core/openspent_core.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../usage/harness_labels.dart';
import '../../dashboard/widgets/dashboard_surface.dart';
import 'metrics_chart_widgets.dart';

class HarnessUsagePanel extends StatelessWidget {
  const HarnessUsagePanel({super.key, required this.metrics});
  final MonetizedAggregatedMetrics metrics;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final exactCount = NumberFormat.decimalPattern(locale);
    final compactCount = NumberFormat.compact(locale: locale);
    final money = NumberFormat.decimalPattern(locale)
      ..minimumFractionDigits = 2
      ..maximumFractionDigits = 2;
    String count(int? n) => n == null ? l.usageUnknown : compactCount.format(n);
    Widget tokenCount(int? n) => Tooltip(
      message: n == null ? l.usageUnknown : exactCount.format(n),
      child: Text(count(n)),
    );
    final summaries = metrics.baseMetrics.harnessUsage;
    final daily = <DateTime, double>{};
    for (final days
        in metrics.displayEstimatedDaily.values
            .whereType<Map<DateTime, double>>()) {
      for (final day in days.entries) {
        daily[day.key] = (daily[day.key] ?? 0) + day.value;
      }
    }
    final dates = daily.keys.toList()..sort();
    return DashboardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.usageComparisonTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(l.usageTokensHelp),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              horizontalMargin: 0,
              columnSpacing: 24,
              dataRowMaxHeight: 76,
              columns: [
                for (final label in [
                  '',
                  l.usageInput,
                  l.usageOutput,
                  l.usageCacheRead,
                  l.usageCacheWrite,
                  l.usageReasoning,
                  l.usageApiEstimate,
                ])
                  DataColumn(label: Text(label)),
              ],
              rows: [
                for (final entry in summaries.entries)
                  DataRow(
                    cells: [
                      DataCell(Text(harnessLabel(entry.key))),
                      DataCell(tokenCount(entry.value.tokens.input)),
                      DataCell(tokenCount(entry.value.tokens.output)),
                      DataCell(tokenCount(entry.value.tokens.cachedInput)),
                      DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            tokenCount(entry.value.tokens.cacheWrite),
                            if (entry.value.tokens.cacheWrite5m != null ||
                                entry.value.tokens.cacheWrite1h != null)
                              Text(
                                '5m ${count(entry.value.tokens.cacheWrite5m)} · 1h ${count(entry.value.tokens.cacheWrite1h)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      DataCell(tokenCount(entry.value.tokens.reasoning)),
                      DataCell(
                        Text(
                          metrics.displayHarnessEstimates[entry.key] == null
                              ? l.usageUnknown
                              : '${metrics.displayCurrency.code} ${money.format(metrics.displayHarnessEstimates[entry.key]!)}'
                                    '${entry.value.pricedEventCount < entry.value.eventCount ? ' (${l.usagePartial})' : ''}',
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          for (final entry in summaries.entries)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${harnessLabel(entry.key)}: ${NumberFormat.percentPattern(locale).format(entry.value.eventCount == 0 ? 0 : entry.value.pricedEventCount / entry.value.eventCount)} · ${l.usagePricingCoverage(entry.value.pricedEventCount, entry.value.eventCount)}'
                '${entry.value.customPriceCount > 0 ? ' · ${l.usageCustomPrice}' : ''}',
              ),
            ),
          if (summaries.values.any((s) => s.assumptionCount > 0))
            Text(l.usageApproximate),
          if (dates.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(l.usageApiEstimate),
            SpendTrendChart(
              displayCurrency: metrics.displayCurrency.code,
              visibleDays: dates,
              showDailyValueLabels: dates.length <= 20,
              dailyBreakdown: [
                for (final date in dates)
                  MonetizedDailyMetrics(
                    baseMetrics: DailyMetrics(
                      date: date,
                      sessionCount: 0,
                      inputTokens: 0,
                      outputTokens: 0,
                      totalCostUsd: 0,
                    ),
                    displayTotalCost: daily[date]!,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
