import 'session_usage_slice.dart';
import '../usage/harness_usage.dart';

final class OpenCodeSession {
  OpenCodeSession({
    required this.id,
    this.harness = UsageHarness.openCode,
    this.tokenUsage,
    Iterable<UsageEvent> usageEvents = const [],
    required this.createdAt,
    this.provider,
    this.modelName,
    this.inputTokens,
    this.outputTokens,
    this.totalCostUsd,
    this.requestCount,
    this.toolCallCount,
    this.responseCount,
    this.totalResponseTimeMs,
    this.subagentCategory,
    Iterable<SessionUsageSlice> usageSlices = const <SessionUsageSlice>[],
  }) : usageEvents = List<UsageEvent>.unmodifiable(usageEvents),
       usageSlices = List<SessionUsageSlice>.unmodifiable(usageSlices);

  final String id;
  final UsageHarness harness;
  final TokenUsage? tokenUsage;
  final List<UsageEvent> usageEvents;
  TokenUsage get tokens => usageEvents.isEmpty
      ? tokenUsage ?? TokenUsage(input: inputTokens, output: outputTokens)
      : TokenUsage.sum(usageEvents.map((e) => e.tokens));
  final String? provider;
  final String? modelName;
  final int? inputTokens;
  final int? outputTokens;
  final double? totalCostUsd;
  final int? requestCount;
  final int? toolCallCount;
  final int? responseCount;
  final int? totalResponseTimeMs;
  final DateTime createdAt;
  final String? subagentCategory;
  final List<SessionUsageSlice> usageSlices;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OpenCodeSession &&
            other.id == id &&
            other.harness == harness &&
            other.tokenUsage == tokenUsage &&
            _listEquals(other.usageEvents, usageEvents) &&
            other.provider == provider &&
            other.modelName == modelName &&
            other.inputTokens == inputTokens &&
            other.outputTokens == outputTokens &&
            other.totalCostUsd == totalCostUsd &&
            other.requestCount == requestCount &&
            other.toolCallCount == toolCallCount &&
            other.responseCount == responseCount &&
            other.totalResponseTimeMs == totalResponseTimeMs &&
            other.createdAt == createdAt &&
            other.subagentCategory == subagentCategory &&
            _listEquals(other.usageSlices, usageSlices);
  }

  @override
  int get hashCode => Object.hash(
    id,
    harness,
    tokenUsage,
    Object.hashAll(usageEvents),
    provider,
    modelName,
    inputTokens,
    outputTokens,
    totalCostUsd,
    requestCount,
    toolCallCount,
    responseCount,
    totalResponseTimeMs,
    createdAt,
    subagentCategory,
    Object.hashAll(usageSlices),
  );
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) {
    return true;
  }

  if (left.length != right.length) {
    return false;
  }

  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }

  return true;
}
