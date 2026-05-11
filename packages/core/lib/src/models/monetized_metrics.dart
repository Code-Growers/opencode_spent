import 'aggregated_metrics.dart';
import 'daily_metrics.dart';
import 'hourly_metrics.dart';
import 'supported_currency.dart';

final class MonetizedDailyMetrics {
  const MonetizedDailyMetrics({
    required this.baseMetrics,
    required this.displayTotalCost,
  });

  final DailyMetrics baseMetrics;
  final double displayTotalCost;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MonetizedDailyMetrics &&
            other.baseMetrics == baseMetrics &&
            other.displayTotalCost == displayTotalCost;
  }

  @override
  int get hashCode => Object.hash(baseMetrics, displayTotalCost);
}

final class MonetizedHourlyMetrics {
  const MonetizedHourlyMetrics({
    required this.baseMetrics,
    required this.displayTotalCost,
  });

  final HourlyMetrics baseMetrics;
  final double displayTotalCost;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MonetizedHourlyMetrics &&
            other.baseMetrics == baseMetrics &&
            other.displayTotalCost == displayTotalCost;
  }

  @override
  int get hashCode => Object.hash(baseMetrics, displayTotalCost);
}

final class MonetizedAggregatedMetrics {
  MonetizedAggregatedMetrics({
    required this.baseMetrics,
    required this.displayCurrency,
    required this.displayTotalCost,
    required Iterable<MonetizedDailyMetrics> dailyBreakdown,
    Iterable<MonetizedHourlyMetrics> hourlyBreakdown =
        const <MonetizedHourlyMetrics>[],
    Map<String, Iterable<MonetizedDailyMetrics>>? perModelDailyBreakdown,
    Map<String, Iterable<MonetizedHourlyMetrics>>? perModelHourlyBreakdown,
  })  : dailyBreakdown =
            List<MonetizedDailyMetrics>.unmodifiable(dailyBreakdown),
        hourlyBreakdown =
            List<MonetizedHourlyMetrics>.unmodifiable(hourlyBreakdown),
        perModelDailyBreakdown =
            Map<String, List<MonetizedDailyMetrics>>.unmodifiable(
          (perModelDailyBreakdown ??
                  const <String, Iterable<MonetizedDailyMetrics>>{})
              .map(
            (modelName, dailyMetrics) => MapEntry(
              modelName,
              List<MonetizedDailyMetrics>.unmodifiable(dailyMetrics),
            ),
          ),
        ),
        perModelHourlyBreakdown =
            Map<String, List<MonetizedHourlyMetrics>>.unmodifiable(
          (perModelHourlyBreakdown ??
                  const <String, Iterable<MonetizedHourlyMetrics>>{})
              .map(
            (modelName, hourlyMetrics) => MapEntry(
              modelName,
              List<MonetizedHourlyMetrics>.unmodifiable(hourlyMetrics),
            ),
          ),
        );

  final AggregatedMetrics baseMetrics;
  final SupportedCurrency displayCurrency;
  final double displayTotalCost;
  final List<MonetizedDailyMetrics> dailyBreakdown;
  final List<MonetizedHourlyMetrics> hourlyBreakdown;
  final Map<String, List<MonetizedDailyMetrics>> perModelDailyBreakdown;
  final Map<String, List<MonetizedHourlyMetrics>> perModelHourlyBreakdown;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MonetizedAggregatedMetrics &&
            other.baseMetrics == baseMetrics &&
            other.displayCurrency == displayCurrency &&
            other.displayTotalCost == displayTotalCost &&
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
        baseMetrics,
        displayCurrency,
        displayTotalCost,
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
