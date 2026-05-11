final class OpenCodeSession {
  const OpenCodeSession({
    required this.id,
    required this.createdAt,
    this.modelName,
    this.inputTokens,
    this.outputTokens,
    this.totalCostUsd,
    this.subagentCategory,
  });

  final String id;
  final String? modelName;
  final int? inputTokens;
  final int? outputTokens;
  final double? totalCostUsd;
  final DateTime createdAt;
  final String? subagentCategory;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OpenCodeSession &&
            other.id == id &&
            other.modelName == modelName &&
            other.inputTokens == inputTokens &&
            other.outputTokens == outputTokens &&
            other.totalCostUsd == totalCostUsd &&
            other.createdAt == createdAt &&
            other.subagentCategory == subagentCategory;
  }

  @override
  int get hashCode => Object.hash(
        id,
        modelName,
        inputTokens,
        outputTokens,
        totalCostUsd,
        createdAt,
        subagentCategory,
      );
}
