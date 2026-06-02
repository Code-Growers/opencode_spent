import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:openspent_core/openspent_core.dart';
import 'package:openspent_dashboard/l10n/app_localizations.dart';
import 'package:openspent_dashboard/src/screens/exchange_rates/widgets/exchange_rates_chart_widgets.dart';

void main() {
  testWidgets('ExchangeRatesHistoryChart formats dates with full date format', (
    WidgetTester tester,
  ) async {
    final now = DateTime.utc(2026, 5, 13);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 400,
            child: ExchangeRatesHistoryChart(
              visibleDays: [now],
              ratesByDate: {
                now: [
                  ExchangeRate(
                    currency: SupportedCurrency.usd,
                    date: now,
                    rateToCzk: 22.0,
                  ),
                ],
              },
              selectedCurrency: SupportedCurrency.usd,
            ),
          ),
        ),
      ),
    );

    await tester.binding.setLocale('en', 'US');
    await tester.pumpAndSettle();

    final formattedDate = DateFormat.yMMMd('en').format(now);
    expect(find.text(formattedDate), findsWidgets);
  });
}
