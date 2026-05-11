import 'daily_metrics.dart';
import 'hourly_metrics.dart';

final class AggregatedMetrics {
  AggregatedMetrics({
    required this.totalSessionCount,
    required this.totalInputTokens,
    required this.totalOutputTokens,
    required this.totalCostUsd,
    required Iterable<DailyMetrics> dailyBreakdown,
    Iterable<HourlyMetrics> hourlyBreakdown = const <HourlyMetrics>[],
    Map<String, Iterable<DailyMetrics>>? perModelDailyBreakdown,
    Map<String, Iterable<HourlyMetrics>>? perModelHourlyBreakdown,
  })  : dailyBreakdown = List<DailyMetrics>.unmodifiable(dailyBreakdown),
        hourlyBreakdown = List<HourlyMetrics>.unmodifiable(hourlyBreakdown),
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
        );

  final int totalSessionCount;
  final int totalInputTokens;
  final int totalOutputTokens;
  final double totalCostUsd;
  final List<DailyMetrics> dailyBreakdown;
  final List<HourlyMetrics> hourlyBreakdown;
  final Map<String, List<DailyMetrics>> perModelDailyBreakdown;
  final Map<String, List<HourlyMetrics>> perModelHourlyBreakdown;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AggregatedMetrics &&
            other.totalSessionCount == totalSessionCount &&
            other.totalInputTokens == totalInputTokens &&
            other.totalOutputTokens == totalOutputTokens &&
            other.totalCostUsd == totalCostUsd &&
            _listEquals(other.dailyBreakdown, dailyBreakdown) &&
            _listEquals(other.hourlyBreakdown, hourlyBreakdown) &&
            _mapOfListsEquals(
              other.perModelDailyBreakdown,
              perModelDailyBreakdown,
            ) &&
            _mapOfListsEquals(
              other.perModelHourlyBreakdown,
              perModelHourlyBreakdown,
            );
  }

  @override
  int get hashCode => Object.hash(
        totalSessionCount,
        totalInputTokens,
        totalOutputTokens,
        totalCostUsd,
        Object.hashAll(dailyBreakdown),
        Object.hashAll(hourlyBreakdown),
        _mapOfListsHash(perModelDailyBreakdown),
        _mapOfListsHash(perModelHourlyBreakdown),
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
