import 'package:drift/drift.dart';
import 'package:openspent_core/openspent_core.dart';

import '../database/open_spent_local_database.dart';

final class LocalExchangeRateRepository implements ExchangeRateRepository {
  LocalExchangeRateRepository(this._database);

  final OpenSpentLocalDatabase _database;

  @override
  Future<List<ExchangeRate>> readExchangeRatesForDate(DateTime date) async {
    final normalizedTargetDate = _normalizeDate(date);
    final rows =
        await (_database.select(_database.exchangeRates)
              ..where(
                (ExchangeRates rates) =>
                    rates.effectiveDateUtc.equals(normalizedTargetDate),
              )
              ..orderBy(<OrderingTerm Function(ExchangeRates)>[
                (ExchangeRates rates) => OrderingTerm.asc(rates.currencyCode),
              ]))
            .get();

    return rows.map(_mapRow).toList(growable: false);
  }

  @override
  Future<void> writeExchangeRates(
    Iterable<ExchangeRate> rates, {
    DateTime? effectiveDate,
  }) async {
    if (rates.isEmpty) {
      return;
    }

    final normalizedEffectiveDate = effectiveDate == null
        ? null
        : _normalizeDate(effectiveDate);

    await _database.transaction(() async {
      final rateCompanions = rates
          .map((ExchangeRate rate) {
            _validateRate(rate);
            final sourceDate = rate.date.toUtc();
            return ExchangeRatesCompanion.insert(
              currencyCode: rate.currency.code,
              effectiveDateUtc:
                  normalizedEffectiveDate ?? _normalizeDate(rate.date),
              sourceDateUtc: sourceDate,
              rateToCzk: rate.rateToCzk,
            );
          })
          .toList(growable: false);

      await _database.batch((Batch batch) {
        batch.insertAll(
          _database.exchangeRates,
          rateCompanions,
          mode: InsertMode.insertOrReplace,
        );
      });
    });
  }

  ExchangeRate _mapRow(LocalExchangeRateRow row) {
    final currencyCode = row.currencyCode;
    final currency = SupportedCurrency.tryParse(currencyCode);
    if (currency == null) {
      throw FormatException('Unsupported persisted currency: $currencyCode');
    }

    final rateToCzk = row.rateToCzk;
    if (!rateToCzk.isFinite || rateToCzk <= 0) {
      throw FormatException(
        'Invalid persisted exchange rate for ${currency.code}: $rateToCzk',
      );
    }

    return ExchangeRate(
      currency: currency,
      date: row.sourceDateUtc.toUtc(),
      rateToCzk: rateToCzk,
    );
  }

  static DateTime _normalizeDate(DateTime value) {
    final utc = value.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day);
  }

  static void _validateRate(ExchangeRate rate) {
    if (!rate.rateToCzk.isFinite || rate.rateToCzk <= 0) {
      throw ArgumentError.value(
        rate.rateToCzk,
        'rate.rateToCzk',
        'Expected a finite positive exchange rate.',
      );
    }
  }
}
