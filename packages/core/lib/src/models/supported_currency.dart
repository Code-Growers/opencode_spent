enum SupportedCurrency {
  usd('USD'),
  czk('CZK');

  const SupportedCurrency(this.code);

  final String code;

  static SupportedCurrency? tryParse(String value) {
    for (final currency in values) {
      if (currency.code == value.trim().toUpperCase()) {
        return currency;
      }
    }

    return null;
  }
}
