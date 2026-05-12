import 'package:openspent_core/openspent_core.dart';
import 'package:test/test.dart';

void main() {
  group('MonetizedMetricsService', () {
    test('defaults to USD when settings are absent', () async {
      final metrics = AggregatedMetrics(
        totalSessionCount: 1,
        totalInputTokens: 120,
        totalOutputTokens: 48,
        totalCostUsd: 1.25,
        dailyBreakdown: <DailyMetrics>[
          DailyMetrics(
            date: DateTime.utc(2026, 5, 1),
            sessionCount: 1,
            inputTokens: 120,
            outputTokens: 48,
            totalCostUsd: 1.25,
          ),
        ],
        hourlyBreakdown: <HourlyMetrics>[
          HourlyMetrics(
            hour: DateTime.utc(2026, 5, 1, 8),
            sessionCount: 1,
            inputTokens: 120,
            outputTokens: 48,
            totalCostUsd: 1.25,
          ),
        ],
        perModelDailyBreakdown: <String, List<DailyMetrics>>{
          'gpt-5.4': <DailyMetrics>[
            DailyMetrics(
              date: DateTime.utc(2026, 5, 1),
              sessionCount: 1,
              inputTokens: 120,
              outputTokens: 48,
              totalCostUsd: 1.25,
            ),
          ],
        },
      );
      final settingsRepository = _SpySettingsRepository();
      final metricsRepository = _SpyMetricsRepository(
        readMetricsResult: metrics,
      );
      final exchangeRateRepository = _SpyExchangeRateRepository();
      final service = MonetizedMetricsService(
        settingsRepository: settingsRepository,
        metricsRepository: metricsRepository,
        composer: MonetizedMetricsComposer(
          exchangeRateRepository: exchangeRateRepository,
        ),
      );

      final result = await service.readMonetizedMetrics();

      expect(settingsRepository.readSettingsCallCount, 1);
      expect(metricsRepository.readMetricsCallCount, 1);
      expect(metricsRepository.lastReadFrom, isNull);
      expect(metricsRepository.lastReadTo, isNull);
      expect(exchangeRateRepository.readDates, isEmpty);
      expect(result.baseMetrics, same(metrics));
      expect(result.displayCurrency, SupportedCurrency.usd);
      expect(result.displayTotalCost, metrics.totalCostUsd);
      expect(result.hourlyBreakdown.single.displayTotalCost, 1.25);
      expect(result.perModelDailyBreakdown.keys, <String>['gpt-5.4']);
      expect(
        result.perModelDailyBreakdown['gpt-5.4']!.single.displayTotalCost,
        1.25,
      );
    });

    test('forwards date filters and returns CZK monetized metrics', () async {
      final firstDate = DateTime.utc(2026, 5, 1);
      final secondDate = DateTime.utc(2026, 5, 2);
      final from = DateTime.utc(2026, 5, 1);
      final to = DateTime.utc(2026, 5, 31);
      final metrics = AggregatedMetrics(
        totalSessionCount: 2,
        totalInputTokens: 120,
        totalOutputTokens: 48,
        totalCostUsd: 1.25,
        dailyBreakdown: <DailyMetrics>[
          DailyMetrics(
            date: firstDate,
            sessionCount: 1,
            inputTokens: 70,
            outputTokens: 20,
            totalCostUsd: 0.75,
          ),
          DailyMetrics(
            date: secondDate,
            sessionCount: 1,
            inputTokens: 50,
            outputTokens: 28,
            totalCostUsd: 0.50,
          ),
        ],
        hourlyBreakdown: <HourlyMetrics>[
          HourlyMetrics(
            hour: DateTime.utc(2026, 5, 1, 8),
            sessionCount: 1,
            inputTokens: 25,
            outputTokens: 10,
            totalCostUsd: 0.25,
          ),
          HourlyMetrics(
            hour: DateTime.utc(2026, 5, 1, 9),
            sessionCount: 1,
            inputTokens: 45,
            outputTokens: 10,
            totalCostUsd: 0.50,
          ),
          HourlyMetrics(
            hour: DateTime.utc(2026, 5, 2, 10),
            sessionCount: 1,
            inputTokens: 50,
            outputTokens: 28,
            totalCostUsd: 0.50,
          ),
        ],
        perModelDailyBreakdown: <String, List<DailyMetrics>>{
          'gpt-5.4': <DailyMetrics>[
            DailyMetrics(
              date: firstDate,
              sessionCount: 1,
              inputTokens: 70,
              outputTokens: 20,
              totalCostUsd: 0.75,
            ),
          ],
          'o4-mini': <DailyMetrics>[
            DailyMetrics(
              date: secondDate,
              sessionCount: 1,
              inputTokens: 50,
              outputTokens: 28,
              totalCostUsd: 0.50,
            ),
          ],
        },
        perModelHourlyBreakdown: <String, List<HourlyMetrics>>{
          'gpt-5.4': <HourlyMetrics>[
            HourlyMetrics(
              hour: DateTime.utc(2026, 5, 1, 8),
              sessionCount: 1,
              inputTokens: 25,
              outputTokens: 10,
              totalCostUsd: 0.25,
            ),
          ],
          'o4-mini': <HourlyMetrics>[
            HourlyMetrics(
              hour: DateTime.utc(2026, 5, 2, 10),
              sessionCount: 1,
              inputTokens: 50,
              outputTokens: 28,
              totalCostUsd: 0.50,
            ),
          ],
        },
      );
      final settingsRepository = _SpySettingsRepository(
        readSettingsResult: OpenCodeSettings(
          selectedCurrency: SupportedCurrency.czk,
          openCodeServerUrl: Uri.parse('http://localhost:4096'),
        ),
      );
      final metricsRepository = _SpyMetricsRepository(
        readMetricsResult: metrics,
      );
      final exchangeRateRepository = _SpyExchangeRateRepository(
        ratesByDate: <DateTime, List<ExchangeRate>>{
          firstDate: <ExchangeRate>[
            ExchangeRate(
              currency: SupportedCurrency.usd,
              date: firstDate,
              rateToCzk: 22.0,
            ),
          ],
          secondDate: <ExchangeRate>[
            ExchangeRate(
              currency: SupportedCurrency.usd,
              date: secondDate,
              rateToCzk: 23.0,
            ),
          ],
        },
      );
      final service = MonetizedMetricsService(
        settingsRepository: settingsRepository,
        metricsRepository: metricsRepository,
        composer: MonetizedMetricsComposer(
          exchangeRateRepository: exchangeRateRepository,
        ),
      );

      final result = await service.readMonetizedMetrics(from: from, to: to);

      expect(settingsRepository.readSettingsCallCount, 1);
      expect(metricsRepository.readMetricsCallCount, 1);
      expect(metricsRepository.lastReadFrom, from);
      expect(metricsRepository.lastReadTo, to);
      expect(exchangeRateRepository.readDates, <DateTime>[
        firstDate,
        secondDate,
      ]);
      expect(result.displayCurrency, SupportedCurrency.czk);
      expect(result.displayTotalCost, closeTo(28.0, 0.000001));
      expect(result.dailyBreakdown, hasLength(2));
      expect(
        result.dailyBreakdown.first.displayTotalCost,
        closeTo(16.5, 0.000001),
      );
      expect(
        result.dailyBreakdown.last.displayTotalCost,
        closeTo(11.5, 0.000001),
      );
      expect(
        result.hourlyBreakdown.map((hourly) => hourly.displayTotalCost),
        <double>[5.5, 11.0, 11.5],
      );
      expect(result.perModelDailyBreakdown.keys, <String>[
        'gpt-5.4',
        'o4-mini',
      ]);
      expect(
        result.perModelDailyBreakdown['gpt-5.4']!.single.displayTotalCost,
        closeTo(16.5, 0.000001),
      );
      expect(
        result.perModelDailyBreakdown['o4-mini']!.single.displayTotalCost,
        closeTo(11.5, 0.000001),
      );
      expect(result.perModelHourlyBreakdown.keys, <String>[
        'gpt-5.4',
        'o4-mini',
      ]);
      expect(
        result.perModelHourlyBreakdown['gpt-5.4']!.single.displayTotalCost,
        closeTo(5.5, 0.000001),
      );
      expect(
        result.perModelHourlyBreakdown['o4-mini']!.single.displayTotalCost,
        closeTo(11.5, 0.000001),
      );
    });

    test('bubbles settings read failures and skips metrics reads', () async {
      final error = StateError('settings read failed');
      final settingsRepository = _SpySettingsRepository(readError: error);
      final metricsRepository = _SpyMetricsRepository(
        readMetricsResult: AggregatedMetrics(
          totalSessionCount: 0,
          totalInputTokens: 0,
          totalOutputTokens: 0,
          totalCostUsd: 0,
          dailyBreakdown: const <DailyMetrics>[],
          hourlyBreakdown: const <HourlyMetrics>[],
        ),
      );
      final exchangeRateRepository = _SpyExchangeRateRepository();
      final service = MonetizedMetricsService(
        settingsRepository: settingsRepository,
        metricsRepository: metricsRepository,
        composer: MonetizedMetricsComposer(
          exchangeRateRepository: exchangeRateRepository,
        ),
      );

      await expectLater(service.readMonetizedMetrics(), throwsA(same(error)));

      expect(settingsRepository.readSettingsCallCount, 1);
      expect(metricsRepository.readMetricsCallCount, 0);
      expect(exchangeRateRepository.readDates, isEmpty);
    });

    test('bubbles metrics read failures without exchange-rate reads', () async {
      final error = StateError('metrics read failed');
      final settingsRepository = _SpySettingsRepository(
        readSettingsResult: OpenCodeSettings(
          selectedCurrency: SupportedCurrency.czk,
          openCodeServerUrl: Uri.parse('http://localhost:4096'),
        ),
      );
      final metricsRepository = _SpyMetricsRepository(readError: error);
      final exchangeRateRepository = _SpyExchangeRateRepository();
      final service = MonetizedMetricsService(
        settingsRepository: settingsRepository,
        metricsRepository: metricsRepository,
        composer: MonetizedMetricsComposer(
          exchangeRateRepository: exchangeRateRepository,
        ),
      );

      await expectLater(service.readMonetizedMetrics(), throwsA(same(error)));

      expect(settingsRepository.readSettingsCallCount, 1);
      expect(metricsRepository.readMetricsCallCount, 1);
      expect(exchangeRateRepository.readDates, isEmpty);
    });
  });
}

