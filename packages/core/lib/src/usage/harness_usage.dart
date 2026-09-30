import '../models/open_code_session.dart';
import '../models/session_usage_slice.dart';

enum UsageHarness { openCode, claudeCode, codex }

/// Only numeric usage and opaque identifiers cross the transcript boundary.
final class TokenUsage {
  const TokenUsage({
    this.input,
    this.output,
    this.cachedInput,
    this.cacheWrite,
    this.cacheWrite5m,
    this.cacheWrite1h,
    this.reasoning,
  });
  final int? input,
      output,
      cachedInput,
      cacheWrite,
      cacheWrite5m,
      cacheWrite1h,
      reasoning;

  Map<String, Object?> toJson() => {
    'input': input,
    'output': output,
    'cachedInput': cachedInput,
    'cacheWrite': cacheWrite,
    'cacheWrite5m': cacheWrite5m,
    'cacheWrite1h': cacheWrite1h,
    'reasoning': reasoning,
  };
  factory TokenUsage.fromJson(Map<String, dynamic> json) {
    int? n(String key) =>
        json[key] is int && (json[key] as int) >= 0 ? json[key] as int : null;
    return TokenUsage(
      input: n('input'),
      output: n('output'),
      cachedInput: n('cachedInput'),
      cacheWrite: n('cacheWrite'),
      cacheWrite5m: n('cacheWrite5m'),
      cacheWrite1h: n('cacheWrite1h'),
      reasoning: n('reasoning'),
    );
  }
  static TokenUsage sum(Iterable<TokenUsage> values) {
    final items = values.toList();
    int? sumOf(int? Function(TokenUsage) get) {
      final known = items.map(get).whereType<int>().toList();
      return known.length != items.length || known.isEmpty
          ? null
          : known.fold<int>(0, (a, b) => a + b);
    }

    return TokenUsage(
      input: sumOf((u) => u.input),
      output: sumOf((u) => u.output),
      cachedInput: sumOf((u) => u.cachedInput),
      cacheWrite: sumOf((u) => u.cacheWrite),
      cacheWrite5m: sumOf((u) => u.cacheWrite5m),
      cacheWrite1h: sumOf((u) => u.cacheWrite1h),
      reasoning: sumOf((u) => u.reasoning),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TokenUsage &&
      toJson().entries.every((e) => other.toJson()[e.key] == e.value);
  @override
  int get hashCode => Object.hashAll(toJson().values);
}

final class UsageEvent {
  const UsageEvent({
    required this.id,
    required this.sessionId,
    required this.timestamp,
    required this.provider,
    this.model,
    required this.tokens,
    this.contextInputTokens,
  });
  final String id, sessionId, provider;
  final String? model;
  final DateTime timestamp;
  final TokenUsage tokens;
  final int? contextInputTokens;
  Map<String, Object?> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'provider': provider,
    'model': model,
    'tokens': tokens.toJson(),
    'contextInputTokens': contextInputTokens,
  };
  factory UsageEvent.fromJson(Map<String, dynamic> j) => UsageEvent(
    id: j['id'] as String,
    sessionId: j['sessionId'] as String,
    timestamp: DateTime.parse(j['timestamp'] as String).toUtc(),
    provider: j['provider'] as String,
    model: j['model'] as String?,
    tokens: TokenUsage.fromJson(j['tokens'] as Map<String, dynamic>),
    contextInputTokens: j['contextInputTokens'] as int?,
  );
  SessionUsageSlice get slice => SessionUsageSlice(
    provider: provider,
    modelName: model ?? 'unknown',
    tokenUsage: tokens,
    inputTokens: tokens.input,
    outputTokens: tokens.output,
    requestCount: 1,
    createdAt: timestamp,
  );
  @override
  bool operator ==(Object other) =>
      other is UsageEvent &&
      other.id == id &&
      other.sessionId == sessionId &&
      other.timestamp == timestamp &&
      other.provider == provider &&
      other.model == model &&
      other.tokens == tokens &&
      other.contextInputTokens == contextInputTokens;
  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    timestamp,
    provider,
    model,
    tokens,
    contextInputTokens,
  );
}

OpenCodeSession sessionFromEvents({
  required String id,
  required UsageHarness harness,
  required Iterable<UsageEvent> events,
  DateTime? createdAt,
}) {
  final list = events.toList()
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  final tokens = TokenUsage.sum(list.map((e) => e.tokens));
  final models = list.map((e) => e.model).toSet();
  return OpenCodeSession(
    id: id,
    harness: harness,
    createdAt: createdAt ?? list.first.timestamp,
    provider: list.isEmpty ? null : list.first.provider,
    modelName: models.length == 1 ? models.first : null,
    inputTokens: tokens.input,
    outputTokens: tokens.output,
    requestCount: list.length,
    usageEvents: list,
    usageSlices: list.map((e) => e.slice),
  );
}

/// Select usage by occurrence time while preserving legacy session-date behavior.
OpenCodeSession? selectSessionUsage(
  OpenCodeSession session, {
  DateTime? from,
  DateTime? to,
  String? model,
  int? utcHour,
}) {
  bool inRange(DateTime date) =>
      (from == null || !date.isBefore(from)) &&
      (to == null || !date.isAfter(to)) &&
      (utcHour == null || date.toUtc().hour == utcHour);
  bool matchesModel(String? value) =>
      model == null ||
      value?.trim().toLowerCase() == model.trim().toLowerCase();
  if (session.usageEvents.isEmpty) {
    return inRange(session.createdAt) && matchesModel(session.modelName)
        ? session
        : null;
  }
  final events = session.usageEvents
      .where((e) => inRange(e.timestamp) && matchesModel(e.model))
      .toList();
  if (events.isEmpty) return null;
  return sessionFromEvents(
    id: session.id,
    harness: session.harness,
    createdAt: session.createdAt,
    events: events,
  );
}

/// OpenCode exposes uncached input separately from its cache read/write counts.
/// Older records without cache metadata retain their existing token contract.
TokenUsage? readOpenCodeTokenUsage(Object? value) {
  if (value is! Map) return null;
  final cache = value['cache'];
  if (cache is! Map) return null;
  int? n(Object? v) => v is int && v >= 0 ? v : null;
  final input = n(value['input']),
      read = n(cache['read']),
      write = n(cache['write']);
  return TokenUsage(
    input: input == null || read == null || write == null
        ? null
        : input + read + write,
    output: n(value['output']),
    cachedInput: read,
    cacheWrite: write,
    reasoning: n(value['reasoning']),
  );
}

/// Legacy OpenCode snapshots can be priced from allowlisted model slices, with
/// session-date attribution and an explicit unknown per-request context length.
Iterable<UsageEvent> usageEventsForPricing(OpenCodeSession session) {
  if (session.usageEvents.isNotEmpty) return session.usageEvents;
  final slices = session.usageSlices.isNotEmpty
      ? session.usageSlices
      : session.provider != null && session.modelName != null
      ? [
          SessionUsageSlice(
            provider: session.provider!,
            modelName: session.modelName!,
            tokenUsage: session.tokenUsage,
            inputTokens: session.inputTokens,
            outputTokens: session.outputTokens,
          ),
        ]
      : <SessionUsageSlice>[];
  return slices.map(
    (slice) => UsageEvent(
      id: '${session.id}:${slice.provider}:${slice.modelName}',
      sessionId: session.id,
      timestamp: session.createdAt,
      provider: slice.provider.toLowerCase(),
      model: slice.modelName,
      tokens:
          slice.tokenUsage ??
          TokenUsage(input: slice.inputTokens, output: slice.outputTokens),
    ),
  );
}
