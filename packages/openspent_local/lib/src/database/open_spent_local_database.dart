import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

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

  TextColumn get modelName => text().named('model_name').nullable()();

  IntColumn get inputTokens => integer().named('input_tokens').nullable()();

  IntColumn get outputTokens => integer().named('output_tokens').nullable()();

  RealColumn get totalCostUsd => real().named('total_cost_usd').nullable()();

  TextColumn get subagentCategory =>
      text().named('subagent_category').nullable()();

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
    return OpenSpentLocalDatabase(NativeDatabase.memory());
  }

  factory OpenSpentLocalDatabase.file(File file) {
    return OpenSpentLocalDatabase(NativeDatabase.createInBackground(file));
  }

  @override
  int get schemaVersion => 2;

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
    },
  );
}
