sed -i '' '/class _ModelData/,$d' apps/dashboard/lib/src/screens/metrics/widgets/metrics_chart_widgets.dart
cat << 'INNER_EOF' >> apps/dashboard/lib/src/screens/metrics/widgets/metrics_chart_widgets.dart

class _ModelData {
  _ModelData(
    this.name,
    this.totalCost,
    this.trend,
    this.totalTokens,
    this.totalSessions, {
    this.selectedDayCost,
    this.selectedDayTokens,
    this.selectedDaySessions,
  });

  final String name;
  final double totalCost;
  final String trend;
  final int totalTokens;
  final int totalSessions;
  final double? selectedDayCost;
  final int? selectedDayTokens;
  final int? selectedDaySessions;
}
INNER_EOF
