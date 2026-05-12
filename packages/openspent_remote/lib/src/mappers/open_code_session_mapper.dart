import 'package:openspent_core/openspent_core.dart';

final class OpenCodeSessionMapper {
  const OpenCodeSessionMapper();

  OpenCodeSession map({
    required Map<String, dynamic> session,
    required List<Map<String, dynamic>> messages,
  }) {
    final id = _readString(session, 'id');
    final createdAt = _parseUnixMillisecondsUtc(
      _readNestedInt(session, <String>['time', 'created']),
      fieldPath: 'session.time.created',
    );

    final orderedMessages =
        messages
            .asMap()
            .entries
            .map(
              (entry) =>
                  _SessionMessageView.fromJson(entry.value, index: entry.key),
            )
            .toList(growable: false)
          ..sort((left, right) {
            final createdAtComparison = left.createdAt.compareTo(
              right.createdAt,
            );
            if (createdAtComparison != 0) {
              return createdAtComparison;
            }

            return left.index.compareTo(right.index);
          });

    final assistantMessages = orderedMessages
        .where((message) => message.role == 'assistant')
        .toList(growable: false);

    if (assistantMessages.isEmpty) {
      return OpenCodeSession(
        id: id,
        createdAt: createdAt,
        requestCount: orderedMessages
            .where((message) => message.role == 'user')
            .length,
        toolCallCount: orderedMessages.fold<int>(
          0,
          (sum, message) => sum + message.toolCallCount,
        ),
        responseCount: 0,
      );
    }

    final latestAssistant = assistantMessages.reduce((current, next) {
      if (next.createdAt.isAfter(current.createdAt)) {
        return next;
      }

      return current;
    });

    final inputTokens = _sumAssistantInts(
      assistantMessages,
      (message) => message.tokens?.input,
    );
    final outputTokens = _sumAssistantInts(
      assistantMessages,
      (message) => message.tokens?.output,
    );
    final totalCostUsd = _sumAssistantDoubles(
      assistantMessages,
      (message) => message.cost,
    );
    final requestCount = orderedMessages
        .where((message) => message.role == 'user')
        .length;
    final toolCallCount = orderedMessages.fold<int>(
      0,
      (sum, message) => sum + message.toolCallCount,
    );
    final responseCount = assistantMessages.length;
    final totalResponseTimeMs = _deriveTotalResponseTimeMs(orderedMessages);
    final usageSlices = _buildUsageSlices(orderedMessages);

    return OpenCodeSession(
      id: id,
      createdAt: createdAt,
      provider: latestAssistant.providerId,
      modelName: latestAssistant.modelId,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      totalCostUsd: totalCostUsd,
      requestCount: requestCount,
      toolCallCount: toolCallCount,
      responseCount: responseCount,
      totalResponseTimeMs: totalResponseTimeMs,
      subagentCategory: null,
      usageSlices: usageSlices,
    );
  }

  static int? _sumAssistantInts(
    Iterable<_SessionMessageView> messages,
    int? Function(_SessionMessageView message) readValue,
  ) {
    var sum = 0;
    var hasValue = false;
    for (final message in messages) {
      final value = readValue(message);
      if (value == null) {
        return hasValue ? null : null;
      }
      hasValue = true;
      sum += value;
    }

    return hasValue ? sum : null;
  }

  static double? _sumAssistantDoubles(
    Iterable<_SessionMessageView> messages,
    double? Function(_SessionMessageView message) readValue,
  ) {
    var sum = 0.0;
    var hasValue = false;
    for (final message in messages) {
      final value = readValue(message);
      if (value == null) {
        return hasValue ? null : null;
      }
      hasValue = true;
      sum += value;
    }

    return hasValue ? sum : null;
  }

