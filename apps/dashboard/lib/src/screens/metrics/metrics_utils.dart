import 'package:flutter/material.dart';
import 'package:openspent_core/openspent_core.dart';

import '../../../l10n/app_localizations.dart';

enum TimeWindow { days7, days30, days90, all, custom }

DateTime normalizeUtcDay(DateTime value) {
  final utc = value.toUtc();
  return DateTime.utc(utc.year, utc.month, utc.day);
}

bool isSameUtcDay(DateTime left, DateTime right) {
  return normalizeUtcDay(left) == normalizeUtcDay(right);
}

bool containsUtcDay(Iterable<DateTime> values, DateTime target) {
  for (final value in values) {
    if (isSameUtcDay(value, target)) {
      return true;
    }
  }

  return false;
}

String formatDateKey(DateTime value) {
  final normalized = normalizeUtcDay(value);
  return '${normalized.year}-${normalized.month.toString().padLeft(2, '0')}-${normalized.day.toString().padLeft(2, '0')}';
}

String formatDayChipLabel(DateTime value) {
  final normalized = normalizeUtcDay(value);
  return '${normalized.month.toString().padLeft(2, '0')}-${normalized.day.toString().padLeft(2, '0')}';
}

String formatHourLabel(int hour) => hour.toString().padLeft(2, '0');

int totalTokens(int inputTokens, int outputTokens) {
  return inputTokens + outputTokens;
}

String formatAverageTokensPerSession({
  required int totalTokensValue,
  required int sessionCount,
}) {
  if (sessionCount <= 0) {
    return '0.0';
  }

  return (totalTokensValue / sessionCount).toStringAsFixed(1);
}

String formatCostPerMillion({
  required double totalCost,
  required int totalTokensValue,
}) {
  if (totalTokensValue <= 0) {
    return '--';
  }

  return (totalCost / (totalTokensValue / 1000000)).toStringAsFixed(2);
}

class DecompositionResult {
  const DecompositionResult({
    required this.splitSessions,
    required this.splitAvg,
    required this.splitCost,
  });

  final double splitSessions;
  final double splitAvg;
  final double splitCost;
}

DecompositionResult? decomposeCompareDelta({
  required int currentSessions,
  required int currentTokens,
  required double currentCost,
  required int priorSessions,
  required int priorTokens,
  required double priorCost,
}) {
  if (currentSessions <= 0 ||
      currentTokens <= 0 ||
      priorSessions <= 0 ||
      priorTokens <= 0) {
    return null;
  }

  final sC = currentSessions.toDouble();
  final vC = currentTokens / currentSessions;
  final pC = currentCost / currentTokens;

  final sP = priorSessions.toDouble();
  final vP = priorTokens / priorSessions;
  final pP = priorCost / priorTokens;

  final deltaS = sC - sP;
  final deltaV = vC - vP;
  final deltaP = pC - pP;

  final splitSessions =
      deltaS * (vP * pP / 3.0 + vC * pC / 3.0 + vP * pC / 6.0 + vC * pP / 6.0);
  final splitAvg =
      deltaV * (sP * pP / 3.0 + sC * pC / 3.0 + sP * pC / 6.0 + sC * pP / 6.0);
  final splitCost =
      deltaP * (sP * vP / 3.0 + sC * vC / 3.0 + sP * vC / 6.0 + sC * vP / 6.0);

  return DecompositionResult(
    splitSessions: splitSessions,
    splitAvg: splitAvg,
    splitCost: splitCost,
  );
}

