import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openspent_core/openspent_core.dart';
import 'package:openspent_dashboard/l10n/app_localizations.dart';
import 'package:openspent_dashboard/src/screens/exchange_rates/cubit/exchange_rates_cubit.dart';
import 'package:openspent_dashboard/src/screens/exchange_rates/exchange_rates_screen.dart';
import 'package:openspent_dashboard/src/screens/exchange_rates/widgets/exchange_rates_chart_widgets.dart';

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
  _FakeMetricsRepository({required this.allDailyBreakdown});

  final List<DailyMetrics> allDailyBreakdown;

  @override
  Future<AggregatedMetrics> readMetrics({DateTime? from, DateTime? to}) async {
    final filteredDailyBreakdown = allDailyBreakdown.where((daily) {
      if (from != null && daily.date.isBefore(from)) {
        return false;
      }

      if (to != null && daily.date.isAfter(to)) {
        return false;
      }

      return true;
    }).toList();

    var totalSessionCount = 0;
    var totalInputTokens = 0;
    var totalOutputTokens = 0;
    var totalCostUsd = 0.0;
    for (final daily in filteredDailyBreakdown) {
      totalSessionCount += daily.sessionCount;
      totalInputTokens += daily.inputTokens;
      totalOutputTokens += daily.outputTokens;
      totalCostUsd += daily.totalCostUsd;
    }

    return AggregatedMetrics(
      totalSessionCount: totalSessionCount,
      totalInputTokens: totalInputTokens,
      totalOutputTokens: totalOutputTokens,
      totalCostUsd: totalCostUsd,
      dailyBreakdown: filteredDailyBreakdown,
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
  _FakeRemoteExchangeRateRepository(this._responses);

  final Map<DateTime, List<ExchangeRate>> _responses;

  @override
  Future<List<ExchangeRate>> readExchangeRatesForDate(DateTime date) async {
    return List<ExchangeRate>.from(_responses[_normalize(date)] ?? const []);
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

ExchangeRate _usdRate(DateTime date, double value) =>
    ExchangeRate(currency: SupportedCurrency.usd, date: date, rateToCzk: value);

ExchangeRatesCubitDependencies _buildDependencies({
  required _FakeMetricsRepository metricsRepository,
  required _FakeSettingsRepository settingsRepository,
  required _FakeExchangeRateRepository localRepository,
  ExchangeRateRepository? remoteRepository,
}) {
  return ExchangeRatesCubitDependencies(
    metricsRepository: metricsRepository,
    settingsRepository: settingsRepository,
    localExchangeRateRepository: localRepository,
    syncService: ExchangeRateSyncService(
      remoteRepository: remoteRepository ?? localRepository,
      localRepository: localRepository,
    ),
  );
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required ExchangeRatesCubitDependencies dependencies,
  int exchangeRatesRevision = 0,
  ValueChanged<SupportedCurrency>? onCurrencyChanged,
  VoidCallback? onRatesSynced,
  DateTime? from,
  DateTime? to,
  DateTime? visibleFrom,
  DateTime? visibleTo,
  String windowLabel = 'ALL',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ExchangeRatesScreen(
          dependencies: dependencies,
          exchangeRatesRevision: exchangeRatesRevision,
          onCurrencyChanged: onCurrencyChanged ?? (_) {},
          onRatesSynced: onRatesSynced ?? () {},
          from: from,
          to: to,
          visibleFrom: visibleFrom,
          visibleTo: visibleTo,
          windowLabel: windowLabel,
        ),
      ),
    ),
  );

  await tester.binding.setLocale('en', 'US');
  await tester.pumpAndSettle();
}

String _textForKey(WidgetTester tester, Key key) {
  return tester.widget<Text>(find.byKey(key)).data ?? '';
}

