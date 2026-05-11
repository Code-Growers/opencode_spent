import 'package:openspent_core/openspent_core.dart';

import '../clients/cnb_exchange_rate_api_client.dart';

final class RemoteExchangeRateRepository implements ExchangeRateRepository {
  RemoteExchangeRateRepository({
    required CnbExchangeRateApiClient apiClient,
    CnbExchangeRateParser parser = const CnbExchangeRateParser(),
  }) : _apiClient = apiClient,
       _parser = parser;

  final CnbExchangeRateApiClient _apiClient;
  final CnbExchangeRateParser _parser;

  @override
  Future<List<ExchangeRate>> readExchangeRatesForDate(DateTime date) async {
    final normalizedDate = _normalizeDate(date);
    final rawResponse = await _apiClient.getDailyExchangeRateFile(
      date: _formatCnbDate(normalizedDate),
    );
    final rates = _parser.parse(rawResponse);

    for (final rate in rates) {
      if (_normalizeDate(rate.date) != normalizedDate) {
        throw StateError(
          'ČNB returned rates for ${_formatCnbDate(_normalizeDate(rate.date))} '
          'when ${_formatCnbDate(normalizedDate)} was requested.',
        );
      }
    }

    return rates;
  }

  @override
  Future<void> writeExchangeRates(Iterable<ExchangeRate> rates) {
    throw UnsupportedError(
      'RemoteExchangeRateRepository is read-only. Use openspent_local for '
      'exchange-rate persistence or caching.',
    );
  }

  static DateTime _normalizeDate(DateTime value) {
    final utc = value.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day);
  }

  static String _formatCnbDate(DateTime value) {
    final normalized = _normalizeDate(value);
    final day = normalized.day.toString().padLeft(2, '0');
    final month = normalized.month.toString().padLeft(2, '0');
    final year = normalized.year.toString().padLeft(4, '0');
    return '$day.$month.$year';
  }
}
