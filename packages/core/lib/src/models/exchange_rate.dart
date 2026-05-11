import 'supported_currency.dart';

final class ExchangeRate {
  const ExchangeRate({
    required this.currency,
    required this.date,
    required this.rateToCzk,
  });

  final SupportedCurrency currency;
  final DateTime date;
  final double rateToCzk;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ExchangeRate &&
            other.currency == currency &&
            other.date == date &&
            other.rateToCzk == rateToCzk;
  }

  @override
  int get hashCode => Object.hash(currency, date, rateToCzk);
}
