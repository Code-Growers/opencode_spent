import '../models/aggregated_metrics.dart';
import '../models/daily_metrics.dart';
import '../models/hourly_metrics.dart';
import '../models/open_code_session.dart';
import '../models/session_usage_slice.dart';
import '../models/usage_breakdown.dart';

final class OpenCodeMetricsCalculator {
  const OpenCodeMetricsCalculator();

  AggregatedMetrics calculate(Iterable<OpenCodeSession> sessions) {
    var totalSessionCount = 0;
    var totalInputTokens = 0;
    var totalOutputTokens = 0;
    var totalCostUsd = 0.0;
    var totalRequestCount = 0;
    var totalToolCallCount = 0;
    var totalResponseCount = 0;
    var totalResponseTimeMs = 0;
    var inputTokensCoverageSessionCount = 0;
    var outputTokensCoverageSessionCount = 0;
    var totalCostCoverageSessionCount = 0;
    var requestCountCoverageSessionCount = 0;
    var toolCallCountCoverageSessionCount = 0;
    var responseCountCoverageSessionCount = 0;
    var responseTimeCoverageSessionCount = 0;
    final dailyGrouped = <DateTime, _MutableMetricsBucket>{};
    final hourlyGrouped = <DateTime, _MutableMetricsBucket>{};
    final perModelGrouped = <String, Map<DateTime, _MutableMetricsBucket>>{};
    final perModelHourlyGrouped =
        <String, Map<DateTime, _MutableMetricsBucket>>{};
    final providerBreakdowns = <String, _MutableUsageBreakdown>{};
    final providerModelBreakdowns =
        <String, Map<String, _MutableUsageBreakdown>>{};

    for (final session in sessions) {
      final day = _normalizeUtcDay(session.createdAt);
      final hour = _normalizeUtcHour(session.createdAt);

      totalSessionCount += 1;
      if (session.inputTokens case final int inputTokens) {
        totalInputTokens += inputTokens;
        inputTokensCoverageSessionCount += 1;
      }
      if (session.outputTokens case final int outputTokens) {
        totalOutputTokens += outputTokens;
        outputTokensCoverageSessionCount += 1;
      }
      if (session.totalCostUsd case final double totalCostUsdValue) {
        totalCostUsd += totalCostUsdValue;
        totalCostCoverageSessionCount += 1;
      }
      if (session.requestCount case final int requestCount) {
        totalRequestCount += requestCount;
        requestCountCoverageSessionCount += 1;
      }
      if (session.toolCallCount case final int toolCallCount) {
        totalToolCallCount += toolCallCount;
        toolCallCountCoverageSessionCount += 1;
      }
      if (session.responseCount case final int responseCount) {
        totalResponseCount += responseCount;
        responseCountCoverageSessionCount += 1;
      }
      if (session.totalResponseTimeMs case final int totalResponseTimeMsValue) {
        totalResponseTimeMs += totalResponseTimeMsValue;
        responseTimeCoverageSessionCount += 1;
      }

      final dailyBucket = dailyGrouped.putIfAbsent(
        day,
        () => _MutableMetricsBucket(),
      );
      _addSessionToBucket(dailyBucket, session);

      final hourlyBucket = hourlyGrouped.putIfAbsent(
        hour,
        () => _MutableMetricsBucket(),
      );
      _addSessionToBucket(hourlyBucket, session);

      final legacyModelName = _normalizeModelName(session.modelName);
      if (legacyModelName != null && session.usageSlices.isEmpty) {
        final perModelBuckets = perModelGrouped.putIfAbsent(
          legacyModelName,
          () => <DateTime, _MutableMetricsBucket>{},
        );
        final perModelBucket = perModelBuckets.putIfAbsent(
          day,
          () => _MutableMetricsBucket(),
        );
        _addSessionToBucket(perModelBucket, session);

        final perModelHourlyBuckets = perModelHourlyGrouped.putIfAbsent(
          legacyModelName,
          () => <DateTime, _MutableMetricsBucket>{},
        );
        final perModelHourlyBucket = perModelHourlyBuckets.putIfAbsent(
          hour,
          () => _MutableMetricsBucket(),
        );
        _addSessionToBucket(perModelHourlyBucket, session);
      }

      for (final usageSlice in _usageSlicesFor(session)) {
        final modelName = _normalizeModelName(usageSlice.modelName);
        final provider = _normalizeProvider(usageSlice.provider);
        if (modelName == null || provider == null) {
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
        _addUsageSliceToBucket(perModelBucket, usageSlice);

        final perModelHourlyBuckets = perModelHourlyGrouped.putIfAbsent(
          modelName,
          () => <DateTime, _MutableMetricsBucket>{},
        );
        final perModelHourlyBucket = perModelHourlyBuckets.putIfAbsent(
          hour,
          () => _MutableMetricsBucket(),
        );
        _addUsageSliceToBucket(perModelHourlyBucket, usageSlice);

        final providerBreakdown = providerBreakdowns.putIfAbsent(
          provider,
          () => _MutableUsageBreakdown(provider: provider),
        );
        providerBreakdown.addSessionSlice(usageSlice);

        final providerModels = providerModelBreakdowns.putIfAbsent(
          provider,
          () => <String, _MutableUsageBreakdown>{},
        );
        final providerModelBreakdown = providerModels.putIfAbsent(
          modelName,
          () =>
              _MutableUsageBreakdown(provider: provider, modelName: modelName),
        );
        providerModelBreakdown.addSessionSlice(usageSlice);
      }
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
      totalRequestCount: totalRequestCount,
      totalToolCallCount: totalToolCallCount,
      totalResponseCount: totalResponseCount,
      totalResponseTimeMs: totalResponseTimeMs,
      inputTokensCoverageSessionCount: inputTokensCoverageSessionCount,
      outputTokensCoverageSessionCount: outputTokensCoverageSessionCount,
      totalCostCoverageSessionCount: totalCostCoverageSessionCount,
      requestCountCoverageSessionCount: requestCountCoverageSessionCount,
      toolCallCountCoverageSessionCount: toolCallCountCoverageSessionCount,
      responseCountCoverageSessionCount: responseCountCoverageSessionCount,
      responseTimeCoverageSessionCount: responseTimeCoverageSessionCount,
      dailyBreakdown: _buildDailyBreakdown(dailyGrouped),
      hourlyBreakdown: _buildHourlyBreakdown(hourlyGrouped),
      perModelDailyBreakdown: perModelDailyBreakdown,
      perModelHourlyBreakdown: perModelHourlyBreakdown,
      providerBreakdowns: _buildUsageBreakdownMap(providerBreakdowns),
      providerModelBreakdowns: _buildNestedUsageBreakdownMap(
        providerModelBreakdowns,
      ),
    );
  }
}

void _addSessionToBucket(
  _MutableMetricsBucket bucket,
  OpenCodeSession session,
) {
  bucket.sessionCount += 1;
  bucket.inputTokens += session.inputTokens ?? 0;
  bucket.outputTokens += session.outputTokens ?? 0;
  bucket.totalCostUsd += session.totalCostUsd ?? 0;
}

void _addUsageSliceToBucket(
  _MutableMetricsBucket bucket,
  SessionUsageSlice usageSlice,
) {
  bucket.sessionCount += 1;
  bucket.inputTokens += usageSlice.inputTokens ?? 0;
  bucket.outputTokens += usageSlice.outputTokens ?? 0;
  bucket.totalCostUsd += usageSlice.totalCostUsd ?? 0;
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

String? _normalizeProvider(String? provider) {
  final normalizedProvider = provider?.trim();
  if (normalizedProvider == null || normalizedProvider.isEmpty) {
    return null;
  }

  return normalizedProvider;
}

Iterable<SessionUsageSlice> _usageSlicesFor(OpenCodeSession session) {
  if (session.usageSlices.isNotEmpty) {
    return session.usageSlices;
  }

  final provider = _normalizeProvider(session.provider);
  final modelName = _normalizeModelName(session.modelName);
  if (provider == null || modelName == null) {
    return const <SessionUsageSlice>[];
  }

  return <SessionUsageSlice>[
    SessionUsageSlice(
      provider: provider,
      modelName: modelName,
      inputTokens: session.inputTokens,
      outputTokens: session.outputTokens,
      totalCostUsd: session.totalCostUsd,
      requestCount: session.requestCount,
      toolCallCount: session.toolCallCount,
      responseCount: session.responseCount,
      totalResponseTimeMs: session.totalResponseTimeMs,
    ),
  ];
}

Map<String, UsageBreakdown> _buildUsageBreakdownMap(
  Map<String, _MutableUsageBreakdown> grouped,
) {
  final sortedEntries = grouped.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));

