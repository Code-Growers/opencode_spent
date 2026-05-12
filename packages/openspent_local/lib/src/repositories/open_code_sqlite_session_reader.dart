import 'dart:convert';

import 'package:openspent_core/openspent_core.dart';
import 'package:sqlite3/common.dart';

List<OpenCodeSession> readOpenCodeSessions(CommonDatabase database) {
  final sessionRows = database.select(_sessionsQuery);
  final messageRows = database.select(_messagesQuery);
  final messagesBySession = _groupMessages(messageRows);

  return List<OpenCodeSession>.unmodifiable(
    sessionRows
        .map(
          (row) => _mapSessionRow(
            row,
            messagesBySession[row['id']] ?? const <_SessionMessage>[],
          ),
        )
        .toList(growable: false),
  );
}

Map<String, List<_SessionMessage>> _groupMessages(ResultSet rows) {
  final grouped = <String, List<_SessionMessage>>{};

  for (final row in rows) {
    final sessionId = row['session_id'];
    if (sessionId is! String || sessionId.isEmpty) {
      throw const FormatException(
        'Expected message.session_id to be a non-empty string.',
      );
    }

    grouped
        .putIfAbsent(sessionId, () => <_SessionMessage>[])
        .add(_SessionMessage.fromRow(row));
  }

  return grouped;
}

