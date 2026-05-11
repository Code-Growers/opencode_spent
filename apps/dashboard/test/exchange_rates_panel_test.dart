import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openspent_core/openspent_core.dart';
import 'package:openspent_dashboard/l10n/app_localizations.dart';
import 'package:openspent_dashboard/src/exchange_rates/exchange_rates_panel.dart';
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
  Future<void> writeExchangeRates(Iterable<ExchangeRate> rates) async {
    for (final rate in rates) {
      final key = _normalize(rate.date);
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

ExchangeRate _usdRate(DateTime date, double value) =>
    ExchangeRate(currency: SupportedCurrency.usd, date: date, rateToCzk: value);

ExchangeRatesCubitDependencies _buildDependencies({
  required _FakeMetricsRepository metricsRepository,
  required _FakeExchangeRateRepository localRepository,
}) {
  return ExchangeRatesCubitDependencies(
    metricsRepository: metricsRepository,
    settingsRepository: _FakeSettingsRepository(
      OpenCodeSettings(
        selectedCurrency: SupportedCurrency.usd,
        openCodeServerUrl: Uri.parse('http://localhost:4096'),
      ),
    ),
    localExchangeRateRepository: localRepository,
    syncService: ExchangeRateSyncService(
      remoteRepository: localRepository,
      localRepository: localRepository,
    ),
  );
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  required ExchangeRatesCubit cubit,
  VoidCallback? onRatesSynced,
  ValueChanged<SupportedCurrency>? onCurrencyChanged,
  String windowLabel = 'ALL',
  DateTime? from,
  DateTime? to,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider<ExchangeRatesCubit>.value(
          value: cubit,
          child: ExchangeRatesPanel(
            onRatesSynced: onRatesSynced ?? () {},
            windowLabel: windowLabel,
            from: from,
            to: to,
            onCurrencyChanged: onCurrencyChanged ?? (_) {},
          ),
        ),
      ),
    ),
  );

  await tester.binding.setLocale('en', 'US');
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders terminal-style exchange-rate summary with stable keys', (
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
    final cubit = ExchangeRatesCubit(
      dependencies: _buildDependencies(
        metricsRepository: metricsRepository,
        localRepository: localRepository,
      ),
    );
    addTearDown(cubit.close);
    await cubit.load();

    await _pumpPanel(tester, cubit: cubit);

    expect(find.byKey(const Key('exchange-rates-panel')), findsOneWidget);
    expect(find.byKey(const Key('exchange-rates-summary')), findsOneWidget);
    expect(
      find.byKey(const Key('exchange-rates-coverage-line')),
      findsOneWidget,
    );
    expect(find.text('> Coverage .......... 0/1'), findsOneWidget);
  });

  testWidgets('currency action notifies parent on success', (
    WidgetTester tester,
  ) async {
    SupportedCurrency? changedCurrency;
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
    final cubit = ExchangeRatesCubit(
      dependencies: _buildDependencies(
        metricsRepository: metricsRepository,
        localRepository: localRepository,
      ),
    );
    addTearDown(cubit.close);
    await cubit.load();

    await _pumpPanel(
      tester,
      cubit: cubit,
      onCurrencyChanged: (currency) {
        changedCurrency = currency;
      },
    );

    await tester.tap(find.byKey(const Key('exchange-rates-currency-czk')));
    await tester.pumpAndSettle();

    expect(changedCurrency, SupportedCurrency.czk);
    expect(find.text('> Display currency set to CZK.'), findsOneWidget);
  });

  testWidgets('external refresh clears stale local status message', (
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
    final cubit = ExchangeRatesCubit(
      dependencies: _buildDependencies(
        metricsRepository: metricsRepository,
        localRepository: localRepository,
      ),
    );
    addTearDown(cubit.close);
    await cubit.load();

    await _pumpPanel(tester, cubit: cubit);

    await tester.tap(find.byKey(const Key('exchange-rates-currency-czk')));
    await tester.pumpAndSettle();
    expect(find.text('> Display currency set to CZK.'), findsOneWidget);

    await cubit.load();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('exchange-rates-status-message')),
      findsNothing,
    );
  });

  testWidgets(
    'window change updates label while preserving current cubit data',
    (WidgetTester tester) async {
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
      final cubit = ExchangeRatesCubit(
        dependencies: _buildDependencies(
          metricsRepository: metricsRepository,
          localRepository: localRepository,
        ),
      );
      addTearDown(cubit.close);
      await cubit.load();

      await _pumpPanel(
        tester,
        cubit: cubit,
        windowLabel: 'ALL',
        from: null,
        to: null,
      );

      expect(find.text('> Window ............ ALL'), findsOneWidget);
      expect(find.text('> Coverage .......... 1/2'), findsOneWidget);

      await _pumpPanel(
        tester,
        cubit: cubit,
        windowLabel: '7D',
        from: DateTime.utc(2026, 5, 2),
        to: DateTime.utc(2026, 5, 8),
      );

      expect(find.text('> Window ............ 7D'), findsOneWidget);
      expect(find.text('> Coverage .......... 1/2'), findsOneWidget);
    },
  );
}
