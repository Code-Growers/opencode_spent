import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openspent_core/openspent_core.dart';
import 'package:openspent_dashboard/src/app/open_spent_app.dart';
import 'package:openspent_dashboard/src/screens/dashboard/dashboard_shell_screen.dart';
import 'package:openspent_dashboard/src/theme/dashboard_colors.dart';
import 'package:openspent_dashboard/src/screens/exchange_rates/cubit/exchange_rates_cubit.dart';
import 'package:openspent_dashboard/src/screens/sessions/cubit/sessions_cubit.dart';
import 'package:openspent_dashboard/src/sessions/import_selection.dart';
import 'package:openspent_local/openspent_local.dart';

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository([this._settings]);

  OpenCodeSettings? _settings;

  @override
  Future<OpenCodeSettings?> readSettings() async => _settings;

  @override
  Future<void> writeSettings(OpenCodeSettings settings) async {
    _settings = settings;
  }
}

class _InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> readString(String key) async => values[key];

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  Future<void> writeString(String key, String value) async {
    values[key] = value;
  }
}

class _FakeMetricsRepository implements MetricsRepository {
  Future<AggregatedMetrics> Function({DateTime? from, DateTime? to})?
  readMetricsOverride;

  List<HourlyMetrics> _buildAllHourly(DateTime today) {
    return [
      HourlyMetrics(
        hour: today
            .subtract(const Duration(days: 1))
            .add(const Duration(hours: 10)),
        sessionCount: 0,
        inputTokens: 0,
        outputTokens: 0,
        totalCostUsd: 0.05,
      ),
      HourlyMetrics(
        hour: today.add(const Duration(hours: 9)),
        sessionCount: 1,
        inputTokens: 40,
        outputTokens: 14,
        totalCostUsd: 0.15,
      ),
      HourlyMetrics(
        hour: today.add(const Duration(hours: 14)),
        sessionCount: 0,
        inputTokens: 20,
        outputTokens: 10,
        totalCostUsd: 0.05,
      ),
    ];
  }

  Map<String, List<HourlyMetrics>> _buildAllPerModelHourly(DateTime today) {
    return {
      'gpt-5.4': [
        HourlyMetrics(
          hour: today.add(const Duration(hours: 9)),
          sessionCount: 1,
          inputTokens: 40,
          outputTokens: 14,
          totalCostUsd: 0.15,
        ),
      ],
      'o4-mini': [
        HourlyMetrics(
          hour: today.add(const Duration(hours: 14)),
          sessionCount: 0,
          inputTokens: 20,
          outputTokens: 10,
          totalCostUsd: 0.05,
        ),
      ],
    };
  }

  Map<String, List<DailyMetrics>> _buildAllPerModel(DateTime today) {
    return {
      'gpt-5.4': [
        DailyMetrics(
          date: today.subtract(const Duration(days: 6)),
          sessionCount: 0,
          inputTokens: 0,
          outputTokens: 0,
          totalCostUsd: 0.10,
        ),
        DailyMetrics(
          date: today.subtract(const Duration(days: 5)),
          sessionCount: 0,
          inputTokens: 0,
          outputTokens: 0,
          totalCostUsd: 0.20,
        ),
        DailyMetrics(
          date: today.subtract(const Duration(days: 4)),
          sessionCount: 0,
          inputTokens: 0,
          outputTokens: 0,
          totalCostUsd: 0.15,
        ),
        DailyMetrics(
          date: today.subtract(const Duration(days: 3)),
          sessionCount: 0,
          inputTokens: 0,
          outputTokens: 0,
          totalCostUsd: 0.30,
        ),
        DailyMetrics(
          date: today.subtract(const Duration(days: 2)),
          sessionCount: 1,
          inputTokens: 60,
          outputTokens: 24,
          totalCostUsd: 0.15,
        ),
      ],
      'o4-mini': [
        DailyMetrics(
          date: today.subtract(const Duration(days: 2)),
          sessionCount: 0,
          inputTokens: 0,
          outputTokens: 0,
          totalCostUsd: 0.10,
        ),
        DailyMetrics(
          date: today.subtract(const Duration(days: 1)),
          sessionCount: 0,
          inputTokens: 0,
          outputTokens: 0,
          totalCostUsd: 0.05,
        ),
        DailyMetrics(
          date: today,
          sessionCount: 1,
          inputTokens: 60,
          outputTokens: 24,
          totalCostUsd: 0.20,
        ),
      ],
    };
  }

  List<T> _filterByDateRange<T>(
    List<T> values,
    DateTime Function(T value) getDate, {
    DateTime? from,
    DateTime? to,
  }) {
    return values.where((value) {
      final date = getDate(value);
      if (from != null && date.isBefore(from)) {
        return false;
      }
      if (to != null && date.isAfter(to)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<AggregatedMetrics> readMetrics({DateTime? from, DateTime? to}) async {
    if (readMetricsOverride != null) {
      return readMetricsOverride!(from: from, to: to);
    }
    final today = DateTime.utc(2026, 5, 8);
    final allDaily = [
      DailyMetrics(
        date: today.subtract(const Duration(days: 6)),
        sessionCount: 0,
        inputTokens: 0,
        outputTokens: 0,
        totalCostUsd: 0.10,
      ),
      DailyMetrics(
        date: today.subtract(const Duration(days: 5)),
        sessionCount: 0,
        inputTokens: 0,
        outputTokens: 0,
        totalCostUsd: 0.20,
      ),
      DailyMetrics(
        date: today.subtract(const Duration(days: 4)),
        sessionCount: 0,
        inputTokens: 0,
        outputTokens: 0,
        totalCostUsd: 0.15,
      ),
      DailyMetrics(
        date: today.subtract(const Duration(days: 3)),
        sessionCount: 0,
        inputTokens: 0,
        outputTokens: 0,
        totalCostUsd: 0.30,
      ),
      DailyMetrics(
        date: today.subtract(const Duration(days: 2)),
        sessionCount: 1,
        inputTokens: 60,
        outputTokens: 24,
        totalCostUsd: 0.25,
      ),
      DailyMetrics(
        date: today.subtract(const Duration(days: 1)),
        sessionCount: 0,
        inputTokens: 0,
        outputTokens: 0,
        totalCostUsd: 0.05,
      ),
      DailyMetrics(
        date: today,
        sessionCount: 1,
        inputTokens: 60,
        outputTokens: 24,
        totalCostUsd: 0.20,
      ),
    ];

    final filteredDaily = _filterByDateRange(
      allDaily,
      (daily) => daily.date,
      from: from,
      to: to,
    );
    final filteredHourly = _filterByDateRange(
      _buildAllHourly(today),
      (hourly) => hourly.hour,
      from: from,
      to: to,
    );
    final filteredPerModel = <String, List<DailyMetrics>>{};
    for (final entry in _buildAllPerModel(today).entries) {
      final scopedDaily = _filterByDateRange(
        entry.value,
        (daily) => daily.date,
        from: from,
        to: to,
      );
      if (scopedDaily.isNotEmpty) {
        filteredPerModel[entry.key] = scopedDaily;
      }
    }

    var totalSessionCount = 0;
    var totalInputTokens = 0;
    var totalOutputTokens = 0;
    double totalCost = 0.0;
    for (final d in filteredDaily) {
      totalSessionCount += d.sessionCount;
      totalInputTokens += d.inputTokens;
      totalOutputTokens += d.outputTokens;
      totalCost += d.totalCostUsd;
    }

    final filteredPerModelHourly = <String, List<HourlyMetrics>>{};
    for (final entry in _buildAllPerModelHourly(today).entries) {
      final scopedHourly = _filterByDateRange(
        entry.value,
        (hourly) => hourly.hour,
        from: from,
        to: to,
      );
      if (scopedHourly.isNotEmpty) {
        filteredPerModelHourly[entry.key] = scopedHourly;
      }
    }

    return AggregatedMetrics(
      totalCostUsd: totalCost,
      totalSessionCount: totalSessionCount,
      totalInputTokens: totalInputTokens,
      totalOutputTokens: totalOutputTokens,
      dailyBreakdown: filteredDaily,
      hourlyBreakdown: filteredHourly,
      perModelDailyBreakdown: filteredPerModel,
      perModelHourlyBreakdown: filteredPerModelHourly,
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
      final next = List<ExchangeRate>.from(_ratesByDate[key] ?? const []);
      next.removeWhere((entry) => entry.currency == rate.currency);
      next.add(rate);
      _ratesByDate[key] = next;
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
    final utc = date.toUtc();
    final normalized = DateTime.utc(utc.year, utc.month, utc.day);
    return List<ExchangeRate>.from(_responses[normalized] ?? const []);
  }

  @override
  Future<void> writeExchangeRates(Iterable<ExchangeRate> rates) async {}
}

class _FakeSessionRepository implements OpenCodeSessionRepository {
  _FakeSessionRepository([List<OpenCodeSession>? sessions])
    : _sessions = sessions ?? <OpenCodeSession>[];

  final List<OpenCodeSession> _sessions;

  @override
  Future<List<OpenCodeSession>> readSessions() async {
    return List<OpenCodeSession>.from(_sessions);
  }

  @override
  Future<void> writeSessions(Iterable<OpenCodeSession> sessions) async {
    _sessions
      ..clear()
      ..addAll(sessions);
  }
}

class _ThrowingSessionRepository implements OpenCodeSessionRepository {
  _ThrowingSessionRepository(this._error);

  final Object _error;

  @override
  Future<List<OpenCodeSession>> readSessions() async {
    throw _error;
  }

  @override
  Future<void> writeSessions(Iterable<OpenCodeSession> sessions) async {
    throw _error;
  }
}

class _CountingSessionRepository implements OpenCodeSessionRepository {
  _CountingSessionRepository({List<OpenCodeSession>? initialSessions})
    : _sessions = List<OpenCodeSession>.from(initialSessions ?? const []);

  final List<OpenCodeSession> _sessions;
  int readCount = 0;
  int writeCount = 0;

  @override
  Future<List<OpenCodeSession>> readSessions() async {
    readCount++;
    return List<OpenCodeSession>.from(_sessions);
  }

  @override
  Future<void> writeSessions(Iterable<OpenCodeSession> sessions) async {
    writeCount++;
    _sessions
      ..clear()
      ..addAll(sessions);
  }
}

Future<void> _pumpEnglishDashboard(
  WidgetTester tester, {
  MonetizedMetricsService? metricsService,
  SettingsRepository? settingsRepository,
  bool omitSettingsRepository = false,
  ExchangeRatesCubitDependencies? exchangeRatesDependencies,
  Future<ServerProbeState> Function(OpenCodeSettings settings)? serverProbe,
  SessionsCubitDependencies? sessionsDependencies,
  Future<ImportSelection?> Function()? pickImportSource,
}) async {
  final repository = settingsRepository ?? _FakeSettingsRepository();
  final service =
      metricsService ??
      MonetizedMetricsService(
        settingsRepository: repository,
        metricsRepository: _FakeMetricsRepository(),
        composer: MonetizedMetricsComposer(
          exchangeRateRepository: _FakeExchangeRateRepository(),
        ),
      );

  tester.view.physicalSize = const Size(1440, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    OpenSpentApp(
      metricsService: service,
      key: UniqueKey(),
      settingsRepository: omitSettingsRepository ? null : repository,
      exchangeRatesDependencies: exchangeRatesDependencies,
      serverProbe: serverProbe,
      sessionsDependencies: sessionsDependencies,
      pickImportSource: pickImportSource,
    ),
  );

  await tester.binding.setLocale('en', 'US');
}

Future<void> _pumpDashboardWithLocale(
  WidgetTester tester, {
  required String languageCode,
  String countryCode = 'US',
  MonetizedMetricsService? metricsService,
  SettingsRepository? settingsRepository,
  bool omitSettingsRepository = false,
  ExchangeRatesCubitDependencies? exchangeRatesDependencies,
  Future<ServerProbeState> Function(OpenCodeSettings settings)? serverProbe,
  SessionsCubitDependencies? sessionsDependencies,
  Future<ImportSelection?> Function()? pickImportSource,
}) async {
  final repository = settingsRepository ?? _FakeSettingsRepository();
  final service =
      metricsService ??
      MonetizedMetricsService(
        settingsRepository: repository,
        metricsRepository: _FakeMetricsRepository(),
        composer: MonetizedMetricsComposer(
          exchangeRateRepository: _FakeExchangeRateRepository(),
        ),
      );

  tester.view.physicalSize = const Size(1440, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    OpenSpentApp(
      metricsService: service,
      key: UniqueKey(),
      settingsRepository: omitSettingsRepository ? null : repository,
      exchangeRatesDependencies: exchangeRatesDependencies,
      serverProbe: serverProbe,
      sessionsDependencies: sessionsDependencies,
      pickImportSource: pickImportSource,
    ),
  );

  await tester.binding.setLocale(languageCode, countryCode);
}

Future<void> _openDashboardSection(WidgetTester tester, String keyValue) async {
  final navLink = find.byKey(Key(keyValue));
  await tester.ensureVisible(navLink);
  await tester.tap(navLink);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Dashboard shell smoke test', (WidgetTester tester) async {
    await _pumpEnglishDashboard(
      tester,
      serverProbe: (_) async => ServerProbeState.connected,
    );

    await tester.pumpAndSettle();

    expect(find.text('_ awaiting first metrics payload ...'), findsNothing);
    expect(find.text('METRICS'), findsOneWidget);

    await _openDashboardSection(tester, 'dashboard-nav-state');
    expect(find.text('> Mode .............. LOCAL CACHE'), findsOneWidget);
    expect(find.text('> Dashboard .......... READY'), findsOneWidget);
    expect(
      find.text('> Server ............ http://localhost:4096'),
      findsOneWidget,
    );
    expect(find.text('> Probe ............. CONNECTED'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.text('> Probe ............. CONNECTED'))
          .style
          ?.color,
      dashboardStatusColor,
    );

    await _openDashboardSection(tester, 'dashboard-nav-metrics');
    expect(find.text('-- OVERALL --'), findsOneWidget);
    expect(find.text('> Total cost ......... USD 1.25'), findsOneWidget);
    expect(find.text('> Sessions ........... 2'), findsOneWidget);
    expect(find.text('> Total tokens ....... 168'), findsOneWidget);
    expect(find.text('> Avg/session ........ 84.0'), findsOneWidget);
    expect(find.text('> Cost/1M tokens ..... USD 7440.48'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('metrics-tab-spend')));
    await tester.tap(find.byKey(const Key('metrics-tab-spend')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('metrics-spend-daily-chart')), findsOneWidget);
    expect(find.byKey(const Key('metrics-spend-hourly-chart')), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('metrics-tab-tokens')).first,
    );
    await tester.ensureVisible(
      find.byKey(const Key('metrics-tab-tokens')).first,
    );
    await tester.tap(find.byKey(const Key('metrics-tab-tokens')).first);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('metrics-tokens-daily-chart')), findsOneWidget);
    expect(
      find.byKey(const Key('metrics-tokens-hourly-chart')),
      findsOneWidget,
    );

    await tester.ensureVisible(find.byKey(const Key('metrics-tab-models')));
    await tester.ensureVisible(find.byKey(const Key('metrics-tab-models')));
    await tester.tap(find.byKey(const Key('metrics-tab-models')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('metrics-spend-daily-chart')), findsNothing);
    expect(find.text('USD --/1M TOK'), findsNothing);
  });

