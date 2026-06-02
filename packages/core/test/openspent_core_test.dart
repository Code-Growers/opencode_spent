import 'dart:convert';

import 'package:openspent_core/openspent_core.dart';
import 'package:test/test.dart';

void main() {
  group('OpenSpentInfo', () {
    test('exposes the expected privacy defaults', () {
      expect(OpenSpentInfo.productName, 'OpenSpent');
      expect(OpenSpentInfo.isLocalOnly, isTrue);
      expect(
        OpenSpentInfo.persistedMetadataAllowlist,
        unorderedEquals(<String>[
          'provider',
          'modelName',
          'inputTokens',
          'outputTokens',
          'totalCostUsd',
          'requestCount',
          'toolCallCount',
          'responseCount',
          'totalResponseTimeMs',
          'createdAt',
          'subagentCategory',
          'usageSlices',
        ]),
      );
      expect(
        OpenSpentInfo.sensitiveFieldsDenylist,
        unorderedEquals(<String>[
          'prompt',
          'state.input',
          'state.output',
          'state.error',
        ]),
      );
      expect(
        OpenSpentInfo.ingestedSessionFieldAllowlist,
        unorderedEquals(<String>[
          'id',
          'provider',
          'modelName',
          'inputTokens',
          'outputTokens',
          'totalCostUsd',
          'requestCount',
          'toolCallCount',
          'responseCount',
          'totalResponseTimeMs',
          'createdAt',
          'subagentCategory',
          'usageSlices',
        ]),
      );
      expect(
        OpenSpentInfo.supportedSubagentCategories,
        unorderedEquals(<String>[
          'visual-engineering',
          'artistry',
          'ultrabrain',
          'deep',
          'quick',
          'unspecified-low',
          'unspecified-high',
          'writing',
        ]),
      );
    });
  });

  group('OpenCodeSettings', () {
    test('generates Basic Auth for https targets with credentials', () {
      final settings = OpenCodeSettings(
        selectedCurrency: SupportedCurrency.usd,
        openCodeServerUrl: Uri.parse('https://example.com:4096'),
        openCodeServerUsername: 'alice',
        openCodeServerPassword: 'secret',
      );

      final credentials = base64Encode(utf8.encode('alice:secret'));
      expect(settings.openCodeServerAuthorizationHeader, 'Basic $credentials');
    });

    test('generates Basic Auth for loopback http targets with credentials', () {
      final loopbackUrls = <String>[
        'http://localhost:4096',
        'http://127.0.0.1:4096',
        'http://[::1]:4096',
      ];

      for (final url in loopbackUrls) {
        final settings = OpenCodeSettings(
          selectedCurrency: SupportedCurrency.usd,
          openCodeServerUrl: Uri.parse(url),
          openCodeServerPassword: 'secret',
        );

        expect(
          settings.openCodeServerAuthorizationHeader,
          startsWith('Basic '),
          reason: 'Expected loopback URL $url to allow Basic Auth.',
        );
      }
    });

    test('does not generate Basic Auth for non-loopback http targets', () {
      final settings = OpenCodeSettings(
        selectedCurrency: SupportedCurrency.usd,
        openCodeServerUrl: Uri.parse('http://example.com:4096'),
        openCodeServerUsername: 'alice',
        openCodeServerPassword: 'secret',
      );

      expect(settings.openCodeServerAuthorizationHeader, isNull);
    });
  });

  group('CnbExchangeRateParser', () {
    test('parses supported rates, normalizes decimals, and adds CZK', () {
      const parser = CnbExchangeRateParser();
      final rates = parser.parse(
        '02.05.2026 #84\n'
        'země|měna|množství|kód|kurz\n'
        'USA|dolar|1|USD|21,930\n'
        'Japonsko|jen|100|JPY|15,123\n',
      );

      expect(rates, hasLength(2));

      final usd = rates.firstWhere(
        (rate) => rate.currency == SupportedCurrency.usd,
      );
      final czk = rates.firstWhere(
        (rate) => rate.currency == SupportedCurrency.czk,
      );

      expect(usd.date, DateTime.utc(2026, 5, 2));
      expect(usd.rateToCzk, closeTo(21.93, 0.000001));
      expect(czk.date, DateTime.utc(2026, 5, 2));
      expect(czk.rateToCzk, 1.0);
    });

    test('parses current English ČNB header format', () {
      const parser = CnbExchangeRateParser();
      final rates = parser.parse(
        '01 Jun 2026 #103\n'
        'Country|Currency|Amount|Code|Rate\n'
        'EMU|euro|1|EUR|24.290\n'
        'United States|dollar|1|USD|21.405\n',
      );

      final eur = rates.firstWhere(
        (rate) => rate.currency == SupportedCurrency.eur,
      );
      final usd = rates.firstWhere(
        (rate) => rate.currency == SupportedCurrency.usd,
      );
      final czk = rates.firstWhere(
        (rate) => rate.currency == SupportedCurrency.czk,
      );

      expect(eur.date, DateTime.utc(2026, 6, 1));
      expect(eur.rateToCzk, closeTo(24.29, 0.000001));
      expect(usd.date, DateTime.utc(2026, 6, 1));
      expect(usd.rateToCzk, closeTo(21.405, 0.000001));
      expect(czk.date, DateTime.utc(2026, 6, 1));
      expect(czk.rateToCzk, 1.0);
    });

    test('divides rates by amount for quoted units above one', () {
      const parser = CnbExchangeRateParser();
      final rates = parser.parse(
        '02.05.2026 #84\n'
        'země|měna|množství|kód|kurz\n'
        'Spojené státy|dolar|100|USD|2 193,000\n',
      );

      final usd = rates.firstWhere(
        (rate) => rate.currency == SupportedCurrency.usd,
      );

      expect(usd.rateToCzk, closeTo(21.93, 0.000001));
    });

    test('fails for invalid calendar dates in the header', () {
      const parser = CnbExchangeRateParser();

      expect(
        () => parser.parse(
          '31.02.2026 #84\n'
          'země|měna|množství|kód|kurz\n'
          'USA|dolar|1|USD|21,930\n',
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Invalid ČNB calendar date: 31.02.2026 #84',
          ),
        ),
      );
    });

    test('rejects non-positive normalized rates', () {
      const parser = CnbExchangeRateParser();

      expect(
        () => parser.parse(
          '02.05.2026 #84\n'
          'země|měna|množství|kód|kurz\n'
          'USA|dolar|1|USD|0,000\n',
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Invalid ČNB rate in row: USA|dolar|1|USD|0,000',
          ),
        ),
      );
    });
  });

  group('OpenCodeSessionJsonParser', () {
    test('parses top-level sessions and sanitizes unsupported fields', () {
      const parser = OpenCodeSessionJsonParser();
      final sessions = parser.parse('''
[
  {
    "id": "session-1",
    "createdAt": "2026-05-02T10:15:00Z",
    "modelName": "gpt-5.4",
    "inputTokens": 120,
    "outputTokens": 30,
    "totalCostUsd": 0.42,
    "subagentCategory": "quick",
    "prompt": "must not be preserved",
    "state": {
      "input": "hidden",
      "output": "hidden",
      "error": "hidden"
    },
    "unknown": "ignored"
  },
  {
    "id": "session-2",
    "createdAt": "2026-05-02T11:00:00Z",
    "subagentCategory": "secret-category"
  }
]
''');

      expect(sessions, hasLength(2));

      expect(sessions.first.id, 'session-1');
      expect(sessions.first.modelName, 'gpt-5.4');
      expect(sessions.first.inputTokens, 120);
      expect(sessions.first.outputTokens, 30);
      expect(sessions.first.totalCostUsd, 0.42);
      expect(sessions.first.createdAt, DateTime.utc(2026, 5, 2, 10, 15));
      expect(sessions.first.subagentCategory, 'quick');
      expect(sessions.last.subagentCategory, isNull);
    });

    test(
      'reads supported fields from metadata when top-level fields are absent',
      () {
        const parser = OpenCodeSessionJsonParser();
        final sessions = parser.parse('''
{
  "sessions": [
    {
      "metadata": {
        "id": "session-3",
        "modelName": "o4-mini",
        "inputTokens": "11",
        "outputTokens": 4,
        "totalCostUsd": "0.13",
        "createdAt": "2026-05-03T00:30:00+02:00",
        "subagentCategory": "writing"
      },
      "prompt": "ignored"
    }
  ]
}
''');

        expect(sessions, hasLength(1));
        expect(sessions.single.id, 'session-3');
        expect(sessions.single.modelName, 'o4-mini');
        expect(sessions.single.inputTokens, 11);
        expect(sessions.single.outputTokens, 4);
        expect(sessions.single.totalCostUsd, 0.13);
        expect(sessions.single.createdAt, DateTime.utc(2026, 5, 2, 22, 30));
        expect(sessions.single.subagentCategory, 'writing');
      },
    );

    test('fails clearly for unsupported top-level JSON shapes', () {
      const parser = OpenCodeSessionJsonParser();

      expect(
        () => parser.parse('{"unexpected":true}'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Expected a top-level JSON list or an object with a sessions list.',
          ),
        ),
      );
    });

    test('fails for invalid createdAt calendar dates', () {
      const parser = OpenCodeSessionJsonParser();

      expect(
        () => parser.parse('''
[
  {
    "id": "session-1",
    "createdAt": "2026-02-30T10:15:00Z"
  }
]
'''),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Invalid createdAt value: 2026-02-30T10:15:00Z',
          ),
        ),
      );
    });

    test('rejects negative or non-finite numeric values', () {
      const parser = OpenCodeSessionJsonParser();

      expect(
        () => parser.parse('''
[
  {
    "id": "session-1",
    "createdAt": "2026-05-02T10:15:00Z",
    "inputTokens": -1
  }
]
'''),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Expected inputTokens to be a non-negative integer.',
          ),
        ),
      );

      expect(
        () => parser.parse('''
[
  {
    "id": "session-2",
    "createdAt": "2026-05-02T10:15:00Z",
    "totalCostUsd": "NaN"
  }
]
'''),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Expected totalCostUsd to be a non-negative number.',
          ),
        ),
      );
    });
  });

  group('OpenCodeMetricsCalculator', () {
    test('aggregates totals and daily metrics deterministically in UTC', () {
      const calculator = OpenCodeMetricsCalculator();
      final metrics = calculator.calculate(<OpenCodeSession>[
        OpenCodeSession(
          id: 'a',
          createdAt: DateTime.parse('2026-05-02T23:15:00-02:00'),
          inputTokens: 10,
          outputTokens: 5,
          totalCostUsd: 0.25,
          subagentCategory: 'quick',
        ),
        OpenCodeSession(
          id: 'b',
          createdAt: DateTime.parse('2026-05-03T09:00:00Z'),
          inputTokens: 20,
          outputTokens: 6,
          totalCostUsd: 0.50,
          subagentCategory: 'deep',
        ),
        OpenCodeSession(
          id: 'c',
          createdAt: DateTime.parse('2026-05-04T00:05:00Z'),
          inputTokens: null,
          outputTokens: 7,
          totalCostUsd: null,
        ),
      ]);

      expect(metrics.totalSessionCount, 3);
      expect(metrics.totalInputTokens, 30);
      expect(metrics.totalOutputTokens, 18);
      expect(metrics.totalCostUsd, closeTo(0.75, 0.000001));
      expect(metrics.dailyBreakdown, hasLength(2));

      expect(metrics.dailyBreakdown.first.date, DateTime.utc(2026, 5, 3));
      expect(metrics.dailyBreakdown.first.sessionCount, 2);
      expect(metrics.dailyBreakdown.first.inputTokens, 30);
      expect(metrics.dailyBreakdown.first.outputTokens, 11);
      expect(
        metrics.dailyBreakdown.first.totalCostUsd,
        closeTo(0.75, 0.000001),
      );

      expect(metrics.dailyBreakdown.last.date, DateTime.utc(2026, 5, 4));
      expect(metrics.dailyBreakdown.last.sessionCount, 1);
      expect(metrics.dailyBreakdown.last.inputTokens, 0);
      expect(metrics.dailyBreakdown.last.outputTokens, 7);
      expect(metrics.dailyBreakdown.last.totalCostUsd, 0);
      expect(metrics.hourlyBreakdown, <HourlyMetrics>[
        HourlyMetrics(
          hour: DateTime.utc(2026, 5, 3, 1),
          sessionCount: 1,
          inputTokens: 10,
          outputTokens: 5,
          totalCostUsd: 0.25,
        ),
        HourlyMetrics(
          hour: DateTime.utc(2026, 5, 3, 9),
          sessionCount: 1,
          inputTokens: 20,
          outputTokens: 6,
          totalCostUsd: 0.50,
        ),
        HourlyMetrics(
          hour: DateTime.utc(2026, 5, 4, 0),
          sessionCount: 1,
          inputTokens: 0,
          outputTokens: 7,
          totalCostUsd: 0,
        ),
      ]);
    });

    test(
      'normalizes hourly buckets to UTC with offset-aware timestamps and preserves daily totals',
      () {
        const calculator = OpenCodeMetricsCalculator();
        final metrics = calculator.calculate(<OpenCodeSession>[
          OpenCodeSession(
            id: 'a',
            createdAt: DateTime.parse('2026-05-03T03:15:00+02:00'),
            inputTokens: 10,
            outputTokens: 2,
            totalCostUsd: 0.10,
          ),
          OpenCodeSession(
            id: 'b',
            createdAt: DateTime.parse('2026-05-03T01:45:00Z'),
            inputTokens: 20,
            outputTokens: 3,
            totalCostUsd: 0.20,
          ),
          OpenCodeSession(
            id: 'c',
            createdAt: DateTime.parse('2026-05-03T04:05:00+02:00'),
            inputTokens: 30,
            outputTokens: 4,
            totalCostUsd: 0.30,
          ),
        ]);

        expect(metrics.dailyBreakdown, hasLength(1));
        expect(metrics.dailyBreakdown.single.date, DateTime.utc(2026, 5, 3));
        expect(metrics.dailyBreakdown.single.sessionCount, 3);
        expect(metrics.dailyBreakdown.single.inputTokens, 60);
        expect(metrics.dailyBreakdown.single.outputTokens, 9);
        expect(
          metrics.dailyBreakdown.single.totalCostUsd,
          closeTo(0.60, 0.000001),
        );
        expect(metrics.hourlyBreakdown, hasLength(2));
        expect(metrics.hourlyBreakdown.first.hour, DateTime.utc(2026, 5, 3, 1));
        expect(metrics.hourlyBreakdown.first.sessionCount, 2);
        expect(metrics.hourlyBreakdown.first.inputTokens, 30);
        expect(metrics.hourlyBreakdown.first.outputTokens, 5);
        expect(
          metrics.hourlyBreakdown.first.totalCostUsd,
          closeTo(0.30, 0.000001),
        );
        expect(metrics.hourlyBreakdown.last.hour, DateTime.utc(2026, 5, 3, 2));
        expect(metrics.hourlyBreakdown.last.sessionCount, 1);
        expect(metrics.hourlyBreakdown.last.inputTokens, 30);
        expect(metrics.hourlyBreakdown.last.outputTokens, 4);
        expect(
          metrics.hourlyBreakdown.last.totalCostUsd,
          closeTo(0.30, 0.000001),
        );

        final hourlyInputTotal = metrics.hourlyBreakdown.fold<int>(
          0,
          (sum, hourly) => sum + hourly.inputTokens,
        );
        final hourlyOutputTotal = metrics.hourlyBreakdown.fold<int>(
          0,
          (sum, hourly) => sum + hourly.outputTokens,
        );
        final hourlyCostTotal = metrics.hourlyBreakdown.fold<double>(
          0,
          (sum, hourly) => sum + hourly.totalCostUsd,
        );

        expect(hourlyInputTotal, metrics.dailyBreakdown.single.inputTokens);
        expect(hourlyOutputTotal, metrics.dailyBreakdown.single.outputTokens);
        expect(
          hourlyCostTotal,
          closeTo(metrics.dailyBreakdown.single.totalCostUsd, 0.000001),
        );
      },
    );

    test(
      'adds per-model daily breakdowns while preserving overall totals and daily metrics',
      () {
        const calculator = OpenCodeMetricsCalculator();
        final metrics = calculator.calculate(<OpenCodeSession>[
          OpenCodeSession(
            id: 'a',
            createdAt: DateTime.parse('2026-05-02T23:15:00-02:00'),
            modelName: 'gpt-5.4',
            inputTokens: 10,
            outputTokens: 5,
            totalCostUsd: 0.25,
          ),
          OpenCodeSession(
            id: 'b',
            createdAt: DateTime.parse('2026-05-03T09:00:00Z'),
            modelName: 'gpt-5.4',
            inputTokens: 20,
            outputTokens: 6,
            totalCostUsd: 0.50,
          ),
          OpenCodeSession(
            id: 'c',
            createdAt: DateTime.parse('2026-05-03T11:00:00Z'),
            modelName: 'o4-mini',
            inputTokens: 7,
            outputTokens: 3,
            totalCostUsd: 0.10,
          ),
          OpenCodeSession(
            id: 'd',
            createdAt: DateTime.parse('2026-05-04T00:05:00Z'),
            modelName: 'o4-mini',
            inputTokens: 12,
            outputTokens: 4,
            totalCostUsd: 0.20,
          ),
          OpenCodeSession(
            id: 'e',
            createdAt: DateTime.parse('2026-05-04T04:00:00Z'),
            modelName: '   ',
            inputTokens: 1,
            outputTokens: 1,
            totalCostUsd: 0.05,
          ),
          OpenCodeSession(
            id: 'f',
            createdAt: DateTime.parse('2026-05-04T07:00:00Z'),
            inputTokens: 2,
            outputTokens: 2,
            totalCostUsd: 0.07,
          ),
        ]);

        expect(metrics.totalSessionCount, 6);
        expect(metrics.totalInputTokens, 52);
        expect(metrics.totalOutputTokens, 21);
        expect(metrics.totalCostUsd, closeTo(1.17, 0.000001));
        expect(metrics.dailyBreakdown, <DailyMetrics>[
          DailyMetrics(
            date: DateTime.utc(2026, 5, 3),
            sessionCount: 3,
            inputTokens: 37,
            outputTokens: 14,
            totalCostUsd: 0.85,
          ),
          DailyMetrics(
            date: DateTime.utc(2026, 5, 4),
            sessionCount: 3,
            inputTokens: 15,
            outputTokens: 7,
            totalCostUsd: 0.32,
          ),
        ]);

        expect(metrics.perModelDailyBreakdown.keys, <String>[
          'gpt-5.4',
          'o4-mini',
        ]);
        expect(metrics.perModelDailyBreakdown['gpt-5.4'], <DailyMetrics>[
          DailyMetrics(
            date: DateTime.utc(2026, 5, 3),
            sessionCount: 2,
            inputTokens: 30,
            outputTokens: 11,
            totalCostUsd: 0.75,
          ),
        ]);
        expect(metrics.perModelDailyBreakdown['o4-mini'], <DailyMetrics>[
          DailyMetrics(
            date: DateTime.utc(2026, 5, 3),
            sessionCount: 1,
            inputTokens: 7,
            outputTokens: 3,
            totalCostUsd: 0.10,
          ),
          DailyMetrics(
            date: DateTime.utc(2026, 5, 4),
            sessionCount: 1,
            inputTokens: 12,
            outputTokens: 4,
            totalCostUsd: 0.20,
          ),
        ]);
        expect(metrics.perModelDailyBreakdown.containsKey(''), isFalse);

        expect(metrics.perModelHourlyBreakdown.keys, <String>[
          'gpt-5.4',
          'o4-mini',
        ]);
        expect(metrics.perModelHourlyBreakdown['gpt-5.4'], <HourlyMetrics>[
          HourlyMetrics(
            hour: DateTime.utc(2026, 5, 3, 1),
            sessionCount: 1,
            inputTokens: 10,
            outputTokens: 5,
            totalCostUsd: 0.25,
          ),
          HourlyMetrics(
            hour: DateTime.utc(2026, 5, 3, 9),
            sessionCount: 1,
            inputTokens: 20,
            outputTokens: 6,
            totalCostUsd: 0.50,
          ),
        ]);
        expect(metrics.perModelHourlyBreakdown['o4-mini'], <HourlyMetrics>[
          HourlyMetrics(
            hour: DateTime.utc(2026, 5, 3, 11),
            sessionCount: 1,
            inputTokens: 7,
            outputTokens: 3,
            totalCostUsd: 0.10,
          ),
          HourlyMetrics(
            hour: DateTime.utc(2026, 5, 4, 0),
            sessionCount: 1,
            inputTokens: 12,
            outputTokens: 4,
            totalCostUsd: 0.20,
          ),
        ]);
      },
    );
  });
}
