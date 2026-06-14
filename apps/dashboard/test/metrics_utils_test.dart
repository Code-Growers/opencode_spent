import 'package:flutter_test/flutter_test.dart';
import 'package:openspent_core/openspent_core.dart';
import 'package:openspent_dashboard/src/screens/metrics/metrics_utils.dart';

MonetizedDailyMetrics _daily({
  required DateTime day,
  required int sessions,
  int inputTokens = 0,
  int outputTokens = 0,
  double cost = 0,
}) {
  return MonetizedDailyMetrics(
    baseMetrics: DailyMetrics(
      date: day,
      sessionCount: sessions,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      totalCostUsd: cost,
    ),
    displayTotalCost: cost,
  );
}

void main() {
  group('HeatmapStats calculations', () {
    test('calculateHeatmapStats returns zeros when visibleDays is empty', () {
      final stats = calculateHeatmapStats([], []);
      expect(stats.activeDays, 0);
      expect(stats.currentStreak, 0);
      expect(stats.longestStreak, 0);
      expect(stats.peakDay, isNull);
      expect(stats.peakDaySessionCount, 0);
      expect(stats.peakDayTokenCount, 0);
      expect(stats.peakDayCost, 0);
    });

    test(
      'calculateHeatmapStats correctly calculates streaks and active days',
      () {
        final today = DateTime.utc(2023, 10, 10);
        final days = List.generate(
          7,
          (i) => today.subtract(Duration(days: 6 - i)),
        );

        // Breakdown with counts:
        // Day 0: 0
        // Day 1: 2
        // Day 2: 5
        // Day 3: 0
        // Day 4: 1
        // Day 5: 1
        // Day 6: 1

        final breakdown = [
          _daily(day: days[1], sessions: 2),
          _daily(day: days[2], sessions: 5, inputTokens: 3, outputTokens: 2),
          _daily(day: days[4], sessions: 1),
          _daily(day: days[5], sessions: 1),
          _daily(day: days[6], sessions: 1),
        ];

        final stats = calculateHeatmapStats(breakdown, days);

        expect(stats.activeDays, 5);
        expect(stats.peakDay, days[2]);
        expect(stats.peakDaySessionCount, 5);
        expect(stats.peakDayTokenCount, 5);
        expect(stats.longestStreak, 3); // Days 4, 5, 6
        expect(stats.currentStreak, 3); // Days 4, 5, 6 leading up to today
      },
    );

    test('calculateHeatmapStats uses tokens then cost then latest date tie-breaks', () {
      final days = List.generate(3, (i) => DateTime.utc(2024, 1, i + 1));
      final stats = calculateHeatmapStats([
        _daily(day: days[0], sessions: 4, inputTokens: 10, cost: 1),
        _daily(day: days[1], sessions: 4, inputTokens: 20, cost: 1),
        _daily(day: days[2], sessions: 4, inputTokens: 20, cost: 2),
      ], days);

      expect(stats.peakDay, days[2]);
      expect(stats.peakDaySessionCount, 4);
      expect(stats.peakDayTokenCount, 20);
      expect(stats.peakDayCost, 2);
    });
  });

  group('buildHeatmapDayData', () {
    test('assigns contiguous heatmap levels from visible days', () {
      final days = List.generate(4, (i) => DateTime.utc(2024, 2, i + 1));
      final data = buildHeatmapDayData([
        _daily(day: days[0], sessions: 0),
        _daily(day: days[1], sessions: 1),
        _daily(day: days[2], sessions: 2),
        _daily(day: days[3], sessions: 4),
      ], days);

      expect(data.map((item) => item.level).toList(), [0, 1, 2, 4]);
    });
  });

  group('buildVisibleWindowDays gap filling', () {
    test('TimeWindow.all fills gaps', () {
      final start = DateTime.utc(2023, 10, 1);
      final end = DateTime.utc(2023, 10, 5);

      final breakdown = [
        _daily(day: start, sessions: 1),
        _daily(day: end, sessions: 1),
      ];

      final days = buildVisibleWindowDays(
        breakdown,
        TimeWindow.all,
        null,
        null,
      );

      expect(days.length, 5);
      expect(days.first, start);
      expect(days.last, end);
    });

    test('TimeWindow.custom fills requested range even with sparse data', () {
      final from = DateTime.utc(2024, 3, 10);
      final to = DateTime.utc(2024, 3, 12, 23, 59, 59);

      final days = buildVisibleWindowDays(
        [_daily(day: from, sessions: 1)],
        TimeWindow.custom,
        from,
        to,
      );

      expect(days, [
        DateTime.utc(2024, 3, 10),
        DateTime.utc(2024, 3, 11),
        DateTime.utc(2024, 3, 12),
      ]);
    });
  });
}
