import 'package:flutter_test/flutter_test.dart';
import 'package:openspent_core/openspent_core.dart';
import 'package:openspent_dashboard/src/screens/exchange_rates/cubit/exchange_rates_cubit.dart';

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this._settings);

  OpenCodeSettings? _settings;

  @override
  Future<OpenCodeSettings?> readSettings() async => _settings;

  @override
  Future<void> writeSettings(OpenCodeSettings settings) async {
    _settings = settings;
  }
}

class _FakeMetricsRepository implements MetricsRepository {
  _FakeMetricsRepository(this.metrics);

  AggregatedMetrics metrics;

  @override
  Future<AggregatedMetrics> readMetrics({DateTime? from, DateTime? to}) async {
    if (from == null && to == null) {
      return metrics;
    }

    final filteredDaily = metrics.dailyBreakdown.where((d) {
      if (from != null && d.date.isBefore(from)) return false;
      if (to != null && d.date.isAfter(to)) return false;
      return true;
    }).toList();

    return AggregatedMetrics(
      totalSessionCount: metrics.totalSessionCount,
      totalInputTokens: metrics.totalInputTokens,
      totalOutputTokens: metrics.totalOutputTokens,
      totalCostUsd: metrics.totalCostUsd,
      dailyBreakdown: filteredDaily,
    );
  }
}

class _FakeExchangeRateRepository implements ExchangeRateRepository {
  final Map<DateTime, List<ExchangeRate>> _ratesByDate = {};

  @override
  Future<List<ExchangeRate>> readExchangeRatesForDate(DateTime date) async {
    return List<ExchangeRate>.from(_ratesByDate[_normalize(date)] ?? const []);
  }

  @override
  Future<void> writeExchangeRates(
    Iterable<ExchangeRate> rates, {
    DateTime? effectiveDate,
  }) async {
    for (final rate in rates) {
      final key = _normalize(effectiveDate ?? rate.date);
      final nextRates = List<ExchangeRate>.from(_ratesByDate[key] ?? const []);
      nextRates.removeWhere((existing) => existing.currency == rate.currency);
      nextRates.add(rate);
      _ratesByDate[key] = nextRates;
    }
  }

  void seed(DateTime date, List<ExchangeRate> rates) {
    _ratesByDate[_normalize(date)] = List<ExchangeRate>.from(rates);
  }

  static DateTime _normalize(DateTime value) {
    final utc = value.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day);
  }
}

class _FakeRemoteExchangeRateRepository implements ExchangeRateRepository {
  _FakeRemoteExchangeRateRepository(this._responses, {this.failingDate});

  final Map<DateTime, List<ExchangeRate>> _responses;
  final DateTime? failingDate;
  final List<DateTime> requestedDates = <DateTime>[];

  @override
  Future<List<ExchangeRate>> readExchangeRatesForDate(DateTime date) async {
    final normalized = _normalize(date);
    requestedDates.add(normalized);
    if (failingDate != null && normalized == failingDate) {
      throw StateError('sync failed for ${normalized.toIso8601String()}');
    }
    return List<ExchangeRate>.from(_responses[normalized] ?? const []);
  }

  @override
  Future<void> writeExchangeRates(
    Iterable<ExchangeRate> rates, {
    DateTime? effectiveDate,
  }) async {}

  static DateTime _normalize(DateTime value) {
    final utc = value.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day);
  }
}

AggregatedMetrics _buildMetrics() {
  return AggregatedMetrics(
    totalSessionCount: 2,
    totalInputTokens: 10,
    totalOutputTokens: 5,
    totalCostUsd: 1.5,
    dailyBreakdown: [
      DailyMetrics(
        date: DateTime.utc(2026, 5, 6),
        sessionCount: 1,
        inputTokens: 2,
        outputTokens: 1,
        totalCostUsd: 0.5,
      ),
      DailyMetrics(
        date: DateTime.utc(2026, 5, 7),
        sessionCount: 0,
        inputTokens: 0,
        outputTokens: 0,
        totalCostUsd: 0,
      ),
      DailyMetrics(
        date: DateTime.utc(2026, 5, 8),
        sessionCount: 1,
        inputTokens: 8,
        outputTokens: 4,
        totalCostUsd: 1.0,
      ),
    ],
  );
}

