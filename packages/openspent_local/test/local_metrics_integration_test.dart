import 'package:flutter_test/flutter_test.dart';
import 'package:openspent_core/openspent_core.dart';
import 'package:openspent_local/openspent_local.dart';

void main() {
  group('Local metrics integration', () {
    test(
      'persists sessions and monetizes aggregated metrics locally',
      () async {
        final database = OpenSpentLocalDatabase.inMemory();
        addTearDown(database.close);

        final sessionRepository = LocalOpenCodeSessionRepository(database);
        final metricsRepository = LocalMetricsRepository(sessionRepository);
        final settingsRepository = _SpySettingsRepository(
          readSettingsResult: OpenCodeSettings(
            selectedCurrency: SupportedCurrency.czk,
            openCodeServerUrl: Uri.parse('http://localhost:4096'),
          ),
        );
        final exchangeRateRepository = _SpyExchangeRateRepository(
          ratesByDate: <DateTime, List<ExchangeRate>>{
            _day(2026, 5, 1): _ratesForDay(_day(2026, 5, 1), usdRateToCzk: 22),
            _day(2026, 5, 3): _ratesForDay(_day(2026, 5, 3), usdRateToCzk: 30),
          },
        );
        final service = MonetizedMetricsService(
          settingsRepository: settingsRepository,
          metricsRepository: metricsRepository,
          composer: MonetizedMetricsComposer(
            exchangeRateRepository: exchangeRateRepository,
          ),
        );

        await sessionRepository.writeSessions(<OpenCodeSession>[
          OpenCodeSession(
            id: 'session-day-1',
            createdAt: DateTime.utc(2026, 5, 1, 9),
            modelName: 'gpt-5.4',
            inputTokens: 10,
            outputTokens: 4,
            totalCostUsd: 0.25,
          ),
          OpenCodeSession(
            id: 'session-day-2-zero',
            createdAt: DateTime.utc(2026, 5, 2, 10),
            modelName: 'gpt-5.4',
            inputTokens: 20,
            outputTokens: 8,
            totalCostUsd: 0,
          ),
          OpenCodeSession(
            id: 'session-day-3',
            createdAt: DateTime.utc(2026, 5, 3, 11),
            modelName: 'o4-mini',
            inputTokens: 30,
            outputTokens: 12,
            totalCostUsd: 0.75,
          ),
        ]);

        final metrics = await metricsRepository.readMetrics(
          from: _day(2026, 5, 1),
          to: DateTime.utc(2026, 5, 3, 23, 59, 59, 999),
        );

        expect(metrics.totalSessionCount, 3);
        expect(metrics.totalInputTokens, 60);
        expect(metrics.totalOutputTokens, 24);
        expect(metrics.totalCostUsd, closeTo(1.0, 0.000001));
        expect(metrics.dailyBreakdown, hasLength(3));
        expect(
          metrics.dailyBreakdown.map((daily) => daily.totalCostUsd),
          <double>[0.25, 0, 0.75],
        );

        final monetizedMetrics = await service.readMonetizedMetrics(
          from: _day(2026, 5, 1),
          to: DateTime.utc(2026, 5, 3, 23, 59, 59, 999),
        );

        expect(settingsRepository.readSettingsCallCount, 1);
        expect(exchangeRateRepository.readDates, <DateTime>[
          _day(2026, 5, 1),
          _day(2026, 5, 3),
        ]);
        expect(monetizedMetrics.baseMetrics, metrics);
        expect(monetizedMetrics.displayCurrency, SupportedCurrency.czk);
        expect(monetizedMetrics.displayTotalCost, closeTo(28.0, 0.000001));
        expect(
          monetizedMetrics.dailyBreakdown.map(
            (daily) => daily.displayTotalCost,
          ),
          <double>[5.5, 0, 22.5],
        );
        expect(
          monetizedMetrics.hourlyBreakdown.map(
            (hourly) => hourly.displayTotalCost,
          ),
          <double>[5.5, 0, 22.5],
        );
      },
    );
  });
}

DateTime _day(int year, int month, int day) => DateTime.utc(year, month, day);

List<ExchangeRate> _ratesForDay(DateTime day, {required double usdRateToCzk}) {
  return <ExchangeRate>[
    ExchangeRate(currency: SupportedCurrency.czk, date: day, rateToCzk: 1),
    ExchangeRate(
      currency: SupportedCurrency.usd,
      date: day,
      rateToCzk: usdRateToCzk,
    ),
  ];
}

final class _SpySettingsRepository implements SettingsRepository {
  _SpySettingsRepository({this.readSettingsResult});

  final OpenCodeSettings? readSettingsResult;
  var readSettingsCallCount = 0;

  @override
  Future<OpenCodeSettings?> readSettings() async {
    readSettingsCallCount++;
    return readSettingsResult;
  }

  @override
  Future<void> writeSettings(OpenCodeSettings settings) async {
    throw UnimplementedError();
  }
}

final class _SpyExchangeRateRepository implements ExchangeRateRepository {
  _SpyExchangeRateRepository({Map<DateTime, List<ExchangeRate>>? ratesByDate})
    : ratesByDate = ratesByDate ?? const <DateTime, List<ExchangeRate>>{};

  final Map<DateTime, List<ExchangeRate>> ratesByDate;
  final List<DateTime> readDates = <DateTime>[];

  @override
  Future<List<ExchangeRate>> readExchangeRatesForDate(DateTime date) async {
    readDates.add(date);
    return ratesByDate[date] ?? const <ExchangeRate>[];
  }

  @override
  Future<void> writeExchangeRates(
    Iterable<ExchangeRate> rates, {
    DateTime? effectiveDate,
  }) async {
    throw UnimplementedError();
  }
}
