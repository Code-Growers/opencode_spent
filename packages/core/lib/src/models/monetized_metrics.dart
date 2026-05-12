import 'aggregated_metrics.dart';
import 'daily_metrics.dart';
import 'hourly_metrics.dart';
import 'supported_currency.dart';
import 'usage_breakdown.dart';

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
    Map<String, MonetizedUsageBreakdown>? providerBreakdowns,
    Map<String, Map<String, MonetizedUsageBreakdown>>? providerModelBreakdowns,
  }) : dailyBreakdown = List<MonetizedDailyMetrics>.unmodifiable(
         dailyBreakdown,
       ),
       hourlyBreakdown = List<MonetizedHourlyMetrics>.unmodifiable(
         hourlyBreakdown,
       ),
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
           ),
       providerBreakdowns = Map<String, MonetizedUsageBreakdown>.unmodifiable(
         providerBreakdowns ?? const <String, MonetizedUsageBreakdown>{},
       ),
       providerModelBreakdowns =
           Map<String, Map<String, MonetizedUsageBreakdown>>.unmodifiable(
             (providerModelBreakdowns ??
                     const <String, Map<String, MonetizedUsageBreakdown>>{})
                 .map(
                   (provider, breakdowns) => MapEntry(
                     provider,
                     Map<String, MonetizedUsageBreakdown>.unmodifiable(
                       breakdowns,
                     ),
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
  final Map<String, MonetizedUsageBreakdown> providerBreakdowns;
  final Map<String, Map<String, MonetizedUsageBreakdown>>
  providerModelBreakdowns;

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
            ) &&
            _mapEquals(other.providerBreakdowns, providerBreakdowns) &&
            _nestedMapEquals(
              other.providerModelBreakdowns,
              providerModelBreakdowns,
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
    _mapHash(providerBreakdowns),
    _nestedMapHash(providerModelBreakdowns),
  );
}

final class MonetizedUsageBreakdown {
  const MonetizedUsageBreakdown({
    required this.baseMetrics,
    required this.displayTotalCost,
  });

  final UsageBreakdown baseMetrics;
  final double? displayTotalCost;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MonetizedUsageBreakdown &&
            other.baseMetrics == baseMetrics &&
            other.displayTotalCost == displayTotalCost;
  }

  @override
  int get hashCode => Object.hash(baseMetrics, displayTotalCost);
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