OpenCodeSession _mapSessionRow(Row row, List<_SessionMessage> messages) {
  final id = row['id'];
  if (id is! String || id.isEmpty) {
    throw const FormatException(
      'Expected session.id to be a non-empty string.',
    );
  }

  final createdAtRaw = row['created_at'];
  if (createdAtRaw is! int) {
    throw const FormatException(
      'Expected session.time_created to be an integer.',
    );
  }

  final messageCountRaw = row['message_count'];
  if (messageCountRaw is! int || messageCountRaw < 0) {
    throw const FormatException(
      'Expected message count to be a non-negative integer.',
    );
  }

  final createdAt = _parseUnixMillisecondsUtc(
    createdAtRaw,
    fieldPath: 'session.time_created',
  );

  if (messages.isEmpty) {
    if (messageCountRaw != 0) {
      throw const FormatException(
        'Expected message count to match imported message rows.',
      );
    }

    return OpenCodeSession(id: id, createdAt: createdAt);
  }

  if (messageCountRaw != messages.length) {
    throw const FormatException(
      'Expected message count to match imported message rows.',
    );
  }

  messages.sort((left, right) {
    final createdAtComparison = left.createdAt.compareTo(right.createdAt);
    if (createdAtComparison != 0) {
      return createdAtComparison;
    }

    return left.messageId.compareTo(right.messageId);
  });

  final assistantMessages = messages
      .where((message) => message.role == 'assistant')
      .toList(growable: false);

  if (assistantMessages.isEmpty) {
    return OpenCodeSession(
      id: id,
      createdAt: createdAt,
      requestCount: messages.where((message) => message.role == 'user').length,
      toolCallCount: messages.fold<int>(
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
    if (next.createdAt.isAtSameMomentAs(current.createdAt) &&
        next.messageId.compareTo(current.messageId) > 0) {
      return next;
    }

    return current;
  });

  final requestCount = messages
      .where((message) => message.role == 'user')
      .length;
  final toolCallCount = messages.fold<int>(
    0,
    (sum, message) => sum + message.toolCallCount,
  );
  final responseCount = assistantMessages.length;
  final inputTokens = _sumAssistantInts(
    assistantMessages,
    (message) => message.inputTokens,
  );
  final outputTokens = _sumAssistantInts(
    assistantMessages,
    (message) => message.outputTokens,
  );
  final totalCostUsd = _sumAssistantDoubles(
    assistantMessages,
    (message) => message.totalCostUsd,
  );
  final totalResponseTimeMs = _deriveTotalResponseTimeMs(messages);
  final usageSlices = _buildUsageSlices(messages);

  return OpenCodeSession(
    id: id,
    createdAt: createdAt,
    provider: latestAssistant.provider,
    modelName: latestAssistant.modelName,
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

int? _sumAssistantInts(
  Iterable<_SessionMessage> messages,
  int? Function(_SessionMessage message) readValue,
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

double? _sumAssistantDoubles(
  Iterable<_SessionMessage> messages,
  double? Function(_SessionMessage message) readValue,
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

int? _deriveTotalResponseTimeMs(List<_SessionMessage> orderedMessages) {
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

List<SessionUsageSlice> _buildUsageSlices(
  List<_SessionMessage> orderedMessages,
) {
  final grouped = <String, _MutableUsageSlice>{};

  for (var index = 0; index < orderedMessages.length; index++) {
    final message = orderedMessages[index];
    if (message.role != 'assistant') {
      continue;
    }

    final provider = message.provider;
    final modelName = message.modelName;
    if (provider == null ||
        provider.isEmpty ||
        modelName == null ||
        modelName.isEmpty) {
      continue;
    }

    final key = '$provider\u0000$modelName';
    final usageSlice = grouped.putIfAbsent(
      key,
      () => _MutableUsageSlice(provider: provider, modelName: modelName),
    );
    usageSlice.responseCount += 1;
    usageSlice.toolCallCount += message.toolCallCount;
    usageSlice.addInputTokens(message.inputTokens);
    usageSlice.addOutputTokens(message.outputTokens);
    usageSlice.addTotalCostUsd(message.totalCostUsd);

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

DateTime _parseUnixMillisecondsUtc(int value, {required String fieldPath}) {
  try {
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  } on ArgumentError {
    throw FormatException('Invalid $fieldPath value: $value');
  }
}

int _readNonNegativeInt(Object? value, {required String fieldPath}) {
  if (value is! int || value < 0) {
    throw FormatException('Expected $fieldPath to be a non-negative integer.');
  }

  return value;
}

double _readNonNegativeDouble(Object? value, {required String fieldPath}) {
  if (value is! num) {
    throw FormatException('Expected $fieldPath to be a number.');
  }

  final result = value.toDouble();
  if (!result.isFinite || result < 0) {
    throw FormatException(
      'Expected $fieldPath to be a finite non-negative number.',
    );
  }

  return result;
}

const String sessionsQuery = r'''
  WITH
  message_aggregates AS (
    SELECT
      session_id,
      COUNT(*) AS message_count
    FROM message
    GROUP BY session_id
  )
  SELECT
    session.id AS id,
    session.time_created AS created_at,
    COALESCE(message_aggregates.message_count, 0)
      AS message_count
  FROM session
  LEFT JOIN message_aggregates
    ON message_aggregates.session_id = session.id
  WHERE session.time_archived IS NULL
  ORDER BY session.time_created ASC, session.id ASC
''';

const String messagesQuery = r'''
  SELECT
    session_id,
    id,
    time_created,
    data
  FROM message
  ORDER BY session_id ASC, time_created ASC, id ASC
''';

const _sessionsQuery = sessionsQuery;
const _messagesQuery = messagesQuery;

final class _SessionMessage {
  const _SessionMessage({
    required this.messageId,
    required this.role,
    required this.createdAt,
    required this.toolCallCount,
    this.provider,
    this.modelName,
    required this.inputTokens,
    required this.outputTokens,
    required this.totalCostUsd,
  });

  final String messageId;
  final String role;
  final DateTime createdAt;
  final int toolCallCount;
  final String? provider;
  final String? modelName;
  final int? inputTokens;
  final int? outputTokens;
  final double? totalCostUsd;

  factory _SessionMessage.fromRow(Row row) {
    final messageId = row['id'];
    if (messageId is! String || messageId.isEmpty) {
      throw const FormatException(
        'Expected message.id to be a non-empty string.',
      );
    }

    final createdAtRaw = row['time_created'];
    if (createdAtRaw is! int) {
      throw const FormatException(
        'Expected message.time_created to be an integer.',
      );
    }

    final data = row['data'];
    if (data is! String || data.isEmpty) {
      throw const FormatException(
        'Expected message.data to be a non-empty JSON string.',
      );
    }

    final decoded = jsonDecode(data);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException(
        'Expected message.data to decode to a JSON object.',
      );
    }

    final role = decoded['role'];
    if (role is! String || role.isEmpty) {
      throw const FormatException(
        'Expected message.role to be a non-empty string.',
      );
    }

    final parts = decoded['parts'];
    var toolCallCount = 0;
    if (parts != null) {
      if (parts is! List<Object?>) {
        throw const FormatException(
          'Expected message.parts to be a JSON list.',
        );
      }
      for (final part in parts) {
        if (part is! Map<String, Object?>) {
          throw const FormatException(
            'Expected each message part to be a JSON object.',
          );
        }
        if (part['type'] == 'tool') {
          toolCallCount += 1;
        }
      }
    }

    return _SessionMessage(
      messageId: messageId,
      role: role,
      createdAt: _parseUnixMillisecondsUtc(
        createdAtRaw,
        fieldPath: 'message.time_created',
      ),
      toolCallCount: toolCallCount,
      provider: _readNullableString(
        decoded['providerID'],
        fieldPath: 'message.providerID',
      ),
      modelName: _readNullableString(
        decoded['modelID'],
        fieldPath: 'message.modelID',
      ),
      inputTokens: _readNullableNonNegativeInt(
        _readNestedValue(decoded, <String>['tokens', 'input']),
        fieldPath: 'assistant.tokens.input',
      ),
      outputTokens: _readNullableNonNegativeInt(
        _readNestedValue(decoded, <String>['tokens', 'output']),
        fieldPath: 'assistant.tokens.output',
      ),
      totalCostUsd: _readNullableNonNegativeDouble(
        decoded['cost'],
        fieldPath: 'assistant.cost',
      ),
    );
  }

  static Object? _readNestedValue(
    Map<String, Object?> source,
    List<String> path,
  ) {
    Object? current = source;
    for (final segment in path) {
      if (current is! Map<String, Object?>) {
        return null;
      }
      current = current[segment];
      if (current == null) {
        return null;
      }
    }

    return current;
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

  static int? _readNullableNonNegativeInt(
    Object? value, {
    required String fieldPath,
  }) {
    if (value == null) {
      return null;
    }

    return _readNonNegativeInt(value, fieldPath: fieldPath);
  }

  static double? _readNullableNonNegativeDouble(
    Object? value, {
    required String fieldPath,
  }) {
    if (value == null) {
      return null;
    }

    return _readNonNegativeDouble(value, fieldPath: fieldPath);
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
