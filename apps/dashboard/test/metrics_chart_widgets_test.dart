import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openspent_dashboard/src/screens/metrics/widgets/metrics_chart_widgets.dart';
import 'package:openspent_dashboard/l10n/app_localizations.dart';

Widget buildTestableWidget(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('ModelUsagePieChart shows overflow text when more than 5 items', (
    WidgetTester tester,
  ) async {
    final usageByModel = {
      'model1': 100,
      'model2': 90,
      'model3': 80,
      'model4': 70,
      'model5': 60,
      'model6': 50,
      'model7': 40,
    };

    await tester.pumpWidget(
      buildTestableWidget(ModelUsagePieChart(usageByModel: usageByModel)),
    );

    expect(
      find.byKey(const Key('metrics-pie-legend-overflow')),
      findsOneWidget,
    );
    expect(find.text('+2 more'), findsOneWidget);
  });

  testWidgets(
    'ModelUsagePieChart uses compact height by default and expanded height when requested, checking rich legend content',
    (WidgetTester tester) async {
      final usageByModel = {'model1': 100};

      // Compact
      await tester.pumpWidget(
        buildTestableWidget(ModelUsagePieChart(usageByModel: usageByModel)),
      );
      final compactSizedBox = tester.widget<SizedBox>(
        find
            .descendant(
              of: find.byType(ModelUsagePieChart),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(compactSizedBox.height, 240.0);
      expect(find.text('model1'), findsOneWidget);
      expect(find.text('100.0% • 100'), findsOneWidget);

      // Expanded
      await tester.pumpWidget(
        buildTestableWidget(
          ModelUsagePieChart(usageByModel: usageByModel, expanded: true),
        ),
      );
      final expandedSizedBox = tester.widget<SizedBox>(
        find
            .descendant(
              of: find.byType(ModelUsagePieChart),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(expandedSizedBox.height, 360.0);
    },
  );

  testWidgets('SpendTrendChart renders surfaced empty state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(
        const SpendTrendChart(
          displayCurrency: 'USD',
          dailyBreakdown: [],
          visibleDays: [],
        ),
      ),
    );

    expect(find.text('> spend trend unavailable'), findsOneWidget);
  });

  testWidgets('ModelUsagePieChart constrained-width regression', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      buildTestableWidget(
        const ModelUsagePieChart(usageByModel: {'modelA': 100}, expanded: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ModelUsagePieChart), findsOneWidget);
  });
}
