final class SessionUsageSlice {
  const SessionUsageSlice({
    required this.provider,
    required this.modelName,
    this.inputTokens,
    this.outputTokens,
    this.totalCostUsd,
    this.requestCount,
    this.toolCallCount,
    this.responseCount,
    this.totalResponseTimeMs,
  });

  final String provider;
  final String modelName;
  final int? inputTokens;
  final int? outputTokens;
  final double? totalCostUsd;
  final int? requestCount;
  final int? toolCallCount;
  final int? responseCount;
  final int? totalResponseTimeMs;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SessionUsageSlice &&
            other.provider == provider &&
            other.modelName == modelName &&
            other.inputTokens == inputTokens &&
            other.outputTokens == outputTokens &&
            other.totalCostUsd == totalCostUsd &&
            other.requestCount == requestCount &&
            other.toolCallCount == toolCallCount &&
            other.responseCount == responseCount &&
            other.totalResponseTimeMs == totalResponseTimeMs;
  }

  @override
  int get hashCode => Object.hash(
    provider,
    modelName,
    inputTokens,
    outputTokens,
    totalCostUsd,
    requestCount,
    toolCallCount,
    responseCount,
    totalResponseTimeMs,
  );
}
