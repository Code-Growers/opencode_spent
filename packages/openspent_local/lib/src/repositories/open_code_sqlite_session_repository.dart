import 'dart:io';

import 'package:openspent_core/openspent_core.dart';
import 'package:sqlite3/sqlite3.dart';

final class OpenCodeSqliteSessionRepository
    implements OpenCodeSessionRepository {
  OpenCodeSqliteSessionRepository(this._databaseFile);

  final File _databaseFile;

  @override
  Future<List<OpenCodeSession>> readSessions() async {
    _validateDatabaseFile(_databaseFile);

    final snapshotDirectory = await _createSnapshot(_databaseFile);
    final snapshotDatabaseFile = File(
      '${snapshotDirectory.path}/${_databaseFile.uri.pathSegments.last}',
    );

    Database? database;

    try {
      database = sqlite3.open(
        snapshotDatabaseFile.path,
        mode: OpenMode.readOnly,
      );

      final sessionRows = database.select(_sessionsQuery);
      final assistantRows = database.select(_assistantMessagesQuery);
      final assistantMessagesBySession = _groupAssistantMessages(assistantRows);

      return List<OpenCodeSession>.unmodifiable(
        sessionRows
            .map(
              (row) => _mapSessionRow(
                row,
                assistantMessagesBySession[row['id']] ??
                    const <_AssistantMessage>[],
              ),
            )
            .toList(growable: false),
      );
    } on SqliteException {
      throw const FormatException(
        'Failed to read imported OpenCode SQLite sessions.',
      );
    } finally {
      database?.dispose();
      if (await snapshotDirectory.exists()) {
        await snapshotDirectory.delete(recursive: true);
      }
    }
  }

  @override
  Future<void> writeSessions(Iterable<OpenCodeSession> sessions) {
    throw UnsupportedError(
      'OpenCodeSqliteSessionRepository is read-only and cannot write sessions.',
    );
  }

  static void _validateDatabaseFile(File databaseFile) {
    if (!databaseFile.existsSync()) {
      throw ArgumentError(
        'Expected an existing SQLite database file for import.',
      );
    }
  }

  static Future<Directory> _createSnapshot(File databaseFile) async {
    final snapshotDirectory = await Directory.systemTemp.createTemp(
      'openspent_opencode_import_',
    );

    try {
      final snapshotDatabaseFile = File(
        '${snapshotDirectory.path}/${databaseFile.uri.pathSegments.last}',
      );
      await databaseFile.copy(snapshotDatabaseFile.path);
      await _copySiblingIfPresent(
        source: File('${databaseFile.path}-wal'),
        target: File('${snapshotDatabaseFile.path}-wal'),
      );
      await _copySiblingIfPresent(
        source: File('${databaseFile.path}-shm'),
        target: File('${snapshotDatabaseFile.path}-shm'),
      );
      return snapshotDirectory;
    } on FileSystemException {
      if (await snapshotDirectory.exists()) {
        await snapshotDirectory.delete(recursive: true);
      }
      throw StateError('Failed to snapshot imported SQLite database.');
    }
  }

  static Future<void> _copySiblingIfPresent({
    required File source,
    required File target,
  }) async {
    if (await source.exists()) {
      await source.copy(target.path);
    }
  }

  static Map<String, List<_AssistantMessage>> _groupAssistantMessages(
    ResultSet rows,
  ) {
    final grouped = <String, List<_AssistantMessage>>{};

    for (final row in rows) {
      final sessionId = row['session_id'];
      if (sessionId is! String || sessionId.isEmpty) {
        throw const FormatException(
          'Expected message.session_id to be a non-empty string.',
        );
      }

      grouped
          .putIfAbsent(sessionId, () => <_AssistantMessage>[])
          .add(_AssistantMessage.fromRow(row));
    }

    return grouped;
  }

  static OpenCodeSession _mapSessionRow(
    Row row,
    List<_AssistantMessage> assistantMessages,
  ) {
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

    final assistantMessageCountRaw = row['assistant_message_count'];
    if (assistantMessageCountRaw is! int || assistantMessageCountRaw < 0) {
      throw const FormatException(
        'Expected assistant message count to be a non-negative integer.',
      );
    }

    final createdAt = _parseUnixMillisecondsUtc(
      createdAtRaw,
      fieldPath: 'session.time_created',
    );

    if (assistantMessages.isEmpty) {
      if (assistantMessageCountRaw != 0) {
        throw const FormatException(
          'Expected assistant message count to match imported assistant rows.',
        );
      }

      return OpenCodeSession(id: id, createdAt: createdAt);
    }

    if (assistantMessageCountRaw != assistantMessages.length) {
      throw const FormatException(
        'Expected assistant message count to match imported assistant rows.',
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

    final inputTokens = assistantMessages.fold<int>(
      0,
      (sum, message) => sum + message.inputTokens,
    );
    final outputTokens = assistantMessages.fold<int>(
      0,
      (sum, message) => sum + message.outputTokens,
    );
    final totalCostUsd = assistantMessages.fold<double>(
      0,
      (sum, message) => sum + message.totalCostUsd,
    );

    return OpenCodeSession(
      id: id,
      createdAt: createdAt,
      modelName: latestAssistant.modelName,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      totalCostUsd: totalCostUsd,
      subagentCategory: null,
    );
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

  static int _readNonNegativeInt(Object? value, {required String fieldPath}) {
    if (value is! int || value < 0) {
      throw FormatException(
        'Expected $fieldPath to be a non-negative integer.',
      );
    }

    return value;
  }

  static double _readNonNegativeDouble(
    Object? value, {
    required String fieldPath,
  }) {
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

  static const String _sessionsQuery = r'''
    WITH
    assistant_aggregates AS (
      SELECT
        session_id,
        COUNT(*) AS assistant_message_count
      FROM message
      WHERE json_extract(data, '$.role') = 'assistant'
      GROUP BY session_id
    )
    SELECT
      session.id AS id,
      session.time_created AS created_at,
      COALESCE(assistant_aggregates.assistant_message_count, 0)
        AS assistant_message_count
    FROM session
    LEFT JOIN assistant_aggregates
      ON assistant_aggregates.session_id = session.id
    WHERE session.time_archived IS NULL
    ORDER BY session.time_created ASC, session.id ASC
  ''';

  static const String _assistantMessagesQuery = r'''
    SELECT
      session_id,
      id,
      time_created,
      json_extract(data, '$.modelID') AS model_name,
      json_extract(data, '$.tokens.input') AS input_tokens,
      json_extract(data, '$.tokens.output') AS output_tokens,
      json_extract(data, '$.cost') AS total_cost_usd
    FROM message
    WHERE json_extract(data, '$.role') = 'assistant'
    ORDER BY session_id ASC, time_created ASC, id ASC
  ''';
}

final class _AssistantMessage {
  const _AssistantMessage({
    required this.messageId,
    required this.createdAt,
    required this.modelName,
    required this.inputTokens,
    required this.outputTokens,
    required this.totalCostUsd,
  });

  final String messageId;
  final DateTime createdAt;
  final String modelName;
  final int inputTokens;
  final int outputTokens;
  final double totalCostUsd;

  factory _AssistantMessage.fromRow(Row row) {
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

    final modelName = row['model_name'];
    if (modelName is! String || modelName.isEmpty) {
      throw const FormatException(
        'Expected assistant message.modelID to be a non-empty string.',
      );
    }

    return _AssistantMessage(
      messageId: messageId,
      createdAt: OpenCodeSqliteSessionRepository._parseUnixMillisecondsUtc(
        createdAtRaw,
        fieldPath: 'message.time_created',
      ),
      modelName: modelName,
      inputTokens: OpenCodeSqliteSessionRepository._readNonNegativeInt(
        row['input_tokens'],
        fieldPath: 'assistant.tokens.input',
      ),
      outputTokens: OpenCodeSqliteSessionRepository._readNonNegativeInt(
        row['output_tokens'],
        fieldPath: 'assistant.tokens.output',
      ),
      totalCostUsd: OpenCodeSqliteSessionRepository._readNonNegativeDouble(
        row['total_cost_usd'],
        fieldPath: 'assistant.cost',
      ),
    );
  }
}