  return Map<String, UsageBreakdown>.unmodifiable({
    for (final entry in sortedEntries) entry.key: entry.value.build(),
  });
}

Map<String, Map<String, UsageBreakdown>> _buildNestedUsageBreakdownMap(
  Map<String, Map<String, _MutableUsageBreakdown>> grouped,
) {
  final sortedProviders = grouped.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));

  return Map<String, Map<String, UsageBreakdown>>.unmodifiable({
    for (final providerEntry in sortedProviders)
      providerEntry.key: Map<String, UsageBreakdown>.unmodifiable({
        for (final modelEntry
            in (providerEntry.value.entries.toList()
              ..sort((left, right) => left.key.compareTo(right.key))))
          modelEntry.key: modelEntry.value.build(),
      }),
  });
}

final class _MutableMetricsBucket {
  int sessionCount = 0;
  int inputTokens = 0;
  int outputTokens = 0;
  double totalCostUsd = 0;
}

final class _MutableUsageBreakdown {
  _MutableUsageBreakdown({required this.provider, this.modelName});

  final String provider;
  final String? modelName;
  int sessionCount = 0;
  int inputTokens = 0;
  int outputTokens = 0;
  double totalCostUsd = 0;
  int requestCount = 0;
  int toolCallCount = 0;
  int responseCount = 0;
  int totalResponseTimeMs = 0;
  int inputTokensCoverageSessionCount = 0;
  int outputTokensCoverageSessionCount = 0;
  int totalCostCoverageSessionCount = 0;
  int requestCountCoverageSessionCount = 0;
  int toolCallCountCoverageSessionCount = 0;
  int responseCountCoverageSessionCount = 0;
  int responseTimeCoverageSessionCount = 0;

