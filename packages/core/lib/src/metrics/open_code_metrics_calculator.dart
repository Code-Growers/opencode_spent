import '../models/aggregated_metrics.dart';
import '../models/daily_metrics.dart';
import '../models/hourly_metrics.dart';
import '../models/open_code_session.dart';

final class OpenCodeMetricsCalculator {
  const OpenCodeMetricsCalculator();

  AggregatedMetrics calculate(Iterable<OpenCodeSession> sessions) {
    var totalSessionCount = 0;
    var totalInputTokens = 0;
    var totalOutputTokens = 0;
    var totalCostUsd = 0.0;
    final dailyGrouped = <DateTime, _MutableMetricsBucket>{};
    final hourlyGrouped = <DateTime, _MutableMetricsBucket>{};
    final perModelGrouped = <String, Map<DateTime, _MutableMetricsBucket>>{};
    final perModelHourlyGrouped =
        <String, Map<DateTime, _MutableMetricsBucket>>{};

    for (final session in sessions) {
      final day = _normalizeUtcDay(session.createdAt);
      final hour = _normalizeUtcHour(session.createdAt);

      totalSessionCount += 1;
      totalInputTokens += session.inputTokens ?? 0;
      totalOutputTokens += session.outputTokens ?? 0;
      totalCostUsd += session.totalCostUsd ?? 0;

      final dailyBucket =
          dailyGrouped.putIfAbsent(day, () => _MutableMetricsBucket());
      _addSessionToBucket(dailyBucket, session);

      final hourlyBucket =
          hourlyGrouped.putIfAbsent(hour, () => _MutableMetricsBucket());
      _addSessionToBucket(hourlyBucket, session);

      final modelName = _normalizeModelName(session.modelName);
      if (modelName == null) {
        continue;
      }

      final perModelBuckets = perModelGrouped.putIfAbsent(
        modelName,
        () => <DateTime, _MutableMetricsBucket>{},
      );
      final perModelBucket = perModelBuckets.putIfAbsent(
        day,
        () => _MutableMetricsBucket(),
      );
      _addSessionToBucket(perModelBucket, session);

      final perModelHourlyBuckets = perModelHourlyGrouped.putIfAbsent(
        modelName,
        () => <DateTime, _MutableMetricsBucket>{},
      );
      final perModelHourlyBucket = perModelHourlyBuckets.putIfAbsent(
        hour,
        () => _MutableMetricsBucket(),
      );
      _addSessionToBucket(perModelHourlyBucket, session);
    }

    final perModelDailyBreakdown = <String, List<DailyMetrics>>{};
    final sortedPerModelEntries = perModelGrouped.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    for (final entry in sortedPerModelEntries) {
      perModelDailyBreakdown[entry.key] = _buildDailyBreakdown(entry.value);
    }

    final perModelHourlyBreakdown = <String, List<HourlyMetrics>>{};
    final sortedPerModelHourlyEntries = perModelHourlyGrouped.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    for (final entry in sortedPerModelHourlyEntries) {
      perModelHourlyBreakdown[entry.key] = _buildHourlyBreakdown(entry.value);
    }

    return AggregatedMetrics(
      totalSessionCount: totalSessionCount,
      totalInputTokens: totalInputTokens,
      totalOutputTokens: totalOutputTokens,
      totalCostUsd: totalCostUsd,
      dailyBreakdown: _buildDailyBreakdown(dailyGrouped),
      hourlyBreakdown: _buildHourlyBreakdown(hourlyGrouped),
      perModelDailyBreakdown: perModelDailyBreakdown,
      perModelHourlyBreakdown: perModelHourlyBreakdown,
    );
  }
}

void _addSessionToBucket(
    _MutableMetricsBucket bucket, OpenCodeSession session) {
  bucket.sessionCount += 1;
  bucket.inputTokens += session.inputTokens ?? 0;
  bucket.outputTokens += session.outputTokens ?? 0;
  bucket.totalCostUsd += session.totalCostUsd ?? 0;
}

List<DailyMetrics> _buildDailyBreakdown(
  Map<DateTime, _MutableMetricsBucket> grouped,
) {
  final dailyBreakdown = grouped.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));

  return dailyBreakdown
      .map(
        (entry) => DailyMetrics(
          date: entry.key,
          sessionCount: entry.value.sessionCount,
          inputTokens: entry.value.inputTokens,
          outputTokens: entry.value.outputTokens,
          totalCostUsd: entry.value.totalCostUsd,
        ),
      )
      .toList(growable: false);
}

List<HourlyMetrics> _buildHourlyBreakdown(
  Map<DateTime, _MutableMetricsBucket> grouped,
) {
  final hourlyBreakdown = grouped.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));

  return hourlyBreakdown
      .map(
        (entry) => HourlyMetrics(
          hour: entry.key,
          sessionCount: entry.value.sessionCount,
          inputTokens: entry.value.inputTokens,
          outputTokens: entry.value.outputTokens,
          totalCostUsd: entry.value.totalCostUsd,
        ),
      )
      .toList(growable: false);
}

DateTime _normalizeUtcDay(DateTime dateTime) {
  final utcDateTime = dateTime.toUtc();
  return DateTime.utc(utcDateTime.year, utcDateTime.month, utcDateTime.day);
}

DateTime _normalizeUtcHour(DateTime dateTime) {
  final utcDateTime = dateTime.toUtc();
  return DateTime.utc(
    utcDateTime.year,
    utcDateTime.month,
    utcDateTime.day,
    utcDateTime.hour,
  );
}

String? _normalizeModelName(String? modelName) {
  final normalizedModelName = modelName?.trim();
  if (normalizedModelName == null || normalizedModelName.isEmpty) {
    return null;
  }

  return normalizedModelName;
}

final class _MutableMetricsBucket {
  int sessionCount = 0;
  int inputTokens = 0;
  int outputTokens = 0;
  double totalCostUsd = 0;
}
