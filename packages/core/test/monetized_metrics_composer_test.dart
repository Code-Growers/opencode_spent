import 'package:openspent_core/openspent_core.dart';
import 'package:test/test.dart';

void main() {
  group('MonetizedMetricsComposer', () {
    test('returns USD display totals without exchange-rate reads', () async {
      final metrics = AggregatedMetrics(
        totalSessionCount: 2,
        totalInputTokens: 120,
        totalOutputTokens: 48,
        totalCostUsd: 1.25,
        dailyBreakdown: <DailyMetrics>[
          DailyMetrics(
            date: DateTime.utc(2026, 5, 1),
            sessionCount: 1,
            inputTokens: 70,
            outputTokens: 20,
            totalCostUsd: 0.75,
          ),
          DailyMetrics(
            date: DateTime.utc(2026, 5, 2),
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
            inputTokens: 70,
            outputTokens: 20,
            totalCostUsd: 0.75,
          ),
          HourlyMetrics(
            hour: DateTime.utc(2026, 5, 2, 9),
            sessionCount: 1,
            inputTokens: 50,
            outputTokens: 28,
            totalCostUsd: 0.50,
          ),
        ],
        perModelDailyBreakdown: <String, List<DailyMetrics>>{
          'gpt-5.4': <DailyMetrics>[
            DailyMetrics(
              date: DateTime.utc(2026, 5, 1),
              sessionCount: 1,
              inputTokens: 70,
              outputTokens: 20,
              totalCostUsd: 0.75,
            ),
            DailyMetrics(
              date: DateTime.utc(2026, 5, 2),
              sessionCount: 1,
              inputTokens: 50,
              outputTokens: 28,
              totalCostUsd: 0.50,
            ),
          ],
        },
      );
      final repository = _SpyExchangeRateRepository();
      final composer = MonetizedMetricsComposer(
        exchangeRateRepository: repository,
      );

      final monetizedMetrics = await composer.compose(
        metrics: metrics,
        selectedCurrency: SupportedCurrency.usd,
      );

      expect(repository.readDates, isEmpty);
      expect(monetizedMetrics.baseMetrics, same(metrics));
      expect(monetizedMetrics.displayCurrency, SupportedCurrency.usd);
      expect(monetizedMetrics.displayTotalCost, metrics.totalCostUsd);
      expect(monetizedMetrics.dailyBreakdown, hasLength(2));
      expect(monetizedMetrics.dailyBreakdown.first.baseMetrics,
          same(metrics.dailyBreakdown.first));
      expect(monetizedMetrics.dailyBreakdown.first.displayTotalCost, 0.75);
      expect(monetizedMetrics.dailyBreakdown.last.baseMetrics,
          same(metrics.dailyBreakdown.last));
      expect(monetizedMetrics.dailyBreakdown.last.displayTotalCost, 0.50);
      expect(monetizedMetrics.hourlyBreakdown, hasLength(2));
      expect(
        monetizedMetrics.hourlyBreakdown.first.baseMetrics,
        same(metrics.hourlyBreakdown.first),
      );
      expect(monetizedMetrics.hourlyBreakdown.first.displayTotalCost, 0.75);
      expect(
        monetizedMetrics.hourlyBreakdown.last.baseMetrics,
        same(metrics.hourlyBreakdown.last),
      );
      expect(monetizedMetrics.hourlyBreakdown.last.displayTotalCost, 0.50);
      expect(monetizedMetrics.perModelDailyBreakdown.keys, <String>['gpt-5.4']);
      expect(
        monetizedMetrics.perModelDailyBreakdown['gpt-5.4']!.map(
          (daily) => daily.displayTotalCost,
        ),
        <double>[0.75, 0.50],
      );
    });

    test(
        'converts top-level and per-model daily USD totals to CZK with same-date rate reuse',
        () async {
      final firstDate = DateTime.utc(2026, 5, 1);
      final secondDate = DateTime.utc(2026, 5, 2);
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
      final repository = _SpyExchangeRateRepository(
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
              currency: SupportedCurrency.czk,
              date: secondDate,
              rateToCzk: 1.0,
            ),
            ExchangeRate(
              currency: SupportedCurrency.usd,
              date: secondDate,
              rateToCzk: 23.0,
            ),
          ],
        },
      );
      final composer = MonetizedMetricsComposer(
        exchangeRateRepository: repository,
      );

      final monetizedMetrics = await composer.compose(
        metrics: metrics,
        selectedCurrency: SupportedCurrency.czk,
      );

      expect(repository.readDates, <DateTime>[firstDate, secondDate]);
      expect(monetizedMetrics.displayCurrency, SupportedCurrency.czk);
      expect(monetizedMetrics.dailyBreakdown, hasLength(2));
      expect(monetizedMetrics.hourlyBreakdown, hasLength(3));
      expect(
        monetizedMetrics.dailyBreakdown.first.displayTotalCost,
        closeTo(16.5, 0.000001),
      );
      expect(
        monetizedMetrics.dailyBreakdown.last.displayTotalCost,
        closeTo(11.5, 0.000001),
      );
      expect(
        monetizedMetrics.hourlyBreakdown[0].displayTotalCost,
        closeTo(5.5, 0.000001),
      );
      expect(
        monetizedMetrics.hourlyBreakdown[1].displayTotalCost,
        closeTo(11.0, 0.000001),
      );
      expect(
        monetizedMetrics.hourlyBreakdown[2].displayTotalCost,
        closeTo(11.5, 0.000001),
      );
      expect(monetizedMetrics.displayTotalCost, closeTo(28.0, 0.000001));
      expect(monetizedMetrics.perModelDailyBreakdown.keys,
          <String>['gpt-5.4', 'o4-mini']);
      expect(
        monetizedMetrics
            .perModelDailyBreakdown['gpt-5.4']!.single.displayTotalCost,
        closeTo(16.5, 0.000001),
      );
      expect(
        monetizedMetrics
            .perModelDailyBreakdown['o4-mini']!.single.displayTotalCost,
        closeTo(11.5, 0.000001),
      );
      expect(monetizedMetrics.perModelHourlyBreakdown.keys,
          <String>['gpt-5.4', 'o4-mini']);
      expect(
        monetizedMetrics
            .perModelHourlyBreakdown['gpt-5.4']!.single.displayTotalCost,
        closeTo(5.5, 0.000001),
      );
      expect(
        monetizedMetrics
            .perModelHourlyBreakdown['o4-mini']!.single.displayTotalCost,
        closeTo(11.5, 0.000001),
      );
    });

    test(
        'skips rate reads for zero-cost days across top-level and per-model data',
        () async {
      final nonZeroDate = DateTime.utc(2026, 5, 2);
      final metrics = AggregatedMetrics(
        totalSessionCount: 3,
        totalInputTokens: 120,
        totalOutputTokens: 48,
        totalCostUsd: 0.50,
        dailyBreakdown: <DailyMetrics>[
          DailyMetrics(
            date: DateTime.utc(2026, 5, 1),
            sessionCount: 1,
            inputTokens: 70,
            outputTokens: 20,
            totalCostUsd: 0,
          ),
          DailyMetrics(
            date: nonZeroDate,
            sessionCount: 1,
            inputTokens: 50,
            outputTokens: 28,
            totalCostUsd: 0.50,
          ),
          DailyMetrics(
            date: DateTime.utc(2026, 5, 3),
            sessionCount: 1,
            inputTokens: 0,
            outputTokens: 0,
            totalCostUsd: 0,
          ),
        ],
        hourlyBreakdown: <HourlyMetrics>[
          HourlyMetrics(
            hour: DateTime.utc(2026, 5, 1, 8),
            sessionCount: 1,
            inputTokens: 70,
            outputTokens: 20,
            totalCostUsd: 0,
          ),
          HourlyMetrics(
            hour: DateTime.utc(2026, 5, 2, 9),
            sessionCount: 1,
            inputTokens: 50,
            outputTokens: 28,
            totalCostUsd: 0.50,
          ),
          HourlyMetrics(
            hour: DateTime.utc(2026, 5, 2, 10),
            sessionCount: 1,
            inputTokens: 0,
            outputTokens: 0,
            totalCostUsd: 0,
          ),
          HourlyMetrics(
            hour: DateTime.utc(2026, 5, 3, 11),
            sessionCount: 1,
            inputTokens: 0,
            outputTokens: 0,
            totalCostUsd: 0,
          ),
        ],
        perModelDailyBreakdown: <String, List<DailyMetrics>>{
          'gpt-5.4': <DailyMetrics>[
            DailyMetrics(
              date: DateTime.utc(2026, 5, 1),
              sessionCount: 1,
              inputTokens: 70,
              outputTokens: 20,
              totalCostUsd: 0,
            ),
            DailyMetrics(
              date: nonZeroDate,
              sessionCount: 1,
              inputTokens: 50,
              outputTokens: 28,
              totalCostUsd: 0.50,
            ),
          ],
          'o4-mini': <DailyMetrics>[
            DailyMetrics(
              date: DateTime.utc(2026, 5, 3),
              sessionCount: 1,
              inputTokens: 0,
              outputTokens: 0,
              totalCostUsd: 0,
            ),
          ],
        },
      );
      final repository = _SpyExchangeRateRepository(
        ratesByDate: <DateTime, List<ExchangeRate>>{
          nonZeroDate: <ExchangeRate>[
            ExchangeRate(
              currency: SupportedCurrency.usd,
              date: nonZeroDate,
              rateToCzk: 22.0,
            ),
          ],
        },
      );
      final composer = MonetizedMetricsComposer(
        exchangeRateRepository: repository,
      );

      final monetizedMetrics = await composer.compose(
        metrics: metrics,
        selectedCurrency: SupportedCurrency.czk,
      );

      expect(repository.readDates, <DateTime>[nonZeroDate]);
      expect(
        monetizedMetrics.dailyBreakdown.map((daily) => daily.displayTotalCost),
        <double>[0, 11.0, 0],
      );
      expect(
        monetizedMetrics.hourlyBreakdown
            .map((hourly) => hourly.displayTotalCost),
        <double>[0, 11.0, 0, 0],
      );
      expect(
        monetizedMetrics.perModelDailyBreakdown['gpt-5.4']!
            .map((daily) => daily.displayTotalCost),
        <double>[0, 11.0],
      );
      expect(
        monetizedMetrics
            .perModelDailyBreakdown['o4-mini']!.single.displayTotalCost,
        0,
      );
      expect(monetizedMetrics.displayTotalCost, 11.0);
    });

    test('throws when a non-zero day has no USD rate', () async {
      final date = DateTime.utc(2026, 5, 2);
      final metrics = AggregatedMetrics(
        totalSessionCount: 1,
        totalInputTokens: 50,
        totalOutputTokens: 28,
        totalCostUsd: 0.50,
        dailyBreakdown: <DailyMetrics>[
          DailyMetrics(
            date: date,
            sessionCount: 1,
            inputTokens: 50,
            outputTokens: 28,
            totalCostUsd: 0.50,
          ),
        ],
        hourlyBreakdown: <HourlyMetrics>[
          HourlyMetrics(
            hour: DateTime.utc(2026, 5, 2, 9),
            sessionCount: 1,
            inputTokens: 50,
            outputTokens: 28,
            totalCostUsd: 0.50,
          ),
        ],
      );
      final repository = _SpyExchangeRateRepository(
        ratesByDate: <DateTime, List<ExchangeRate>>{
          date: <ExchangeRate>[
            ExchangeRate(
              currency: SupportedCurrency.czk,
              date: date,
              rateToCzk: 1.0,
            ),
          ],
        },
      );
      final composer = MonetizedMetricsComposer(
        exchangeRateRepository: repository,
      );

      await expectLater(
        composer.compose(
          metrics: metrics,
          selectedCurrency: SupportedCurrency.czk,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Missing USD exchange rate for ${date.toIso8601String()}.',
          ),
        ),
      );
      expect(repository.readDates, <DateTime>[date]);
    });

    test('converts hourly totals to USD and CZK using UTC-day rate reuse',
        () async {
      final date = DateTime.utc(2026, 5, 2);
      final metrics = AggregatedMetrics(
        totalSessionCount: 2,
        totalInputTokens: 42,
        totalOutputTokens: 16,
        totalCostUsd: 1.20,
        dailyBreakdown: <DailyMetrics>[
          DailyMetrics(
            date: date,
            sessionCount: 2,
            inputTokens: 42,
            outputTokens: 16,
            totalCostUsd: 1.20,
          ),
        ],
        hourlyBreakdown: <HourlyMetrics>[
          HourlyMetrics(
            hour: DateTime.utc(2026, 5, 2, 8),
            sessionCount: 1,
            inputTokens: 20,
            outputTokens: 7,
            totalCostUsd: 0.45,
          ),
          HourlyMetrics(
            hour: DateTime.utc(2026, 5, 2, 9),
            sessionCount: 1,
            inputTokens: 22,
            outputTokens: 9,
            totalCostUsd: 0.75,
          ),
        ],
      );

      final usdRepository = _SpyExchangeRateRepository();
      final usdComposer = MonetizedMetricsComposer(
        exchangeRateRepository: usdRepository,
      );
      final usdMetrics = await usdComposer.compose(
        metrics: metrics,
        selectedCurrency: SupportedCurrency.usd,
      );

      expect(usdRepository.readDates, isEmpty);
      expect(
        usdMetrics.hourlyBreakdown.map((hourly) => hourly.displayTotalCost),
        <double>[0.45, 0.75],
      );

      final czkRepository = _SpyExchangeRateRepository(
        ratesByDate: <DateTime, List<ExchangeRate>>{
          date: <ExchangeRate>[
            ExchangeRate(
              currency: SupportedCurrency.usd,
              date: date,
              rateToCzk: 22.0,
            ),
          ],
        },
      );
      final czkComposer = MonetizedMetricsComposer(
        exchangeRateRepository: czkRepository,
      );
      final czkMetrics = await czkComposer.compose(
        metrics: metrics,
        selectedCurrency: SupportedCurrency.czk,
      );

      expect(czkRepository.readDates, <DateTime>[date]);
      expect(
        czkMetrics.hourlyBreakdown.map((hourly) => hourly.displayTotalCost),
        orderedEquals(<Matcher>[
          closeTo(9.9, 0.000001),
          closeTo(16.5, 0.000001),
        ]),
      );
    });
  });
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
  Future<void> writeExchangeRates(Iterable<ExchangeRate> rates) {
    throw UnimplementedError();
  }
}