List<DateTime> buildVisibleWindowDays(
  List<MonetizedDailyMetrics> dailyBreakdown,
  TimeWindow selectedWindow,
  DateTime? from,
  DateTime? to,
) {
  if (dailyBreakdown.isEmpty && selectedWindow != TimeWindow.custom) {
    return const <DateTime>[];
  }

  final sorted = List<MonetizedDailyMetrics>.from(dailyBreakdown)
    ..sort((a, b) => a.baseMetrics.date.compareTo(b.baseMetrics.date));

  if (selectedWindow == TimeWindow.all) {
    return sorted.map((e) => normalizeUtcDay(e.baseMetrics.date)).toList();
  }

  if (selectedWindow == TimeWindow.custom) {
    if (from != null && to != null) {
      final start = normalizeUtcDay(from);
      final end = normalizeUtcDay(to);
      final diff = end.difference(start).inDays + 1;
      if (diff > 0) {
        return List<DateTime>.generate(
          diff,
          (index) => start.add(Duration(days: index)),
        );
      }
    }
    return sorted.map((e) => normalizeUtcDay(e.baseMetrics.date)).toList();
  }

  final latestDay = to != null
      ? normalizeUtcDay(to)
      : normalizeUtcDay(sorted.last.baseMetrics.date);

  final int days;
  switch (selectedWindow) {
    case TimeWindow.days7:
      days = 7;
      break;
    case TimeWindow.days30:
      days = 30;
      break;
    case TimeWindow.days90:
      days = 90;
      break;
    case TimeWindow.all:
    case TimeWindow.custom:
      days = 0;
  }

  return List<DateTime>.generate(
    days,
    (index) => latestDay.subtract(Duration(days: (days - 1) - index)),
  );
}

MonetizedDailyMetrics? findDailyMetricsForDay(
  List<MonetizedDailyMetrics> dailyBreakdown,
  DateTime day,
) {
  for (final metrics in dailyBreakdown) {
    if (isSameUtcDay(metrics.baseMetrics.date, day)) {
      return metrics;
    }
  }

  return null;
}

List<MonetizedHourlyMetrics> findHourlyMetricsForDay(
  List<MonetizedHourlyMetrics> hourlyBreakdown,
  DateTime day,
) {
  return hourlyBreakdown
      .where((metrics) => isSameUtcDay(metrics.baseMetrics.hour, day))
      .toList();
}

List<double> buildVisibleDailyCostSeries(
  List<MonetizedDailyMetrics> dailyBreakdown,
  List<DateTime> visibleDays,
) {
  return List<double>.generate(visibleDays.length, (index) {
    final daily = findDailyMetricsForDay(dailyBreakdown, visibleDays[index]);
    return daily?.displayTotalCost ?? 0.0;
  });
}

List<int> buildVisibleDailyTokenSeries(
  List<MonetizedDailyMetrics> dailyBreakdown,
  List<DateTime> visibleDays,
) {
  return List<int>.generate(visibleDays.length, (index) {
    final daily = findDailyMetricsForDay(dailyBreakdown, visibleDays[index]);
    if (daily == null) {
      return 0;
    }

    return totalTokens(
      daily.baseMetrics.inputTokens,
      daily.baseMetrics.outputTokens,
    );
  });
}

double averageDoubleSeries(List<double> values) {
  if (values.isEmpty) {
    return 0.0;
  }

  double total = 0.0;
  for (final value in values) {
    total += value;
  }

  return total / values.length;
}

int averageIntSeries(List<int> values) {
  if (values.isEmpty) {
    return 0;
  }

  int total = 0;
  for (final value in values) {
    total += value;
  }

  return (total / values.length).round();
}

String formatWindowLabel(
  BuildContext context,
  TimeWindow window,
  DateTime? from,
  DateTime? to,
) {
  final l10n = AppLocalizations.of(context)!;
  switch (window) {
    case TimeWindow.days7:
      return l10n.window7d;
    case TimeWindow.days30:
      return l10n.window30d;
    case TimeWindow.days90:
      return l10n.window90d;
    case TimeWindow.all:
      return l10n.windowAll;
    case TimeWindow.custom:
      if (from != null && to != null) {
        return '${formatDateKey(from)} - ${formatDateKey(to)}';
      }
      return l10n.windowCustom;
  }
}

bool isMissingExchangeRateError(Object? error) {
  if (error is! StateError) {
    return false;
  }

  final message = error.message;
  return message.startsWith('Missing USD exchange rate');
}

String compactNumber(double value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  } else if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toInt().toString();
}
