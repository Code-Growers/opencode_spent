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

    final assistantMessages = messages
        .map(_SessionMessageView.fromJson)
        .where((message) => message.role == 'assistant')
        .toList(growable: false);

    if (assistantMessages.isEmpty) {
      return OpenCodeSession(id: id, createdAt: createdAt);
    }

    final latestAssistant = assistantMessages.reduce((current, next) {
      if (next.createdAt.isAfter(current.createdAt)) {
        return next;
      }

      return current;
    });

    final inputTokens = assistantMessages.fold<int>(
      0,
      (sum, message) => sum + message.tokens.input,
    );
    final outputTokens = assistantMessages.fold<int>(
      0,
      (sum, message) => sum + message.tokens.output,
    );
    final totalCostUsd = assistantMessages.fold<double>(
      0,
      (sum, message) => sum + message.cost,
    );

    return OpenCodeSession(
      id: id,
      createdAt: createdAt,
      modelName: latestAssistant.modelId,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      totalCostUsd: totalCostUsd,
      subagentCategory: null,
    );
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
    required this.role,
    required this.createdAt,
    required this.modelId,
    required this.cost,
    required this.tokens,
  });

  final String role;
  final DateTime createdAt;
  final String modelId;
  final double cost;
  final _SessionTokensView tokens;

  factory _SessionMessageView.fromJson(Map<String, dynamic> json) {
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

    if (role != 'assistant') {
      return _SessionMessageView(
        role: role,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          createdValue,
          isUtc: true,
        ),
        modelId: '',
        cost: 0,
        tokens: const _SessionTokensView(input: 0, output: 0),
      );
    }

    final modelId = info['modelID'];
    if (modelId is! String || modelId.isEmpty) {
      throw const FormatException(
        'Expected assistant message.info.modelID to be a non-empty string.',
      );
    }

    final cost = info['cost'];
    if (cost is! num || !cost.isFinite || cost < 0) {
      throw const FormatException(
        'Expected assistant message.info.cost to be a non-negative number.',
      );
    }

    final tokens = info['tokens'];
    if (tokens is! Map<String, dynamic>) {
      throw const FormatException(
        'Expected assistant message.info.tokens to be an object.',
      );
    }

    return _SessionMessageView(
      role: role,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdValue, isUtc: true),
      modelId: modelId,
      cost: cost.toDouble(),
      tokens: _SessionTokensView.fromJson(tokens),
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
