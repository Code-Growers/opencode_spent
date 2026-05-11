import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openspent_core/openspent_core.dart';
import 'package:openspent_local/openspent_local.dart';

void main() {
  group('LocalOpenCodeSessionRepository', () {
    test('writes and reads deterministic session storage', () async {
      final database = OpenSpentLocalDatabase.inMemory();
      addTearDown(database.close);

      final repository = LocalOpenCodeSessionRepository(database);

      await repository.writeSessions(<OpenCodeSession>[
        OpenCodeSession(
          id: 'session-b',
          createdAt: DateTime.utc(2026, 5, 3, 9),
          inputTokens: 20,
          outputTokens: 4,
          totalCostUsd: 0.5,
          subagentCategory: 'deep',
        ),
        OpenCodeSession(
          id: 'session-a',
          createdAt: DateTime.utc(2026, 5, 2, 9),
          modelName: 'gpt-5.4',
          inputTokens: 10,
          outputTokens: 2,
          totalCostUsd: 0.25,
          subagentCategory: 'quick',
        ),
        OpenCodeSession(
          id: 'session-a',
          createdAt: DateTime.utc(2026, 5, 4, 12),
          modelName: 'gpt-5.4',
          inputTokens: 99,
          outputTokens: 99,
          totalCostUsd: 9.99,
        ),
      ]);

      expect(await repository.readSessions(), <OpenCodeSession>[
        OpenCodeSession(
          id: 'session-b',
          createdAt: DateTime.utc(2026, 5, 3, 9),
          inputTokens: 20,
          outputTokens: 4,
          totalCostUsd: 0.5,
          subagentCategory: 'deep',
        ),
        OpenCodeSession(
          id: 'session-a',
          createdAt: DateTime.utc(2026, 5, 4, 12),
          modelName: 'gpt-5.4',
          inputTokens: 99,
          outputTokens: 99,
          totalCostUsd: 9.99,
        ),
      ]);
    });

    test(
      'coerces unsupported subagent categories to null on persistence',
      () async {
        final database = OpenSpentLocalDatabase.inMemory();
        addTearDown(database.close);

        final repository = LocalOpenCodeSessionRepository(database);

        await repository.writeSessions(<OpenCodeSession>[
          OpenCodeSession(
            id: 'session-x',
            createdAt: DateTime.utc(2026, 5, 3, 9),
            subagentCategory: 'unknown-category',
          ),
        ]);

        final sessions = await repository.readSessions();
        expect(sessions.single.subagentCategory, isNull);
      },
    );
  });

  group('LocalExchangeRateRepository', () {
    test(
      'writes exchange rates and reads them by normalized UTC date',
      () async {
        final database = OpenSpentLocalDatabase.inMemory();
        addTearDown(database.close);

        final repository = LocalExchangeRateRepository(database);

        await repository.writeExchangeRates(<ExchangeRate>[
          ExchangeRate(
            currency: SupportedCurrency.usd,
            date: DateTime.parse('2026-05-02T23:30:00-02:00'),
            rateToCzk: 21.93,
          ),
          ExchangeRate(
            currency: SupportedCurrency.czk,
            date: DateTime.utc(2026, 5, 3),
            rateToCzk: 1,
          ),
        ]);

        expect(
          await repository.readExchangeRatesForDate(
            DateTime.utc(2026, 5, 3, 12),
          ),
          <ExchangeRate>[
            ExchangeRate(
              currency: SupportedCurrency.czk,
              date: DateTime.utc(2026, 5, 3),
              rateToCzk: 1,
            ),
            ExchangeRate(
              currency: SupportedCurrency.usd,
              date: DateTime.parse('2026-05-02T23:30:00-02:00'),
              rateToCzk: 21.93,
            ),
          ],
        );
      },
    );

    test('migrates legacy schema-v1 exchange rates to schema v2', () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'openspent_local_',
      );
      final databaseFile = File('${tempDirectory.path}/openspent_local.sqlite');

      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final legacyDatabase = _LegacyOpenSpentLocalDatabase(
        NativeDatabase.createInBackground(databaseFile),
      );

      await legacyDatabase.customInsert(
        '''
          INSERT INTO ${OpenSpentLocalDatabase.exchangeRatesTable}
            (currency_code, effective_date_utc, rate_to_czk)
          VALUES (?, ?, ?)
        ''',
        variables: <Variable<Object>>[
          Variable.withString(SupportedCurrency.usd.code),
          Variable.withDateTime(DateTime.utc(2026, 5, 3)),
          Variable.withReal(21.93),
        ],
      );
      await legacyDatabase.close();

      final database = OpenSpentLocalDatabase.file(databaseFile);
      addTearDown(database.close);

      final repository = LocalExchangeRateRepository(database);

      expect(
        await repository.readExchangeRatesForDate(DateTime.utc(2026, 5, 3, 12)),
        <ExchangeRate>[
          ExchangeRate(
            currency: SupportedCurrency.usd,
            date: DateTime.utc(2026, 5, 3),
            rateToCzk: 21.93,
          ),
        ],
      );
    });
  });

  group('LocalMetricsRepository', () {
    test(
      'derives metrics from stored sessions using the core calculator',
      () async {
        final database = OpenSpentLocalDatabase.inMemory();
        addTearDown(database.close);

        final sessions = LocalOpenCodeSessionRepository(database);
        final repository = LocalMetricsRepository(sessions);

        await sessions.writeSessions(<OpenCodeSession>[
          OpenCodeSession(
            id: 'session-1',
            createdAt: DateTime.utc(2026, 5, 2, 8),
            inputTokens: 10,
            outputTokens: 3,
            totalCostUsd: 0.2,
          ),
          OpenCodeSession(
            id: 'session-2',
            createdAt: DateTime.utc(2026, 5, 3, 8),
            inputTokens: 20,
            outputTokens: 4,
            totalCostUsd: 0.4,
          ),
          OpenCodeSession(
            id: 'session-3',
            createdAt: DateTime.utc(2026, 5, 4, 8),
            inputTokens: 30,
            outputTokens: 5,
            totalCostUsd: 0.6,
          ),
        ]);

        final metrics = await repository.readMetrics(
          from: DateTime.utc(2026, 5, 3),
          to: DateTime.utc(2026, 5, 4, 23, 59, 59, 999),
        );

        expect(metrics.totalSessionCount, 2);
        expect(metrics.totalInputTokens, 50);
        expect(metrics.totalOutputTokens, 9);
        expect(metrics.totalCostUsd, closeTo(1.0, 0.000001));
        expect(metrics.dailyBreakdown, <DailyMetrics>[
          DailyMetrics(
            date: DateTime.utc(2026, 5, 3),
            sessionCount: 1,
            inputTokens: 20,
            outputTokens: 4,
            totalCostUsd: 0.4,
          ),
          DailyMetrics(
            date: DateTime.utc(2026, 5, 4),
            sessionCount: 1,
            inputTokens: 30,
            outputTokens: 5,
            totalCostUsd: 0.6,
          ),
        ]);
        expect(metrics.hourlyBreakdown, <HourlyMetrics>[
          HourlyMetrics(
            hour: DateTime.utc(2026, 5, 3, 8),
            sessionCount: 1,
            inputTokens: 20,
            outputTokens: 4,
            totalCostUsd: 0.4,
          ),
          HourlyMetrics(
            hour: DateTime.utc(2026, 5, 4, 8),
            sessionCount: 1,
            inputTokens: 30,
            outputTokens: 5,
            totalCostUsd: 0.6,
          ),
        ]);
      },
    );

    test(
      'keeps hourly buckets correct after session filtering excludes adjacent sessions',
      () async {
        final database = OpenSpentLocalDatabase.inMemory();
        addTearDown(database.close);

        final sessions = LocalOpenCodeSessionRepository(database);
        final repository = LocalMetricsRepository(sessions);

        await sessions.writeSessions(<OpenCodeSession>[
          OpenCodeSession(
            id: 'session-1',
            createdAt: DateTime.utc(2026, 5, 3, 7, 59),
            inputTokens: 5,
            outputTokens: 1,
            totalCostUsd: 0.1,
          ),
          OpenCodeSession(
            id: 'session-2',
            createdAt: DateTime.utc(2026, 5, 3, 8, 15),
            inputTokens: 10,
            outputTokens: 2,
            totalCostUsd: 0.2,
          ),
          OpenCodeSession(
            id: 'session-3',
            createdAt: DateTime.utc(2026, 5, 3, 8, 45),
            inputTokens: 20,
            outputTokens: 3,
            totalCostUsd: 0.3,
          ),
          OpenCodeSession(
            id: 'session-4',
            createdAt: DateTime.utc(2026, 5, 3, 9, 5),
            inputTokens: 30,
            outputTokens: 4,
            totalCostUsd: 0.4,
          ),
          OpenCodeSession(
            id: 'session-5',
            createdAt: DateTime.utc(2026, 5, 3, 9, 31),
            inputTokens: 40,
            outputTokens: 5,
            totalCostUsd: 0.5,
          ),
        ]);

        final metrics = await repository.readMetrics(
          from: DateTime.utc(2026, 5, 3, 8),
          to: DateTime.utc(2026, 5, 3, 9, 30),
        );

        expect(metrics.totalSessionCount, 3);
        expect(metrics.totalInputTokens, 60);
        expect(metrics.totalOutputTokens, 9);
        expect(metrics.totalCostUsd, closeTo(0.9, 0.000001));
        expect(metrics.dailyBreakdown, <DailyMetrics>[
          DailyMetrics(
            date: DateTime.utc(2026, 5, 3),
            sessionCount: 3,
            inputTokens: 60,
            outputTokens: 9,
            totalCostUsd: 0.9,
          ),
        ]);
        expect(metrics.hourlyBreakdown, <HourlyMetrics>[
          HourlyMetrics(
            hour: DateTime.utc(2026, 5, 3, 8),
            sessionCount: 2,
            inputTokens: 30,
            outputTokens: 5,
            totalCostUsd: 0.5,
          ),
          HourlyMetrics(
            hour: DateTime.utc(2026, 5, 3, 9),
            sessionCount: 1,
            inputTokens: 30,
            outputTokens: 4,
            totalCostUsd: 0.4,
          ),
        ]);
      },
    );
  });
}

final class _LegacyOpenSpentLocalDatabase extends GeneratedDatabase {
  _LegacyOpenSpentLocalDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      const <TableInfo<Table, Object?>>[];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator _) async {
      await customStatement('''
            CREATE TABLE ${OpenSpentLocalDatabase.exchangeRatesTable} (
              currency_code TEXT NOT NULL,
              effective_date_utc INTEGER NOT NULL,
              rate_to_czk REAL NOT NULL,
              PRIMARY KEY (currency_code, effective_date_utc)
            )
          ''');

      await customStatement('''
            CREATE TABLE ${OpenSpentLocalDatabase.openCodeSessionsTable} (
              id TEXT NOT NULL PRIMARY KEY,
              created_at_utc INTEGER NOT NULL,
              model_name TEXT,
              input_tokens INTEGER,
              output_tokens INTEGER,
              total_cost_usd REAL,
              subagent_category TEXT
            )
          ''');
    },
  );
}
