import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openspent_dashboard/l10n/app_localizations.dart';
import 'package:openspent_dashboard/src/screens/dashboard/widgets/dashboard_shell_chrome.dart';

void main() {
  for (final width in [390.0, 900.0]) {
    for (final language in ['en', 'cs']) {
      testWidgets(
        'Brand shell fits $width px in $language and supports keyboard navigation',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var sessionsOpened = false;
          await tester.pumpWidget(
            MaterialApp(
              locale: Locale(language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        DashboardShellHeader(
                          hasSettingsRoute: true,
                          onHelpPressed: () {},
                          onSettingsPressed: () {},
                        ),
                        const DashboardShellHero(),
                        DashboardShellNav(
                          selectedIndex: 0,
                          hasSessionsRoute: true,
                          hasExchangeRatesRoute: true,
                          onMetricsNav: () {},
                          onSessionsNav: () => sessionsOpened = true,
                          onExchangeRatesNav: () {},
                          onStateNav: () {},
                        ),
                        const DashboardShellFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final metrics = find.byKey(const Key('dashboard-nav-metrics'));
          final sessions = find.byKey(const Key('dashboard-nav-sessions'));
          final metricsRect = tester.getRect(metrics);
          final sessionsRect = tester.getRect(sessions);
          expect(metricsRect.left, greaterThanOrEqualTo(24));
          expect(sessionsRect.right, lessThanOrEqualTo(width - 24));
          // Start with focus on a section and traverse to the next cell.
          final metricsLabel = find
              .descendant(of: metrics, matching: find.byType(Text))
              .first;
          Focus.of(tester.element(metricsLabel)).requestFocus();
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          expect(sessionsOpened, isTrue);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
