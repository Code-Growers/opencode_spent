import 'dart:convert';
import '../models/open_code_session.dart';
import '../usage/harness_usage.dart';

/// Streaming projection: raw records are discarded immediately after projection.
final class HarnessTranscriptParser {
  HarnessTranscriptParser(this.harness);
  final UsageHarness harness;
  int skippedRecords = 0;
  String? _sessionId, _model;
  final Set<String?> _intervalModels = {};
  DateTime? _startedAt;
  final Map<String, UsageEvent> _events = {};
  TokenUsage? _previousTotal;
  bool _intervalHasResponseRecords = false;
  final Map<String, String> _fallbacksByTotal = {};
  String _signature(TokenUsage u) => jsonEncode(u.toJson());

  void addLine(String line) {
    if (line.trim().isEmpty) return;
    try {
      final record = jsonDecode(line);
      if (record is! Map<String, dynamic>) {
        skippedRecords++;
        return;
      }
      switch (harness) {
        case UsageHarness.claudeCode:
          _claude(record);
        case UsageHarness.codex:
          _codex(record);
        case UsageHarness.openCode:
          throw const FormatException('Unsupported transcript.');
      }
    } catch (_) {
      // Never expose JSON decoder exceptions: they can contain transcript text.
      skippedRecords++;
    }
  }

  List<OpenCodeSession> finish() {
    final grouped = <String, List<UsageEvent>>{};
    for (final e in _events.values) {
      grouped.putIfAbsent(e.sessionId, () => []).add(e);
    }
    return grouped.entries
        .map(
          (e) =>
              sessionFromEvents(id: e.key, harness: harness, events: e.value),
        )
        .toList();
  }

  static String? _id(Object? value) =>
      value is String && RegExp(r'^[a-zA-Z0-9_-]{1,200}$').hasMatch(value)
      ? value
      : null;
  static String? _modelName(Object? value) =>
      value is String && RegExp(r'^[a-zA-Z0-9_.:-]{1,120}$').hasMatch(value)
      ? value
      : null;
  static Map<String, dynamic> _map(Object? value) =>
      value is Map<String, dynamic> ? value : {};
  static int? _n(Object? value) => value is int && value >= 0 ? value : null;
  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;

  void _claude(Map<String, dynamic> r) {
    if (r['type'] != 'assistant' ||
        r['isApiErrorMessage'] == true ||
        r['error'] != null) {
      return;
    }
    final m = _map(r['message']);
    final usage = _map(m['usage']);
    final model = _modelName(m['model']);
    final session = _id(r['sessionId']);
    final message = _id(m['id']);
    final timestamp = _date(r['timestamp']);
    if (usage.isEmpty ||
        model == null ||
        session == null ||
        message == null ||
        timestamp == null) {
      return;
    }
    final input = _n(usage['input_tokens']);
    final output = _n(usage['output_tokens']);
    if (input == null && output == null) return;
    final read = _n(usage['cache_read_input_tokens']);
    final write = _n(usage['cache_creation_input_tokens']);
    final creation = _map(usage['cache_creation']);
    final totalInput = input == null || read == null || write == null
        ? null
        : input + read + write;
    final tokens = TokenUsage(
      input: totalInput,
      output: output,
      cachedInput: read,
      cacheWrite: write,
      cacheWrite5m: _n(creation['ephemeral_5m_input_tokens']),
      cacheWrite1h: _n(creation['ephemeral_1h_input_tokens']),
      reasoning: _n(_map(usage['output_tokens_details'])['thinking_tokens']),
    );
    final sessionId = 'claudeCode:$session';
    final key = 'claudeCode:$message';
    final old = _events[key];
    // Multiple content blocks and streaming revisions describe one response.
    _events[key] = UsageEvent(
      id: key,
      sessionId: sessionId,
      timestamp: old?.timestamp ?? timestamp,
      provider: 'anthropic',
      model: model,
      tokens: _maximum(old?.tokens, tokens),
      contextInputTokens: totalInput,
    );
  }

  static TokenUsage _maximum(TokenUsage? old, TokenUsage next) {
    if (old == null) return next;
    final previous = old.toJson();
    return TokenUsage.fromJson(
      next.toJson().map((k, v) {
        final before = previous[k] as int?;
        final after = v as int?;
        return MapEntry(
          k,
          after == null
              ? before
              : before == null || after > before
              ? after
              : before,
        );
      }),
    );
  }

