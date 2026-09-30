import 'dart:convert';
import 'package:openspent_core/openspent_core.dart';
import 'package:test/test.dart';

final start = DateTime.utc(2026, 9, 1);
Map<String, Object?> usage(
  int input,
  int output, {
  int cached = 0,
  int writes = 0,
}) => {
  'input_tokens': input,
  'output_tokens': output,
  'cached_input_tokens': cached,
  'cache_write_input_tokens': writes,
  'reasoning_output_tokens': output ~/ 2,
};
void add(
  HarnessTranscriptParser parser,
  String type,
  Map<String, Object?> payload, {
  int minute = 1,
}) => parser.addLine(
  jsonEncode({
    'type': type,
    'timestamp': start.add(Duration(minutes: minute)).toIso8601String(),
    'payload': payload,
  }),
);
HarnessTranscriptParser codex() {
  final parser = HarnessTranscriptParser(UsageHarness.codex);
  add(parser, 'session_meta', {
    'id': 'session-a',
    'timestamp': start.toIso8601String(),
    'cwd': '/private/project',
    'base_instructions': 'SECRET',
  });
  add(parser, 'turn_context', {'model': 'gpt-6.1-sol'});
  return parser;
}

Map<String, Object?> claude({
  String id = 'msg-a',
  String session = 'session-a',
  int output = 10,
  int hour = 0,
}) => {
  'type': 'assistant',
  'sessionId': session,
  'timestamp': start.add(Duration(hours: hour)).toIso8601String(),
  'cwd': '/private/project',
  'message': {
    'id': id,
    'model': 'claude-opus-5-5',
    'content': [
      {'text': 'SECRET PROMPT AND TOOL OUTPUT'},
    ],
    'usage': {
      'input_tokens': 100,
      'output_tokens': output,
      'cache_read_input_tokens': 50,
      'cache_creation_input_tokens': 20,
      'cache_creation': {
        'ephemeral_5m_input_tokens': 10,
        'ephemeral_1h_input_tokens': 10,
      },
      'output_tokens_details': {'thinking_tokens': 5},
    },
  },
};