void main() {
  testWidgets('screen loads exchange-rates panel from its local cubit', (
    WidgetTester tester,
  ) async {
    final settingsRepository = _FakeSettingsRepository(
      OpenCodeSettings(
        selectedCurrency: SupportedCurrency.usd,
        openCodeServerUrl: Uri.parse('http://localhost:4096'),
      ),
    );
    final metricsRepository = _FakeMetricsRepository(
      allDailyBreakdown: [
        DailyMetrics(
          date: DateTime.utc(2026, 5, 8),
          sessionCount: 1,
          inputTokens: 10,
          outputTokens: 4,
          totalCostUsd: 1,
        ),
      ],
    );
    final localRepository = _FakeExchangeRateRepository();

    await _pumpScreen(
      tester,
      dependencies: _buildDependencies(
        metricsRepository: metricsRepository,
        settingsRepository: settingsRepository,
        localRepository: localRepository,
      ),
    );

    expect(find.byKey(const Key('exchange-rates-panel')), findsOneWidget);
    expect(
      _textForKey(tester, const Key('exchange-rates-display-line')),
      contains('USD'),
    );
    expect(
      _textForKey(tester, const Key('exchange-rates-coverage-line')),
      contains('0/1'),
    );
  });

  testWidgets(
    'screen reloads local cubit data when exchange revision changes',
    (WidgetTester tester) async {
      final settingsRepository = _FakeSettingsRepository(
        OpenCodeSettings(
          selectedCurrency: SupportedCurrency.usd,
          openCodeServerUrl: Uri.parse('http://localhost:4096'),
        ),
      );
      final metricsRepository = _FakeMetricsRepository(
        allDailyBreakdown: [
          DailyMetrics(
            date: DateTime.utc(2026, 5, 1),
            sessionCount: 1,
            inputTokens: 20,
            outputTokens: 10,
            totalCostUsd: 0.5,
          ),
          DailyMetrics(
            date: DateTime.utc(2026, 5, 8),
            sessionCount: 1,
            inputTokens: 10,
            outputTokens: 4,
            totalCostUsd: 1,
          ),
        ],
      );
      final localRepository = _FakeExchangeRateRepository()
        ..seed(DateTime.utc(2026, 5, 8), [
          _usdRate(DateTime.utc(2026, 5, 8), 22),
        ]);
      final dependencies = _buildDependencies(
        metricsRepository: metricsRepository,
        settingsRepository: settingsRepository,
        localRepository: localRepository,
      );

      await _pumpScreen(
        tester,
        dependencies: dependencies,
        exchangeRatesRevision: 0,
        windowLabel: 'ALL',
      );

      expect(
        _textForKey(tester, const Key('exchange-rates-window-line')),
        contains('ALL'),
      );
      expect(
        _textForKey(tester, const Key('exchange-rates-coverage-line')),
        contains('1/2'),
      );

      await _pumpScreen(
        tester,
        dependencies: dependencies,
        exchangeRatesRevision: 1,
        from: DateTime.utc(2026, 5, 2),
        to: DateTime.utc(2026, 5, 8, 23, 59, 59),
        windowLabel: '7D',
      );

      expect(
        _textForKey(tester, const Key('exchange-rates-window-line')),
        contains('7D'),
      );
      expect(
        _textForKey(tester, const Key('exchange-rates-coverage-line')),
        contains('1/1'),
      );
    },
  );

  testWidgets('screen recreates its local cubit when dependencies change', (
    WidgetTester tester,
  ) async {
    final metricsRepository = _FakeMetricsRepository(
      allDailyBreakdown: [
        DailyMetrics(
          date: DateTime.utc(2026, 5, 8),
          sessionCount: 1,
          inputTokens: 10,
          outputTokens: 4,
          totalCostUsd: 1,
        ),
      ],
    );
    final localRepository = _FakeExchangeRateRepository();
    final usdDependencies = _buildDependencies(
      metricsRepository: metricsRepository,
      settingsRepository: _FakeSettingsRepository(
        OpenCodeSettings(
          selectedCurrency: SupportedCurrency.usd,
          openCodeServerUrl: Uri.parse('http://localhost:4096'),
        ),
      ),
      localRepository: localRepository,
    );
    final czkDependencies = _buildDependencies(
      metricsRepository: metricsRepository,
      settingsRepository: _FakeSettingsRepository(
        OpenCodeSettings(
          selectedCurrency: SupportedCurrency.czk,
          openCodeServerUrl: Uri.parse('http://localhost:4096'),
        ),
      ),
      localRepository: localRepository,
    );

    await _pumpScreen(tester, dependencies: usdDependencies);
    expect(
      _textForKey(tester, const Key('exchange-rates-display-line')),
      contains('USD'),
    );

    await _pumpScreen(tester, dependencies: czkDependencies);
    expect(
      _textForKey(tester, const Key('exchange-rates-display-line')),
      contains('CZK'),
    );
  });

  testWidgets('screen preserves currency and sync callbacks', (
    WidgetTester tester,
  ) async {
    SupportedCurrency? changedCurrency;
    var syncCount = 0;
    final settingsRepository = _FakeSettingsRepository(
      OpenCodeSettings(
        selectedCurrency: SupportedCurrency.usd,
        openCodeServerUrl: Uri.parse('http://localhost:4096'),
      ),
    );
    final metricsRepository = _FakeMetricsRepository(
      allDailyBreakdown: [
        DailyMetrics(
          date: DateTime.utc(2026, 5, 8),
          sessionCount: 1,
          inputTokens: 10,
          outputTokens: 4,
          totalCostUsd: 1,
        ),
      ],
    );
    final localRepository = _FakeExchangeRateRepository();
    final remoteRepository = _FakeRemoteExchangeRateRepository({
      DateTime.utc(2026, 5, 8): [
        _usdRate(DateTime.utc(2026, 5, 8), 22),
        ExchangeRate(
          currency: SupportedCurrency.czk,
          date: DateTime.utc(2026, 5, 8),
          rateToCzk: 1,
        ),
      ],
    });

    await _pumpScreen(
      tester,
      dependencies: _buildDependencies(
        metricsRepository: metricsRepository,
        settingsRepository: settingsRepository,
        localRepository: localRepository,
        remoteRepository: remoteRepository,
      ),
      onCurrencyChanged: (currency) {
        changedCurrency = currency;
      },
      onRatesSynced: () {
        syncCount++;
      },
    );

    await tester.tap(find.byKey(const Key('exchange-rates-currency-czk')));
    await tester.pumpAndSettle();

    expect(changedCurrency, SupportedCurrency.czk);
    expect(find.text('> Display currency set to CZK.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('exchange-rates-sync-button')));
    await tester.pumpAndSettle();

    expect(syncCount, 1);
    expect(
      _textForKey(tester, const Key('exchange-rates-coverage-line')),
      contains('1/1'),
    );
    expect(find.textContaining('> Synced missing rates for'), findsOneWidget);
  });

  testWidgets('screen reloads local cubit data when visible bounds change', (
    WidgetTester tester,
  ) async {
    final settingsRepository = _FakeSettingsRepository(
      OpenCodeSettings(
        selectedCurrency: SupportedCurrency.usd,
        openCodeServerUrl: Uri.parse('http://localhost:4096'),
      ),
    );
    final metricsRepository = _FakeMetricsRepository(
      allDailyBreakdown: [
        DailyMetrics(
          date: DateTime.utc(2026, 5, 8),
          sessionCount: 1,
          inputTokens: 10,
          outputTokens: 4,
          totalCostUsd: 1,
        ),
      ],
    );
    final localRepository = _FakeExchangeRateRepository()
      ..seed(DateTime.utc(2026, 5, 8), [
        _usdRate(DateTime.utc(2026, 5, 8), 22),
      ]);
    final dependencies = _buildDependencies(
      metricsRepository: metricsRepository,
      settingsRepository: settingsRepository,
      localRepository: localRepository,
    );

    await _pumpScreen(
      tester,
      dependencies: dependencies,
      exchangeRatesRevision: 0,
      visibleFrom: DateTime.utc(2026, 5, 8),
      visibleTo: DateTime.utc(2026, 5, 8),
    );

    final chartFinder = find.byType(ExchangeRatesHistoryChart);
    expect(chartFinder, findsOneWidget);

    await _pumpScreen(
      tester,
      dependencies: dependencies,
      exchangeRatesRevision: 0,
      visibleFrom: DateTime.utc(2026, 5, 7),
      visibleTo: DateTime.utc(2026, 5, 8),
    );
    await tester.pumpAndSettle();

    final chart = tester.widget<ExchangeRatesHistoryChart>(chartFinder);
    expect(chart.visibleDays.length, 2);
    expect(chart.visibleDays.first, DateTime.utc(2026, 5, 7));

    // Assert the new title logic and that USD doesn't suppress chart text
    expect(find.text('Exchange Rate History (USD → CZK)'), findsOneWidget);
  });
}
