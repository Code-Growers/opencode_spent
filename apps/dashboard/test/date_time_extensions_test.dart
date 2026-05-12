import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openspent_dashboard/l10n/app_localizations.dart';
import 'package:openspent_dashboard/src/app/date_time_extensions.dart';

String _expectedLocalTimestamp(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString().padLeft(4, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day.$month.$year $hour:$minute';
}

void main() {
  testWidgets(
    'formatter distinguishes real timestamps from canonical UTC days',
    (WidgetTester tester) async {
      late BuildContext context;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en', 'US'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (buildContext) {
              context = buildContext;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(
        DateTime.utc(2026, 5, 8, 12).formatDashboardDateTime(context),
        _expectedLocalTimestamp(DateTime.utc(2026, 5, 8, 12)),
      );
      expect(
        DateTime.utc(2026, 5, 8, 23, 30).formatDashboardUtcDay(context),
        '08.05.2026 00:00',
      );
      expect(
        formatDashboardUtcDayIsoStrings(
          context,
          'Missing USD exchange rate for 2026-05-08T00:00:00.000Z.',
        ),
        'Missing USD exchange rate for 08.05.2026 00:00.',
      );
    },
  );
}
