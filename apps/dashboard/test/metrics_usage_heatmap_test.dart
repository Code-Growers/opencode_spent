import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openspent_dashboard/l10n/app_localizations.dart';
import 'package:openspent_dashboard/src/screens/metrics/metrics_utils.dart';
import 'package:openspent_dashboard/src/screens/metrics/widgets/metrics_usage_heatmap.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('MetricsUsageHeatmap renders section, cards, and grid', (
    tester,
  ) async {
    final days = List.generate(7, (i) => DateTime.utc(2024, 4, i + 1));
    final dayData = [
      for (var index = 0; index < days.length; index++)
        HeatmapDayData(
          day: days[index],
          sessionCount: index == 6 ? 3 : 0,
          tokenCount: index == 6 ? 1200 : 0,
          displayCost: index == 6 ? 2.4 : 0,
          level: index == 6 ? 4 : 0,
        ),
    ];
    const stats = HeatmapStats(
      activeDays: 1,
      currentStreak: 1,
      longestStreak: 1,
      peakDay: null,
      peakDaySessionCount: 3,
      peakDayTokenCount: 1200,
      peakDayCost: 2.4,
    );

    await tester.pumpWidget(
      _wrap(
        MetricsUsageHeatmap(
          visibleDays: days,
          dayData: dayData,
          stats: stats,
          selectedDay: days.last,
          onDaySelected: (_) {},
        ),
      ),
    );

    expect(find.byKey(const Key('metrics-usage-heatmap-section')), findsOneWidget);
    expect(find.byKey(const Key('metrics-heatmap-active-days')), findsOneWidget);
    expect(find.byKey(const Key('metrics-heatmap-current-streak')), findsOneWidget);
    expect(find.byKey(const Key('metrics-heatmap-longest-streak')), findsOneWidget);
    expect(find.byKey(const Key('metrics-heatmap-peak-day')), findsOneWidget);
    expect(find.byKey(const Key('metrics-heatmap-grid')), findsOneWidget);
  });

  testWidgets('MetricsUsageHeatmap forwards day taps', (tester) async {
    final day = DateTime.utc(2024, 4, 1);
    final dayData = [
      HeatmapDayData(
        day: day,
        sessionCount: 2,
        tokenCount: 400,
        displayCost: 1,
        level: 4,
      ),
    ];
    DateTime? selected;

    await tester.pumpWidget(
      _wrap(
        MetricsUsageHeatmap(
          visibleDays: [day],
          dayData: dayData,
          stats: HeatmapStats(
            activeDays: 1,
            currentStreak: 1,
            longestStreak: 1,
            peakDay: day,
            peakDaySessionCount: 2,
            peakDayTokenCount: 400,
            peakDayCost: 1,
          ),
          selectedDay: null,
          onDaySelected: (value) {
            selected = value;
          },
        ),
      ),
    );

    await tester.tap(find.byKey(Key('metrics-heatmap-cell-${day.toIso8601String()}')));
    await tester.pumpAndSettle();

    expect(selected, day);
  });
}
