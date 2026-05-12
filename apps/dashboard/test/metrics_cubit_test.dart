import 'package:flutter_test/flutter_test.dart';
import 'package:openspent_core/openspent_core.dart';
import 'package:openspent_dashboard/src/screens/metrics/cubit/metrics_cubit.dart';

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

class _RecordingMetricsRepository implements MetricsRepository {
  _RecordingMetricsRepository({
    required this.responses,
    this.failingRanges = const <String>{},
  });

  final Map<String, AggregatedMetrics> responses;
  final Set<String> failingRanges;
  final List<String> requestedRanges = <String>[];

  @override
  Future<AggregatedMetrics> readMetrics({DateTime? from, DateTime? to}) async {
    final key = _rangeKey(from: from, to: to);
    requestedRanges.add(key);

    if (failingRanges.contains(key)) {
      throw StateError('failed for $key');
    }

    final response = responses[key];
    if (response == null) {
      throw StateError('missing response for $key');
    }

    return response;
  }
}

AggregatedMetrics _buildMetrics({
  required DateTime date,
  required double totalCostUsd,
  int totalSessionCount = 1,
  int totalInputTokens = 10,
  int totalOutputTokens = 5,
}) {
  return AggregatedMetrics(
    totalSessionCount: totalSessionCount,
    totalInputTokens: totalInputTokens,
    totalOutputTokens: totalOutputTokens,
    totalCostUsd: totalCostUsd,
    dailyBreakdown: [
      DailyMetrics(
        date: date,
        sessionCount: totalSessionCount,
        inputTokens: totalInputTokens,
        outputTokens: totalOutputTokens,
        totalCostUsd: totalCostUsd,
      ),
    ],
  );
}

String _rangeKey({DateTime? from, DateTime? to}) {
  final fromValue = from?.toIso8601String() ?? 'null';
  final toValue = to?.toIso8601String() ?? 'null';
  return '$fromValue|$toValue';
}

void main() {
  test('load reads current and prior window metrics', () async {
    final from = DateTime.utc(2026, 5, 6);
    final to = DateTime.utc(2026, 5, 8, 23, 59, 59, 999);
    final priorFrom = DateTime.utc(2026, 5, 3);
    final priorTo = DateTime.utc(2026, 5, 5, 23, 59, 59, 999);

    final settingsRepository = _FakeSettingsRepository(
      OpenCodeSettings(
        selectedCurrency: SupportedCurrency.usd,
        openCodeServerUrl: Uri.parse('http://localhost:4096'),
      ),
    );
    final metricsRepository = _RecordingMetricsRepository(
      responses: {
        _rangeKey(from: from, to: to): _buildMetrics(
          date: DateTime.utc(2026, 5, 8),
          totalCostUsd: 2.5,
        ),
        _rangeKey(from: priorFrom, to: priorTo): _buildMetrics(
          date: DateTime.utc(2026, 5, 5),
          totalCostUsd: 1.5,
        ),
      },
    );
    final service = MonetizedMetricsService(
      settingsRepository: settingsRepository,
      metricsRepository: metricsRepository,
      composer: MonetizedMetricsComposer(
        exchangeRateRepository: _NoopExchangeRateRepository(),
      ),
    );

    final cubit = MetricsCubit(metricsService: service);
    addTearDown(cubit.close);

    await cubit.load(from: from, to: to);

    expect(metricsRepository.requestedRanges, [
      _rangeKey(from: from, to: to),
      _rangeKey(from: priorFrom, to: priorTo),
    ]);
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.hasError, isFalse);
    expect(cubit.state.data, isNotNull);
    expect(cubit.state.data!.currentMetrics.displayTotalCost, 2.5);
    expect(cubit.state.data!.priorMetrics, isNotNull);
    expect(cubit.state.data!.priorMetrics!.displayTotalCost, 1.5);
  });

  test(
    'load tolerates prior-window failure and keeps current metrics',
    () async {
      final from = DateTime.utc(2026, 5, 6);
      final to = DateTime.utc(2026, 5, 8, 23, 59, 59, 999);
      final priorFrom = DateTime.utc(2026, 5, 3);
      final priorTo = DateTime.utc(2026, 5, 5, 23, 59, 59, 999);

      final settingsRepository = _FakeSettingsRepository(
        OpenCodeSettings(
          selectedCurrency: SupportedCurrency.usd,
          openCodeServerUrl: Uri.parse('http://localhost:4096'),
        ),
      );
      final metricsRepository = _RecordingMetricsRepository(
        responses: {
          _rangeKey(from: from, to: to): _buildMetrics(
            date: DateTime.utc(2026, 5, 8),
            totalCostUsd: 3.0,
          ),
        },
        failingRanges: {_rangeKey(from: priorFrom, to: priorTo)},
      );
      final service = MonetizedMetricsService(
        settingsRepository: settingsRepository,
        metricsRepository: metricsRepository,
        composer: MonetizedMetricsComposer(
          exchangeRateRepository: _NoopExchangeRateRepository(),
        ),
      );

      final cubit = MetricsCubit(metricsService: service);
      addTearDown(cubit.close);

      await cubit.load(from: from, to: to);

      expect(cubit.state.hasError, isFalse);
      expect(cubit.state.data, isNotNull);
      expect(cubit.state.data!.currentMetrics.displayTotalCost, 3.0);
      expect(cubit.state.data!.priorMetrics, isNull);
    },
  );

  test('load emits error state when current metrics fail', () async {
    final from = DateTime.utc(2026, 5, 6);
    final to = DateTime.utc(2026, 5, 8, 23, 59, 59, 999);

    final settingsRepository = _FakeSettingsRepository(
      OpenCodeSettings(
        selectedCurrency: SupportedCurrency.czk,
        openCodeServerUrl: Uri.parse('http://localhost:4096'),
      ),
    );
    final metricsRepository = _RecordingMetricsRepository(
      responses: const {},
      failingRanges: {_rangeKey(from: from, to: to)},
    );
    final service = MonetizedMetricsService(
      settingsRepository: settingsRepository,
      metricsRepository: metricsRepository,
      composer: MonetizedMetricsComposer(
        exchangeRateRepository: _NoopExchangeRateRepository(),
      ),
    );

    final cubit = MetricsCubit(metricsService: service);
    addTearDown(cubit.close);

    await cubit.load(from: from, to: to);

    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.hasData, isFalse);
    expect(cubit.state.hasError, isTrue);
    expect(cubit.state.error, isA<StateError>());
  });
}

class _NoopExchangeRateRepository implements ExchangeRateRepository {
  @override
  Future<List<ExchangeRate>> readExchangeRatesForDate(DateTime date) async {
    return const <ExchangeRate>[];
  }

  @override
  Future<void> writeExchangeRates(
    Iterable<ExchangeRate> rates, {
    DateTime? effectiveDate,
  }) async {}
}