ExchangeRate _usdRate(DateTime date, double value) =>
    ExchangeRate(currency: SupportedCurrency.usd, date: date, rateToCzk: value);

ExchangeRatesCubit _buildCubit({
  required _FakeMetricsRepository metricsRepository,
  required _FakeSettingsRepository settingsRepository,
  required _FakeExchangeRateRepository localRepository,
  required _FakeRemoteExchangeRateRepository remoteRepository,
}) {
  return ExchangeRatesCubit(
    dependencies: ExchangeRatesCubitDependencies(
      metricsRepository: metricsRepository,
      settingsRepository: settingsRepository,
      localExchangeRateRepository: localRepository,
      syncService: ExchangeRateSyncService(
        remoteRepository: remoteRepository,
        localRepository: localRepository,
      ),
    ),
  );
}

void main() {
  test('load derives spend-day coverage from USD rates only', () async {
    final metricsRepository = _FakeMetricsRepository(_buildMetrics());
    final settingsRepository = _FakeSettingsRepository(
      OpenCodeSettings(
        selectedCurrency: SupportedCurrency.czk,
        openCodeServerUrl: Uri.parse('http://localhost:4096'),
      ),
    );
    final localRepository = _FakeExchangeRateRepository()
      ..seed(DateTime.utc(2026, 5, 6), [
        ExchangeRate(
          currency: SupportedCurrency.czk,
          date: DateTime.utc(2026, 5, 6),
          rateToCzk: 1,
        ),
      ])
      ..seed(DateTime.utc(2026, 5, 8), [
        _usdRate(DateTime.utc(2026, 5, 8), 22),
      ]);
    final remoteRepository = _FakeRemoteExchangeRateRepository({});

    final cubit = _buildCubit(
      metricsRepository: metricsRepository,
      settingsRepository: settingsRepository,
      localRepository: localRepository,
      remoteRepository: remoteRepository,
    );
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.selectedCurrency, SupportedCurrency.czk);
    expect(cubit.state.requiredDates, [
      DateTime.utc(2026, 5, 6),
      DateTime.utc(2026, 5, 8),
    ]);
    expect(cubit.state.missingDates, [DateTime.utc(2026, 5, 6)]);
  });

  test('selectCurrency persists selection and refreshes state', () async {
    final metricsRepository = _FakeMetricsRepository(_buildMetrics());
    final settingsRepository = _FakeSettingsRepository(
      OpenCodeSettings(
        selectedCurrency: SupportedCurrency.usd,
        openCodeServerUrl: Uri.parse('http://localhost:4096'),
      ),
    );
    final localRepository = _FakeExchangeRateRepository();
    final remoteRepository = _FakeRemoteExchangeRateRepository({});
    final cubit = _buildCubit(
      metricsRepository: metricsRepository,
      settingsRepository: settingsRepository,
      localRepository: localRepository,
      remoteRepository: remoteRepository,
    );
    addTearDown(cubit.close);

    final success = await cubit.selectCurrency(SupportedCurrency.czk);

    expect(success, isTrue);
    expect(
      (await settingsRepository.readSettings())!.selectedCurrency,
      SupportedCurrency.czk,
    );
    expect(cubit.state.selectedCurrency, SupportedCurrency.czk);
  });

  test(
    'syncMissingRates fetches only missing spend days and updates coverage',
    () async {
      final metricsRepository = _FakeMetricsRepository(_buildMetrics());
      final settingsRepository = _FakeSettingsRepository(
        OpenCodeSettings(
          selectedCurrency: SupportedCurrency.czk,
          openCodeServerUrl: Uri.parse('http://localhost:4096'),
        ),
      );
      final localRepository = _FakeExchangeRateRepository()
        ..seed(DateTime.utc(2026, 5, 8), [
          _usdRate(DateTime.utc(2026, 5, 8), 22),
        ]);
      final remoteRepository = _FakeRemoteExchangeRateRepository({
        DateTime.utc(2026, 5, 6): [
          _usdRate(DateTime.utc(2026, 5, 6), 21.5),
          ExchangeRate(
            currency: SupportedCurrency.czk,
            date: DateTime.utc(2026, 5, 6),
            rateToCzk: 1,
          ),
        ],
      });
      final cubit = _buildCubit(
        metricsRepository: metricsRepository,
        settingsRepository: settingsRepository,
        localRepository: localRepository,
        remoteRepository: remoteRepository,
      );
      addTearDown(cubit.close);

      await cubit.load();
      final success = await cubit.syncMissingRates();

      expect(success, isTrue);
      expect(remoteRepository.requestedDates, [DateTime.utc(2026, 5, 6)]);
      expect(cubit.state.missingDates, isEmpty);
      expect(cubit.state.coveredDateCount, 2);
    },
  );

  test(
    'syncMissingRates marks a weekend day covered by the prior working-day fixing',
    () async {
      final weekendDate = DateTime.utc(2026, 5, 9);
      final metricsRepository = _FakeMetricsRepository(
        AggregatedMetrics(
          totalSessionCount: 1,
          totalInputTokens: 8,
          totalOutputTokens: 4,
          totalCostUsd: 1.0,
          dailyBreakdown: [
            DailyMetrics(
              date: weekendDate,
              sessionCount: 1,
              inputTokens: 8,
              outputTokens: 4,
              totalCostUsd: 1.0,
            ),
          ],
        ),
      );
      final settingsRepository = _FakeSettingsRepository(
        OpenCodeSettings(
          selectedCurrency: SupportedCurrency.czk,
          openCodeServerUrl: Uri.parse('http://localhost:4096'),
        ),
      );
      final localRepository = _FakeExchangeRateRepository();
      final remoteRepository = _FakeRemoteExchangeRateRepository({
        weekendDate: [
          _usdRate(DateTime.utc(2026, 5, 8), 22.0),
          ExchangeRate(
            currency: SupportedCurrency.czk,
            date: DateTime.utc(2026, 5, 8),
            rateToCzk: 1,
          ),
        ],
      });
      final cubit = _buildCubit(
        metricsRepository: metricsRepository,
        settingsRepository: settingsRepository,
        localRepository: localRepository,
        remoteRepository: remoteRepository,
      );
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.missingDates, [weekendDate]);

      final success = await cubit.syncMissingRates();

      expect(success, isTrue);
      expect(remoteRepository.requestedDates, [weekendDate]);
      expect(cubit.state.missingDates, isEmpty);
      final storedRates = await localRepository.readExchangeRatesForDate(
        weekendDate,
      );
      expect(
        storedRates.map((rate) => rate.currency),
        containsAll(<SupportedCurrency>[
          SupportedCurrency.czk,
          SupportedCurrency.usd,
        ]),
      );
      expect(
        storedRates.map((rate) => rate.date),
        everyElement(DateTime.utc(2026, 5, 8)),
      );
    },
  );

  test(
    'syncMissingRates refreshes coverage after a partial sync failure',
    () async {
      final metricsRepository = _FakeMetricsRepository(_buildMetrics());
      final settingsRepository = _FakeSettingsRepository(
        OpenCodeSettings(
          selectedCurrency: SupportedCurrency.czk,
          openCodeServerUrl: Uri.parse('http://localhost:4096'),
        ),
      );
      final localRepository = _FakeExchangeRateRepository();
      final remoteRepository = _FakeRemoteExchangeRateRepository({
        DateTime.utc(2026, 5, 6): [
          _usdRate(DateTime.utc(2026, 5, 6), 21.5),
          ExchangeRate(
            currency: SupportedCurrency.czk,
            date: DateTime.utc(2026, 5, 6),
            rateToCzk: 1,
          ),
        ],
      }, failingDate: DateTime.utc(2026, 5, 8));
      final cubit = _buildCubit(
        metricsRepository: metricsRepository,
        settingsRepository: settingsRepository,
        localRepository: localRepository,
        remoteRepository: remoteRepository,
      );
      addTearDown(cubit.close);

      await cubit.load();
      final success = await cubit.syncMissingRates();

      expect(success, isFalse);
      expect(remoteRepository.requestedDates, [
        DateTime.utc(2026, 5, 6),
        DateTime.utc(2026, 5, 8),
      ]);
      expect(cubit.state.isError, isTrue);
      expect(cubit.state.coveredDateCount, 1);
      expect(cubit.state.missingDates, [DateTime.utc(2026, 5, 8)]);
      expect(
        cubit.state.errorMessage,
        contains('sync failed for 2026-05-08T00:00:00.000Z'),
      );
    },
  );

  test(
    'load derives spend-day coverage restricted by from and to dates',
    () async {
      final metricsRepository = _FakeMetricsRepository(_buildMetrics());
      final settingsRepository = _FakeSettingsRepository(
        OpenCodeSettings(
          selectedCurrency: SupportedCurrency.czk,
          openCodeServerUrl: Uri.parse('http://localhost:4096'),
        ),
      );
      final localRepository = _FakeExchangeRateRepository();
      final remoteRepository = _FakeRemoteExchangeRateRepository({});

      final cubit = _buildCubit(
        metricsRepository: metricsRepository,
        settingsRepository: settingsRepository,
        localRepository: localRepository,
        remoteRepository: remoteRepository,
      );
      addTearDown(cubit.close);

      final fromDate = DateTime.utc(2026, 5, 8);
      final toDate = DateTime.utc(2026, 5, 8, 23, 59, 59);

      await cubit.load(from: fromDate, to: toDate);

      expect(cubit.state.selectedCurrency, SupportedCurrency.czk);
      expect(cubit.state.requiredDates, [DateTime.utc(2026, 5, 8)]);
      expect(cubit.state.missingDates, [DateTime.utc(2026, 5, 8)]);
    },
  );

  test(
    'syncMissingRates fetches only missing spend days inside the active window',
    () async {
      final metricsRepository = _FakeMetricsRepository(_buildMetrics());
      final settingsRepository = _FakeSettingsRepository(
        OpenCodeSettings(
          selectedCurrency: SupportedCurrency.czk,
          openCodeServerUrl: Uri.parse('http://localhost:4096'),
        ),
      );
      final localRepository = _FakeExchangeRateRepository();
      final remoteRepository = _FakeRemoteExchangeRateRepository({
        DateTime.utc(2026, 5, 8): [
          _usdRate(DateTime.utc(2026, 5, 8), 22.0),
          ExchangeRate(
            currency: SupportedCurrency.czk,
            date: DateTime.utc(2026, 5, 8),
            rateToCzk: 1,
          ),
        ],
      });

      final cubit = _buildCubit(
        metricsRepository: metricsRepository,
        settingsRepository: settingsRepository,
        localRepository: localRepository,
        remoteRepository: remoteRepository,
      );
      addTearDown(cubit.close);

      final fromDate = DateTime.utc(2026, 5, 8);

      await cubit.load(from: fromDate);

      expect(cubit.state.requiredDates, [DateTime.utc(2026, 5, 8)]);

      final success = await cubit.syncMissingRates(from: fromDate);

      expect(success, isTrue);
      expect(remoteRepository.requestedDates, [DateTime.utc(2026, 5, 8)]);
      expect(cubit.state.missingDates, isEmpty);
      expect(cubit.state.coveredDateCount, 1);
    },
  );
}
