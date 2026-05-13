import '../models/aggregated_metrics.dart';
import '../models/daily_metrics.dart';
import '../models/exchange_rate.dart';
import '../models/hourly_metrics.dart';
import '../models/monetized_metrics.dart';
import '../models/supported_currency.dart';
import '../models/usage_breakdown.dart';
import '../repositories/exchange_rate_repository.dart';

final class MonetizedMetricsComposer {
  const MonetizedMetricsComposer({required this.exchangeRateRepository});

  final ExchangeRateRepository exchangeRateRepository;

  Future<MonetizedAggregatedMetrics> compose({
    required AggregatedMetrics metrics,
    required SupportedCurrency selectedCurrency,
  }) async {
    if (selectedCurrency == SupportedCurrency.usd) {
      return MonetizedAggregatedMetrics(
        baseMetrics: metrics,
        displayCurrency: selectedCurrency,
        displayTotalCost: metrics.totalCostUsd,
        dailyBreakdown: _createUsdDailyBreakdown(metrics.dailyBreakdown),
        hourlyBreakdown: _createUsdHourlyBreakdown(metrics.hourlyBreakdown),
        perModelDailyBreakdown: metrics.perModelDailyBreakdown.map(
          (modelName, dailyBreakdown) =>
              MapEntry(modelName, _createUsdDailyBreakdown(dailyBreakdown)),
        ),
        perModelHourlyBreakdown: metrics.perModelHourlyBreakdown.map(
          (modelName, hourlyBreakdown) =>
              MapEntry(modelName, _createUsdHourlyBreakdown(hourlyBreakdown)),
        ),
        providerBreakdowns: metrics.providerBreakdowns.map(
          (provider, breakdown) => MapEntry(
            provider,
            MonetizedUsageBreakdown(
              baseMetrics: breakdown,
              displayTotalCost: breakdown.totalCostUsd,
            ),
          ),
        ),
        providerModelBreakdowns: metrics.providerModelBreakdowns.map(
          (provider, breakdowns) => MapEntry(
            provider,
            breakdowns.map(
              (modelName, breakdown) => MapEntry(
                modelName,
                MonetizedUsageBreakdown(
                  baseMetrics: breakdown,
                  displayTotalCost: breakdown.totalCostUsd,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final exchangeRateCache = <DateTime, List<ExchangeRate>>{};
    final dailyBreakdown = await _createDisplayCurrencyDailyBreakdown(
      dailyBreakdown: metrics.dailyBreakdown,
      displayCurrency: selectedCurrency,
      exchangeRateCache: exchangeRateCache,
    );
    final hourlyBreakdown = await _createDisplayCurrencyHourlyBreakdown(
      hourlyBreakdown: metrics.hourlyBreakdown,
      displayCurrency: selectedCurrency,
      exchangeRateCache: exchangeRateCache,
    );
    final perModelDailyBreakdown = <String, List<MonetizedDailyMetrics>>{};

    for (final entry in metrics.perModelDailyBreakdown.entries) {
      perModelDailyBreakdown[entry.key] =
          await _createDisplayCurrencyDailyBreakdown(
            dailyBreakdown: entry.value,
            displayCurrency: selectedCurrency,
            exchangeRateCache: exchangeRateCache,
          );
    }

    final perModelHourlyBreakdown = <String, List<MonetizedHourlyMetrics>>{};

    for (final entry in metrics.perModelHourlyBreakdown.entries) {
      perModelHourlyBreakdown[entry.key] =
          await _createDisplayCurrencyHourlyBreakdown(
            hourlyBreakdown: entry.value,
            displayCurrency: selectedCurrency,
            exchangeRateCache: exchangeRateCache,
          );
    }

    final providerModelBreakdowns =
        <String, Map<String, MonetizedUsageBreakdown>>{};
    for (final providerEntry in metrics.providerModelBreakdowns.entries) {
      final monetizedBreakdowns = <String, MonetizedUsageBreakdown>{};
      for (final modelEntry in providerEntry.value.entries) {
        final modelName = modelEntry.key;
        final convertedDaily = perModelDailyBreakdown[modelName];
        double? convertedTotalCost;
        if (convertedDaily != null) {
          convertedTotalCost = 0.0;
          for (final d in convertedDaily) {
            convertedTotalCost = convertedTotalCost! + d.displayTotalCost;
          }
        }
        monetizedBreakdowns[modelName] =
            await _createDisplayCurrencyUsageBreakdown(
              breakdown: modelEntry.value,
              displayCurrency: selectedCurrency,
              exchangeRateCache: exchangeRateCache,
              convertedTotalCost: convertedTotalCost,
            );
      }
      providerModelBreakdowns[providerEntry.key] = monetizedBreakdowns;
    }

    final providerBreakdowns = <String, MonetizedUsageBreakdown>{};
    for (final entry in metrics.providerBreakdowns.entries) {
      final provider = entry.key;
      double? providerTotalCost;
      final providerModels = providerModelBreakdowns[provider];
      if (providerModels != null) {
        providerTotalCost = 0.0;
        for (final m in providerModels.values) {
          if (m.displayTotalCost != null) {
            providerTotalCost = providerTotalCost! + m.displayTotalCost!;
          }
        }
      }
      providerBreakdowns[provider] = await _createDisplayCurrencyUsageBreakdown(
        breakdown: entry.value,
        displayCurrency: selectedCurrency,
        exchangeRateCache: exchangeRateCache,
        convertedTotalCost: providerTotalCost,
      );
    }

    var displayTotalCost = 0.0;
    for (final daily in dailyBreakdown) {
      displayTotalCost += daily.displayTotalCost;
    }

    return MonetizedAggregatedMetrics(
      baseMetrics: metrics,
      displayCurrency: selectedCurrency,
      displayTotalCost: displayTotalCost,
      dailyBreakdown: dailyBreakdown,
      hourlyBreakdown: hourlyBreakdown,
      perModelDailyBreakdown: perModelDailyBreakdown,
      perModelHourlyBreakdown: perModelHourlyBreakdown,
      providerBreakdowns: providerBreakdowns,
      providerModelBreakdowns: providerModelBreakdowns,
    );
  }

  Future<MonetizedUsageBreakdown> _createDisplayCurrencyUsageBreakdown({
    required UsageBreakdown breakdown,
    required SupportedCurrency displayCurrency,
    required Map<DateTime, List<ExchangeRate>> exchangeRateCache,
    required double? convertedTotalCost,
  }) async {
    if (displayCurrency == SupportedCurrency.usd) {
      return MonetizedUsageBreakdown(
        baseMetrics: breakdown,
        displayTotalCost: breakdown.totalCostUsd,
      );
    }

    return MonetizedUsageBreakdown(
      baseMetrics: breakdown,
      displayTotalCost: convertedTotalCost,
    );
  }

  List<MonetizedDailyMetrics> _createUsdDailyBreakdown(
    Iterable<DailyMetrics> dailyBreakdown,
  ) {
    return dailyBreakdown
        .map(
          (daily) => MonetizedDailyMetrics(
            baseMetrics: daily,
            displayTotalCost: daily.totalCostUsd,
          ),
        )
        .toList(growable: false);
  }

  List<MonetizedHourlyMetrics> _createUsdHourlyBreakdown(
    Iterable<HourlyMetrics> hourlyBreakdown,
  ) {
    return hourlyBreakdown
        .map(
          (hourly) => MonetizedHourlyMetrics(
            baseMetrics: hourly,
            displayTotalCost: hourly.totalCostUsd,
          ),
        )
        .toList(growable: false);
  }

  Future<List<MonetizedDailyMetrics>> _createDisplayCurrencyDailyBreakdown({
    required Iterable<DailyMetrics> dailyBreakdown,
    required SupportedCurrency displayCurrency,
    required Map<DateTime, List<ExchangeRate>> exchangeRateCache,
  }) async {
    final monetizedDailyBreakdown = <MonetizedDailyMetrics>[];

    for (final daily in dailyBreakdown) {
      monetizedDailyBreakdown.add(
        MonetizedDailyMetrics(
          baseMetrics: daily,
          displayTotalCost: await _convertDailyUsdTotalToDisplayCurrency(
            daily: daily,
            displayCurrency: displayCurrency,
            exchangeRateCache: exchangeRateCache,
          ),
        ),
      );
    }

    return monetizedDailyBreakdown;
  }

  Future<List<MonetizedHourlyMetrics>> _createDisplayCurrencyHourlyBreakdown({
    required Iterable<HourlyMetrics> hourlyBreakdown,
    required SupportedCurrency displayCurrency,
    required Map<DateTime, List<ExchangeRate>> exchangeRateCache,
  }) async {
    final monetizedHourlyBreakdown = <MonetizedHourlyMetrics>[];

    for (final hourly in hourlyBreakdown) {
      monetizedHourlyBreakdown.add(
        MonetizedHourlyMetrics(
          baseMetrics: hourly,
          displayTotalCost: await _convertUsdTotalToDisplayCurrency(
            totalCostUsd: hourly.totalCostUsd,
            date: hourly.hour,
            displayCurrency: displayCurrency,
            exchangeRateCache: exchangeRateCache,
          ),
        ),
      );
    }

    return monetizedHourlyBreakdown;
  }

  Future<double> _convertDailyUsdTotalToDisplayCurrency({
    required DailyMetrics daily,
    required SupportedCurrency displayCurrency,
    required Map<DateTime, List<ExchangeRate>> exchangeRateCache,
  }) async {
    return _convertUsdTotalToDisplayCurrency(
      totalCostUsd: daily.totalCostUsd,
      date: daily.date,
      displayCurrency: displayCurrency,
      exchangeRateCache: exchangeRateCache,
    );
  }

  Future<double> _convertUsdTotalToDisplayCurrency({
    required double totalCostUsd,
    required DateTime date,
    required SupportedCurrency displayCurrency,
    required Map<DateTime, List<ExchangeRate>> exchangeRateCache,
  }) async {
    if (totalCostUsd == 0) {
      return 0;
    }

    final rates = await _readExchangeRatesForDate(
      date: date,
      exchangeRateCache: exchangeRateCache,
    );
    final usdRateToCzk = _findRateToCzk(
      rates: rates,
      currency: SupportedCurrency.usd,
      date: _normalizeUtcDay(date),
    );
    final displayRateToCzk = _resolveDisplayRateToCzk(
      rates: rates,
      displayCurrency: displayCurrency,
      date: _normalizeUtcDay(date),
    );

    return totalCostUsd * usdRateToCzk / displayRateToCzk;
  }

  Future<List<ExchangeRate>> _readExchangeRatesForDate({
    required DateTime date,
    required Map<DateTime, List<ExchangeRate>> exchangeRateCache,
  }) async {
    final normalizedDate = _normalizeUtcDay(date);
    final cachedRates = exchangeRateCache[normalizedDate];
    if (cachedRates != null) {
      return cachedRates;
    }

    final rates = await exchangeRateRepository.readExchangeRatesForDate(
      normalizedDate,
    );
    exchangeRateCache[normalizedDate] = rates;
    return rates;
  }

  DateTime _normalizeUtcDay(DateTime dateTime) {
    final utcDateTime = dateTime.toUtc();
    return DateTime.utc(utcDateTime.year, utcDateTime.month, utcDateTime.day);
  }

  double _resolveDisplayRateToCzk({
    required Iterable<ExchangeRate> rates,
    required SupportedCurrency displayCurrency,
    required DateTime date,
  }) {
    if (displayCurrency == SupportedCurrency.czk) {
      return 1.0;
    }

    return _findRateToCzk(rates: rates, currency: displayCurrency, date: date);
  }

  double _findRateToCzk({
    required Iterable<ExchangeRate> rates,
    required SupportedCurrency currency,
    required DateTime date,
  }) {
    for (final rate in rates) {
      if (rate.currency == currency) {
        return rate.rateToCzk;
      }
    }

    throw StateError(
      'Missing ${currency.code} exchange rate for ${date.toIso8601String()}.',
    );
  }
}
