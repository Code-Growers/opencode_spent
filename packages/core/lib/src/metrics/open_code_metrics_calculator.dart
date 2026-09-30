import '../usage/api_pricing.dart';
import '../usage/harness_usage.dart';
import '../models/aggregated_metrics.dart';
import '../models/daily_metrics.dart';
import '../models/hourly_metrics.dart';
import '../models/open_code_session.dart';
import '../models/session_usage_slice.dart';
import '../models/usage_breakdown.dart';

final class OpenCodeMetricsCalculator {
  const OpenCodeMetricsCalculator();

  AggregatedMetrics calculate(
    Iterable<OpenCodeSession> sessions, {
    PricingConfig? pricing,
  }) {
    final sourceSessions = sessions.toList();
    pricing ??= PricingConfig();
    final harnessUsage = <UsageHarness, HarnessUsageSummary>{};
    final estimatedDaily = <UsageHarness, Map<DateTime, double>>{};
    for (final harness in UsageHarness.values) {
      final selected = sourceSessions
          .where((s) => s.harness == harness)
          .toList();
      if (selected.isEmpty) continue;
      final events = selected.expand(usageEventsForPricing).toList();
      var priced = 0, custom = 0, assumptions = 0;
      var usd = 0.0;
      for (final event in events) {
        final estimate = pricing.estimate(event);
        if (estimate.usd == null) continue;
        priced++;
        usd += estimate.usd!;
        if (estimate.custom) custom++;
        if (estimate.assumedShortContext || estimate.assumedCacheDuration) {
          assumptions++;
        }
        final days = estimatedDaily.putIfAbsent(harness, () => {});
        final day = _normalizeUtcDay(event.timestamp);
        days[day] = (days[day] ?? 0) + estimate.usd!;
      }
      harnessUsage[harness] = HarnessUsageSummary(
        harness: harness,
        tokens: TokenUsage.sum(selected.map((s) => s.tokens)),
        eventCount:
            events.length +
            selected
                .where(
                  (s) => s.usageEvents.isEmpty && _usageSlicesFor(s).isEmpty,
                )
                .length,
        pricedEventCount: priced,
        estimatedUsd: priced == 0 ? null : usd,
        customPriceCount: custom,
        assumptionCount: assumptions,
      );
    }
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

    for (final session in sourceSessions) {
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

      if (session.usageEvents.isEmpty) {
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
      } else {
        final seenDays = <DateTime>{};
        final seenHours = <DateTime>{};
        for (final event in session.usageEvents) {
          final eventDay = _normalizeUtcDay(event.timestamp);
          final eventHour = _normalizeUtcHour(event.timestamp);
          final dailyBucket = dailyGrouped.putIfAbsent(
            eventDay,
            () => _MutableMetricsBucket(),
          );
          final hourlyBucket = hourlyGrouped.putIfAbsent(
            eventHour,
            () => _MutableMetricsBucket(),
          );
          _addUsageSliceToBucket(dailyBucket, event.slice);
          _addUsageSliceToBucket(hourlyBucket, event.slice);
          if (!seenDays.add(eventDay)) dailyBucket.sessionCount--;
          if (!seenHours.add(eventHour)) hourlyBucket.sessionCount--;
        }
      }

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

      final seenModelDays = <(String, DateTime)>{};
      final seenModelHours = <(String, DateTime)>{};
      for (final usageSlice in _usageSlicesFor(session)) {
        final sliceDay = _normalizeUtcDay(
          usageSlice.createdAt ?? session.createdAt,
        );
        final sliceHour = _normalizeUtcHour(
          usageSlice.createdAt ?? session.createdAt,
        );
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
          sliceDay,
          () => _MutableMetricsBucket(),
        );
        _addUsageSliceToBucket(perModelBucket, usageSlice);
        if (session.usageEvents.isNotEmpty &&
            !seenModelDays.add((modelName, sliceDay))) {
          perModelBucket.sessionCount--;
        }

        final perModelHourlyBuckets = perModelHourlyGrouped.putIfAbsent(
          modelName,
          () => <DateTime, _MutableMetricsBucket>{},
        );
        final perModelHourlyBucket = perModelHourlyBuckets.putIfAbsent(
          sliceHour,
          () => _MutableMetricsBucket(),
        );
        _addUsageSliceToBucket(perModelHourlyBucket, usageSlice);
        if (session.usageEvents.isNotEmpty &&
            !seenModelHours.add((modelName, sliceHour))) {
          perModelHourlyBucket.sessionCount--;
        }
        if (session.usageEvents.isNotEmpty) continue;

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
      if (session.usageEvents.isNotEmpty) {
        final byProvider = <String, List<UsageEvent>>{};
        final byProviderModel = <String, Map<String, List<UsageEvent>>>{};
        for (final event in session.usageEvents) {
          byProvider.putIfAbsent(event.provider, () => []).add(event);
          byProviderModel
              .putIfAbsent(event.provider, () => {})
              .putIfAbsent(event.model ?? 'unknown', () => [])
              .add(event);
        }
        SessionUsageSlice combined(
          String provider,
          String model,
          List<UsageEvent> events,
        ) {
          final tokens = TokenUsage.sum(events.map((e) => e.tokens));
          return SessionUsageSlice(
            provider: provider,
            modelName: model,
            inputTokens: tokens.input,
            outputTokens: tokens.output,
            requestCount: events.length,
          );
        }

        for (final entry in byProvider.entries) {
          providerBreakdowns
              .putIfAbsent(
                entry.key,
                () => _MutableUsageBreakdown(provider: entry.key),
              )
              .addSessionSlice(combined(entry.key, 'mixed', entry.value));
        }
        for (final entry in byProviderModel.entries) {
          final models = providerModelBreakdowns.putIfAbsent(
            entry.key,
            () => {},
          );
          for (final model in entry.value.entries) {
            models
                .putIfAbsent(
                  model.key,
                  () => _MutableUsageBreakdown(
                    provider: entry.key,
                    modelName: model.key,
                  ),
                )
                .addSessionSlice(combined(entry.key, model.key, model.value));
          }
        }
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
      harnessUsage: harnessUsage,
      estimatedDailyUsd: estimatedDaily,
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
      tokenUsage: session.tokenUsage,
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