  testWidgets(
    'Dashboard shell initializes with default settings when repository is omitted',
    (WidgetTester tester) async {
      await _pumpEnglishDashboard(
        tester,
        omitSettingsRepository: true,
        serverProbe: (_) async => ServerProbeState.connected,
      );

      await tester.pumpAndSettle();

      await _openDashboardSection(tester, 'dashboard-nav-state');
      expect(find.text('> Dashboard .......... READY'), findsOneWidget);
      expect(
        find.text('> Server ............ http://localhost:4096'),
        findsOneWidget,
      );
      expect(find.text('> Probe ............. CONNECTED'), findsOneWidget);
      expect(find.text('[ SETTINGS ]'), findsNothing);
    },
  );

  testWidgets('settings surface allows updating server URL', (
    WidgetTester tester,
  ) async {
    final settingsRepo = _FakeSettingsRepository();
    final service = MonetizedMetricsService(
      settingsRepository: settingsRepo,
      metricsRepository: _EmptyMetricsRepository(),
      composer: MonetizedMetricsComposer(
        exchangeRateRepository: _UnusedExchangeRateRepository(),
      ),
    );

    await _pumpEnglishDashboard(
      tester,
      metricsService: service,
      settingsRepository: settingsRepo,
      serverProbe: (settings) async {
        return settings.openCodeServerUrl.host == 'localhost'
            ? ServerProbeState.connected
            : ServerProbeState.error;
      },
    );
    await tester.pumpAndSettle();

    await _openDashboardSection(tester, 'dashboard-nav-state');
    expect(
      find.text('> Server ............ http://localhost:4096'),
      findsOneWidget,
    );
    expect(find.text('> Probe ............. CONNECTED'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-open-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings-modal-overlay')), findsOneWidget);
    expect(find.byKey(const Key('settings-server-url-field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('settings-server-url-field')),
      'http://localhost:3000',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-save-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings-dialog')), findsNothing);
    expect(
      find.text('> Server ............ http://localhost:3000'),
      findsOneWidget,
    );
    expect(find.text('> Probe ............. CONNECTED'), findsOneWidget);
  });

  testWidgets('app boot honors persisted Czech locale', (
    WidgetTester tester,
  ) async {
    final settingsRepo = _FakeSettingsRepository(
      OpenCodeSettings(
        selectedCurrency: SupportedCurrency.usd,
        openCodeServerUrl: Uri.parse('http://localhost:4096'),
        languageCode: 'cs',
      ),
    );

    await _pumpDashboardWithLocale(
      tester,
      languageCode: 'en',
      settingsRepository: settingsRepo,
      serverProbe: (_) async => ServerProbeState.connected,
    );
    await tester.pumpAndSettle();

    expect(find.text('METRIKY'), findsOneWidget);
    await _openDashboardSection(tester, 'dashboard-nav-state');
    expect(find.text('> Sonda ............. PŘIPOJENO'), findsOneWidget);
    expect(find.text('[ NASTAVENÍ ]'), findsNothing);
  });

  testWidgets('null language code preserves current system-locale behavior', (
    WidgetTester tester,
  ) async {
    final settingsRepo = _FakeSettingsRepository(
      OpenCodeSettings(
        selectedCurrency: SupportedCurrency.usd,
        openCodeServerUrl: Uri.parse('http://localhost:4096'),
        languageCode: null,
      ),
    );

    await _pumpDashboardWithLocale(
      tester,
      languageCode: 'cs',
      countryCode: 'CZ',
      settingsRepository: settingsRepo,
      serverProbe: (_) async => ServerProbeState.connected,
    );
    await tester.pumpAndSettle();

    expect(find.text('METRIKY'), findsOneWidget);
    await _openDashboardSection(tester, 'dashboard-nav-state');
    expect(find.text('> Sonda ............. PŘIPOJENO'), findsOneWidget);
  });

  testWidgets('settings save persists language choice', (
    WidgetTester tester,
  ) async {
    final settingsRepo = _FakeSettingsRepository(
      OpenCodeSettings(
        selectedCurrency: SupportedCurrency.usd,
        openCodeServerUrl: Uri.parse('http://localhost:4096'),
      ),
    );

    await _pumpEnglishDashboard(
      tester,
      settingsRepository: settingsRepo,
      serverProbe: (_) async => ServerProbeState.connected,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-open-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-language-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Czech').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-save-button')));
    await tester.pumpAndSettle();

    expect((await settingsRepo.readSettings())!.languageCode, 'cs');
    expect(find.text('METRIKY'), findsOneWidget);
    await _openDashboardSection(tester, 'dashboard-nav-state');
    expect(find.text('> Sonda ............. PŘIPOJENO'), findsOneWidget);
  });

  testWidgets('manual import shows source-aware summary and refreshes metrics', (
    WidgetTester tester,
  ) async {
    final settingsRepo = _FakeSettingsRepository(
      OpenCodeSettings(
        openCodeServerUrl: Uri.parse('http://localhost:4096'),
        selectedCurrency: SupportedCurrency.usd,
      ),
    );

    final localRepo = _CountingSessionRepository();
    final sessionsDependencies = SessionsCubitDependencies(
      localRepository: localRepo,
      jsonParser: const OpenCodeSessionJsonParser(),
      remoteRepositoryFactory: (_) => _FakeSessionRepository(),
    );
    final metricsService = MonetizedMetricsService(
      settingsRepository: settingsRepo,
      metricsRepository: LocalMetricsRepository(localRepo),
      composer: MonetizedMetricsComposer(
        exchangeRateRepository: _UnusedExchangeRateRepository(),
      ),
    );

    await _pumpEnglishDashboard(
      tester,
      metricsService: metricsService,
      settingsRepository: settingsRepo,
      serverProbe: (_) async => ServerProbeState.disconnected,
      sessionsDependencies: sessionsDependencies,
      pickImportSource: () async => ImportSelection.json(
        '[{"id":"ses_imported_manual","createdAt":"2026-05-08T12:00:00Z","modelName":"imported-model","inputTokens":10,"outputTokens":5,"totalCostUsd":0.05}]',
        sourceLabel: 'history.json',
      ),
    );
    await tester.pumpAndSettle();

    await _openDashboardSection(tester, 'dashboard-nav-sessions');

    expect(find.byKey(const Key('sessions-panel')), findsOneWidget);
    expect(find.text('> Cache is empty'), findsOneWidget);
    expect(find.text('> Type .............. LOAD'), findsOneWidget);
    expect(find.text('> Source ............ history.json'), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('sessions-import-button')));
    await tester.tap(find.byKey(const Key('sessions-import-button')));
    await tester.pumpAndSettle();

    expect(find.text('> Import completed successfully.'), findsOneWidget);
    expect(find.text('> Status ............ SUCCESS'), findsOneWidget);
    expect(find.text('> Source ............ history.json'), findsOneWidget);
    expect(find.text('> Cached ............ 1'), findsOneWidget);
    expect(find.textContaining('imported-model • 15 TOK'), findsWidgets);
    expect(find.text('> Sessions .......... 1'), findsOneWidget);
    expect(find.textContaining('USD 0.05'), findsWidgets);

    await _openDashboardSection(tester, 'dashboard-nav-metrics');
    expect(find.textContaining('USD 0.05'), findsWidgets);
  });

  testWidgets('settings surface rejects invalid server URL input', (
    WidgetTester tester,
  ) async {
    final settingsRepo = _FakeSettingsRepository();

    await _pumpEnglishDashboard(
      tester,
      settingsRepository: settingsRepo,
      serverProbe: (_) async => ServerProbeState.connected,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-open-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings-modal-overlay')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('settings-server-url-field')),
      'localhost:3000',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-save-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Enter a valid http:// or https:// server URL.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('settings-dialog')), findsOneWidget);
  });

  testWidgets('default localhost offline state is reported as disconnected', (
    WidgetTester tester,
  ) async {
    final settingsRepo = _FakeSettingsRepository();

    await _pumpEnglishDashboard(
      tester,
      settingsRepository: settingsRepo,
      serverProbe: (_) async => ServerProbeState.disconnected,
    );
    await tester.pumpAndSettle();

    await _openDashboardSection(tester, 'dashboard-nav-state');
    expect(
      find.text('> Server ............ http://localhost:4096'),
      findsOneWidget,
    );
    expect(find.text('> Probe ............. DISCONNECTED'), findsOneWidget);
  });

  testWidgets('chart modes show fallback when daily breakdown is empty', (
    WidgetTester tester,
  ) async {
    final service = MonetizedMetricsService(
      settingsRepository: _FakeSettingsRepository(),
      metricsRepository: _EmptyMetricsRepository(),
      composer: MonetizedMetricsComposer(
        exchangeRateRepository: _UnusedExchangeRateRepository(),
      ),
    );

    await _pumpEnglishDashboard(
      tester,
      metricsService: service,
      serverProbe: (_) async => ServerProbeState.unknown,
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('metrics-tab-spend')));
    await tester.tap(find.byKey(const Key('metrics-tab-spend')));
    await tester.pumpAndSettle();
    expect(find.text('> spend trend unavailable'), findsOneWidget);
    expect(find.byType(BarChart), findsNothing);

    await tester.ensureVisible(
      find.byKey(const Key('metrics-tab-tokens')).first,
    );
    await tester.ensureVisible(
      find.byKey(const Key('metrics-tab-tokens')).first,
    );
    await tester.tap(find.byKey(const Key('metrics-tab-tokens')).first);
    await tester.pumpAndSettle();
    expect(find.text('> token trend unavailable'), findsOneWidget);
    expect(find.byType(BarChart), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('metrics-tab-models')));
    await tester.ensureVisible(find.byKey(const Key('metrics-tab-models')));
    await tester.tap(find.byKey(const Key('metrics-tab-models')));
    await tester.pumpAndSettle();
    expect(find.text('> model spend unavailable'), findsOneWidget);
    expect(find.byType(BarChart), findsNothing);
  });

  testWidgets('chart modes show zero-token fallback for model efficiency', (
    WidgetTester tester,
  ) async {
    final service = MonetizedMetricsService(
      settingsRepository: _FakeSettingsRepository(),
      metricsRepository: _ZeroTokenMetricsRepository(),
      composer: MonetizedMetricsComposer(
        exchangeRateRepository: _UnusedExchangeRateRepository(),
      ),
    );

    await _pumpEnglishDashboard(
      tester,
      metricsService: service,
      serverProbe: (_) async => ServerProbeState.unknown,
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('metrics-tab-models')));
    await tester.ensureVisible(find.byKey(const Key('metrics-tab-models')));
    await tester.tap(find.byKey(const Key('metrics-tab-models')));
    await tester.pumpAndSettle();

    expect(find.text('USD --/1M TOK'), findsWidgets);
  });

  testWidgets('dashboard supports inline CZK flow with exchange-rate sync', (
    WidgetTester tester,
  ) async {
    final settingsRepo = _FakeSettingsRepository(
      OpenCodeSettings(
        selectedCurrency: SupportedCurrency.usd,
        openCodeServerUrl: Uri.parse('http://localhost:4096'),
      ),
    );
    final metricsRepository = _FakeMetricsRepository();
    final localRates = _FakeExchangeRateRepository();
    final remoteRates = _FakeRemoteExchangeRateRepository({
      DateTime.utc(2026, 5, 2): [
        ExchangeRate(
          currency: SupportedCurrency.usd,
          date: DateTime.utc(2026, 5, 2),
          rateToCzk: 22.0,
        ),
        ExchangeRate(
          currency: SupportedCurrency.czk,
          date: DateTime.utc(2026, 5, 2),
          rateToCzk: 1,
        ),
      ],
      DateTime.utc(2026, 5, 3): [
        ExchangeRate(
          currency: SupportedCurrency.usd,
          date: DateTime.utc(2026, 5, 3),
          rateToCzk: 22.0,
        ),
        ExchangeRate(
          currency: SupportedCurrency.czk,
          date: DateTime.utc(2026, 5, 3),
          rateToCzk: 1,
        ),
      ],
      DateTime.utc(2026, 5, 4): [
        ExchangeRate(
          currency: SupportedCurrency.usd,
          date: DateTime.utc(2026, 5, 4),
          rateToCzk: 22.0,
        ),
        ExchangeRate(
          currency: SupportedCurrency.czk,
          date: DateTime.utc(2026, 5, 4),
          rateToCzk: 1,
        ),
      ],
      DateTime.utc(2026, 5, 5): [
        ExchangeRate(
          currency: SupportedCurrency.usd,
          date: DateTime.utc(2026, 5, 5),
          rateToCzk: 22.0,
        ),
        ExchangeRate(
          currency: SupportedCurrency.czk,
          date: DateTime.utc(2026, 5, 5),
          rateToCzk: 1,
        ),
      ],
      DateTime.utc(2026, 5, 6): [
        ExchangeRate(
          currency: SupportedCurrency.usd,
          date: DateTime.utc(2026, 5, 6),
          rateToCzk: 22.0,
        ),
        ExchangeRate(
          currency: SupportedCurrency.czk,
          date: DateTime.utc(2026, 5, 6),
          rateToCzk: 1,
        ),
      ],
      DateTime.utc(2026, 5, 7): [
        ExchangeRate(
          currency: SupportedCurrency.usd,
          date: DateTime.utc(2026, 5, 7),
          rateToCzk: 22.0,
        ),
        ExchangeRate(
          currency: SupportedCurrency.czk,
          date: DateTime.utc(2026, 5, 7),
          rateToCzk: 1,
        ),
      ],
      DateTime.utc(2026, 5, 8): [
        ExchangeRate(
          currency: SupportedCurrency.usd,
          date: DateTime.utc(2026, 5, 8),
          rateToCzk: 23.0,
        ),
        ExchangeRate(
          currency: SupportedCurrency.czk,
          date: DateTime.utc(2026, 5, 8),
          rateToCzk: 1,
        ),
      ],
    });
    final metricsService = MonetizedMetricsService(
      settingsRepository: settingsRepo,
      metricsRepository: metricsRepository,
      composer: MonetizedMetricsComposer(exchangeRateRepository: localRates),
    );
    final exchangeRatesDependencies = ExchangeRatesCubitDependencies(
      metricsRepository: metricsRepository,
      settingsRepository: settingsRepo,
      localExchangeRateRepository: localRates,
      syncService: ExchangeRateSyncService(
        remoteRepository: remoteRates,
        localRepository: localRates,
      ),
    );

    final sessionsDependencies = SessionsCubitDependencies(
      localRepository: _FakeSessionRepository([
        OpenCodeSession(
          id: 'ses_o4_mini',
          createdAt: DateTime.utc(2026, 5, 8),
          modelName: 'o4-mini',
          inputTokens: 100,
          outputTokens: 50,
          totalCostUsd: 0.42,
        ),
      ]),
      jsonParser: const OpenCodeSessionJsonParser(),
      remoteRepositoryFactory: (_) => _FakeSessionRepository(),
    );

    await _pumpEnglishDashboard(
      tester,
      metricsService: metricsService,
      settingsRepository: settingsRepo,
      exchangeRatesDependencies: exchangeRatesDependencies,
      sessionsDependencies: sessionsDependencies,
      pickImportSource: () async => null,
      serverProbe: (_) async => ServerProbeState.connected,
    );
    await tester.pumpAndSettle();

    expect(find.text('> Total cost ......... USD 1.25'), findsOneWidget);

    // Switch to CUSTOM window explicitly
    await tester.ensureVisible(find.byKey(const Key('metrics-window-custom')));
    await tester.tap(find.byKey(const Key('metrics-window-custom')));
    await tester.pumpAndSettle();

    // Tap the edit icon to switch to text input mode by tooltip
    await tester.tap(find.byTooltip('Switch to input'));
    await tester.pumpAndSettle();

    // Input fields depend on locale. Our test uses English, so mm/dd/yyyy is standard.
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.first, '05/06/2026');
    await tester.enterText(textFields.last, '05/08/2026');

    await tester.tap(find.byType(TextButton).last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('metrics-window-line')));

