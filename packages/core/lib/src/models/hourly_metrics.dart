final class HourlyMetrics {
  const HourlyMetrics({
    required this.hour,
    required this.sessionCount,
    required this.inputTokens,
    required this.outputTokens,
    required this.totalCostUsd,
  });

  final DateTime hour;
  final int sessionCount;
  final int inputTokens;
  final int outputTokens;
  final double totalCostUsd;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HourlyMetrics &&
            other.hour == hour &&
            other.sessionCount == sessionCount &&
            other.inputTokens == inputTokens &&
            other.outputTokens == outputTokens &&
            other.totalCostUsd == totalCostUsd;
  }

  @override
  int get hashCode => Object.hash(
        hour,
        sessionCount,
        inputTokens,
        outputTokens,
        totalCostUsd,
      );
}