void main() {
  test(
    'observed legacy models have verified prices including cache lifetimes',
    () {
      final pricing = PricingConfig();
      for (final model in [
        'claude-opus-5',
        'claude-opus-4-8',
        'claude-fable-5',
        'claude-fable-5-1',
        'claude-sonnet-5',
      ]) {
        final rate = ApiPriceCatalog.rates['anthropic/$model']!;
        final event = UsageEvent(
          id: 'event',
          sessionId: 'session',
          timestamp: start,
          provider: 'anthropic',
          model: model,
          tokens: const TokenUsage(
            input: 1000000,
            output: 1000000,
            cachedInput: 500000,
            cacheWrite: 200000,
            cacheWrite5m: 100000,
            cacheWrite1h: 100000,
          ),
        );
        expect(
          pricing.estimate(event).usd,
          closeTo(
            .3 * rate.input +
                rate.output +
                .5 * rate.cachedInput! +
                .1 * rate.cacheWrite! +
                .1 * rate.cacheWrite1h!,
            .000001,
          ),
        );
      }
      for (final model in ['gpt-5.6-sol', 'gpt-5.6-terra', 'gpt-5.6-luna']) {
        final rate = ApiPriceCatalog.rates['openai/$model']!;
        final event = UsageEvent(
          id: 'event',
          sessionId: 'session',
          timestamp: start,
          provider: 'openai',
          model: model,
          contextInputTokens: 300000,
          tokens: const TokenUsage(
            input: 1000000,
            output: 1000000,
            cachedInput: 500000,
            cacheWrite: 0,
          ),
        );
        expect(
          pricing.estimate(event).usd,
          closeTo(
            rate.input +
                .5 * rate.longContextRates!.cachedInput! +
                rate.output * 1.5,
            .000001,
          ),
        );
      }
    },
  );
  test('OpenCode input includes cache and reasoning stays inside output', () {
    final tokens = readOpenCodeTokenUsage({
      'input': 100,
      'output': 20,
      'reasoning': 10,
      'cache': {'read': 50, 'write': 20},
    });
    expect(tokens?.input, 170);
    expect(tokens?.output, 20);
    expect(tokens?.reasoning, 10);
    expect(tokens?.cachedInput, 50);
    expect(tokens?.cacheWrite, 20);
    expect(readOpenCodeTokenUsage({'input': 100, 'output': 20}), isNull);
  });
  test('late detailed Codex records replace matching cumulative usage', () {
    final parser = codex();
    add(parser, 'event_msg', {
      'type': 'token_count',
      'info': {
        'total_token_usage': usage(100, 20),
        'last_token_usage': usage(100, 20),
      },
    });
    add(parser, 'token_usage_record', {
      'response_id': 'response',
      'thread_id': 'session-a',
      'usage': usage(100, 20),
      'thread_token_usage': usage(100, 20),
    });
    expect(parser.finish().single.inputTokens, 100);
    expect(parser.finish().single.usageEvents, hasLength(1));
  });
  test('fork cumulative counters use copied history only as a baseline', () {
    final parser = codex();
    parser.addLine(
      jsonEncode({
        'type': 'event_msg',
        'timestamp': '2026-08-31T23:00:00Z',
        'payload': {
          'type': 'token_count',
          'info': {'total_token_usage': usage(10000, 1000)},
        },
      }),
    );
    add(parser, 'event_msg', {
      'type': 'token_count',
      'info': {
        'total_token_usage': usage(10100, 1020),
        'last_token_usage': usage(100, 20),
      },
    });
    expect(parser.finish().single.inputTokens, 100);
    expect(parser.finish().single.outputTokens, 20);
  });
  test(
    'partial pricing and currency conversion remain separate from reported cost',
    () async {
      UsageEvent event(String id, DateTime date, String model) => UsageEvent(
        id: id,
        sessionId: 's',
        timestamp: date,
        provider: 'openai',
        model: model,
        contextInputTokens: 100,
        tokens: const TokenUsage(
          input: 100,
          output: 20,
          cachedInput: 50,
          cacheWrite: 0,
        ),
      );
      final metrics = const OpenCodeMetricsCalculator().calculate([
        sessionFromEvents(
          id: 's',
          harness: UsageHarness.codex,
          events: [
            event('a', start, 'gpt-6.1-sol'),
            event('b', start.add(const Duration(days: 1)), 'gpt-6.1-sol'),
            event('unknown', start, 'unknown-model'),
          ],
        ),
      ]);
      expect(metrics.totalCostUsd, 0);
      expect(metrics.harnessUsage[UsageHarness.codex]!.pricedEventCount, 2);
      expect(metrics.harnessUsage[UsageHarness.codex]!.eventCount, 3);
      expect(metrics.providerBreakdowns['openai']!.sessionCount, 1);
      final composer = MonetizedMetricsComposer(
        exchangeRateRepository: _Rates({
          start: 22,
          start.add(const Duration(days: 1)): 25,
        }),
      );
      final czk = await composer.compose(
        metrics: metrics,
        selectedCurrency: SupportedCurrency.czk,
      );
      expect(czk.displayTotalCost, 0);
      expect(
        czk.displayHarnessEstimates[UsageHarness.codex],
        closeTo(.000305 * 47, 1e-12),
      );
      final eur = await composer.compose(
        metrics: metrics,
        selectedCurrency: SupportedCurrency.eur,
      );
      expect(
        eur.displayHarnessEstimates[UsageHarness.codex],
        closeTo(.000305 * 47 / 25, 1e-12),
      );
      final missing = await MonetizedMetricsComposer(
        exchangeRateRepository: _Rates({}),
      ).compose(metrics: metrics, selectedCurrency: SupportedCurrency.czk);
      expect(missing.displayHarnessEstimates[UsageHarness.codex], isNull);
      expect(missing.baseMetrics.totalInputTokens, 300);
    },
  );

  test(
    'Claude consolidates content blocks and streaming revisions; subagents are counted once',
    () {
      final parser = HarnessTranscriptParser(UsageHarness.claudeCode);
      parser.addLine(jsonEncode(claude(output: 5)));
      parser.addLine(jsonEncode(claude()));
      parser.addLine(jsonEncode(claude()));
      parser.addLine(
        jsonEncode(claude(id: 'msg-agent', hour: 1)..['isSidechain'] = true),
      );
      final session = parser.finish().single;
      expect(session.requestCount, 2);
      expect(session.inputTokens, 340);
      expect(session.outputTokens, 20);
      expect(session.tokens.cachedInput, 100);
      expect(session.tokens.cacheWrite1h, 20);
      expect(session.tokens.reasoning, 10);
      final encoded = jsonEncode(
        session.usageEvents.map((e) => e.toJson()).toList(),
      );
      expect(encoded, isNot(contains('SECRET')));
      expect(encoded, isNot(contains('/private/project')));
      expect(encoded, isNot(contains('content')));
    },
  );
  test('malformed, synthetic and API errors never surface transcript data', () {
    final parser = HarnessTranscriptParser(UsageHarness.claudeCode);
    parser.addLine('{"prompt":"SECRET');
    parser.addLine(jsonEncode(claude()..['isApiErrorMessage'] = true));
    final synthetic = claude();
    (synthetic['message'] as Map)['model'] = '<synthetic>';
    parser.addLine(jsonEncode(synthetic));
    expect(parser.skippedRecords, 1);
    expect(parser.finish(), isEmpty);
    parser.addLine(jsonEncode(claude()));
    expect(parser.finish(), hasLength(1));
  });
  test(
    'Codex prefers response records over overlapping cumulative snapshots',
    () {
      final parser = codex();
      add(parser, 'token_usage_record', {
        'response_id': 'response-a',
        'thread_id': 'session-a',
        'usage': usage(100, 20, cached: 50),
        'thread_token_usage': usage(100, 20),
      });
      add(parser, 'event_msg', {
        'type': 'token_count',
        'info': {
          'total_token_usage': usage(100, 20, cached: 50),
          'last_token_usage': usage(100, 20, cached: 50),
        },
      });
      add(parser, 'event_msg', {
        'type': 'token_count',
        'info': {'total_token_usage': usage(100, 20, cached: 50)},
      });
      expect(parser.finish().single.inputTokens, 100);
      expect(parser.finish().single.requestCount, 1);
    },
  );
  test('Codex handles legacy deltas, model switching and counter resets', () {
    final parser = codex();
    add(parser, 'event_msg', {
      'type': 'token_count',
      'info': {
        'total_token_usage': usage(100, 20),
        'last_token_usage': usage(100, 20),
      },
    });
    add(parser, 'turn_context', {'model': 'unknown-model'});
    add(parser, 'event_msg', {
      'type': 'token_count',
      'info': {
        'total_token_usage': usage(150, 30),
        'last_token_usage': usage(50, 10),
      },
    }, minute: 2);
    add(parser, 'event_msg', {
      'type': 'token_count',
      'info': {
        'total_token_usage': usage(10, 2),
        'last_token_usage': usage(10, 2),
      },
    }, minute: 3);
    final session = parser.finish().single;
    expect(session.inputTokens, 160);
    expect(session.outputTokens, 32);
    expect(session.modelName, isNull);
    expect(session.usageEvents.map((e) => e.model).toSet(), {
      'gpt-6.1-sol',
      'unknown-model',
    });
  });
  test('Codex ignores copied fork history and foreign-thread responses', () {
    final parser = codex();
    add(parser, 'token_usage_record', {
      'response_id': 'parent',
      'thread_id': 'parent-thread',
      'usage': usage(9999, 9999),
    });
    parser.addLine(
      jsonEncode({
        'type': 'event_msg',
        'timestamp': '2026-08-31T00:00:00Z',
        'payload': {
          'type': 'token_count',
          'info': {'total_token_usage': usage(9999, 9999)},
        },
      }),
    );
    expect(parser.finish(), isEmpty);
  });
  test(
    'standard estimate accounts for reads, cache lifetimes and reasoning once',
    () {
      final parser = HarnessTranscriptParser(UsageHarness.claudeCode)
        ..addLine(jsonEncode(claude()));
      final event = parser.finish().single.usageEvents.single;
      final estimate = PricingConfig().estimate(event);
      expect(
        estimate.usd,
        closeTo((100 * 4 + 50 * .2 + 10 * 5 + 10 * 8 + 10 * 20) / 1e6, 1e-12),
      );
      expect(estimate.custom, isFalse);
    },
  );
  test(
    'unknown and missing token categories are unpriced; custom mappings and overrides work',
    () {
      final event = UsageEvent(
        id: 'e',
        sessionId: 's',
        timestamp: start,
        provider: 'openai',
        model: 'unmatched',
        tokens: const TokenUsage(
          input: 100,
          output: 20,
          cachedInput: 50,
          cacheWrite: 0,
        ),
      );
      expect(PricingConfig().estimate(event).usd, isNull);
      final config = PricingConfig(
        mappings: {'openai/unmatched': 'openai/gpt-6.1-sol'},
      );
      expect(
        config.estimate(event).usd,
        closeTo((50 * 2 + 50 * .1 + 20 * 10) / 1e6, 1e-12),
      );
      expect(config.estimate(event).custom, isTrue);
      final custom = PricingConfig(
        overrides: {
          'openai/unmatched': ApiRates(input: 1, output: 1, cachedInput: 0),
        },
      );
      expect(custom.estimate(event).usd, closeTo(70 / 1e6, 1e-12));
      expect(
        () => ApiRates(input: double.infinity, output: 1),
        throwsFormatException,
      );
      expect(() => ApiRates(input: -1, output: 1), throwsFormatException);
      final unknownCache = UsageEvent(
        id: 'e',
        sessionId: 's',
        timestamp: start,
        provider: 'openai',
        model: 'gpt-6.1-sol',
        tokens: const TokenUsage(input: 100, output: 20),
      );
      expect(PricingConfig().estimate(unknownCache).usd, isNull);
    },
  );
  test(
    'context-tier pricing uses per-request input, with disclosed missing-context fallback',
    () {
      UsageEvent event(int? context) => UsageEvent(
        id: 'e',
        sessionId: 's',
        timestamp: start,
        provider: 'openai',
        model: 'gpt-6.1-sol',
        contextInputTokens: context,
        tokens: const TokenUsage(
          input: 300000,
          output: 20000,
          cachedInput: 0,
          cacheWrite: 0,
        ),
      );
      expect(PricingConfig().estimate(event(300000)).usd, closeTo(1.5, 1e-12));
      expect(PricingConfig().estimate(event(null)).assumedShortContext, isTrue);
    },
  );
  test('event timestamps drive daily/hourly buckets and window selection', () {
    final parser = HarnessTranscriptParser(UsageHarness.claudeCode)
      ..addLine(jsonEncode(claude()))
      ..addLine(jsonEncode(claude(id: 'next-day', hour: 25)));
    final session = parser.finish().single;
    final metrics = const OpenCodeMetricsCalculator().calculate([session]);
    expect(metrics.totalSessionCount, 1);
    expect(metrics.dailyBreakdown.map((d) => d.inputTokens), [170, 170]);
    expect(metrics.hourlyBreakdown.map((d) => d.inputTokens), [170, 170]);
    expect(metrics.harnessUsage[UsageHarness.claudeCode]!.pricedEventCount, 2);
    final selected = selectSessionUsage(
      session,
      from: start.add(const Duration(days: 1)),
    )!;
    expect(selected.inputTokens, 170);
    expect(selected.usageEvents.single.model, 'claude-opus-5-5');
  });
}

class _Rates implements ExchangeRateRepository {
  _Rates(this.rates);
  final Map<DateTime, double> rates;
  @override
  Future<List<ExchangeRate>> readExchangeRatesForDate(DateTime date) async =>
      rates.containsKey(date)
      ? [
          ExchangeRate(
            currency: SupportedCurrency.usd,
            date: date,
            rateToCzk: rates[date]!,
          ),
          ExchangeRate(
            currency: SupportedCurrency.eur,
            date: date,
            rateToCzk: 25,
          ),
        ]
      : [];
  @override
  Future<void> writeExchangeRates(
    Iterable<ExchangeRate> rates, {
    DateTime? effectiveDate,
  }) async {}
}