  static TokenUsage _codexTokens(Map<String, dynamic> u) => TokenUsage(
    input: _n(u['input_tokens']),
    output: _n(u['output_tokens']),
    cachedInput: _n(u['cached_input_tokens']),
    // Older Codex schemas have no cache-write category: those models did not emit writes.
    cacheWrite: u.containsKey('cache_write_input_tokens')
        ? _n(u['cache_write_input_tokens'])
        : 0,
    reasoning: _n(u['reasoning_output_tokens']),
  );

  void _codex(Map<String, dynamic> r) {
    final p = _map(r['payload']);
    if (r['type'] == 'session_meta') {
      _sessionId = _id(p['id']);
      _startedAt = _date(p['timestamp']) ?? _date(r['timestamp']);
      return;
    }
    if (r['type'] == 'turn_context') {
      _model = _modelName(p['model']);
      _intervalModels.add(_model);
      return;
    }
    final session = _sessionId;
    final timestamp = _date(r['timestamp']);
    if (session == null || timestamp == null) return;
    // Forks can contain history belonging to an earlier thread.
    if (_startedAt != null && timestamp.isBefore(_startedAt!)) {
      if (r['type'] == 'event_msg' && p['type'] == 'token_count') {
        final total = _map(_map(p['info'])['total_token_usage']);
        if (total.isNotEmpty) _previousTotal = _codexTokens(total);
      }
      return;
    }
    final sessionId = 'codex:$session';
    if (r['type'] == 'token_usage_record') {
      final owner = _id(p['thread_id']);
      _intervalHasResponseRecords = true;
      if (owner != null && owner != session) return;
      final response = _id(p['response_id']);
      final usage = _map(p['usage']);
      if (response == null || usage.isEmpty) {
        skippedRecords++;
        return;
      }
      final tokens = _codexTokens(usage);
      final key = 'codex:$response';
      final old = _events[key];
      final consolidated = _maximum(old?.tokens, tokens);
      final threadTotal = _map(p['thread_token_usage']);
      if (threadTotal.isNotEmpty) {
        final overlapping = _fallbacksByTotal.remove(
          _signature(_codexTokens(threadTotal)),
        );
        if (overlapping != null) _events.remove(overlapping);
      }
      _events[key] = UsageEvent(
        id: key,
        sessionId: sessionId,
        timestamp: old?.timestamp ?? timestamp,
        provider: 'openai',
        model: _modelName(p['model']) ?? old?.model ?? _model,
        tokens: consolidated,
        contextInputTokens: tokens.input,
      );
      return;
    }
    if (r['type'] != 'event_msg' || p['type'] != 'token_count') return;
    final info = _map(p['info']);
    final totalMap = _map(info['total_token_usage']);
    if (totalMap.isEmpty) return;
    final total = _codexTokens(totalMap);
    final last = _codexTokens(_map(info['last_token_usage']));
    final previous = _previousTotal;
    final fallbackModel = _intervalModels.length > 1 ? null : _model;
    _intervalModels.clear();
    final coveredByResponses = _intervalHasResponseRecords;
    _intervalHasResponseRecords = false;
    final reset =
        previous != null &&
        ((total.input ?? 0) < (previous.input ?? 0) ||
            (total.output ?? 0) < (previous.output ?? 0));
    final delta = <String, dynamic>{};
    for (final entry in total.toJson().entries) {
      final value = entry.value as int?;
      final baseline = previous?.toJson()[entry.key] as int? ?? 0;
      final difference = reset
          ? last.toJson()[entry.key] as int?
          : value == null
          ? null
          : value - baseline;
      delta[entry.key] = difference?.clamp(0, 1 << 62);
    }
    _previousTotal = total;
    if (coveredByResponses) return;
    final tokens = TokenUsage.fromJson(delta);
    if ((tokens.input ?? 0) + (tokens.output ?? 0) == 0) return;
    final turn = _id(p['turn_id']) ?? _id(r['turn_id']) ?? 'snapshot';
    final key =
        'codex:$session:$turn:${timestamp.toIso8601String()}:${total.input}:${total.output}';
    _fallbacksByTotal[_signature(total)] = key;
    _events[key] = UsageEvent(
      id: key,
      sessionId: sessionId,
      timestamp: timestamp,
      provider: 'openai',
      model: fallbackModel,
      tokens: tokens,
      contextInputTokens:
          tokens.input == last.input && tokens.output == last.output
          ? last.input
          : null,
    );
  }
}
