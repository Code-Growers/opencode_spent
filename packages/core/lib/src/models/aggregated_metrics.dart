import 'daily_metrics.dart';
import 'hourly_metrics.dart';
import 'usage_breakdown.dart';

final class AggregatedMetrics {
  AggregatedMetrics({
    required this.totalSessionCount,
    required this.totalInputTokens,
    required this.totalOutputTokens,
    required this.totalCostUsd,
    this.totalRequestCount = 0,
    this.totalToolCallCount = 0,
    this.totalResponseCount = 0,
    this.totalResponseTimeMs = 0,
    required Iterable<DailyMetrics> dailyBreakdown,
    Iterable<HourlyMetrics> hourlyBreakdown = const <HourlyMetrics>[],
    Map<String, Iterable<DailyMetrics>>? perModelDailyBreakdown,
    Map<String, Iterable<HourlyMetrics>>? perModelHourlyBreakdown,
    Map<String, UsageBreakdown>? providerBreakdowns,
    Map<String, Map<String, UsageBreakdown>>? providerModelBreakdowns,
    int? inputTokensCoverageSessionCount,
    int? outputTokensCoverageSessionCount,
    int? totalCostCoverageSessionCount,
    this.requestCountCoverageSessionCount = 0,
    this.toolCallCountCoverageSessionCount = 0,
    this.responseCountCoverageSessionCount = 0,
    this.responseTimeCoverageSessionCount = 0,
  }) : dailyBreakdown = List<DailyMetrics>.unmodifiable(dailyBreakdown),
       hourlyBreakdown = List<HourlyMetrics>.unmodifiable(hourlyBreakdown),
       inputTokensCoverageSessionCount =
           inputTokensCoverageSessionCount ?? totalSessionCount,
       outputTokensCoverageSessionCount =
           outputTokensCoverageSessionCount ?? totalSessionCount,
       totalCostCoverageSessionCount =
           totalCostCoverageSessionCount ?? totalSessionCount,
       perModelDailyBreakdown = Map<String, List<DailyMetrics>>.unmodifiable(
         (perModelDailyBreakdown ?? const <String, Iterable<DailyMetrics>>{})
             .map(
               (modelName, dailyMetrics) => MapEntry(
                 modelName,
                 List<DailyMetrics>.unmodifiable(dailyMetrics),
               ),
             ),
       ),
       perModelHourlyBreakdown = Map<String, List<HourlyMetrics>>.unmodifiable(
         (perModelHourlyBreakdown ?? const <String, Iterable<HourlyMetrics>>{})
             .map(
               (modelName, hourlyMetrics) => MapEntry(
                 modelName,
                 List<HourlyMetrics>.unmodifiable(hourlyMetrics),
               ),
             ),
       ),
       providerBreakdowns = Map<String, UsageBreakdown>.unmodifiable(
         providerBreakdowns ?? const <String, UsageBreakdown>{},
       ),
       providerModelBreakdowns =
           Map<String, Map<String, UsageBreakdown>>.unmodifiable(
             (providerModelBreakdowns ??
                     const <String, Map<String, UsageBreakdown>>{})
                 .map(
                   (provider, modelBreakdowns) => MapEntry(
                     provider,
                     Map<String, UsageBreakdown>.unmodifiable(modelBreakdowns),
                   ),
                 ),
           );

