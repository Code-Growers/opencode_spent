import 'package:flutter/material.dart';
import 'package:openspent_core/openspent_core.dart';

import '../../../l10n/app_localizations.dart';
import '../../app/date_time_extensions.dart';

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

String formatDateKey(BuildContext context, DateTime value) {
  return normalizeUtcDay(value).formatDashboardUtcDay(context);
}

String formatDayChipLabel(BuildContext context, DateTime value) {
  return normalizeUtcDay(value).formatDashboardUtcDay(context);
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

  if (selectedWindow == TimeWindow.all ||
      (selectedWindow == TimeWindow.custom && (from == null || to == null))) {
    if (sorted.isEmpty) return const <DateTime>[];
    final start = normalizeUtcDay(sorted.first.baseMetrics.date);
    final end = normalizeUtcDay(sorted.last.baseMetrics.date);
    final diff = end.difference(start).inDays + 1;
    if (diff > 0) {
      return List<DateTime>.generate(
        diff,
        (index) => start.add(Duration(days: index)),
      );
    }
  }

  if (selectedWindow == TimeWindow.custom && from != null && to != null) {
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

List<int> buildVisibleDailySessionsSeries(
  List<MonetizedDailyMetrics> dailyBreakdown,
  List<DateTime> visibleDays,
) {
  return List<int>.generate(visibleDays.length, (index) {
    final daily = findDailyMetricsForDay(dailyBreakdown, visibleDays[index]);
    return daily?.baseMetrics.sessionCount ?? 0;
  });
}

List<double> buildVisibleDailyAvgCostPerSessionSeries(
  List<MonetizedDailyMetrics> dailyBreakdown,
  List<DateTime> visibleDays,
) {
  return List<double>.generate(visibleDays.length, (index) {
    final daily = findDailyMetricsForDay(dailyBreakdown, visibleDays[index]);
    if (daily == null || daily.baseMetrics.sessionCount <= 0) {
      return 0.0;
    }
    return daily.displayTotalCost / daily.baseMetrics.sessionCount;
  });
}

List<double> buildVisibleDailyAvgTokensPerSessionSeries(
  List<MonetizedDailyMetrics> dailyBreakdown,
  List<DateTime> visibleDays,
) {
  return List<double>.generate(visibleDays.length, (index) {
    final daily = findDailyMetricsForDay(dailyBreakdown, visibleDays[index]);
    if (daily == null || daily.baseMetrics.sessionCount <= 0) {
      return 0.0;
    }
    final tokens = totalTokens(
      daily.baseMetrics.inputTokens,
      daily.baseMetrics.outputTokens,
    );
    return tokens / daily.baseMetrics.sessionCount;
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
        return '${formatDateKey(context, from)} - ${formatDateKey(context, to)}';
      }
      return l10n.windowCustom;
  }
}

bool isMissingExchangeRateError(Object? error) {
  if (error is! StateError) {
    return false;
  }

  final message = error.message.toString();
  if (message.startsWith('Missing ')) {
    return message.contains('exchange rate');
  }
  final lower = message.toLowerCase();
  return lower.contains('missing') && lower.contains('exchange rate');
}

String compactNumber(double value) {
  if (value >= 1000000) {
    final str = (value / 1000000).toStringAsFixed(1);
    return '${str.endsWith('.0') ? str.substring(0, str.length - 2) : str}M';
  } else if (value >= 1000) {
    final str = (value / 1000).toStringAsFixed(1);
    return '${str.endsWith('.0') ? str.substring(0, str.length - 2) : str}K';
  }
  return value.toInt().toString();
}

class HeatmapDayData {
  const HeatmapDayData({
    required this.day,
    required this.sessionCount,
    required this.tokenCount,
    required this.displayCost,
    required this.level,
  });

  final DateTime day;
  final int sessionCount;
  final int tokenCount;
  final double displayCost;
  final int level;

  bool get isActive => sessionCount > 0;
}

class HeatmapStats {
  const HeatmapStats({
    required this.activeDays,
    required this.currentStreak,
    required this.longestStreak,
    required this.peakDay,
    required this.peakDaySessionCount,
    required this.peakDayTokenCount,
    required this.peakDayCost,
  });

  final int activeDays;
  final int currentStreak;
  final int longestStreak;
  final DateTime? peakDay;
  final int peakDaySessionCount;
  final int peakDayTokenCount;
  final double peakDayCost;
}

int resolveHeatmapLevel({
  required int sessionCount,
  required int peakSessionCount,
}) {
  if (sessionCount <= 0 || peakSessionCount <= 0) {
    return 0;
  }

  if (peakSessionCount == 1) {
    return 4;
  }

  final ratio = sessionCount / peakSessionCount;
  return (ratio * 4).ceil().clamp(1, 4);
}

List<HeatmapDayData> buildHeatmapDayData(
  List<MonetizedDailyMetrics> dailyBreakdown,
  List<DateTime> visibleDays,
) {
  final normalizedMetrics = <DateTime, MonetizedDailyMetrics>{
    for (final daily in dailyBreakdown)
      normalizeUtcDay(daily.baseMetrics.date): daily,
  };

  var peakSessionCount = 0;
  for (final day in visibleDays) {
    final sessions = normalizedMetrics[normalizeUtcDay(day)]?.baseMetrics.sessionCount ??
        0;
    if (sessions > peakSessionCount) {
      peakSessionCount = sessions;
    }
  }

  return List<HeatmapDayData>.generate(visibleDays.length, (index) {
    final day = normalizeUtcDay(visibleDays[index]);
    final daily = normalizedMetrics[day];
    final sessionCount = daily?.baseMetrics.sessionCount ?? 0;
    final tokenCount = daily == null
        ? 0
        : totalTokens(
            daily.baseMetrics.inputTokens,
            daily.baseMetrics.outputTokens,
          );
    final displayCost = daily?.displayTotalCost ?? 0.0;

    return HeatmapDayData(
      day: day,
      sessionCount: sessionCount,
      tokenCount: tokenCount,
      displayCost: displayCost,
      level: resolveHeatmapLevel(
        sessionCount: sessionCount,
        peakSessionCount: peakSessionCount,
      ),
    );
  });
}

HeatmapStats calculateHeatmapStats(
  List<MonetizedDailyMetrics> dailyBreakdown,
  List<DateTime> visibleDays,
) {
  if (visibleDays.isEmpty) {
    return const HeatmapStats(
      activeDays: 0,
      currentStreak: 0,
      longestStreak: 0,
      peakDay: null,
      peakDaySessionCount: 0,
      peakDayTokenCount: 0,
      peakDayCost: 0,
    );
  }

  final dayData = buildHeatmapDayData(dailyBreakdown, visibleDays);

  int activeDays = 0;
  int currentStreak = 0;
  int longestStreak = 0;
  int runningStreak = 0;
  HeatmapDayData? peakDay;

  for (final day in dayData) {
    if (day.isActive) {
      activeDays++;
      runningStreak++;

      if (peakDay == null || _isBetterPeakDay(candidate: day, current: peakDay)) {
        peakDay = day;
      }
    } else {
      if (runningStreak > longestStreak) {
        longestStreak = runningStreak;
      }
      runningStreak = 0;
    }
  }

  if (runningStreak > longestStreak) {
    longestStreak = runningStreak;
  }

  for (var index = dayData.length - 1; index >= 0; index--) {
    if (dayData[index].isActive) {
      currentStreak++;
    } else {
      break;
    }
  }

  return HeatmapStats(
    activeDays: activeDays,
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    peakDay: peakDay?.day,
    peakDaySessionCount: peakDay?.sessionCount ?? 0,
    peakDayTokenCount: peakDay?.tokenCount ?? 0,
    peakDayCost: peakDay?.displayCost ?? 0,
  );
}

bool _isBetterPeakDay({
  required HeatmapDayData candidate,
  required HeatmapDayData? current,
}) {
  if (current == null) {
    return true;
  }

  if (candidate.sessionCount != current.sessionCount) {
    return candidate.sessionCount > current.sessionCount;
  }

  if (candidate.tokenCount != current.tokenCount) {
    return candidate.tokenCount > current.tokenCount;
  }

  if (candidate.displayCost != current.displayCost) {
    return candidate.displayCost > current.displayCost;
  }

  return candidate.day.isAfter(current.day);
}
