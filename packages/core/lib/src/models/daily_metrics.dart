final class DailyMetrics {
  const DailyMetrics({
    required this.date,
    required this.sessionCount,
    required this.inputTokens,
    required this.outputTokens,
    required this.totalCostUsd,
  });

  final DateTime date;
  final int sessionCount;
  final int inputTokens;
  final int outputTokens;
  final double totalCostUsd;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DailyMetrics &&
            other.date == date &&
            other.sessionCount == sessionCount &&
            other.inputTokens == inputTokens &&
            other.outputTokens == outputTokens &&
            other.totalCostUsd == totalCostUsd;
  }

  @override
  int get hashCode => Object.hash(
        date,
        sessionCount,
        inputTokens,
        outputTokens,
        totalCostUsd,
      );
}