    expect(
      find.text('> Window ............. 2026-05-06 - 2026-05-08'),
      findsOneWidget,
    );
    expect(
      find.text('> Total cost ......... USD 0.50'),
      findsOneWidget,
    ); // 0.25 + 0.05 + 0.20

    await _openDashboardSection(tester, 'dashboard-nav-exchange-rates');
    await tester.ensureVisible(find.byKey(const Key('exchange-rates-panel')));
    await tester.pumpAndSettle();
    expect(find.text('> Coverage .......... 0/6'), findsOneWidget);
    await tester.tap(find.byKey(const Key('exchange-rates-currency-czk')));
    await tester.pumpAndSettle();

    expect(find.text('> Display currency set to CZK.'), findsOneWidget);

    await _openDashboardSection(tester, 'dashboard-nav-metrics');
    expect(
      find.text(
        '> missing CZK exchange rates for spend days. Sync rates in the exchange panel and retry.',
      ),
      findsOneWidget,
    );

    await _openDashboardSection(tester, 'dashboard-nav-exchange-rates');

    await tester.ensureVisible(
      find.byKey(const Key('exchange-rates-sync-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('exchange-rates-sync-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('> Synced missing rates for'), findsOneWidget);
    expect(find.text('> Coverage .......... 6/6'), findsOneWidget);

    await _openDashboardSection(tester, 'dashboard-nav-metrics');
    expect(find.text('> Total cost ......... CZK 11.20'), findsOneWidget);
  });

  testWidgets('dashboard supports model drilldown flow', (
    WidgetTester tester,
  ) async {
    final settingsRepo = _FakeSettingsRepository(
      OpenCodeSettings(
        openCodeServerUrl: Uri.parse('http://localhost:4096'),
        selectedCurrency: SupportedCurrency.usd,
      ),
    );

    final today = DateTime.utc(2026, 5, 8);

    final metricsRepository =
        _ZeroTokenMetricsRepository(); // has 'gpt-5.4' model
    final metricsService = MonetizedMetricsService(
      settingsRepository: settingsRepo,
      metricsRepository: metricsRepository,
      composer: MonetizedMetricsComposer(
        exchangeRateRepository: _UnusedExchangeRateRepository(),
      ),
    );

    final sessionsDependencies = SessionsCubitDependencies(
      localRepository: _FakeSessionRepository([
        OpenCodeSession(
          id: 'ses_gpt_5_4',
          createdAt: today,
          modelName: 'gpt-5.4',
          inputTokens: 100,
          outputTokens: 50,
          totalCostUsd: 0.42,
        ),
        OpenCodeSession(
          id: 'ses_other',
          createdAt: today.subtract(const Duration(hours: 1)),
          modelName: 'other-model',
          inputTokens: 100,
          outputTokens: 50,
          totalCostUsd: 0.10,
        ),
      ]),
      jsonParser: const OpenCodeSessionJsonParser(),
      remoteRepositoryFactory: (_) => _FakeSessionRepository(),
    );

    await _pumpEnglishDashboard(
      tester,
      metricsService: metricsService,
      settingsRepository: settingsRepo,
      serverProbe: (_) async => ServerProbeState.disconnected,
      sessionsDependencies: sessionsDependencies,
      pickImportSource: () async => null,
    );

    await tester.pumpAndSettle();

    // Verify both sessions are visible initially
    await _openDashboardSection(tester, 'dashboard-nav-sessions');
    expect(find.byKey(const Key('sessions-panel')), findsOneWidget);
    expect(find.textContaining('ID: ses_gpt'), findsWidgets);
    expect(find.textContaining('ses_othe'), findsWidgets);

    // Switch to models tab
    await _openDashboardSection(tester, 'dashboard-nav-metrics');
    await tester.ensureVisible(find.byKey(const Key('metrics-tab-models')));
    await tester.tap(find.byKey(const Key('metrics-tab-models')));
    await tester.pumpAndSettle();

    // Tap gpt-5.4 in the chart
    await tester.ensureVisible(find.byKey(const Key('model-filter-gpt-5.4')));
    await tester.tap(find.byKey(const Key('model-filter-gpt-5.4')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('model-filter-gpt-5.4')), findsOneWidget);
    expect(find.textContaining('USD --/1M TOK'), findsWidgets);

    // Verify sessions list is filtered
    await _openDashboardSection(tester, 'dashboard-nav-sessions');
    expect(find.text('> Model filter ...... gpt-5.4'), findsOneWidget);
    expect(find.textContaining('ID: ses_gpt'), findsWidgets);
    expect(find.textContaining('ses_othe'), findsNothing);

    // Tapping selected model card clears the filter directly from Models pane.
    await _openDashboardSection(tester, 'dashboard-nav-metrics');
    await tester.tap(find.byKey(const Key('model-filter-gpt-5.4')));
    await tester.pumpAndSettle();

    expect(find.text('> Model filter ...... gpt-5.4'), findsNothing);
    await _openDashboardSection(tester, 'dashboard-nav-sessions');
    expect(find.textContaining('ID: ses_gpt'), findsWidgets);
    expect(find.textContaining('ses_othe'), findsWidgets);

    // Re-select, then clear from sessions panel.
    await _openDashboardSection(tester, 'dashboard-nav-metrics');
    await tester.tap(find.byKey(const Key('model-filter-gpt-5.4')));
    await tester.pumpAndSettle();

    await _openDashboardSection(tester, 'dashboard-nav-sessions');
    await tester.ensureVisible(find.byKey(const Key('sessions-clear-filter')));
    await tester.tap(find.byKey(const Key('sessions-clear-filter')));
    await tester.pumpAndSettle();

    // Verify both sessions are visible again
    expect(find.text('> Model filter ...... gpt-5.4'), findsNothing);
    expect(find.textContaining('ses_gpt_'), findsWidgets);
    expect(find.textContaining('ses_othe'), findsWidgets);
  });