  final int totalSessionCount;
  final int totalInputTokens;
  final int totalOutputTokens;
  final double totalCostUsd;
  final int totalRequestCount;
  final int totalToolCallCount;
  final int totalResponseCount;
  final int totalResponseTimeMs;
  final int inputTokensCoverageSessionCount;
  final int outputTokensCoverageSessionCount;
  final int totalCostCoverageSessionCount;
  final int requestCountCoverageSessionCount;
  final int toolCallCountCoverageSessionCount;
  final int responseCountCoverageSessionCount;
  final int responseTimeCoverageSessionCount;
  final List<DailyMetrics> dailyBreakdown;
  final List<HourlyMetrics> hourlyBreakdown;
  final Map<String, List<DailyMetrics>> perModelDailyBreakdown;
  final Map<String, List<HourlyMetrics>> perModelHourlyBreakdown;
  final Map<String, UsageBreakdown> providerBreakdowns;
  final Map<String, Map<String, UsageBreakdown>> providerModelBreakdowns;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AggregatedMetrics &&
            other.totalSessionCount == totalSessionCount &&
            other.totalInputTokens == totalInputTokens &&
            other.totalOutputTokens == totalOutputTokens &&
            other.totalCostUsd == totalCostUsd &&
            other.totalRequestCount == totalRequestCount &&
            other.totalToolCallCount == totalToolCallCount &&
            other.totalResponseCount == totalResponseCount &&
            other.totalResponseTimeMs == totalResponseTimeMs &&
            other.inputTokensCoverageSessionCount ==
                inputTokensCoverageSessionCount &&
            other.outputTokensCoverageSessionCount ==
                outputTokensCoverageSessionCount &&
            other.totalCostCoverageSessionCount ==
                totalCostCoverageSessionCount &&
            other.requestCountCoverageSessionCount ==
                requestCountCoverageSessionCount &&
            other.toolCallCountCoverageSessionCount ==
                toolCallCountCoverageSessionCount &&
            other.responseCountCoverageSessionCount ==
                responseCountCoverageSessionCount &&
            other.responseTimeCoverageSessionCount ==
                responseTimeCoverageSessionCount &&
            _listEquals(other.dailyBreakdown, dailyBreakdown) &&
            _listEquals(other.hourlyBreakdown, hourlyBreakdown) &&
            _mapOfListsEquals(
              other.perModelDailyBreakdown,
              perModelDailyBreakdown,
            ) &&
            _mapOfListsEquals(
              other.perModelHourlyBreakdown,
              perModelHourlyBreakdown,
            ) &&
            _mapEquals(other.providerBreakdowns, providerBreakdowns) &&
            _nestedMapEquals(
              other.providerModelBreakdowns,
              providerModelBreakdowns,
            );
  }

  @override
  int get hashCode => Object.hash(
    Object.hash(
      totalSessionCount,
      totalInputTokens,
      totalOutputTokens,
      totalCostUsd,
      totalRequestCount,
      totalToolCallCount,
      totalResponseCount,
      totalResponseTimeMs,
      inputTokensCoverageSessionCount,
      outputTokensCoverageSessionCount,
      totalCostCoverageSessionCount,
    ),
    Object.hash(
      requestCountCoverageSessionCount,
      toolCallCountCoverageSessionCount,
      responseCountCoverageSessionCount,
      responseTimeCoverageSessionCount,
      Object.hashAll(dailyBreakdown),
      Object.hashAll(hourlyBreakdown),
      _mapOfListsHash(perModelDailyBreakdown),
      _mapOfListsHash(perModelHourlyBreakdown),
      _mapHash(providerBreakdowns),
      _nestedMapHash(providerModelBreakdowns),
    ),
  );
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) {
    return true;
  }

  if (left.length != right.length) {
    return false;
  }

  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }

  return true;
}

bool _mapOfListsEquals<T>(
  Map<String, List<T>> left,
  Map<String, List<T>> right,
) {
  if (identical(left, right)) {
    return true;
  }

  if (left.length != right.length) {
    return false;
  }

  for (final entry in left.entries) {
    final rightValue = right[entry.key];
    if (rightValue == null || !_listEquals(entry.value, rightValue)) {
      return false;
    }
  }

  return true;
}

int _mapOfListsHash<T>(Map<String, List<T>> map) {
  return Object.hashAllUnordered(
    map.entries.map(
      (entry) => Object.hash(entry.key, Object.hashAll(entry.value)),
    ),
  );
}

bool _mapEquals<T>(Map<String, T> left, Map<String, T> right) {
  if (identical(left, right)) {
    return true;
  }

  if (left.length != right.length) {
    return false;
  }

  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) {
      return false;
    }
  }

  return true;
}

bool _nestedMapEquals<T>(
  Map<String, Map<String, T>> left,
  Map<String, Map<String, T>> right,
) {
  if (identical(left, right)) {
    return true;
  }

  if (left.length != right.length) {
    return false;
  }

  for (final entry in left.entries) {
    final rightValue = right[entry.key];
    if (rightValue == null || !_mapEquals(entry.value, rightValue)) {
      return false;
    }
  }

  return true;
}

int _mapHash<T>(Map<String, T> map) {
  return Object.hashAllUnordered(
    map.entries.map((entry) => Object.hash(entry.key, entry.value)),
  );
}

int _nestedMapHash<T>(Map<String, Map<String, T>> map) {
  return Object.hashAllUnordered(
    map.entries.map((entry) => Object.hash(entry.key, _mapHash(entry.value))),
  );
}
