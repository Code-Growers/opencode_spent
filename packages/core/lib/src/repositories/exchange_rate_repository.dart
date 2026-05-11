import '../models/exchange_rate.dart';

abstract interface class ExchangeRateRepository {
  Future<List<ExchangeRate>> readExchangeRatesForDate(DateTime date);

  Future<void> writeExchangeRates(Iterable<ExchangeRate> rates);
}
