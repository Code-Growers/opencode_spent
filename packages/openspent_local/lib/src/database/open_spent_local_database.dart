import 'package:drift/drift.dart';

import 'open_spent_local_database_executor_native.dart'
    if (dart.library.html) 'open_spent_local_database_executor_web.dart'
    as local_database_executor;

part 'open_spent_local_database.g.dart';

@DataClassName('LocalExchangeRateRow')
class ExchangeRates extends Table {
  TextColumn get currencyCode => text().named('currency_code')();

  DateTimeColumn get effectiveDateUtc =>
      dateTime().named('effective_date_utc')();

  DateTimeColumn get sourceDateUtc => dateTime().named('source_date_utc')();

  RealColumn get rateToCzk => real().named('rate_to_czk')();

  @override
  String get tableName => 'exchange_rates';

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{
    currencyCode,
    effectiveDateUtc,
  };
}

@DataClassName('LocalOpenCodeSessionRow')
class OpenCodeSessions extends Table {
  TextColumn get id => text()();

  DateTimeColumn get createdAtUtc => dateTime().named('created_at_utc')();

  TextColumn get provider => text().nullable()();

  TextColumn get modelName => text().named('model_name').nullable()();

  IntColumn get inputTokens => integer().named('input_tokens').nullable()();

  IntColumn get outputTokens => integer().named('output_tokens').nullable()();

  RealColumn get totalCostUsd => real().named('total_cost_usd').nullable()();

  IntColumn get requestCount => integer().named('request_count').nullable()();

  IntColumn get toolCallCount =>
      integer().named('tool_call_count').nullable()();

  IntColumn get responseCount => integer().named('response_count').nullable()();

  IntColumn get totalResponseTimeMs =>
      integer().named('total_response_time_ms').nullable()();

  TextColumn get subagentCategory =>
      text().named('subagent_category').nullable()();

  TextColumn get usageSlicesJson =>
      text().named('usage_slices_json').nullable()();

  @override
  String get tableName => 'open_code_sessions';

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DriftDatabase(tables: <Type>[ExchangeRates, OpenCodeSessions])
final class OpenSpentLocalDatabase extends _$OpenSpentLocalDatabase {
  OpenSpentLocalDatabase(super.e);

  static const String exchangeRatesTable = 'exchange_rates';
  static const String openCodeSessionsTable = 'open_code_sessions';

  factory OpenSpentLocalDatabase.inMemory() {
    return OpenSpentLocalDatabase(
      local_database_executor.createInMemoryOpenSpentLocalDatabaseExecutor(),
    );
  }

  factory OpenSpentLocalDatabase.filePath(String path) {
    return OpenSpentLocalDatabase(
      local_database_executor.createFileOpenSpentLocalDatabaseExecutor(path),
    );
  }

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator migrator) async {
      await migrator.createTable(exchangeRates);
      await migrator.createTable(openCodeSessions);
    },
    onUpgrade: (Migrator _, int from, int to) async {
      if (from < 2) {
        await customStatement('''
              CREATE TABLE ${exchangeRatesTable}_next (
                currency_code TEXT NOT NULL,
                effective_date_utc INTEGER NOT NULL,
                source_date_utc INTEGER NOT NULL,
                rate_to_czk REAL NOT NULL,
                PRIMARY KEY (currency_code, effective_date_utc)
              )
            ''');

        await customStatement('''
              INSERT INTO ${exchangeRatesTable}_next (
                currency_code,
                effective_date_utc,
                source_date_utc,
                rate_to_czk
              )
              SELECT
                currency_code,
                effective_date_utc,
                effective_date_utc,
                rate_to_czk
              FROM $exchangeRatesTable
            ''');

        await customStatement('DROP TABLE $exchangeRatesTable');
        await customStatement(
          'ALTER TABLE ${exchangeRatesTable}_next RENAME TO $exchangeRatesTable',
        );
      }

      if (from < 3) {
        await customStatement(
          'ALTER TABLE $openCodeSessionsTable ADD COLUMN provider TEXT',
        );
        await customStatement(
          'ALTER TABLE $openCodeSessionsTable ADD COLUMN request_count INTEGER',
        );
        await customStatement(
          'ALTER TABLE $openCodeSessionsTable ADD COLUMN tool_call_count INTEGER',
        );
        await customStatement(
          'ALTER TABLE $openCodeSessionsTable ADD COLUMN response_count INTEGER',
        );
        await customStatement(
          'ALTER TABLE $openCodeSessionsTable ADD COLUMN total_response_time_ms INTEGER',
        );
        await customStatement(
          'ALTER TABLE $openCodeSessionsTable ADD COLUMN usage_slices_json TEXT',
        );
      }
    },
  );
}
