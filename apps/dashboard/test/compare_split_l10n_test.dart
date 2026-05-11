import 'package:flutter_test/flutter_test.dart';
import 'package:openspent_dashboard/l10n/app_localizations_en.dart';
import 'package:openspent_dashboard/l10n/app_localizations_cs.dart';

void main() {
  group('Compare Split L10n Formatting', () {
    test('English formats as {sign}{currency} {value}', () {
      final l10n = AppLocalizationsEn();

      expect(
        l10n.compareSplitSessions('+', 'USD', '1.23'),
        '> Split sessions ..... +USD 1.23',
      );
      expect(
        l10n.compareSplitAvg('+', 'USD', '1.23'),
        '> Split avg/session .. +USD 1.23',
      );
      expect(
        l10n.compareSplitCost('+', 'USD', '1.23'),
        '> Split cost/1M ...... +USD 1.23',
      );
    });

    test('Czech formats as {sign}{value} {currency}', () {
      final l10n = AppLocalizationsCs();

      expect(
        l10n.compareSplitSessions('+', 'USD', '1.23'),
        '> Vliv relací ........ +1.23 USD',
      );
      expect(
        l10n.compareSplitAvg('+', 'USD', '1.23'),
        '> Vliv prům./relaci .. +1.23 USD',
      );
      expect(
        l10n.compareSplitCost('+', 'USD', '1.23'),
        '> Vliv ceny/1M ....... +1.23 USD',
      );
    });
  });
}
