import 'package:flutter/material.dart';
import 'package:openspent_core/openspent_core.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../theme/dashboard_colors.dart';
import '../metrics_utils.dart';
import '../../dashboard/widgets/dashboard_surface.dart';

class MetricsKpiCards extends StatelessWidget {
  const MetricsKpiCards({
    super.key,
    required this.metrics,
    required this.displayCurrency,
  });

  final MonetizedAggregatedMetrics metrics;
  final String displayCurrency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final base = metrics.baseMetrics;
    final totalSessions = base.totalSessionCount;

    String formatKpiValue({
      required double value,
      required int coverage,
      required String Function(double) formatter,
      bool isCurrency = false,
    }) {
      if (totalSessions == 0 || coverage == 0) {
        return l10n.metricsKpiNotAvailable;
      }
      final formatted = formatter(value);
      final finalStr = isCurrency ? '$displayCurrency $formatted' : formatted;
      if (coverage < totalSessions) {
        return l10n.metricsKpiPartial(finalStr);
      }
      return finalStr;
    }

    final totalTokensValue = totalTokens(
      base.totalInputTokens,
      base.totalOutputTokens,
    ).toDouble();
    final tokenCoverage =
        base.inputTokensCoverageSessionCount <
            base.outputTokensCoverageSessionCount
        ? base.inputTokensCoverageSessionCount
        : base.outputTokensCoverageSessionCount;

    final bool canComputeAvgLatency =
        base.responseTimeCoverageSessionCount > 0 &&
        base.responseTimeCoverageSessionCount ==
            base.responseCountCoverageSessionCount;

    final avgResponseTime = canComputeAvgLatency && base.totalResponseCount > 0
        ? base.totalResponseTimeMs / base.totalResponseCount
        : 0.0;

    String formatNumber(double val) => compactNumber(val);
    String formatPrice(double val) => val.toStringAsFixed(2);
    String formatLatency(double val) => '${val.toStringAsFixed(0)} ms';

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = DashboardSpacing.nestedPanelPadding;
        final minCardWidth = 230.0;
        int crossAxisCount = (constraints.maxWidth / minCardWidth).floor();
        if (crossAxisCount == 0) crossAxisCount = 1;
        if (crossAxisCount > 5) crossAxisCount = 5;

        final width =
            (constraints.maxWidth - ((crossAxisCount - 1) * spacing)) /
                crossAxisCount -
            0.1;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            _KpiCard(
              key: const Key('metrics-kpi-total-price'),
              width: width,
              icon: Icons.attach_money,
              title: l10n.metricsKpiTotalPrice(
                displayCurrency,
                formatKpiValue(
                  value: metrics.displayTotalCost,
                  coverage: base.totalCostCoverageSessionCount,
                  formatter: formatPrice,
                ),
              ),
            ),
            _KpiCard(
              key: const Key('metrics-kpi-total-requests'),
              width: width,
              icon: Icons.sync_alt,
              title: l10n.metricsKpiTotalRequests(
                formatKpiValue(
                  value: base.totalRequestCount.toDouble(),
                  coverage: base.requestCountCoverageSessionCount,
                  formatter: formatNumber,
                ),
              ),
            ),
            _KpiCard(
              key: const Key('metrics-kpi-total-tool-calls'),
              width: width,
              icon: Icons.build_outlined,
              title: l10n.metricsKpiTotalToolCalls(
                formatKpiValue(
                  value: base.totalToolCallCount.toDouble(),
                  coverage: base.toolCallCountCoverageSessionCount,
                  formatter: formatNumber,
                ),
              ),
            ),
            _KpiCard(
              key: const Key('metrics-kpi-avg-response-time'),
              width: width,
              icon: Icons.timer_outlined,
              title: l10n.metricsKpiAvgResponseTime(
                canComputeAvgLatency
                    ? formatKpiValue(
                        value: avgResponseTime,
                        coverage: base.responseTimeCoverageSessionCount,
                        formatter: formatLatency,
                      )
                    : l10n.metricsKpiNotAvailable,
              ),
            ),
            _KpiCard(
              key: const Key('metrics-kpi-total-tokens'),
              width: width,
              icon: Icons.data_usage,
              title: l10n.metricsKpiTotalTokens(
                formatKpiValue(
                  value: totalTokensValue,
                  coverage: tokenCoverage,
                  formatter: formatNumber,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    super.key,
    required this.title,
    required this.icon,
    required this.width,
  });

  final String title;
  final IconData icon;
  final double width;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 150),
      child: DashboardSurface(
        padding: const EdgeInsets.all(DashboardSpacing.primaryPanelPadding),
        backgroundColor: dashboardSurfaceElevatedColor,
        borderColor: dashboardBorderColor.withValues(alpha: 0.9),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: dashboardAccentColor.withValues(alpha: 0.12),
                    border: Border.all(
                      color: dashboardAccentColor.withValues(alpha: 0.42),
                    ),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Icon(icon, color: dashboardAccentSoftColor, size: 20),
                ),
                const Spacer(),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: dashboardStatusColor.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: textTheme.bodyMedium?.copyWith(
                color: dashboardPrimaryTextColor,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