  testWidgets('metrics day selection filters sessions evidence pane', (
    WidgetTester tester,
  ) async {
    final settingsRepo = _FakeSettingsRepository(
      OpenCodeSettings(
        openCodeServerUrl: Uri.parse('http://localhost:4096'),
        selectedCurrency: SupportedCurrency.usd,
      ),
    );

    final metricsService = MonetizedMetricsService(
      settingsRepository: settingsRepo,
      metricsRepository: _FakeMetricsRepository(),
      composer: MonetizedMetricsComposer(
        exchangeRateRepository: _UnusedExchangeRateRepository(),
      ),
    );

    final sessionsDependencies = SessionsCubitDependencies(
      localRepository: _FakeSessionRepository([
        OpenCodeSession(
          id: 'ses_m08_a',
          createdAt: DateTime.utc(2026, 5, 8, 12),
          modelName: 'o4-mini',
          inputTokens: 10,
          outputTokens: 5,
          totalCostUsd: 0.05,
        ),
        OpenCodeSession(
          id: 'ses_m06_b',
          createdAt: DateTime.utc(2026, 5, 6, 9),
          modelName: 'gpt-5.4',
          inputTokens: 20,
          outputTokens: 10,
          totalCostUsd: 0.15,
        ),
      ]),
      jsonParser: const OpenCodeSessionJsonParser(),
      remoteRepositoryFactory: (_) => _FakeSessionRepository(),
    );

    await _pumpEnglishDashboard(
      tester,
      metricsService: metricsService,
      settingsRepository: settingsRepo,
      serverProbe: (_) async => ServerProbeState.disconnected,
      sessionsDependencies: sessionsDependencies,
      pickImportSource: () async => null,
    );

    await tester.pumpAndSettle();

    await _openDashboardSection(tester, 'dashboard-nav-sessions');
    expect(find.text('> Day filter ........ 2026-05-08'), findsNothing);
    expect(find.textContaining('ses_m08_'), findsWidgets);
    expect(find.textContaining('ses_m06_'), findsWidgets);

    await _openDashboardSection(tester, 'dashboard-nav-metrics');
    await tester.ensureVisible(
      find.byKey(const Key('metrics-day-picker-button')),
    );
    await tester.tap(find.byKey(const Key('metrics-day-picker-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('6'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await _openDashboardSection(tester, 'dashboard-nav-sessions');
    expect(find.text('> Day filter ........ 2026-05-06'), findsOneWidget);
    expect(find.textContaining('ses_m06_'), findsWidgets);
    expect(find.textContaining('ses_m08_'), findsNothing);
  });

  testWidgets('metrics hour selection filters sessions evidence pane', (
    WidgetTester tester,
  ) async {
    final settingsRepo = _FakeSettingsRepository(
      OpenCodeSettings(
        openCodeServerUrl: Uri.parse('http://localhost:4096'),
        selectedCurrency: SupportedCurrency.usd,
      ),
    );

    final metricsRepo = _FakeMetricsRepository();
    final metricsService = MonetizedMetricsService(
      settingsRepository: settingsRepo,
      metricsRepository: metricsRepo,
      composer: MonetizedMetricsComposer(
        exchangeRateRepository: _UnusedExchangeRateRepository(),
      ),
    );

    final sessionsDependencies = SessionsCubitDependencies(
      localRepository: _FakeSessionRepository([
        OpenCodeSession(
          id: 'ses_h09',
          createdAt: DateTime.utc(2026, 5, 8, 9),
          modelName: 'gpt-5.4',
          inputTokens: 40,
          outputTokens: 14,
          totalCostUsd: 0.15,
        ),
        OpenCodeSession(
          id: 'ses_h14',
          createdAt: DateTime.utc(2026, 5, 8, 14),
          modelName: 'o4-mini',
          inputTokens: 20,
          outputTokens: 10,
          totalCostUsd: 0.05,
        ),
      ]),
      jsonParser: const OpenCodeSessionJsonParser(),
      remoteRepositoryFactory: (_) => _FakeSessionRepository(),
    );

    await _pumpEnglishDashboard(
      tester,
      metricsService: metricsService,
      settingsRepository: settingsRepo,
      serverProbe: (_) async => ServerProbeState.disconnected,
      sessionsDependencies: sessionsDependencies,
      pickImportSource: () async => null,
    );

    await tester.pumpAndSettle();

    // Verify both are present initially
    await _openDashboardSection(tester, 'dashboard-nav-sessions');
    expect(find.text('> Day filter ........ 2026-05-08'), findsNothing);
    expect(find.textContaining('ses_h09'), findsWidgets);
    expect(find.textContaining('ses_h14'), findsWidgets);

    // Switch to spend view to expose the hourly chart
    await _openDashboardSection(tester, 'dashboard-nav-metrics');
    await tester.ensureVisible(find.byKey(const Key('metrics-tab-spend')));
    await tester.tap(find.byKey(const Key('metrics-tab-spend')));
    await tester.pumpAndSettle();

    final hourlyChart = find.byKey(const Key('metrics-spend-hourly-chart'));
    expect(hourlyChart, findsOneWidget);

    // Trigger onHourSelected by tapping our test affordance
    await tester.tap(find.byKey(const Key('metrics-hour-test-9')));
    await tester.pumpAndSettle();

    await _openDashboardSection(tester, 'dashboard-nav-sessions');
    expect(find.text('> Day filter ........ 2026-05-08'), findsOneWidget);
    expect(find.text('> Hour filter ....... 09:00 UTC'), findsOneWidget);
    expect(find.textContaining('ses_h09'), findsWidgets);
    expect(find.textContaining('ses_h14'), findsNothing);

    // Toggle hour off
    await _openDashboardSection(tester, 'dashboard-nav-metrics');
    await tester.ensureVisible(find.byKey(const Key('metrics-tab-spend')));
    await tester.tap(find.byKey(const Key('metrics-tab-spend')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('metrics-hour-test-9')));
    await tester.pumpAndSettle();

    await _openDashboardSection(tester, 'dashboard-nav-sessions');
    expect(find.text('> Day filter ........ 2026-05-08'), findsOneWidget);
    expect(find.text('> Hour filter ....... 09:00 UTC'), findsNothing);
    expect(find.textContaining('ses_h09'), findsWidgets);
    expect(find.textContaining('ses_h14'), findsWidgets);
  });

  testWidgets(
    'metrics panel rolling averages and chart annotations render correctly',
    (WidgetTester tester) async {
      final settingsRepo = _FakeSettingsRepository(
        OpenCodeSettings(
          openCodeServerUrl: Uri.parse('http://localhost:4096'),
          selectedCurrency: SupportedCurrency.usd,
        ),
      );

      final metricsRepo = _FakeMetricsRepository();
      metricsRepo.readMetricsOverride = ({DateTime? from, DateTime? to}) async {
        final today = DateTime.utc(2026, 5, 8);
        final daily = List.generate(
          7,
          (i) => DailyMetrics(
            date: today.subtract(Duration(days: 6 - i)),
            sessionCount: 2,
            inputTokens: 100,
            outputTokens: 50,
            totalCostUsd: i == 6 ? 10.0 : 1.0,
          ),
        );

        final hourly = List.generate(
          24,
          (i) => HourlyMetrics(
            hour: DateTime.utc(2026, 5, 8, i),
            sessionCount: 1,
            inputTokens: 10,
            outputTokens: 5,
            totalCostUsd: i == 12 ? 5.0 : 0.5,
          ),
        );

        return AggregatedMetrics(
          totalSessionCount: 14,
          totalInputTokens: 700,
          totalOutputTokens: 350,
          totalCostUsd: 16.0,
          dailyBreakdown: daily,
          hourlyBreakdown: hourly,
          perModelDailyBreakdown: {},
        );
      };
      final metricsService = MonetizedMetricsService(
        settingsRepository: settingsRepo,
        metricsRepository: metricsRepo,
        composer: MonetizedMetricsComposer(
          exchangeRateRepository: _UnusedExchangeRateRepository(),
        ),
      );

      await _pumpEnglishDashboard(
        tester,
        metricsService: metricsService,
        settingsRepository: settingsRepo,
        serverProbe: (_) async => ServerProbeState.disconnected,
        sessionsDependencies: null,
      );
      await tester.pumpAndSettle();

      // 1) Verify rolling averages in text tab
      expect(
        find.byKey(const Key('metrics-rolling-cost-line')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('metrics-rolling-tokens-line')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('metrics-pace-line')), findsOneWidget);

      // total cost 16.0 over 7 days = 2.2857 -> 2.29
      expect(
        find.textContaining('Rolling avg cost ... USD 2.29/day'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Rolling avg tokens . 150/day'),
        findsOneWidget,
      );
      // pace = 2.2857 * 7 = 16.0
      expect(
        find.textContaining('Pace (7d forecast) . USD 16.00'),
        findsOneWidget,
      );

      await tester.ensureVisible(find.byKey(const Key('metrics-window-30d')));
      await tester.tap(find.byKey(const Key('metrics-window-30d')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('metrics-rolling-cost-line')),
      );

      expect(
        find.byKey(const Key('metrics-rolling-cost-line')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('metrics-rolling-tokens-line')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('metrics-pace-line')), findsOneWidget);
      expect(find.textContaining('USD 3.73'), findsOneWidget);

      // 2) Verify daily spend chart average and peak labels
      await tester.ensureVisible(find.byKey(const Key('metrics-tab-spend')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('metrics-tab-spend')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('metrics-spend-daily-avg-label')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('metrics-spend-daily-peak-label')),
        findsOneWidget,
      );

      expect(find.textContaining('AVG USD 0.53'), findsOneWidget);
      expect(find.textContaining('PEAK USD 10.00'), findsOneWidget);

      // 3) Verify hourly spend chart average and peak labels
      expect(
        find.byKey(const Key('metrics-spend-hourly-avg-label')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('metrics-spend-hourly-peak-label')),
        findsOneWidget,
      );

      // total hourly cost for the selected day = 23 * 0.5 + 5.0 = 16.5 over 24 hours = 0.6875 -> 0.69
      expect(find.textContaining('AVG USD 0.69'), findsOneWidget);
      expect(find.textContaining('PEAK USD 5.00'), findsOneWidget);
    },
  );

  testWidgets('dashboard supports window scoping behavior', (
    WidgetTester tester,
  ) async {
    final settingsRepo = _FakeSettingsRepository(
      OpenCodeSettings(
        openCodeServerUrl: Uri.parse('http://localhost:4096'),
        selectedCurrency: SupportedCurrency.usd,
      ),
    );

    final metricsRepo = _FakeMetricsRepository();
    metricsRepo.readMetricsOverride = ({DateTime? from, DateTime? to}) async {
      final today = DateTime.utc(2026, 5, 8);
      final allDaily = [
        DailyMetrics(
          date: today.subtract(const Duration(days: 10)),
          sessionCount: 1,
          inputTokens: 10,
          outputTokens: 5,
          totalCostUsd: 1.00,
        ),
        DailyMetrics(
          date: today.subtract(const Duration(days: 6)),
          sessionCount: 0,
          inputTokens: 0,
          outputTokens: 0,
          totalCostUsd: 0.10,
        ),
        DailyMetrics(
          date: today,
          sessionCount: 1,
          inputTokens: 60,
          outputTokens: 24,
          totalCostUsd: 0.20,
        ),
      ];

      final filteredDaily = allDaily.where((d) {
        if (from != null && d.date.isBefore(from)) return false;
        if (to != null && d.date.isAfter(to)) return false;
        return true;
      }).toList();

      double totalCost = 0.0;
      for (final d in filteredDaily) {
        totalCost += d.totalCostUsd;
      }

      return AggregatedMetrics(
        totalSessionCount: filteredDaily.fold<int>(
          0,
          (sum, daily) => sum + daily.sessionCount,
        ),
        totalInputTokens: filteredDaily.fold<int>(
          0,
          (sum, daily) => sum + daily.inputTokens,
        ),
        totalOutputTokens: filteredDaily.fold<int>(
          0,
          (sum, daily) => sum + daily.outputTokens,
        ),
        totalCostUsd: totalCost,
        dailyBreakdown: filteredDaily,
        perModelDailyBreakdown: {'gpt-5.4': filteredDaily},
      );
    };
    final localRates = _FakeExchangeRateRepository()
      ..seed(DateTime.utc(2026, 5, 8), [
        ExchangeRate(
          currency: SupportedCurrency.usd,
          date: DateTime.utc(2026, 5, 8),
          rateToCzk: 22.0,
        ),
      ]);
    final remoteRates = _FakeRemoteExchangeRateRepository({});

    final metricsService = MonetizedMetricsService(
      settingsRepository: settingsRepo,
      metricsRepository: metricsRepo,
      composer: MonetizedMetricsComposer(exchangeRateRepository: localRates),
    );

    final exchangeRatesDependencies = ExchangeRatesCubitDependencies(
      metricsRepository: metricsRepo,
      settingsRepository: settingsRepo,
      localExchangeRateRepository: localRates,
      syncService: ExchangeRateSyncService(
        remoteRepository: remoteRates,
        localRepository: localRates,
      ),
    );

    await _pumpEnglishDashboard(
      tester,
      metricsService: metricsService,
      settingsRepository: settingsRepo,
      exchangeRatesDependencies: exchangeRatesDependencies,
      serverProbe: (_) async => ServerProbeState.connected,
    );

    await tester.pumpAndSettle();

    // Initial state is ALL
    expect(find.text('> Window ............. ALL'), findsOneWidget);
    expect(find.text('> Total cost ......... USD 1.30'), findsOneWidget);
    expect(find.text('> Sessions ........... 2'), findsOneWidget);
    await _openDashboardSection(tester, 'dashboard-nav-exchange-rates');
    expect(find.text('> Coverage .......... 1/3'), findsOneWidget);
    await _openDashboardSection(tester, 'dashboard-nav-metrics');

    // Switch to CUSTOM to restrict window explicitly
    await tester.ensureVisible(find.byKey(const Key('metrics-window-custom')));
    await tester.tap(find.byKey(const Key('metrics-window-custom')));
    await tester.pumpAndSettle();

    // Tap the edit icon to switch to text input mode by tooltip
    await tester.tap(find.byTooltip('Switch to input'));
    await tester.pumpAndSettle();

    // Input fields depend on locale. Our test uses English, so mm/dd/yyyy is standard.
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.first, '05/01/2026');
    await tester.enterText(textFields.last, '05/08/2026');

    await tester.tap(find.byType(TextButton).last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('metrics-window-line')));

    expect(
      find.text('> Window ............. 2026-05-01 - 2026-05-08'),
      findsOneWidget,
    );
    expect(find.text('> Total cost ......... USD 0.30'), findsOneWidget);

    // Switch to 7D to restrict window
    await tester.ensureVisible(find.byKey(const Key('metrics-window-7d')));
    await tester.tap(find.byKey(const Key('metrics-window-7d')));
    await tester.pumpAndSettle();

    expect(find.text('> Window ............. 7D'), findsOneWidget);
    expect(find.text('> Total cost ......... USD 0.30'), findsOneWidget);
    expect(find.text('-- SELECTED DAY (2026-05-08) --'), findsOneWidget);
    expect(find.text('> Sessions ........... 1'), findsNWidgets(2));
    await _openDashboardSection(tester, 'dashboard-nav-exchange-rates');
    expect(find.text('> Coverage .......... 1/3'), findsOneWidget);
    await _openDashboardSection(tester, 'dashboard-nav-metrics');

    // Switch to MODELS and verify it uses 7D data
    await tester.ensureVisible(find.byKey(const Key('metrics-tab-models')));
    await tester.ensureVisible(find.byKey(const Key('metrics-tab-models')));
    await tester.tap(find.byKey(const Key('metrics-tab-models')));
    await tester.pumpAndSettle();

    // In 7D, we only see 0.10 and 0.20, so model total is 0.30
    expect(find.textContaining('USD 0.30 [100%]'), findsOneWidget);

    // Tap ALL again
    await tester.ensureVisible(find.byKey(const Key('metrics-window-all')));
    await tester.tap(find.byKey(const Key('metrics-window-all')));
    await tester.pumpAndSettle();

    // Switch back to TEXT view to check general metrics
    await tester.tap(find.byKey(const Key('metrics-tab-text')));
    await tester.pumpAndSettle();

    expect(find.text('> Window ............. ALL'), findsOneWidget);
    expect(find.text('> Total cost ......... USD 1.30'), findsOneWidget);
    await _openDashboardSection(tester, 'dashboard-nav-exchange-rates');
    expect(find.text('> Coverage .......... 1/3'), findsOneWidget);
  });

  testWidgets(
    'window changes clear model filter when selected model leaves view',
    (WidgetTester tester) async {
      final settingsRepo = _FakeSettingsRepository(
        OpenCodeSettings(
          openCodeServerUrl: Uri.parse('http://localhost:4096'),
          selectedCurrency: SupportedCurrency.usd,
        ),
      );

      final metricsRepo = _FakeMetricsRepository();
      metricsRepo.readMetricsOverride = ({DateTime? from, DateTime? to}) async {
        final latest = DateTime.utc(2026, 5, 8);
        final allDaily = [
          DailyMetrics(
            date: latest.subtract(const Duration(days: 40)),
            sessionCount: 1,
            inputTokens: 20,
            outputTokens: 10,
            totalCostUsd: 0.80,
          ),
          DailyMetrics(
            date: latest,
            sessionCount: 1,
            inputTokens: 30,
            outputTokens: 10,
            totalCostUsd: 0.20,
          ),
        ];

        final filteredDaily = allDaily.where((d) {
          if (from != null && d.date.isBefore(from)) return false;
          if (to != null && d.date.isAfter(to)) return false;
          return true;
        }).toList();

        final legacyModelDaily = [allDaily.first].where((d) {
          if (from != null && d.date.isBefore(from)) return false;
          if (to != null && d.date.isAfter(to)) return false;
          return true;
        }).toList();
        final activeModelDaily = [allDaily.last].where((d) {
          if (from != null && d.date.isBefore(from)) return false;
          if (to != null && d.date.isAfter(to)) return false;
          return true;
        }).toList();

        return AggregatedMetrics(
          totalSessionCount: filteredDaily.fold<int>(
            0,
            (sum, daily) => sum + daily.sessionCount,
          ),
          totalInputTokens: filteredDaily.fold<int>(
            0,
            (sum, daily) => sum + daily.inputTokens,
          ),
          totalOutputTokens: filteredDaily.fold<int>(
            0,
            (sum, daily) => sum + daily.outputTokens,
          ),
          totalCostUsd: filteredDaily.fold<double>(
            0,
            (sum, daily) => sum + daily.totalCostUsd,
          ),
          dailyBreakdown: filteredDaily,
          perModelDailyBreakdown: {
            if (legacyModelDaily.isNotEmpty) 'legacy-model': legacyModelDaily,
            if (activeModelDaily.isNotEmpty) 'gpt-5.4': activeModelDaily,
          },
        );
      };
      final metricsService = MonetizedMetricsService(
        settingsRepository: settingsRepo,
        metricsRepository: metricsRepo,
        composer: MonetizedMetricsComposer(
          exchangeRateRepository: _UnusedExchangeRateRepository(),
        ),
      );

      final sessionsDependencies = SessionsCubitDependencies(
        localRepository: _FakeSessionRepository([
          OpenCodeSession(
            id: 'ses_legacy',
            createdAt: DateTime.utc(2026, 3, 29),
            modelName: 'legacy-model',
            inputTokens: 20,
            outputTokens: 10,
            totalCostUsd: 0.80,
          ),
          OpenCodeSession(
            id: 'ses_recent',
            createdAt: DateTime.utc(2026, 5, 8),
            modelName: 'gpt-5.4',
            inputTokens: 30,
            outputTokens: 10,
            totalCostUsd: 0.20,
          ),
        ]),
        jsonParser: const OpenCodeSessionJsonParser(),
        remoteRepositoryFactory: (_) => _FakeSessionRepository(),
      );

      await _pumpEnglishDashboard(
        tester,
        metricsService: metricsService,
        settingsRepository: settingsRepo,
        serverProbe: (_) async => ServerProbeState.disconnected,
        sessionsDependencies: sessionsDependencies,
        pickImportSource: () async => null,
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('metrics-tab-models')));
      await tester.ensureVisible(find.byKey(const Key('metrics-tab-models')));
      await tester.tap(find.byKey(const Key('metrics-tab-models')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('model-filter-legacy-model')),
      );
      await tester.tap(find.byKey(const Key('model-filter-legacy-model')));
      await tester.pumpAndSettle();

      await _openDashboardSection(tester, 'dashboard-nav-sessions');
      expect(find.text('> Model filter ...... legacy-model'), findsOneWidget);
      expect(find.textContaining('legacy-model • 30 TOK'), findsWidgets);
      expect(find.textContaining('ses_rece'), findsNothing);

      await _openDashboardSection(tester, 'dashboard-nav-metrics');
      await tester.ensureVisible(find.byKey(const Key('metrics-window-7d')));
      await tester.tap(find.byKey(const Key('metrics-window-7d')));
      await tester.pumpAndSettle();
      await tester.pump();

      await _openDashboardSection(tester, 'dashboard-nav-sessions');
      expect(find.byKey(const Key('model-filter-legacy-model')), findsNothing);
      expect(find.text('> Model filter ...... legacy-model'), findsNothing);
      expect(find.textContaining('ses_lega'), findsNothing);
      expect(find.textContaining('ses_rece'), findsWidgets);

      // Select gpt-5.4 which is in the 7D window
      await _openDashboardSection(tester, 'dashboard-nav-metrics');
      await tester.ensureVisible(find.byKey(const Key('model-filter-gpt-5.4')));
      await tester.tap(find.byKey(const Key('model-filter-gpt-5.4')));
      await tester.pumpAndSettle();

      await _openDashboardSection(tester, 'dashboard-nav-sessions');
      expect(find.text('> Model filter ...... gpt-5.4'), findsOneWidget);

      // Switch to custom window that excludes gpt-5.4 (e.g. older range)
      await _openDashboardSection(tester, 'dashboard-nav-metrics');
      await tester.ensureVisible(
        find.byKey(const Key('metrics-window-custom')),
      );
      await tester.tap(find.byKey(const Key('metrics-window-custom')));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Switch to input'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, '03/01/2026');
      await tester.enterText(textFields.last, '04/01/2026');

      await tester.tap(find.byType(TextButton).last);
      await tester.pumpAndSettle();

      // gpt-5.4 left view, filter should be cleared
      await _openDashboardSection(tester, 'dashboard-nav-sessions');
      expect(find.text('> Model filter ...... gpt-5.4'), findsNothing);
      expect(find.byKey(const Key('model-filter-gpt-5.4')), findsNothing);
    },
  );

  testWidgets('selected day is preserved across refresh when still visible', (
    WidgetTester tester,
  ) async {
    final settingsRepo = _FakeSettingsRepository(
      OpenCodeSettings(
        openCodeServerUrl: Uri.parse('http://localhost:4096'),
        selectedCurrency: SupportedCurrency.usd,
      ),
    );
    final localRates = _FakeExchangeRateRepository();
    final metricsRepository = _FakeMetricsRepository();
    final metricsService = MonetizedMetricsService(
      settingsRepository: settingsRepo,
      metricsRepository: metricsRepository,
      composer: MonetizedMetricsComposer(exchangeRateRepository: localRates),
    );

    await _pumpEnglishDashboard(
      tester,
      metricsService: metricsService,
      settingsRepository: settingsRepo,
      serverProbe: (_) async => ServerProbeState.connected,
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('metrics-window-7d')));
    await tester.tap(find.byKey(const Key('metrics-window-7d')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('metrics-day-picker-button')),
    );
    await tester.tap(find.byKey(const Key('metrics-day-picker-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('6'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('-- SELECTED DAY (2026-05-06) --'), findsOneWidget);

    await tester.tap(find.byKey(const Key('metrics-tab-spend')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('metrics-tab-text')));
    await tester.pumpAndSettle();

    expect(find.text('-- SELECTED DAY (2026-05-06) --'), findsOneWidget);

    await tester.tap(find.byKey(const Key('metrics-window-all')));
    await tester.pumpAndSettle();

    expect(find.text('-- SELECTED DAY (2026-05-06) --'), findsOneWidget);

    // Switch to CUSTOM window
    await tester.ensureVisible(find.byKey(const Key('metrics-window-custom')));
    await tester.tap(find.byKey(const Key('metrics-window-custom')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Switch to input'));
    await tester.pumpAndSettle();

    final textFields = find.byType(TextField);
    await tester.enterText(textFields.first, '05/01/2026');
    await tester.enterText(textFields.last, '05/08/2026');

    await tester.tap(find.byType(TextButton).last);
    await tester.pumpAndSettle();

    // 05/06 is in range, so it is preserved
    expect(find.text('-- SELECTED DAY (2026-05-06) --'), findsOneWidget);

    // Switch to CUSTOM window outside the selected day
    await tester.ensureVisible(find.byKey(const Key('metrics-window-custom')));
    await tester.tap(find.byKey(const Key('metrics-window-custom')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Switch to input'));
    await tester.pumpAndSettle();

    final textFields2 = find.byType(TextField);
    await tester.enterText(textFields2.first, '05/07/2026');
    await tester.enterText(textFields2.last, '05/08/2026');

    await tester.tap(find.byType(TextButton).last);
    await tester.pumpAndSettle();

    // 05/06 is out of range, fallback to latest visible day (05/08)
    expect(find.text('-- SELECTED DAY (2026-05-08) --'), findsOneWidget);
  });

  testWidgets('live probe status changes and triggers sync on reconnect', (
    WidgetTester tester,
  ) async {
    final settingsRepo = _FakeSettingsRepository(
      OpenCodeSettings(
        openCodeServerUrl: Uri.parse('http://localhost:4096'),
        selectedCurrency: SupportedCurrency.usd,
      ),
    );

    ServerProbeState currentProbeState = ServerProbeState.disconnected;

    final initialSessions = [
      OpenCodeSession(
        id: 'ses_local',
        createdAt: DateTime.utc(2026, 5, 8, 11),
        modelName: 'local-model',
        inputTokens: 10,
        outputTokens: 5,
        totalCostUsd: 0.10,
      ),
    ];
    final syncedSessions = [
      OpenCodeSession(
        id: 'ses_live_1',
        createdAt: DateTime.utc(2026, 5, 8, 12),
        modelName: 'gpt-5.4',
        inputTokens: 30,
        outputTokens: 20,
        totalCostUsd: 0.25,
      ),
      OpenCodeSession(
        id: 'ses_live_2',
        createdAt: DateTime.utc(2026, 5, 8, 13),
        modelName: 'o4-mini',
        inputTokens: 20,
        outputTokens: 10,
        totalCostUsd: 0.15,
      ),
    ];

    final localRepo = _CountingSessionRepository(
      initialSessions: initialSessions,
    );
    final remoteRepo = _CountingSessionRepository(
      initialSessions: syncedSessions,
    );
    final sessionsDependencies = SessionsCubitDependencies(
      localRepository: localRepo,
      jsonParser: const OpenCodeSessionJsonParser(),
      remoteRepositoryFactory: (_) => remoteRepo,
    );
    final metricsService = MonetizedMetricsService(
      settingsRepository: settingsRepo,
      metricsRepository: LocalMetricsRepository(localRepo),
      composer: MonetizedMetricsComposer(
        exchangeRateRepository: _UnusedExchangeRateRepository(),
      ),
    );

    await _pumpEnglishDashboard(
      tester,
      metricsService: metricsService,
      settingsRepository: settingsRepo,
      sessionsDependencies: sessionsDependencies,
      pickImportSource: () async => null,
      serverProbe: (_) async => currentProbeState,
    );
    await tester.pumpAndSettle();

    await _openDashboardSection(tester, 'dashboard-nav-state');
    expect(find.text('> Probe ............. DISCONNECTED'), findsOneWidget);
    await _openDashboardSection(tester, 'dashboard-nav-metrics');

    expect(find.textContaining('USD 0.10'), findsWidgets);
    expect(find.text('> Sessions ........... 1'), findsWidgets);
    expect(localRepo.readCount, greaterThan(0));

    await _openDashboardSection(tester, 'dashboard-nav-sessions');
    expect(find.textContaining('local-model • 15 TOK'), findsWidgets);
    expect(remoteRepo.readCount, 0);

    // Transition to connected
    currentProbeState = ServerProbeState.connected;
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    await _openDashboardSection(tester, 'dashboard-nav-state');
    expect(find.text('> Probe ............. CONNECTED'), findsOneWidget);
    await _openDashboardSection(tester, 'dashboard-nav-metrics');

    expect(remoteRepo.readCount, 1);
    expect(localRepo.writeCount, 1);
    expect(find.textContaining('USD 0.40'), findsWidgets);
    expect(find.text('> Sessions ........... 2'), findsWidgets);

    await _openDashboardSection(tester, 'dashboard-nav-sessions');
    expect(find.textContaining('gpt-5.4 • 50 TOK'), findsWidgets);
    expect(find.textContaining('o4-mini • 30 TOK'), findsWidgets);
    expect(find.textContaining('local-model • 15 TOK'), findsNothing);

    // Repeated connected ticks do not trigger duplicate syncs
    final int currentRemoteReads = remoteRepo.readCount;
    final int currentWrites = localRepo.writeCount;
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();

    await _openDashboardSection(tester, 'dashboard-nav-state');
    expect(find.text('> Probe ............. CONNECTED'), findsOneWidget);
    await _openDashboardSection(tester, 'dashboard-nav-metrics');

    expect(remoteRepo.readCount, currentRemoteReads);
    expect(localRepo.writeCount, currentWrites);
    expect(find.textContaining('USD 0.40'), findsWidgets);
    expect(find.text('> Sessions ........... 2'), findsWidgets);
  });

  testWidgets(
    'startup connected state triggers initial sync and refreshes metrics',
    (WidgetTester tester) async {
      final settingsRepo = _FakeSettingsRepository(
        OpenCodeSettings(
          openCodeServerUrl: Uri.parse('http://localhost:4096'),
          selectedCurrency: SupportedCurrency.usd,
        ),
      );

      final localRepo = _CountingSessionRepository(
        initialSessions: [
          OpenCodeSession(
            id: 'ses_local',
            createdAt: DateTime.utc(2026, 5, 8, 11),
            modelName: 'local-model',
            inputTokens: 10,
            outputTokens: 5,
            totalCostUsd: 0.10,
          ),
        ],
      );
      final remoteRepo = _CountingSessionRepository(
        initialSessions: [
          OpenCodeSession(
            id: 'ses_live_1',
            createdAt: DateTime.utc(2026, 5, 8, 12),
            modelName: 'gpt-5.4',
            inputTokens: 30,
            outputTokens: 20,
            totalCostUsd: 0.25,
          ),
          OpenCodeSession(
            id: 'ses_live_2',
            createdAt: DateTime.utc(2026, 5, 8, 13),
            modelName: 'o4-mini',
            inputTokens: 20,
            outputTokens: 10,
            totalCostUsd: 0.15,
          ),
        ],
      );
      final sessionsDependencies = SessionsCubitDependencies(
        localRepository: localRepo,
        jsonParser: const OpenCodeSessionJsonParser(),
        remoteRepositoryFactory: (_) => remoteRepo,
      );
      final metricsService = MonetizedMetricsService(
        settingsRepository: settingsRepo,
        metricsRepository: LocalMetricsRepository(localRepo),
        composer: MonetizedMetricsComposer(
          exchangeRateRepository: _UnusedExchangeRateRepository(),
        ),
      );

      await _pumpEnglishDashboard(
        tester,
        metricsService: metricsService,
        settingsRepository: settingsRepo,
        sessionsDependencies: sessionsDependencies,
        pickImportSource: () async => null,
        serverProbe: (_) async => ServerProbeState.connected,
      );
      await tester.pumpAndSettle();

      await _openDashboardSection(tester, 'dashboard-nav-state');
      expect(find.text('> Probe ............. CONNECTED'), findsOneWidget);
      await _openDashboardSection(tester, 'dashboard-nav-metrics');

      expect(remoteRepo.readCount, 1);
      expect(localRepo.writeCount, 1);
      expect(find.textContaining('USD 0.40'), findsWidgets);
      expect(find.text('> Sessions ........... 2'), findsWidgets);

      await _openDashboardSection(tester, 'dashboard-nav-sessions');
      expect(find.textContaining('local-model • 15 TOK'), findsNothing);
      expect(find.textContaining('gpt-5.4 • 50 TOK'), findsWidgets);
      expect(find.textContaining('o4-mini • 30 TOK'), findsWidgets);
    },
  );

  testWidgets('reconnect sync failure does not refresh metrics', (
    WidgetTester tester,
  ) async {
    final settingsRepo = _FakeSettingsRepository(
      OpenCodeSettings(
        openCodeServerUrl: Uri.parse('http://localhost:4096'),
        selectedCurrency: SupportedCurrency.usd,
      ),
    );

    var metricsReadCount = 0;
    final metricsRepo = _FakeMetricsRepository()
      ..readMetricsOverride = ({DateTime? from, DateTime? to}) async {
        metricsReadCount++;
        return AggregatedMetrics(
          totalSessionCount: 1,
          totalInputTokens: 10,
          totalOutputTokens: 5,
          totalCostUsd: 0.10,
          dailyBreakdown: [
            DailyMetrics(
              date: DateTime.utc(2026, 5, 8),
              sessionCount: 1,
              inputTokens: 10,
              outputTokens: 5,
              totalCostUsd: 0.10,
            ),
          ],
        );
      };

    final localRepo = _CountingSessionRepository(
      initialSessions: [
        OpenCodeSession(
          id: 'ses_local',
          createdAt: DateTime.utc(2026, 5, 8, 11),
          modelName: 'local-model',
          inputTokens: 10,
          outputTokens: 5,
          totalCostUsd: 0.10,
        ),
      ],
    );
    final sessionsDependencies = SessionsCubitDependencies(
      localRepository: localRepo,
      jsonParser: const OpenCodeSessionJsonParser(),
      remoteRepositoryFactory: (_) =>
          _ThrowingSessionRepository(StateError('sync failed')),
    );
    final metricsService = MonetizedMetricsService(
      settingsRepository: settingsRepo,
      metricsRepository: metricsRepo,
      composer: MonetizedMetricsComposer(
        exchangeRateRepository: _UnusedExchangeRateRepository(),
      ),
    );
    ServerProbeState currentProbeState = ServerProbeState.disconnected;

    await _pumpEnglishDashboard(
      tester,
      metricsService: metricsService,
      settingsRepository: settingsRepo,
      sessionsDependencies: sessionsDependencies,
      pickImportSource: () async => null,
      serverProbe: (_) async => currentProbeState,
    );
    await tester.pumpAndSettle();

    await _openDashboardSection(tester, 'dashboard-nav-state');
    expect(find.text('> Probe ............. DISCONNECTED'), findsOneWidget);
    await _openDashboardSection(tester, 'dashboard-nav-metrics');

    expect(metricsReadCount, 1);
    expect(find.textContaining('USD 0.10'), findsWidgets);
    expect(localRepo.writeCount, 0);

    currentProbeState = ServerProbeState.connected;
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();

    await _openDashboardSection(tester, 'dashboard-nav-state');
    expect(find.text('> Probe ............. CONNECTED'), findsOneWidget);
    await _openDashboardSection(tester, 'dashboard-nav-metrics');
    expect(metricsReadCount, 1);
    expect(localRepo.writeCount, 0);
    expect(find.textContaining('USD 0.10'), findsWidgets);
    expect(find.text('> Sessions ........... 1'), findsWidgets);
    await _openDashboardSection(tester, 'dashboard-nav-sessions');
    expect(find.textContaining('local-model • 15 TOK'), findsWidgets);
    expect(find.textContaining('gpt-5.4 • 50 TOK'), findsNothing);
    expect(find.textContaining('o4-mini • 30 TOK'), findsNothing);
  });

  testWidgets('reconnect sync still works when sessions panel is omitted', (
    WidgetTester tester,
  ) async {
    final settingsRepo = _FakeSettingsRepository(
      OpenCodeSettings(
        openCodeServerUrl: Uri.parse('http://localhost:4096'),
        selectedCurrency: SupportedCurrency.usd,
      ),
    );

    final localRepo = _CountingSessionRepository(
      initialSessions: [
        OpenCodeSession(
          id: 'ses_local',
          createdAt: DateTime.utc(2026, 5, 8, 11),
          modelName: 'local-model',
          inputTokens: 10,
          outputTokens: 5,
          totalCostUsd: 0.10,
        ),
      ],
    );
    final remoteRepo = _CountingSessionRepository(
      initialSessions: [
        OpenCodeSession(
          id: 'ses_live_1',
          createdAt: DateTime.utc(2026, 5, 8, 12),
          modelName: 'gpt-5.4',
          inputTokens: 30,
          outputTokens: 20,
          totalCostUsd: 0.25,
        ),
        OpenCodeSession(
          id: 'ses_live_2',
          createdAt: DateTime.utc(2026, 5, 8, 13),
          modelName: 'o4-mini',
          inputTokens: 20,
          outputTokens: 10,
          totalCostUsd: 0.15,
        ),
      ],
    );
    final sessionsDependencies = SessionsCubitDependencies(
      localRepository: localRepo,
      jsonParser: const OpenCodeSessionJsonParser(),
      remoteRepositoryFactory: (_) => remoteRepo,
    );
    final metricsService = MonetizedMetricsService(
      settingsRepository: settingsRepo,
      metricsRepository: LocalMetricsRepository(localRepo),
      composer: MonetizedMetricsComposer(
        exchangeRateRepository: _UnusedExchangeRateRepository(),
      ),
    );
    ServerProbeState currentProbeState = ServerProbeState.disconnected;

    await _pumpEnglishDashboard(
      tester,
      metricsService: metricsService,
      settingsRepository: settingsRepo,
      sessionsDependencies: sessionsDependencies,
      pickImportSource: null,
      serverProbe: (_) async => currentProbeState,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sessions-panel')), findsNothing);
    await _openDashboardSection(tester, 'dashboard-nav-state');
    expect(find.text('> Probe ............. DISCONNECTED'), findsOneWidget);
    await _openDashboardSection(tester, 'dashboard-nav-metrics');

    expect(remoteRepo.readCount, 0);
    expect(localRepo.writeCount, 0);

    currentProbeState = ServerProbeState.connected;
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();

    await _openDashboardSection(tester, 'dashboard-nav-state');
    expect(find.text('> Probe ............. CONNECTED'), findsOneWidget);
    await _openDashboardSection(tester, 'dashboard-nav-metrics');
    expect(remoteRepo.readCount, 1);
    expect(localRepo.writeCount, 1);
    expect(find.textContaining('USD 0.40'), findsWidgets);
    expect(find.byKey(const Key('sessions-panel')), findsNothing);
  });

  testWidgets('probe loop stops after disposal', (WidgetTester tester) async {
    final settingsRepo = _FakeSettingsRepository(
      OpenCodeSettings(
        openCodeServerUrl: Uri.parse('http://localhost:4096'),
        selectedCurrency: SupportedCurrency.usd,
      ),
    );

    final localRepo = _CountingSessionRepository(
      initialSessions: [
        OpenCodeSession(
          id: 'ses_local',
          createdAt: DateTime.utc(2026, 5, 8, 11),
          modelName: 'local-model',
          inputTokens: 10,
          outputTokens: 5,
          totalCostUsd: 0.10,
        ),
      ],
    );
    final remoteRepo = _CountingSessionRepository(
      initialSessions: [
        OpenCodeSession(
          id: 'ses_live_1',
          createdAt: DateTime.utc(2026, 5, 8, 12),
          modelName: 'gpt-5.4',
          inputTokens: 30,
          outputTokens: 20,
          totalCostUsd: 0.25,
        ),
      ],
    );
    final sessionsDependencies = SessionsCubitDependencies(
      localRepository: localRepo,
      jsonParser: const OpenCodeSessionJsonParser(),
      remoteRepositoryFactory: (_) => remoteRepo,
    );
    final metricsService = MonetizedMetricsService(
      settingsRepository: settingsRepo,
      metricsRepository: LocalMetricsRepository(localRepo),
      composer: MonetizedMetricsComposer(
        exchangeRateRepository: _UnusedExchangeRateRepository(),
      ),
    );
    var serverProbeCalls = 0;

    await _pumpEnglishDashboard(
      tester,
      metricsService: metricsService,
      settingsRepository: settingsRepo,
      sessionsDependencies: sessionsDependencies,
      pickImportSource: null,
      serverProbe: (_) async {
        serverProbeCalls++;
        return ServerProbeState.connected;
      },
    );
    await tester.pumpAndSettle();

    expect(serverProbeCalls, 1);
    expect(remoteRepo.readCount, 1);
    expect(localRepo.writeCount, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();

    expect(serverProbeCalls, 1);
    expect(remoteRepo.readCount, 1);
    expect(localRepo.writeCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'dashboard supports selected-day token drivers and model details',
    (WidgetTester tester) async {
      final settingsRepo = _FakeSettingsRepository(
        OpenCodeSettings(
          openCodeServerUrl: Uri.parse('http://localhost:4096'),
          selectedCurrency: SupportedCurrency.usd,
        ),
      );

      final metricsRepo = _FakeMetricsRepository();
      final exchangeRateRepo = _FakeExchangeRateRepository();
      final metricsService = MonetizedMetricsService(
        metricsRepository: metricsRepo,
        settingsRepository: settingsRepo,
        composer: MonetizedMetricsComposer(
          exchangeRateRepository: exchangeRateRepo,
        ),
      );
      final exchangeRatesDependencies = ExchangeRatesCubitDependencies(
        metricsRepository: metricsRepo,
        settingsRepository: settingsRepo,
        localExchangeRateRepository: exchangeRateRepo,
        syncService: ExchangeRateSyncService(
          remoteRepository: _FakeRemoteExchangeRateRepository({}),
          localRepository: exchangeRateRepo,
        ),
      );

      final sessionsDependencies = SessionsCubitDependencies(
        localRepository: _CountingSessionRepository(),
        jsonParser: const OpenCodeSessionJsonParser(),
        remoteRepositoryFactory: (_) => _CountingSessionRepository(),
      );

      await _pumpEnglishDashboard(
        tester,
        metricsService: metricsService,
        settingsRepository: settingsRepo,
        exchangeRatesDependencies: exchangeRatesDependencies,
        sessionsDependencies: sessionsDependencies,
        pickImportSource: () async => null,
        serverProbe: (_) async => ServerProbeState.connected,
      );

      await tester.pumpAndSettle();

      // Switch to TOKENS
      await tester.ensureVisible(
        find.byKey(const Key('metrics-tab-tokens')).first,
      );
      await tester.tap(find.byKey(const Key('metrics-tab-tokens')).first);
      await tester.pumpAndSettle();

      // Select the actual visible day
      await tester.ensureVisible(
        find.byKey(const Key('metrics-day-picker-button')),
      );
      await tester.tap(find.byKey(const Key('metrics-day-picker-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('8'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Assert drivers panel
      expect(
        find.byKey(const Key('metrics-tokens-drivers-panel')),
        findsOneWidget,
      );

      // Tap a concrete driver row
      final driverRow = find.byKey(const Key('token-driver-model-o4-mini'));
      await tester.ensureVisible(driverRow);
      await tester.tap(driverRow);
      await tester.pumpAndSettle();

      // Verify shared model filter banner
      await _openDashboardSection(tester, 'dashboard-nav-sessions');
      expect(find.text('> Model filter ...... o4-mini'), findsOneWidget);

      // Switch to MODELS
      await _openDashboardSection(tester, 'dashboard-nav-metrics');
      await tester.ensureVisible(find.byKey(const Key('metrics-tab-models')));
      await tester.tap(find.byKey(const Key('metrics-tab-models')));
      await tester.pumpAndSettle();

      // Assert detail charts
      expect(
        find.byKey(const Key('metrics-model-detail-section')),
        findsOneWidget,
      );
      expect(find.text('[ o4-mini ]'), findsOneWidget);
    },
  );

  testWidgets('dashboard supports model momentum attribution and top mover', (
    WidgetTester tester,
  ) async {
    final settingsRepo = _FakeSettingsRepository(
      OpenCodeSettings(
        openCodeServerUrl: Uri.parse('http://localhost:4096'),
        selectedCurrency: SupportedCurrency.usd,
      ),
    );

    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final metricsRepository = _FakeMetricsRepository();
    metricsRepository.readMetricsOverride = ({from, to}) async {
      return AggregatedMetrics(
        totalCostUsd: 15.0,
        totalSessionCount: 2,
        totalInputTokens: 200,
        totalOutputTokens: 200,
        dailyBreakdown: [
          DailyMetrics(
            date: yesterday,
            sessionCount: 1,
            inputTokens: 100,
            outputTokens: 100,
            totalCostUsd: 5.0,
          ),
          DailyMetrics(
            date: today,
            sessionCount: 1,
            inputTokens: 100,
            outputTokens: 100,
            totalCostUsd: 10.0,
          ),
        ],
        hourlyBreakdown: [],
        perModelDailyBreakdown: {
          'stable-model': [
            DailyMetrics(
              date: yesterday,
              sessionCount: 1,
              inputTokens: 50,
              outputTokens: 50,
              totalCostUsd: 4.0,
            ),
            DailyMetrics(
              date: today,
              sessionCount: 1,
              inputTokens: 50,
              outputTokens: 50,
              totalCostUsd: 4.0,
            ),
          ],
          'growing-model': [
            DailyMetrics(
              date: yesterday,
              sessionCount: 1,
              inputTokens: 50,
              outputTokens: 50,
              totalCostUsd: 1.0,
            ),
            DailyMetrics(
              date: today,
              sessionCount: 1,
              inputTokens: 50,
              outputTokens: 50,
              totalCostUsd: 6.0,
            ),
          ],
        },
      );
    };

    final metricsService = MonetizedMetricsService(
      settingsRepository: settingsRepo,
      metricsRepository: metricsRepository,
      composer: MonetizedMetricsComposer(
        exchangeRateRepository: _UnusedExchangeRateRepository(),
      ),
    );

    await _pumpEnglishDashboard(
      tester,
      metricsService: metricsService,
      settingsRepository: settingsRepo,
      serverProbe: (_) async => ServerProbeState.disconnected,
      sessionsDependencies: SessionsCubitDependencies(
        localRepository: _FakeSessionRepository([
          OpenCodeSession(
            id: 'ses_grow',
            createdAt: today,
            modelName: 'growing-model',
            inputTokens: 100,
            outputTokens: 100,
            totalCostUsd: 6.0,
          ),
          OpenCodeSession(
            id: 'ses_stable',
            createdAt: today,
            modelName: 'stable-model',
            inputTokens: 100,
            outputTokens: 100,
            totalCostUsd: 4.0,
          ),
        ]),
        jsonParser: const OpenCodeSessionJsonParser(),
        remoteRepositoryFactory: (_) => _FakeSessionRepository(),
      ),
      pickImportSource: () async => null,
    );

    await tester.pumpAndSettle();

    // Ensure TEXT tab is visible before tapping
    await tester.ensureVisible(find.byKey(const Key('metrics-tab-text')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('metrics-tab-text')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('metrics-top-mover-line')), findsOneWidget);
    expect(find.textContaining('growing-model (+USD5.00)'), findsOneWidget);

    // Switch to MODELS tab
    await tester.ensureVisible(find.byKey(const Key('metrics-tab-models')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('metrics-tab-models')));
    await tester.pumpAndSettle();

    expect(find.textContaining('2D 4.00/4.00'), findsOneWidget);
    expect(find.textContaining('2D 1.00/6.00'), findsOneWidget);

    // Verify that tap triggers selection
    await tester.ensureVisible(find.byKey(const Key('metrics-tab-text')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('metrics-tab-text')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('metrics-top-mover-line')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('metrics-top-mover-line')));
    await tester.pumpAndSettle();

    await _openDashboardSection(tester, 'dashboard-nav-sessions');
    expect(find.text('> Model filter ...... growing-model'), findsOneWidget);
  });

  testWidgets('model momentum uses sparse visible days for top mover', (
    WidgetTester tester,
  ) async {
    final settingsRepo = _FakeSettingsRepository(
      OpenCodeSettings(
        openCodeServerUrl: Uri.parse('http://localhost:4096'),
        selectedCurrency: SupportedCurrency.usd,
      ),
    );

    final now = DateTime.now();
    final latest = DateTime.utc(now.year, now.month, now.day);
    final sparsePrevious = latest.subtract(const Duration(days: 6));

    final metricsRepository = _FakeMetricsRepository();
    metricsRepository.readMetricsOverride = ({from, to}) async {
      return AggregatedMetrics(
        totalCostUsd: 11.0,
        totalSessionCount: 2,
        totalInputTokens: 200,
        totalOutputTokens: 200,
        dailyBreakdown: [
          DailyMetrics(
            date: sparsePrevious,
            sessionCount: 1,
            inputTokens: 100,
            outputTokens: 100,
            totalCostUsd: 1.0,
          ),
          DailyMetrics(
            date: latest,
            sessionCount: 1,
            inputTokens: 100,
            outputTokens: 100,
            totalCostUsd: 10.0,
          ),
        ],
        hourlyBreakdown: [],
        perModelDailyBreakdown: {
          'sparse-grower': [
            DailyMetrics(
              date: latest,
              sessionCount: 1,
              inputTokens: 100,
              outputTokens: 100,
              totalCostUsd: 10.0,
            ),
          ],
          'older-model': [
            DailyMetrics(
              date: sparsePrevious,
              sessionCount: 1,
              inputTokens: 100,
              outputTokens: 100,
              totalCostUsd: 1.0,
            ),
          ],
        },
      );
    };

    final metricsService = MonetizedMetricsService(
      settingsRepository: settingsRepo,
      metricsRepository: metricsRepository,
      composer: MonetizedMetricsComposer(
        exchangeRateRepository: _UnusedExchangeRateRepository(),
      ),
    );

    await _pumpEnglishDashboard(
      tester,
      metricsService: metricsService,
      settingsRepository: settingsRepo,
      serverProbe: (_) async => ServerProbeState.disconnected,
    );

    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('metrics-window-7d')));
    await tester.tap(find.byKey(const Key('metrics-window-7d')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('metrics-top-mover-line')), findsOneWidget);
    expect(find.textContaining('sparse-grower (+USD10.00)'), findsOneWidget);
  });

  testWidgets('dashboard hides compare widgets for ALL window', (
    WidgetTester tester,
  ) async {
    final settingsRepo = _FakeSettingsRepository(
      OpenCodeSettings(
        openCodeServerUrl: Uri.parse('http://localhost:4096'),
        selectedCurrency: SupportedCurrency.usd,
      ),
    );
    final metricsRepo = _FakeMetricsRepository();
    metricsRepo.readMetricsOverride = ({DateTime? from, DateTime? to}) async {
      return AggregatedMetrics(
        totalSessionCount: 1,
        totalInputTokens: 10,
        totalOutputTokens: 5,
        totalCostUsd: 1.00,
        dailyBreakdown: [
          DailyMetrics(
            date: DateTime.now(),
            sessionCount: 1,
            inputTokens: 10,
            outputTokens: 5,
            totalCostUsd: 1.00,
          ),
        ],
        perModelDailyBreakdown: {},
      );
    };
    final metricsService = MonetizedMetricsService(
      settingsRepository: settingsRepo,
      metricsRepository: metricsRepo,
      composer: MonetizedMetricsComposer(
        exchangeRateRepository: _UnusedExchangeRateRepository(),
      ),
    );
    await _pumpEnglishDashboard(
      tester,
      metricsService: metricsService,
      settingsRepository: settingsRepo,
      serverProbe: (_) async => ServerProbeState.connected,
    );
    await tester.pumpAndSettle();
    expect(find.text('> Window ............. ALL'), findsOneWidget);
    for (final key in [
      'metrics-compare-prior-window',
      'metrics-compare-total-line',
      'metrics-compare-sessions-line',
      'metrics-compare-tokens-line',
      'metrics-compare-split-unavailable',
      'metrics-compare-split-sessions-line',
      'metrics-compare-split-avg-line',
      'metrics-compare-split-cost-line',
      'metrics-compare-driver-line',
      'metrics-compare-driver-line-empty',
      'metrics-compare-unavailable',
    ]) {
      expect(find.byKey(Key(key)), findsNothing);
    }
  });

  testWidgets(
    'dashboard shows compare block for 30D and 90D windows and opens model filter from compare driver',
    (WidgetTester tester) async {
      final settingsRepo = _FakeSettingsRepository(
        OpenCodeSettings(
          openCodeServerUrl: Uri.parse('http://localhost:4096'),
          selectedCurrency: SupportedCurrency.usd,
        ),
      );

      final sessionsDependencies = SessionsCubitDependencies(
        localRepository: _FakeSessionRepository([
          OpenCodeSession(
            id: 'ses_gpt_5_4',
            createdAt: DateTime.utc(2026, 5, 8, 9),
            modelName: 'gpt-5.4',
            inputTokens: 10,
            outputTokens: 5,
            totalCostUsd: 10.0,
          ),
          OpenCodeSession(
            id: 'ses_steady',
            createdAt: DateTime.utc(2026, 5, 8, 10),
            modelName: 'steady-model',
            inputTokens: 10,
            outputTokens: 5,
            totalCostUsd: 2.0,
          ),
        ]),
        jsonParser: const OpenCodeSessionJsonParser(),
        remoteRepositoryFactory: (_) => _FakeSessionRepository(),
      );

      AggregatedMetrics metricsFor({
        required int sessions,
        required int inputTokens,
        required int outputTokens,
        required double totalCostUsd,
        required List<DailyMetrics> dailyBreakdown,
        required Map<String, List<DailyMetrics>> perModelDailyBreakdown,
      }) {
        return AggregatedMetrics(
          totalSessionCount: sessions,
          totalInputTokens: inputTokens,
          totalOutputTokens: outputTokens,
          totalCostUsd: totalCostUsd,
          dailyBreakdown: dailyBreakdown,
          perModelDailyBreakdown: perModelDailyBreakdown,
        );
      }

      final currentDay = DateTime.utc(2026, 5, 8);
      final current30Start = DateTime.utc(2026, 4, 9);
      final prior30Start = DateTime.utc(2026, 3, 10);
      final current90Start = DateTime.utc(2026, 2, 8);
      final prior90Start = DateTime.utc(2025, 11, 10);

      final metricsRepo = _FakeMetricsRepository();
      metricsRepo.readMetricsOverride = ({DateTime? from, DateTime? to}) async {
        final currentWindow = from != null && to != null;
        if (!currentWindow) {
          return metricsFor(
            sessions: 3,
            inputTokens: 30,
            outputTokens: 15,
            totalCostUsd: 3.0,
            dailyBreakdown: [
              DailyMetrics(
                date: currentDay,
                sessionCount: 1,
                inputTokens: 10,
                outputTokens: 5,
                totalCostUsd: 1.0,
              ),
            ],
            perModelDailyBreakdown: const {},
          );
        }

        bool matches(DateTime candidate) =>
            from.year == candidate.year &&
            from.month == candidate.month &&
            from.day == candidate.day;

        if (matches(current30Start)) {
          return metricsFor(
            sessions: 12,
            inputTokens: 120,
            outputTokens: 60,
            totalCostUsd: 12.0,
            dailyBreakdown: [
              DailyMetrics(
                date: currentDay,
                sessionCount: 2,
                inputTokens: 20,
                outputTokens: 10,
                totalCostUsd: 2.0,
              ),
            ],
            perModelDailyBreakdown: {
              'gpt-5.4': [
                DailyMetrics(
                  date: currentDay,
                  sessionCount: 1,
                  inputTokens: 10,
                  outputTokens: 5,
                  totalCostUsd: 10.0,
                ),
              ],
              'steady-model': [
                DailyMetrics(
                  date: currentDay,
                  sessionCount: 1,
                  inputTokens: 10,
                  outputTokens: 5,
                  totalCostUsd: 2.0,
                ),
              ],
            },
          );
        }

        if (matches(prior30Start)) {
          return metricsFor(
            sessions: 4,
            inputTokens: 40,
            outputTokens: 20,
            totalCostUsd: 4.0,
            dailyBreakdown: [
              DailyMetrics(
                date: prior30Start,
                sessionCount: 1,
                inputTokens: 10,
                outputTokens: 5,
                totalCostUsd: 1.0,
              ),
            ],
            perModelDailyBreakdown: {
              'gpt-5.4': [
                DailyMetrics(
                  date: prior30Start,
                  sessionCount: 1,
                  inputTokens: 10,
                  outputTokens: 5,
                  totalCostUsd: 1.0,
                ),
              ],
              'steady-model': [
                DailyMetrics(
                  date: prior30Start,
                  sessionCount: 1,
                  inputTokens: 10,
                  outputTokens: 5,
                  totalCostUsd: 1.5,
                ),
              ],
            },
          );
        }

        if (matches(current90Start)) {
          return metricsFor(
            sessions: 18,
            inputTokens: 180,
            outputTokens: 90,
            totalCostUsd: 18.0,
            dailyBreakdown: [
              DailyMetrics(
                date: currentDay,
                sessionCount: 2,
                inputTokens: 20,
                outputTokens: 10,
                totalCostUsd: 2.0,
              ),
            ],
            perModelDailyBreakdown: {
              'gpt-5.4': [
                DailyMetrics(
                  date: currentDay,
                  sessionCount: 1,
                  inputTokens: 10,
                  outputTokens: 5,
                  totalCostUsd: 14.0,
                ),
              ],
              'steady-model': [
                DailyMetrics(
                  date: currentDay,
                  sessionCount: 1,
                  inputTokens: 10,
                  outputTokens: 5,
                  totalCostUsd: 4.0,
                ),
              ],
            },
          );
        }

        if (matches(prior90Start)) {
          return metricsFor(
            sessions: 8,
            inputTokens: 80,
            outputTokens: 40,
            totalCostUsd: 8.0,
            dailyBreakdown: [
              DailyMetrics(
                date: prior90Start,
                sessionCount: 1,
                inputTokens: 10,
                outputTokens: 5,
                totalCostUsd: 1.0,
              ),
            ],
            perModelDailyBreakdown: {
              'gpt-5.4': [
                DailyMetrics(
                  date: prior90Start,
                  sessionCount: 1,
                  inputTokens: 10,
                  outputTokens: 5,
                  totalCostUsd: 2.0,
                ),
              ],
              'steady-model': [
                DailyMetrics(
                  date: prior90Start,
                  sessionCount: 1,
                  inputTokens: 10,
                  outputTokens: 5,
                  totalCostUsd: 3.0,
                ),
              ],
            },
          );
        }

        throw StateError('Unexpected compare range: $from - $to');
      };

      final metricsService = MonetizedMetricsService(
        settingsRepository: settingsRepo,
        metricsRepository: metricsRepo,
        composer: MonetizedMetricsComposer(
          exchangeRateRepository: _UnusedExchangeRateRepository(),
        ),
      );

      await _pumpEnglishDashboard(
        tester,
        metricsService: metricsService,
        settingsRepository: settingsRepo,
        sessionsDependencies: sessionsDependencies,
        serverProbe: (_) async => ServerProbeState.connected,
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('metrics-window-30d')));
      await tester.tap(find.byKey(const Key('metrics-window-30d')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('metrics-compare-prior-window')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('metrics-compare-total-line')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('metrics-compare-sessions-line')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('metrics-compare-tokens-line')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('metrics-compare-split-sessions-line')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('metrics-compare-split-avg-line')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('metrics-compare-split-cost-line')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('metrics-compare-unavailable')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('metrics-compare-split-unavailable')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('metrics-compare-driver-line')),
        findsOneWidget,
      );
      expect(
        find.text('> Delta driver ....... gpt-5.4 +USD 9.00'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('metrics-compare-driver-line')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('metrics-tab-models')));
      await tester.tap(find.byKey(const Key('metrics-tab-models')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('model-filter-gpt-5.4')), findsOneWidget);
      expect(find.text('[ gpt-5.4 ]'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('metrics-tab-text')));
      await tester.tap(find.byKey(const Key('metrics-tab-text')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('metrics-window-90d')));
      await tester.tap(find.byKey(const Key('metrics-window-90d')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('metrics-compare-prior-window')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('metrics-compare-total-line')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('metrics-compare-sessions-line')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('metrics-compare-tokens-line')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('metrics-compare-split-sessions-line')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('metrics-compare-split-avg-line')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('metrics-compare-split-cost-line')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('metrics-compare-unavailable')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('metrics-compare-split-unavailable')),
        findsNothing,
      );
    },
  );

  testWidgets('dashboard shows compare block for 7D window', (
    WidgetTester tester,
  ) async {
    final settingsRepo = _FakeSettingsRepository(
      OpenCodeSettings(
        openCodeServerUrl: Uri.parse('http://localhost:4096'),
        selectedCurrency: SupportedCurrency.usd,
      ),
    );
    final metricsRepo = _FakeMetricsRepository();
    final now = DateTime.now();
    final latestDay = DateTime.utc(now.year, now.month, now.day);
    final currentStart = latestDay.subtract(const Duration(days: 6));
    final priorStart = latestDay.subtract(const Duration(days: 13));
    bool isSameUtcDate(DateTime value, DateTime other) {
      final normalized = value.toUtc();
      return normalized.year == other.year &&
          normalized.month == other.month &&
          normalized.day == other.day;
    }

    metricsRepo.readMetricsOverride = ({DateTime? from, DateTime? to}) async {
      if (from == null) {
        return AggregatedMetrics(
          totalSessionCount: 20,
          totalInputTokens: 200,
          totalOutputTokens: 100,
          totalCostUsd: 10.00,
          dailyBreakdown: [
            DailyMetrics(
              date: latestDay,
              sessionCount: 1,
              inputTokens: 10,
              outputTokens: 5,
              totalCostUsd: 1.00,
            ),
          ],
          perModelDailyBreakdown: {},
        );
      }

      if (to != null && isSameUtcDate(from, currentStart)) {
        return AggregatedMetrics(
          totalSessionCount: 10,
          totalInputTokens: 100,
          totalOutputTokens: 50,
          totalCostUsd: 5.00,
          dailyBreakdown: [
            DailyMetrics(
              date: latestDay,
              sessionCount: 1,
              inputTokens: 10,
              outputTokens: 5,
              totalCostUsd: 1.00,
            ),
          ],
          perModelDailyBreakdown: {},
        );
      }

      if (to != null && isSameUtcDate(from, priorStart)) {
        return AggregatedMetrics(
          totalSessionCount: 5,
          totalInputTokens: 50,
          totalOutputTokens: 25,
          totalCostUsd: 2.00,
          dailyBreakdown: [
            DailyMetrics(
              date: priorStart,
              sessionCount: 1,
              inputTokens: 10,
              outputTokens: 5,
              totalCostUsd: 1.00,
            ),
          ],
          perModelDailyBreakdown: {},
        );
      }

      throw StateError('Unexpected compare range: $from - $to');
    };
    final metricsService = MonetizedMetricsService(
      settingsRepository: settingsRepo,
      metricsRepository: metricsRepo,
      composer: MonetizedMetricsComposer(
        exchangeRateRepository: _UnusedExchangeRateRepository(),
      ),
    );
    await _pumpEnglishDashboard(
      tester,
      metricsService: metricsService,
      settingsRepository: settingsRepo,
      serverProbe: (_) async => ServerProbeState.connected,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('metrics-window-7d')));
    await tester.tap(find.byKey(const Key('metrics-window-7d')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('metrics-window-line')), findsOneWidget);
    expect(find.textContaining('> Prior window .......'), findsOneWidget);
    expect(find.byKey(const Key('metrics-compare-total-line')), findsOneWidget);
    expect(find.text('> Delta sessions ..... +5'), findsOneWidget);
    expect(find.text('> Delta tokens ....... +75'), findsOneWidget);
    expect(
      find.byKey(const Key('metrics-compare-split-sessions-line')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('metrics-compare-split-avg-line')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('metrics-compare-split-cost-line')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('metrics-compare-split-unavailable')),
      findsNothing,
    );
  });

  testWidgets('dashboard shows compare block for custom window', (
    WidgetTester tester,
  ) async {
    final settingsRepo = _FakeSettingsRepository(
      OpenCodeSettings(
        openCodeServerUrl: Uri.parse('http://localhost:4096'),
        selectedCurrency: SupportedCurrency.usd,
      ),
    );
    final metricsRepo = _FakeMetricsRepository();
    metricsRepo.readMetricsOverride = ({DateTime? from, DateTime? to}) async {
      if (from == null) {
        return AggregatedMetrics(
          totalSessionCount: 20,
          totalInputTokens: 200,
          totalOutputTokens: 100,
          totalCostUsd: 10.00,
          dailyBreakdown: [
            DailyMetrics(
              date: DateTime.now(),
              sessionCount: 1,
              inputTokens: 10,
              outputTokens: 5,
              totalCostUsd: 1.00,
            ),
          ],
          perModelDailyBreakdown: {},
        );
      }
      if (from.year == 2026 && from.month == 5 && from.day == 6) {
        return AggregatedMetrics(
          totalSessionCount: 4,
          totalInputTokens: 40,
          totalOutputTokens: 20,
          totalCostUsd: 4.00,
          dailyBreakdown: [
            DailyMetrics(
              date: DateTime.now(),
              sessionCount: 1,
              inputTokens: 10,
              outputTokens: 5,
              totalCostUsd: 1.00,
            ),
          ],
          perModelDailyBreakdown: {},
        );
      } else {
        return AggregatedMetrics(
          totalSessionCount: 6,
          totalInputTokens: 60,
          totalOutputTokens: 30,
          totalCostUsd: 6.00,
          dailyBreakdown: [
            DailyMetrics(
              date: DateTime.now(),
              sessionCount: 1,
              inputTokens: 10,
              outputTokens: 5,
              totalCostUsd: 1.00,
            ),
          ],
          perModelDailyBreakdown: {},
        );
      }
    };
    final metricsService = MonetizedMetricsService(
      settingsRepository: settingsRepo,
      metricsRepository: metricsRepo,
      composer: MonetizedMetricsComposer(
        exchangeRateRepository: _UnusedExchangeRateRepository(),
      ),
    );
    await _pumpEnglishDashboard(
      tester,
      metricsService: metricsService,
      settingsRepository: settingsRepo,
      serverProbe: (_) async => ServerProbeState.connected,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('metrics-window-custom')));
    await tester.tap(find.byKey(const Key('metrics-window-custom')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Switch to input'));
    await tester.pumpAndSettle();
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.first, '05/06/2026');
    await tester.enterText(textFields.last, '05/08/2026');
    await tester.tap(find.byType(TextButton).last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('metrics-window-line')), findsOneWidget);
    expect(
      find.text('> Prior window ....... 2026-05-03 - 2026-05-05'),
      findsOneWidget,
    );
    expect(find.text('> Vs prior ........... -USD 2.00'), findsOneWidget);
    expect(find.text('> Delta sessions ..... -2'), findsOneWidget);
    expect(find.text('> Delta tokens ....... -30'), findsOneWidget);
    expect(
      find.byKey(const Key('metrics-compare-split-sessions-line')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('metrics-compare-split-avg-line')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('metrics-compare-split-cost-line')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('metrics-compare-split-unavailable')),
      findsNothing,
    );
  });

  testWidgets(
    'dashboard shows unavailable compare helper when missing CZK exchange rates',
    (WidgetTester tester) async {
      final settingsRepo = _FakeSettingsRepository(
        OpenCodeSettings(
          openCodeServerUrl: Uri.parse('http://localhost:4096'),
          selectedCurrency: SupportedCurrency.czk,
        ),
      );
      final metricsRepo = _FakeMetricsRepository();
      metricsRepo.readMetricsOverride = ({DateTime? from, DateTime? to}) async {
        final currentFrom = from ?? DateTime.utc(2026, 5, 8);
        return AggregatedMetrics(
          totalSessionCount: 1,
          totalInputTokens: 10,
          totalOutputTokens: 5,
          totalCostUsd: 1.00,
          dailyBreakdown: [
            DailyMetrics(
              date: currentFrom,
              sessionCount: 1,
              inputTokens: 10,
              outputTokens: 5,
              totalCostUsd: 1.00,
            ),
          ],
          perModelDailyBreakdown: {},
        );
      };
      final exchangeRateRepo = _FakeExchangeRateRepository();
      // Seed ONLY the exact "from" date that the 7D window uses, so current window succeeds.
      final targetDate7d = DateTime.utc(2026, 5, 2);
      final targetDate30d = DateTime.utc(2026, 4, 9);
      final currentDate = DateTime.utc(2026, 5, 8);
      exchangeRateRepo.seed(targetDate7d, [
        ExchangeRate(
          currency: SupportedCurrency.usd,
          date: targetDate7d,
          rateToCzk: 22.0,
        ),
      ]);
      exchangeRateRepo.seed(targetDate30d, [
        ExchangeRate(
          currency: SupportedCurrency.usd,
          date: targetDate30d,
          rateToCzk: 22.0,
        ),
      ]);
      exchangeRateRepo.seed(currentDate, [
        ExchangeRate(
          currency: SupportedCurrency.usd,
          date: currentDate,
          rateToCzk: 22.0,
        ),
      ]);

      final metricsService = MonetizedMetricsService(
        settingsRepository: settingsRepo,
        metricsRepository: metricsRepo,
        composer: MonetizedMetricsComposer(
          exchangeRateRepository: exchangeRateRepo,
        ),
      );

      await _pumpEnglishDashboard(
        tester,
        metricsService: metricsService,
        settingsRepository: settingsRepo,
        serverProbe: (_) async => ServerProbeState.connected,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('metrics-window-7d')));
      await tester.tap(find.byKey(const Key('metrics-window-7d')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('metrics-window-line')));
      expect(find.text('> Window ............. 7D'), findsOneWidget);
      expect(find.text('> Sessions ........... 1'), findsOneWidget);
      expect(find.text('> Total tokens ....... 15'), findsOneWidget);
      expect(
        find.text(
          '> Prior-window compare unavailable due to missing exchange rates.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('metrics-compare-unavailable')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('metrics-compare-split-sessions-line')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('metrics-compare-split-unavailable')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'dashboard shows split compare unavailable when tokens are zero',
    (WidgetTester tester) async {
      final settingsRepo = _FakeSettingsRepository(
        OpenCodeSettings(
          openCodeServerUrl: Uri.parse('http://localhost:4096'),
          selectedCurrency: SupportedCurrency.usd,
        ),
      );
      final metricsRepo = _FakeMetricsRepository();
      metricsRepo.readMetricsOverride = ({DateTime? from, DateTime? to}) async {
        return AggregatedMetrics(
          totalSessionCount: 1,
          totalInputTokens: 0,
          totalOutputTokens: 0,
          totalCostUsd: 0.0,
          dailyBreakdown: [
            DailyMetrics(
              date: DateTime.utc(2026, 5, 8),
              sessionCount: 1,
              inputTokens: 0,
              outputTokens: 0,
              totalCostUsd: 0.0,
            ),
          ],
          hourlyBreakdown: [],
          perModelDailyBreakdown: {},
        );
      };

      final metricsService = MonetizedMetricsService(
        settingsRepository: settingsRepo,
        metricsRepository: metricsRepo,
        composer: MonetizedMetricsComposer(
          exchangeRateRepository: _UnusedExchangeRateRepository(),
        ),
      );

      await _pumpEnglishDashboard(
        tester,
        metricsService: metricsService,
        settingsRepository: settingsRepo,
        serverProbe: (_) async => ServerProbeState.connected,
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('metrics-window-30d')));
      await tester.tap(find.byKey(const Key('metrics-window-30d')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('metrics-compare-prior-window')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('metrics-compare-split-unavailable')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('metrics-compare-total-line')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('metrics-compare-sessions-line')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('metrics-compare-tokens-line')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('metrics-compare-split-sessions-line')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'dashboard shows split compare unavailable when sessions are zero',
    (WidgetTester tester) async {
      final settingsRepo = _FakeSettingsRepository(
        OpenCodeSettings(
          openCodeServerUrl: Uri.parse('http://localhost:4096'),
          selectedCurrency: SupportedCurrency.usd,
        ),
      );
      final metricsRepo = _FakeMetricsRepository();
      metricsRepo.readMetricsOverride = ({DateTime? from, DateTime? to}) async {
        return AggregatedMetrics(
          totalSessionCount: 0,
          totalInputTokens: 10,
          totalOutputTokens: 5,
          totalCostUsd: 0.0,
          dailyBreakdown: [
            DailyMetrics(
              date: DateTime.utc(2026, 5, 8),
              sessionCount: 0,
              inputTokens: 10,
              outputTokens: 5,
              totalCostUsd: 0.0,
            ),
          ],
          hourlyBreakdown: [],
          perModelDailyBreakdown: {},
        );
      };

      final metricsService = MonetizedMetricsService(
        settingsRepository: settingsRepo,
        metricsRepository: metricsRepo,
        composer: MonetizedMetricsComposer(
          exchangeRateRepository: _UnusedExchangeRateRepository(),
        ),
      );

      await _pumpEnglishDashboard(
        tester,
        metricsService: metricsService,
        settingsRepository: settingsRepo,
        serverProbe: (_) async => ServerProbeState.connected,
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('metrics-window-30d')));
      await tester.tap(find.byKey(const Key('metrics-window-30d')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('metrics-compare-prior-window')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('metrics-compare-split-unavailable')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('metrics-compare-total-line')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('metrics-compare-sessions-line')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('metrics-compare-tokens-line')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('metrics-compare-split-sessions-line')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'dashboard router shell starts on metrics and switches sections',
    (WidgetTester tester) async {
      final localRates = _FakeExchangeRateRepository();
      final exchangeRatesDependencies = ExchangeRatesCubitDependencies(
        metricsRepository: _FakeMetricsRepository(),
        settingsRepository: _FakeSettingsRepository(),
        localExchangeRateRepository: localRates,
        syncService: ExchangeRateSyncService(
          remoteRepository: _FakeRemoteExchangeRateRepository({}),
          localRepository: localRates,
        ),
      );

      await _pumpEnglishDashboard(
        tester,
        exchangeRatesDependencies: exchangeRatesDependencies,
        sessionsDependencies: SessionsCubitDependencies(
          localRepository: _FakeSessionRepository(),
          jsonParser: const OpenCodeSessionJsonParser(),
          remoteRepositoryFactory: (_) => _FakeSessionRepository(),
        ),
        pickImportSource: () async => null,
        serverProbe: (_) async => ServerProbeState.connected,
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('metrics-window-line')), findsOneWidget);
      expect(find.byKey(const Key('sessions-panel')), findsNothing);
      expect(find.byKey(const Key('exchange-rates-panel')), findsNothing);

      await _openDashboardSection(tester, 'dashboard-nav-sessions');
      expect(find.byKey(const Key('sessions-panel')), findsOneWidget);
      expect(find.byKey(const Key('metrics-window-line')), findsNothing);

      await _openDashboardSection(tester, 'dashboard-nav-exchange-rates');
      expect(find.byKey(const Key('exchange-rates-panel')), findsOneWidget);
      expect(find.byKey(const Key('sessions-panel')), findsNothing);

      expect(find.byKey(const Key('dashboard-nav-settings')), findsNothing);
      await tester.tap(find.byKey(const Key('settings-open-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settings-dialog')), findsOneWidget);
      expect(find.byKey(const Key('settings-save-button')), findsOneWidget);
      expect(find.byKey(const Key('settings-modal-overlay')), findsOneWidget);
    },
  );

  testWidgets('settings modal can close without saving', (
    WidgetTester tester,
  ) async {
    await _pumpEnglishDashboard(
      tester,
      settingsRepository: _FakeSettingsRepository(),
      serverProbe: (_) async => ServerProbeState.connected,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-open-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings-dialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-close-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings-dialog')), findsNothing);
  });

  testWidgets('help dialog opens with local and remote tabs', (
    WidgetTester tester,
  ) async {
    await _pumpEnglishDashboard(
      tester,
      settingsRepository: _FakeSettingsRepository(),
      serverProbe: (_) async => ServerProbeState.connected,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('help-open-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('help-modal-overlay')), findsOneWidget);
    expect(find.byKey(const Key('help-dialog')), findsOneWidget);
    expect(find.text('Local'), findsOneWidget);
    expect(find.text('Remote'), findsOneWidget);
    expect(find.textContaining('opencode db path'), findsOneWidget);

    await tester.tap(find.byKey(const Key('help-tab-remote')));
    await tester.pumpAndSettle();

    expect(find.textContaining('opencode serve'), findsOneWidget);
    expect(
      find.text('> Default server URL: http://localhost:4096'),
      findsOneWidget,
    );
    expect(find.textContaining('OPENCODE_SERVER_USERNAME'), findsOneWidget);
    expect(
      find.textContaining('default username is `opencode`'),
      findsOneWidget,
    );
  });

  testWidgets('settings modal persists username without raw password', (
    WidgetTester tester,
  ) async {
    final store = _InMemoryKeyValueStore();
    final settingsRepo = LocalSettingsRepository(store);

    await _pumpEnglishDashboard(
      tester,
      settingsRepository: settingsRepo,
      serverProbe: (_) async => ServerProbeState.connected,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-open-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('settings-server-username-field')),
      'alice',
    );
    await tester.enterText(
      find.byKey(const Key('settings-server-password-field')),
      'secret',
    );
    await tester.tap(find.byKey(const Key('settings-save-button')));
    await tester.pumpAndSettle();

    final saved = await settingsRepo.readSettings();
    final persistedPayload =
        jsonDecode(store.values['openspent.settings']!) as Map<String, Object?>;

    expect(saved?.openCodeServerUsername, 'alice');
    expect(saved?.openCodeServerPassword, isNull);
    expect(persistedPayload['openCodeServerPassword'], isNull);
    expect(store.values['openspent.settings'], isNot(contains('secret')));
  });

  testWidgets(
    'saved credentials remain in memory for immediate probe and sync',
    (WidgetTester tester) async {
      final store = _InMemoryKeyValueStore();
      final settingsRepo = LocalSettingsRepository(store);
      final localRepo = _CountingSessionRepository();
      OpenCodeSettings? capturedProbeSettings;
      OpenCodeSettings? capturedSyncSettings;
      ServerProbeState currentProbeState = ServerProbeState.disconnected;
      final sessionsDependencies = SessionsCubitDependencies(
        localRepository: localRepo,
        jsonParser: const OpenCodeSessionJsonParser(),
        remoteRepositoryFactory: (settings) {
          capturedSyncSettings = settings;
          return _FakeSessionRepository([
            OpenCodeSession(
              id: 'ses_remote',
              createdAt: DateTime.utc(2026, 5, 8, 12),
              modelName: 'gpt-5.4',
              inputTokens: 10,
              outputTokens: 5,
              totalCostUsd: 0.10,
            ),
          ]);
        },
      );

      await _pumpEnglishDashboard(
        tester,
        settingsRepository: settingsRepo,
        sessionsDependencies: sessionsDependencies,
        pickImportSource: () async => null,
        serverProbe: (settings) async {
          capturedProbeSettings = settings;
          return currentProbeState;
        },
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings-open-button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('settings-server-password-field')),
        'secret',
      );
      await tester.tap(find.byKey(const Key('settings-save-button')));
      await tester.pumpAndSettle();

      final persistedSettings = await settingsRepo.readSettings();

      expect(
        capturedProbeSettings?.effectiveOpenCodeServerUsername,
        'opencode',
      );
      expect(capturedProbeSettings?.openCodeServerPassword, 'secret');
      expect(
        capturedProbeSettings?.openCodeServerAuthorizationHeader,
        startsWith('Basic '),
      );
      expect(persistedSettings?.openCodeServerPassword, isNull);

      currentProbeState = ServerProbeState.connected;
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();

      expect(capturedSyncSettings?.effectiveOpenCodeServerUsername, 'opencode');
      expect(capturedSyncSettings?.openCodeServerPassword, 'secret');
    },
  );
}

class _EmptyMetricsRepository implements MetricsRepository {
  @override
  Future<AggregatedMetrics> readMetrics({DateTime? from, DateTime? to}) async =>
      AggregatedMetrics(
        totalCostUsd: 0,
        totalSessionCount: 0,
        totalInputTokens: 0,
        totalOutputTokens: 0,
        dailyBreakdown: [],
        hourlyBreakdown: [],
        perModelDailyBreakdown: {},
      );
}

class _UnusedExchangeRateRepository implements ExchangeRateRepository {
  @override
  Future<void> writeExchangeRates(Iterable<ExchangeRate> rates) async {}
  @override
  Future<List<ExchangeRate>> readExchangeRatesForDate(DateTime date) async =>
      [];
}

class _ZeroTokenMetricsRepository implements MetricsRepository {
  @override
  Future<AggregatedMetrics> readMetrics({DateTime? from, DateTime? to}) async =>
      AggregatedMetrics(
        totalCostUsd: 0.0,
        totalSessionCount: 2,
        totalInputTokens: 0,
        totalOutputTokens: 0,
        dailyBreakdown: [
          DailyMetrics(
            date: DateTime.utc(2026, 5, 8),
            sessionCount: 2,
            inputTokens: 0,
            outputTokens: 0,
            totalCostUsd: 0.0,
          ),
        ],
        hourlyBreakdown: [],
        perModelDailyBreakdown: {
          'gpt-5.4': [
            DailyMetrics(
              date: DateTime.utc(2026, 5, 8),
              sessionCount: 2,
              inputTokens: 0,
              outputTokens: 0,
              totalCostUsd: 0.0,
            ),
          ],
          'o4-mini': [
            DailyMetrics(
              date: DateTime.utc(2026, 5, 8),
              sessionCount: 1,
              inputTokens: 0,
              outputTokens: 0,
              totalCostUsd: 0.0,
            ),
          ],
        },
      );
}