  void addSessionSlice(SessionUsageSlice usageSlice) {
    sessionCount += 1;
    if (usageSlice.inputTokens case final int inputTokensValue) {
      inputTokens += inputTokensValue;
      inputTokensCoverageSessionCount += 1;
    }
    if (usageSlice.outputTokens case final int outputTokensValue) {
      outputTokens += outputTokensValue;
      outputTokensCoverageSessionCount += 1;
    }
    if (usageSlice.totalCostUsd case final double totalCostUsdValue) {
      totalCostUsd += totalCostUsdValue;
      totalCostCoverageSessionCount += 1;
    }
    if (usageSlice.requestCount case final int requestCountValue) {
      requestCount += requestCountValue;
      requestCountCoverageSessionCount += 1;
    }
    if (usageSlice.toolCallCount case final int toolCallCountValue) {
      toolCallCount += toolCallCountValue;
      toolCallCountCoverageSessionCount += 1;
    }
    if (usageSlice.responseCount case final int responseCountValue) {
      responseCount += responseCountValue;
      responseCountCoverageSessionCount += 1;
    }
    if (usageSlice.totalResponseTimeMs
        case final int totalResponseTimeMsValue) {
      totalResponseTimeMs += totalResponseTimeMsValue;
      responseTimeCoverageSessionCount += 1;
    }
  }

  UsageBreakdown build() {
    return UsageBreakdown(
      provider: provider,
      modelName: modelName,
      sessionCount: sessionCount,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      totalCostUsd: totalCostUsd,
      requestCount: requestCount,
      toolCallCount: toolCallCount,
      responseCount: responseCount,
      totalResponseTimeMs: totalResponseTimeMs,
      inputTokensCoverageSessionCount: inputTokensCoverageSessionCount,
      outputTokensCoverageSessionCount: outputTokensCoverageSessionCount,
      totalCostCoverageSessionCount: totalCostCoverageSessionCount,
      requestCountCoverageSessionCount: requestCountCoverageSessionCount,
      toolCallCountCoverageSessionCount: toolCallCountCoverageSessionCount,
      responseCountCoverageSessionCount: responseCountCoverageSessionCount,
      responseTimeCoverageSessionCount: responseTimeCoverageSessionCount,
    );
  }
}