  static int? _deriveTotalResponseTimeMs(
    List<_SessionMessageView> orderedMessages,
  ) {
    var total = 0;
    var hasDerivableResponse = false;

    for (var index = 1; index < orderedMessages.length; index++) {
      final message = orderedMessages[index];
      final previousMessage = orderedMessages[index - 1];
      if (message.role != 'assistant' || previousMessage.role != 'user') {
        continue;
      }

      final delta =
          message.createdAt.millisecondsSinceEpoch -
          previousMessage.createdAt.millisecondsSinceEpoch;
      if (delta < 0) {
        continue;
      }

      hasDerivableResponse = true;
      total += delta;
    }

    return hasDerivableResponse ? total : null;
  }

  static List<SessionUsageSlice> _buildUsageSlices(
    List<_SessionMessageView> orderedMessages,
  ) {
    final grouped = <String, _MutableUsageSlice>{};

    for (var index = 0; index < orderedMessages.length; index++) {
      final message = orderedMessages[index];
      if (message.role != 'assistant') {
        continue;
      }

      final provider = _normalizeNullableString(message.providerId);
      final modelName = _normalizeNullableString(message.modelId);
      if (provider == null || modelName == null) {
        continue;
      }

      final key = '$provider\u0000$modelName';
      final usageSlice = grouped.putIfAbsent(
        key,
        () => _MutableUsageSlice(provider: provider, modelName: modelName),
      );
      usageSlice.responseCount += 1;
      usageSlice.toolCallCount += message.toolCallCount;
      usageSlice.addInputTokens(message.tokens?.input);
      usageSlice.addOutputTokens(message.tokens?.output);
      usageSlice.addTotalCostUsd(message.cost);

      if (index > 0 && orderedMessages[index - 1].role == 'user') {
        final delta =
            message.createdAt.millisecondsSinceEpoch -
            orderedMessages[index - 1].createdAt.millisecondsSinceEpoch;
        if (delta >= 0) {
          usageSlice.requestCount += 1;
          usageSlice.totalResponseTimeMs += delta;
          usageSlice.hasResponseTime = true;
        }
      }
    }

    final entries = grouped.values.toList()
      ..sort((left, right) {
        final providerComparison = left.provider.compareTo(right.provider);
        if (providerComparison != 0) {
          return providerComparison;
        }

        return left.modelName.compareTo(right.modelName);
      });

    return entries.map((entry) => entry.build()).toList(growable: false);
  }

  static String? _normalizeNullableString(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  static String _readString(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }

    throw FormatException('Expected $key to be a non-empty string.');
  }

  static int _readNestedInt(Map<String, dynamic> source, List<String> path) {
    Object? current = source;
    for (final segment in path) {
      if (current is! Map<String, dynamic> || !current.containsKey(segment)) {
        throw FormatException('Missing ${path.join('.')} field.');
      }
      current = current[segment];
    }

    if (current is int) {
      return current;
    }

    throw FormatException('Expected ${path.join('.')} to be an integer.');
  }

  static DateTime _parseUnixMillisecondsUtc(
    int value, {
    required String fieldPath,
  }) {
    try {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
    } on ArgumentError {
      throw FormatException('Invalid $fieldPath value: $value');
    }
  }
}

final class _SessionMessageView {
  const _SessionMessageView({
    required this.index,
    required this.role,
    required this.createdAt,
    required this.toolCallCount,
    this.modelId,
    this.providerId,
    required this.cost,
    required this.tokens,
  });

  final int index;
  final String role;
  final DateTime createdAt;
  final int toolCallCount;
  final String? modelId;
  final String? providerId;
  final double? cost;
  final _SessionTokensView? tokens;

