import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:openspent_core/openspent_core.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../theme/dashboard_colors.dart';
import '../../dashboard/widgets/dashboard_surface.dart';

class ExchangeRatesHistoryChart extends StatelessWidget {
  const ExchangeRatesHistoryChart({
    super.key,
    required this.ratesByDate,
    required this.selectedCurrency,
    required this.visibleDays,
  });

  final Map<DateTime, List<ExchangeRate>> ratesByDate;
  final SupportedCurrency selectedCurrency;
  final List<DateTime> visibleDays;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (ratesByDate.isEmpty || visibleDays.isEmpty) {
      return const SizedBox.shrink();
    }

    final values = List<double>.filled(visibleDays.length, 0.0);
    double minRate = double.infinity;
    double maxRate = 0.0;
    bool hasData = false;

    for (int i = 0; i < visibleDays.length; i++) {
      final day = visibleDays[i];
      final rates = ratesByDate[day];
      if (rates != null) {
        final rate = rates
            .where((r) => r.currency == selectedCurrency)
            .firstOrNull;
        if (rate != null) {
          values[i] = rate.rateToCzk;
          hasData = true;
          if (rate.rateToCzk < minRate) minRate = rate.rateToCzk;
          if (rate.rateToCzk > maxRate) maxRate = rate.rateToCzk;
        }
      }
    }

    if (!hasData) {
      return const SizedBox.shrink();
    }

    // Add some padding to min/max
    final yRange = maxRate - minRate;
    final padding = yRange == 0 ? maxRate * 0.1 : yRange * 0.2;
    final minY = math.max(0.0, minRate - padding);
    final maxY = maxRate + padding;

    final spots = <FlSpot>[];
    for (int i = 0; i < values.length; i++) {
      if (values[i] > 0) {
        spots.add(FlSpot(i.toDouble(), values[i]));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          l10n.exchangeRatesHistoryTitle(selectedCurrency.code),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        DashboardSurface(
          backgroundColor: dashboardBackgroundColor,
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                minX: 0,
                maxX: math.max(1, visibleDays.length - 1).toDouble(),
                lineTouchData: LineTouchData(enabled: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(2),
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
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      interval: math
                          .max(1, visibleDays.length / 6)
                          .floorToDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= visibleDays.length) {
                          return const SizedBox.shrink();
                        }
                        final dateStr = DateFormat.yMMMd(
                          Localizations.localeOf(context).toString(),
                        ).format(visibleDays[index]);
                        return Text(
                          dateStr,
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
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: dashboardPrimaryTextColor,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: dashboardPrimaryTextColor.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