final class _SpySettingsRepository implements SettingsRepository {
  _SpySettingsRepository({this.readSettingsResult, this.readError});

  final OpenCodeSettings? readSettingsResult;
  final Object? readError;

  int readSettingsCallCount = 0;

  @override
  Future<OpenCodeSettings?> readSettings() async {
    readSettingsCallCount += 1;

    if (readError != null) {
      throw readError!;
    }

    return readSettingsResult;
  }

  @override
  Future<void> writeSettings(OpenCodeSettings settings) {
    throw UnimplementedError();
  }
}

final class _SpyMetricsRepository implements MetricsRepository {
  _SpyMetricsRepository({this.readMetricsResult, this.readError});

  final AggregatedMetrics? readMetricsResult;
  final Object? readError;

  int readMetricsCallCount = 0;
  DateTime? lastReadFrom;
  DateTime? lastReadTo;

  @override
  Future<AggregatedMetrics> readMetrics({DateTime? from, DateTime? to}) async {
    readMetricsCallCount += 1;
    lastReadFrom = from;
    lastReadTo = to;

    if (readError != null) {
      throw readError!;
    }

    return readMetricsResult!;
  }
}

final class _SpyExchangeRateRepository implements ExchangeRateRepository {
  _SpyExchangeRateRepository({Map<DateTime, List<ExchangeRate>>? ratesByDate})
    : _ratesByDate = ratesByDate ?? <DateTime, List<ExchangeRate>>{};

  final Map<DateTime, List<ExchangeRate>> _ratesByDate;

  final List<DateTime> readDates = <DateTime>[];

  @override
  Future<List<ExchangeRate>> readExchangeRatesForDate(DateTime date) async {
    readDates.add(date);
    return _ratesByDate[date] ?? <ExchangeRate>[];
  }

  @override
  Future<void> writeExchangeRates(
    Iterable<ExchangeRate> rates, {
    DateTime? effectiveDate,
  }) {
    throw UnimplementedError();
  }
}
