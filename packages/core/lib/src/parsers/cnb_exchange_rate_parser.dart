import '../models/exchange_rate.dart';
import '../models/supported_currency.dart';

const _cnbEnglishMonthNumbers = <String, int>{
  'jan': 1,
  'feb': 2,
  'mar': 3,
  'apr': 4,
  'may': 5,
  'jun': 6,
  'jul': 7,
  'aug': 8,
  'sep': 9,
  'oct': 10,
  'nov': 11,
  'dec': 12,
};

final class CnbExchangeRateParser {
  const CnbExchangeRateParser();

  List<ExchangeRate> parse(String source) {
    final lines = source
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    if (lines.length < 2) {
      throw const FormatException(
        'ČNB exchange rate file must contain a dated header and column row.',
      );
    }

    final date = _parseDate(lines.first);
    final supportedRates = <SupportedCurrency, ExchangeRate>{
      SupportedCurrency.czk: ExchangeRate(
        currency: SupportedCurrency.czk,
        date: date,
        rateToCzk: 1.0,
      ),
    };

    for (final row in lines.skip(2)) {
      final columns = row.split('|');
      if (columns.length != 5) {
        throw FormatException('Invalid ČNB data row: $row');
      }

      final amount = int.tryParse(columns[2].trim());
      if (amount == null || amount <= 0) {
        throw FormatException('Invalid ČNB amount in row: $row');
      }

      final currency = SupportedCurrency.tryParse(columns[3]);
      if (currency == null) {
        continue;
      }

      final rawRate = _parseDecimal(columns[4]);
      final normalizedRate = rawRate / amount;
      if (!normalizedRate.isFinite || normalizedRate <= 0) {
        throw FormatException('Invalid ČNB rate in row: $row');
      }

      if (supportedRates.containsKey(currency)) {
        throw FormatException('Duplicate ČNB rate for ${currency.code}.');
      }

      supportedRates[currency] = ExchangeRate(
        currency: currency,
        date: date,
        rateToCzk: normalizedRate,
      );
    }

    return SupportedCurrency.values
        .where(supportedRates.containsKey)
        .map((currency) => supportedRates.getValueOrNull(currency)!)
        .toList(growable: false);
  }

  DateTime _parseDate(String header) {
    final dottedMatch = RegExp(
      r'^(\d{1,2})\.(\d{1,2})\.(\d{4})',
    ).firstMatch(header);
    if (dottedMatch != null) {
      final day = int.parse(dottedMatch.group(1)!);
      final month = int.parse(dottedMatch.group(2)!);
      final year = int.parse(dottedMatch.group(3)!);
      return _validatedDate(year, month, day, header);
    }

    final englishMatch = RegExp(
      r'^(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})',
    ).firstMatch(header);
    if (englishMatch == null) {
      throw FormatException('Missing ČNB date header: $header');
    }

    final day = int.parse(englishMatch.group(1)!);
    final monthToken = englishMatch.group(2)!.toLowerCase();
    final month = _cnbEnglishMonthNumbers[monthToken];
    if (month == null) {
      throw FormatException('Missing ČNB date header: $header');
    }

    final year = int.parse(englishMatch.group(3)!);
    return _validatedDate(year, month, day, header);
  }

  DateTime _validatedDate(int year, int month, int day, String header) {
    if (!_isValidCalendarDate(year, month, day)) {
      throw FormatException('Invalid ČNB calendar date: $header');
    }

    return DateTime.utc(year, month, day);
  }

  double _parseDecimal(String input) {
    final normalized = input.trim().replaceAll(' ', '').replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null || !value.isFinite) {
      throw FormatException('Invalid ČNB decimal value: $input');
    }

    return value;
  }
}

bool _isValidCalendarDate(int year, int month, int day) {
  if (month < 1 || month > 12 || day < 1) {
    return false;
  }

  final lastDayOfMonth = DateTime.utc(year, month + 1, 0).day;
  return day <= lastDayOfMonth;
}

extension on Map<SupportedCurrency, ExchangeRate> {
  ExchangeRate? getValueOrNull(SupportedCurrency key) => this[key];
}
