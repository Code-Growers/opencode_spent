final class UsageBreakdown {
  const UsageBreakdown({
    required this.provider,
    this.modelName,
    required this.sessionCount,
    required this.inputTokens,
    required this.outputTokens,
    required this.totalCostUsd,
    required this.requestCount,
    required this.toolCallCount,
    required this.responseCount,
    required this.totalResponseTimeMs,
    required this.inputTokensCoverageSessionCount,
    required this.outputTokensCoverageSessionCount,
    required this.totalCostCoverageSessionCount,
    required this.requestCountCoverageSessionCount,
    required this.toolCallCountCoverageSessionCount,
    required this.responseCountCoverageSessionCount,
    required this.responseTimeCoverageSessionCount,
  });

  final String provider;
  final String? modelName;
  final int sessionCount;
  final int inputTokens;
  final int outputTokens;
  final double totalCostUsd;
  final int requestCount;
  final int toolCallCount;
  final int responseCount;
  final int totalResponseTimeMs;
  final int inputTokensCoverageSessionCount;
  final int outputTokensCoverageSessionCount;
  final int totalCostCoverageSessionCount;
  final int requestCountCoverageSessionCount;
  final int toolCallCountCoverageSessionCount;
  final int responseCountCoverageSessionCount;
  final int responseTimeCoverageSessionCount;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UsageBreakdown &&
            other.provider == provider &&
            other.modelName == modelName &&
            other.sessionCount == sessionCount &&
            other.inputTokens == inputTokens &&
            other.outputTokens == outputTokens &&
            other.totalCostUsd == totalCostUsd &&
            other.requestCount == requestCount &&
            other.toolCallCount == toolCallCount &&
            other.responseCount == responseCount &&
            other.totalResponseTimeMs == totalResponseTimeMs &&
            other.inputTokensCoverageSessionCount ==
                inputTokensCoverageSessionCount &&
            other.outputTokensCoverageSessionCount ==
                outputTokensCoverageSessionCount &&
            other.totalCostCoverageSessionCount ==
                totalCostCoverageSessionCount &&
            other.requestCountCoverageSessionCount ==
                requestCountCoverageSessionCount &&
            other.toolCallCountCoverageSessionCount ==
                toolCallCountCoverageSessionCount &&
            other.responseCountCoverageSessionCount ==
                responseCountCoverageSessionCount &&
            other.responseTimeCoverageSessionCount ==
                responseTimeCoverageSessionCount;
  }

  @override
  int get hashCode => Object.hash(
    provider,
    modelName,
    sessionCount,
    inputTokens,
    outputTokens,
    totalCostUsd,
    requestCount,
    toolCallCount,
    responseCount,
    totalResponseTimeMs,
    inputTokensCoverageSessionCount,
    outputTokensCoverageSessionCount,
    totalCostCoverageSessionCount,
    requestCountCoverageSessionCount,
    toolCallCountCoverageSessionCount,
    responseCountCoverageSessionCount,
    responseTimeCoverageSessionCount,
  );
}
