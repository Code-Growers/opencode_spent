import 'package:flutter/widgets.dart';
import 'package:openspent_core/openspent_core.dart';

enum DashboardDataMode { real, mock }

class DemoModeController extends ValueNotifier<DashboardDataMode> {
  DemoModeController([super.value = DashboardDataMode.real]);

  void toggle() {
    value = value == DashboardDataMode.real
        ? DashboardDataMode.mock
        : DashboardDataMode.real;
  }
}

List<ExchangeRate> buildDashboardMockExchangeRates(
  DateTime now, {
  int dayCount = 45,
}) {
  final anchor = DateTime.utc(now.year, now.month, now.day);
  return <ExchangeRate>[
    for (int i = 0; i < dayCount; i++) ...[
      ExchangeRate(
        currency: SupportedCurrency.usd,
        rateToCzk: 22.8 + ((i % 6) * 0.15),
        date: anchor.subtract(Duration(days: i)),
      ),
      ExchangeRate(
        currency: SupportedCurrency.czk,
        rateToCzk: 1.0,
        date: anchor.subtract(Duration(days: i)),
      ),
    ],
  ];
}

List<OpenCodeSession> buildDashboardMockSessions(DateTime now) {
  final anchor = DateTime.utc(now.year, now.month, now.day, 10);
  return List<OpenCodeSession>.generate(84, (index) {
    final createdAt = anchor.subtract(Duration(hours: index * 4));
    final isOpenAi = index.isEven;
    final provider = isOpenAi ? 'OpenAI' : 'Anthropic';
    final modelName = switch (index % 4) {
      0 => 'gpt-5.4',
      1 => 'o4-mini',
      2 => 'claude-3.7-sonnet',
      _ => 'claude-opus-4',
    };
    final inputTokens = 180 + ((index % 9) * 35);
    final outputTokens = 90 + ((index % 7) * 22);
    final requestCount = 4 + (index % 5);
    final toolCallCount = 1 + (index % 4);
    final totalCostUsd = isOpenAi
        ? 0.18 + ((index % 8) * 0.04)
        : 0.09 + ((index % 8) * 0.025);

    return OpenCodeSession(
      id: 'mock_session_$index',
      createdAt: createdAt,
      provider: provider,
      modelName: modelName,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      requestCount: requestCount,
      toolCallCount: toolCallCount,
      responseCount: requestCount,
      totalResponseTimeMs: 900 + ((index % 6) * 180),
      totalCostUsd: totalCostUsd,
    );
  });
}

class DemoModeScope extends InheritedNotifier<DemoModeController> {
  const DemoModeScope({
    super.key,
    DemoModeController? controller,
    required super.child,
  }) : super(notifier: controller);

  static DemoModeController? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DemoModeScope>()
        ?.notifier;
  }
}

class MockExchangeRateRepository implements ExchangeRateRepository {
  MockExchangeRateRepository([List<ExchangeRate>? rates]) {
    if (rates != null) {
      for (final rate in rates) {
        final key = _normalize(rate.date);
        final next = List<ExchangeRate>.from(_ratesByDate[key] ?? const []);
        next.add(rate);
        _ratesByDate[key] = next;
      }
    }
  }

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
      final next = List<ExchangeRate>.from(_ratesByDate[key] ?? const []);
      next.removeWhere((entry) => entry.currency == rate.currency);
      next.add(rate);
      _ratesByDate[key] = next;
    }
  }

  static DateTime _normalize(DateTime value) {
    final utc = value.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day);
  }
}

class MockOpenCodeSessionRepository implements OpenCodeSessionRepository {
  MockOpenCodeSessionRepository([List<OpenCodeSession>? sessions])
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

class DelegatingSessionRepository implements OpenCodeSessionRepository {
  DelegatingSessionRepository(this.real, this.mock, this.controller);

  final OpenCodeSessionRepository real;
  final OpenCodeSessionRepository mock;
  final DemoModeController controller;

  OpenCodeSessionRepository get _current =>
      controller.value == DashboardDataMode.real ? real : mock;

  @override
  Future<List<OpenCodeSession>> readSessions() => _current.readSessions();

  @override
  Future<void> writeSessions(Iterable<OpenCodeSession> sessions) =>
      _current.writeSessions(sessions);
}

class DelegatingExchangeRateRepository implements ExchangeRateRepository {
  DelegatingExchangeRateRepository(this.real, this.mock, this.controller);

  final ExchangeRateRepository real;
  final ExchangeRateRepository mock;
  final DemoModeController controller;

  ExchangeRateRepository get _current =>
      controller.value == DashboardDataMode.real ? real : mock;

  @override
  Future<List<ExchangeRate>> readExchangeRatesForDate(DateTime date) =>
      _current.readExchangeRatesForDate(date);

  @override
  Future<void> writeExchangeRates(
    Iterable<ExchangeRate> rates, {
    DateTime? effectiveDate,
  }) => _current.writeExchangeRates(rates, effectiveDate: effectiveDate);
}

class DelegatingMetricsRepository implements MetricsRepository {
  DelegatingMetricsRepository(this.real, this.mock, this.controller);

  final MetricsRepository real;
  final MetricsRepository mock;
  final DemoModeController controller;

  MetricsRepository get _current =>
      controller.value == DashboardDataMode.real ? real : mock;

  @override
  Future<AggregatedMetrics> readMetrics({DateTime? from, DateTime? to}) =>
      _current.readMetrics(from: from, to: to);
}