  factory _SessionMessageView.fromJson(
    Map<String, dynamic> json, {
    required int index,
  }) {
    final info = json['info'];
    if (info is! Map<String, dynamic>) {
      throw const FormatException('Expected message.info to be an object.');
    }

    final role = info['role'];
    if (role is! String || role.isEmpty) {
      throw const FormatException('Expected message.info.role to be a string.');
    }

    final createdAtRaw = info['time'];
    if (createdAtRaw is! Map<String, dynamic>) {
      throw const FormatException(
        'Expected message.info.time to be an object.',
      );
    }

    final createdValue = createdAtRaw['created'];
    if (createdValue is! int) {
      throw const FormatException(
        'Expected message.info.time.created to be an integer.',
      );
    }

    final parts = json['parts'];
    var toolCallCount = 0;
    if (parts != null) {
      if (parts is! List) {
        throw const FormatException('Expected message.parts to be a list.');
      }
      for (final part in parts) {
        if (part is! Map) {
          throw const FormatException(
            'Expected each message part to be an object.',
          );
        }
        final dynamic type = part['type'];
        if (type == 'tool') {
          toolCallCount += 1;
        }
      }
    }

    if (role != 'assistant') {
      return _SessionMessageView(
        index: index,
        role: role,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          createdValue,
          isUtc: true,
        ),
        toolCallCount: toolCallCount,
        cost: null,
        tokens: null,
      );
    }

    final modelId = _readNullableString(
      info['modelID'],
      fieldPath: 'assistant message.info.modelID',
    );
    final providerId = _readNullableString(
      info['providerID'],
      fieldPath: 'assistant message.info.providerID',
    );
    final cost = _readNullableCost(info['cost']);
    final tokens = _readNullableTokens(info['tokens']);

    return _SessionMessageView(
      index: index,
      role: role,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdValue, isUtc: true),
      toolCallCount: toolCallCount,
      modelId: modelId,
      providerId: providerId,
      cost: cost,
      tokens: tokens,
    );
  }

  static String? _readNullableString(
    Object? value, {
    required String fieldPath,
  }) {
    if (value == null) {
      return null;
    }

    if (value is! String) {
      throw FormatException('Expected $fieldPath to be a string.');
    }

    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  static double? _readNullableCost(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is! num || !value.isFinite || value < 0) {
      throw const FormatException(
        'Expected assistant message.info.cost to be a non-negative number.',
      );
    }

    return value.toDouble();
  }

  static _SessionTokensView? _readNullableTokens(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is! Map<String, dynamic>) {
      throw const FormatException(
        'Expected assistant message.info.tokens to be an object.',
      );
    }

    return _SessionTokensView.fromJson(value);
  }
}

final class _MutableUsageSlice {
  _MutableUsageSlice({required this.provider, required this.modelName});

  final String provider;
  final String modelName;
  int? _inputTokens = 0;
  int? _outputTokens = 0;
  double? _totalCostUsd = 0;
  int requestCount = 0;
  int toolCallCount = 0;
  int responseCount = 0;
  int totalResponseTimeMs = 0;
  bool hasResponseTime = false;

  void addInputTokens(int? value) {
    if (_inputTokens == null || value == null) {
      _inputTokens = null;
      return;
    }

    _inputTokens = _inputTokens! + value;
  }

  void addOutputTokens(int? value) {
    if (_outputTokens == null || value == null) {
      _outputTokens = null;
      return;
    }

    _outputTokens = _outputTokens! + value;
  }

  void addTotalCostUsd(double? value) {
    if (_totalCostUsd == null || value == null) {
      _totalCostUsd = null;
      return;
    }

    _totalCostUsd = _totalCostUsd! + value;
  }

  SessionUsageSlice build() {
    return SessionUsageSlice(
      provider: provider,
      modelName: modelName,
      inputTokens: _inputTokens,
      outputTokens: _outputTokens,
      totalCostUsd: _totalCostUsd,
      requestCount: requestCount,
      toolCallCount: toolCallCount,
      responseCount: responseCount,
      totalResponseTimeMs: hasResponseTime ? totalResponseTimeMs : null,
    );
  }
}

final class _SessionTokensView {
  const _SessionTokensView({required this.input, required this.output});

  final int input;
  final int output;

  factory _SessionTokensView.fromJson(Map<String, dynamic> json) {
    final input = json['input'];
    final output = json['output'];

    if (input is! int || input < 0) {
      throw const FormatException(
        'Expected assistant message.info.tokens.input to be a non-negative integer.',
      );
    }

    if (output is! int || output < 0) {
      throw const FormatException(
        'Expected assistant message.info.tokens.output to be a non-negative integer.',
      );
    }

    return _SessionTokensView(input: input, output: output);
  }
}
