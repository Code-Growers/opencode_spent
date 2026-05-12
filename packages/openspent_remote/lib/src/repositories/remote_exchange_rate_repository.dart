import 'package:openspent_core/openspent_core.dart';

import '../clients/cnb_exchange_rate_api_client.dart';

final class RemoteExchangeRateRepository implements ExchangeRateRepository {
  RemoteExchangeRateRepository({
    required CnbExchangeRateApiClient apiClient,
    CnbExchangeRateParser parser = const CnbExchangeRateParser(),
    DateTime Function() now = DateTime.now,
  }) : _apiClient = apiClient,
       _parser = parser,
       _now = now;

  final CnbExchangeRateApiClient _apiClient;
  final CnbExchangeRateParser _parser;
  final DateTime Function() _now;

  @override
  Future<List<ExchangeRate>> readExchangeRatesForDate(DateTime date) async {
    final normalizedDate = _normalizeDate(date);
    final currentDate = _normalizeDate(_now());
    final rawResponse = await _apiClient.getDailyExchangeRateFile(
      date: _formatCnbDate(normalizedDate),
    );
    final rates = _parser.parse(rawResponse);

    for (final rate in rates) {
      final parsedDate = _normalizeDate(rate.date);
      if (!_isAcceptedFixingDate(parsedDate, normalizedDate, currentDate)) {
        throw StateError(
          'ČNB returned rates for ${_formatCnbDate(parsedDate)} '
          'when ${_formatCnbDate(normalizedDate)} was requested.',
        );
      }
    }

    return rates;
  }

  @override
  Future<void> writeExchangeRates(
    Iterable<ExchangeRate> rates, {
    DateTime? effectiveDate,
  }) {
    throw UnsupportedError(
      'RemoteExchangeRateRepository is read-only. Use openspent_local for '
      'exchange-rate persistence or caching.',
    );
  }

  static DateTime _normalizeDate(DateTime value) {
    final utc = value.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day);
  }

  static bool _isAcceptedFixingDate(
    DateTime parsedDate,
    DateTime requestedDate,
    DateTime currentDate,
  ) {
    if (parsedDate.isAfter(requestedDate) || !_isCzechWorkingDay(parsedDate)) {
      return false;
    }

    if (parsedDate == requestedDate) {
      return true;
    }

    var date = parsedDate.add(const Duration(days: 1));
    while (requestedDate == currentDate
        ? date.isBefore(requestedDate)
        : !date.isAfter(requestedDate)) {
      if (_isCzechWorkingDay(date)) {
        return false;
      }
      date = date.add(const Duration(days: 1));
    }

    return true;
  }

  static bool _isCzechWorkingDay(DateTime value) {
    final normalized = _normalizeDate(value);
    return !_isWeekend(normalized) && !_isCzechPublicHoliday(normalized);
  }

  static bool _isWeekend(DateTime value) {
    return value.weekday == DateTime.saturday ||
        value.weekday == DateTime.sunday;
  }

  static bool _isCzechPublicHoliday(DateTime value) {
    final normalized = _normalizeDate(value);
    final monthDay = normalized.month * 100 + normalized.day;
    switch (monthDay) {
      case 101:
      case 501:
      case 508:
      case 705:
      case 706:
      case 928:
      case 1028:
      case 1117:
      case 1224:
      case 1225:
      case 1226:
        return true;
    }

    final easterSunday = _easterSundayUtc(normalized.year);
    final easterMonday = easterSunday.add(const Duration(days: 1));
    final goodFriday = easterSunday.subtract(const Duration(days: 2));

    return normalized == easterMonday ||
        (normalized.year >= 2016 && normalized == goodFriday);
  }

  static DateTime _easterSundayUtc(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime.utc(year, month, day);
  }

  static String _formatCnbDate(DateTime value) {
    final normalized = _normalizeDate(value);
    final day = normalized.day.toString().padLeft(2, '0');
    final month = normalized.month.toString().padLeft(2, '0');
    final year = normalized.year.toString().padLeft(4, '0');
    return '$day.$month.$year';
  }
}
