import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:openspent_core/openspent_core.dart';

import '../database/open_spent_local_database.dart';

final class LocalOpenCodeSessionRepository
    implements OpenCodeSessionRepository {
  LocalOpenCodeSessionRepository(this._database);

  final OpenSpentLocalDatabase _database;

  @override
  Future<List<OpenCodeSession>> readSessions() async {
    final rows =
        await (_database.select(_database.openCodeSessions)
              ..orderBy(<OrderingTerm Function(OpenCodeSessions)>[
                (OpenCodeSessions sessions) =>
                    OrderingTerm.asc(sessions.createdAtUtc),
                (OpenCodeSessions sessions) => OrderingTerm.asc(sessions.id),
              ]))
            .get();

    return List<OpenCodeSession>.unmodifiable(
      rows.map(_mapRow).toList(growable: false),
    );
  }

  @override
  Future<void> writeSessions(Iterable<OpenCodeSession> sessions) async {
    await _database.transaction(() async {
      final sessionCompanions = sessions
          .map((OpenCodeSession session) {
            _validateSession(session);
            return OpenCodeSessionsCompanion.insert(
              id: session.id,
              createdAtUtc: session.createdAt.toUtc(),
              provider: Value<String?>(
                _normalizeNullableText(session.provider),
              ),
              modelName: Value<String?>(session.modelName),
              inputTokens: Value<int?>(session.inputTokens),
              outputTokens: Value<int?>(session.outputTokens),
              totalCostUsd: Value<double?>(session.totalCostUsd),
              requestCount: Value<int?>(session.requestCount),
              toolCallCount: Value<int?>(session.toolCallCount),
              responseCount: Value<int?>(session.responseCount),
              totalResponseTimeMs: Value<int?>(session.totalResponseTimeMs),
              subagentCategory: Value<String?>(
                _sanitizeSubagentCategory(session.subagentCategory),
              ),
              usageSlicesJson: Value<String?>(_encodeUsageSlices(session)),
            );
          })
          .toList(growable: false);

      await _database.batch((Batch batch) {
        batch.insertAll(
          _database.openCodeSessions,
          sessionCompanions,
          mode: InsertMode.insertOrReplace,
        );
      });
    });
  }

  OpenCodeSession _mapRow(LocalOpenCodeSessionRow row) {
    return OpenCodeSession(
      id: row.id,
      createdAt: row.createdAtUtc.toUtc(),
      provider: _normalizeNullableText(row.provider),
      modelName: row.modelName,
      inputTokens: row.inputTokens,
      outputTokens: row.outputTokens,
      totalCostUsd: row.totalCostUsd,
      requestCount: row.requestCount,
      toolCallCount: row.toolCallCount,
      responseCount: row.responseCount,
      totalResponseTimeMs: row.totalResponseTimeMs,
      subagentCategory: _sanitizeSubagentCategory(row.subagentCategory),
      usageSlices: _decodeUsageSlices(row.usageSlicesJson),
    );
  }

  static void _validateSession(OpenCodeSession session) {
    if (session.inputTokens case final int value when value < 0) {
      throw ArgumentError.value(
        session.inputTokens,
        'session.inputTokens',
        'Expected a non-negative token count.',
      );
    }
    if (session.outputTokens case final int value when value < 0) {
      throw ArgumentError.value(
        session.outputTokens,
        'session.outputTokens',
        'Expected a non-negative token count.',
      );
    }
    if (session.totalCostUsd case final double value
        when !value.isFinite || value < 0) {
      throw ArgumentError.value(
        session.totalCostUsd,
        'session.totalCostUsd',
        'Expected a finite non-negative cost.',
      );
    }
    if (session.requestCount case final int value when value < 0) {
      throw ArgumentError.value(
        session.requestCount,
        'session.requestCount',
        'Expected a non-negative request count.',
      );
    }
    if (session.toolCallCount case final int value when value < 0) {
      throw ArgumentError.value(
        session.toolCallCount,
        'session.toolCallCount',
        'Expected a non-negative tool call count.',
      );
    }
    if (session.responseCount case final int value when value < 0) {
      throw ArgumentError.value(
        session.responseCount,
        'session.responseCount',
        'Expected a non-negative response count.',
      );
    }
    if (session.totalResponseTimeMs case final int value when value < 0) {
      throw ArgumentError.value(
        session.totalResponseTimeMs,
        'session.totalResponseTimeMs',
        'Expected a non-negative total response time.',
      );
    }
    for (final usageSlice in session.usageSlices) {
      if (usageSlice.provider.trim().isEmpty) {
        throw ArgumentError.value(
          usageSlice.provider,
          'usageSlice.provider',
          'Expected a non-empty provider.',
        );
      }
      if (usageSlice.modelName.trim().isEmpty) {
        throw ArgumentError.value(
          usageSlice.modelName,
          'usageSlice.modelName',
          'Expected a non-empty model name.',
        );
      }
      if (usageSlice.inputTokens case final int value when value < 0) {
        throw ArgumentError.value(
          usageSlice.inputTokens,
          'usageSlice.inputTokens',
          'Expected a non-negative token count.',
        );
      }
      if (usageSlice.outputTokens case final int value when value < 0) {
        throw ArgumentError.value(
          usageSlice.outputTokens,
          'usageSlice.outputTokens',
          'Expected a non-negative token count.',
        );
      }
      if (usageSlice.totalCostUsd case final double value
          when !value.isFinite || value < 0) {
        throw ArgumentError.value(
          usageSlice.totalCostUsd,
          'usageSlice.totalCostUsd',
          'Expected a finite non-negative cost.',
        );
      }
      if (usageSlice.requestCount case final int value when value < 0) {
        throw ArgumentError.value(
          usageSlice.requestCount,
          'usageSlice.requestCount',
          'Expected a non-negative request count.',
        );
      }
      if (usageSlice.toolCallCount case final int value when value < 0) {
        throw ArgumentError.value(
          usageSlice.toolCallCount,
          'usageSlice.toolCallCount',
          'Expected a non-negative tool call count.',
        );
      }
      if (usageSlice.responseCount case final int value when value < 0) {
        throw ArgumentError.value(
          usageSlice.responseCount,
          'usageSlice.responseCount',
          'Expected a non-negative response count.',
        );
      }
      if (usageSlice.totalResponseTimeMs case final int value when value < 0) {
        throw ArgumentError.value(
          usageSlice.totalResponseTimeMs,
          'usageSlice.totalResponseTimeMs',
          'Expected a non-negative total response time.',
        );
      }
    }
  }

  static String? _normalizeNullableText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  static String? _encodeUsageSlices(OpenCodeSession session) {
    if (session.usageSlices.isEmpty) {
      return null;
    }

    return jsonEncode(
      session.usageSlices
          .map(
            (usageSlice) => <String, Object?>{
              'provider': usageSlice.provider,
              'modelName': usageSlice.modelName,
              'inputTokens': usageSlice.inputTokens,
              'outputTokens': usageSlice.outputTokens,
              'totalCostUsd': usageSlice.totalCostUsd,
              'requestCount': usageSlice.requestCount,
              'toolCallCount': usageSlice.toolCallCount,
              'responseCount': usageSlice.responseCount,
              'totalResponseTimeMs': usageSlice.totalResponseTimeMs,
            },
          )
          .toList(growable: false),
    );
  }

  static List<SessionUsageSlice> _decodeUsageSlices(String? source) {
    if (source == null || source.isEmpty) {
      return const <SessionUsageSlice>[];
    }

    final decoded = jsonDecode(source);
    if (decoded is! List<Object?>) {
      throw const FormatException(
        'Expected usage_slices_json to decode to a JSON list.',
      );
    }

    return decoded.map(_decodeUsageSlice).toList(growable: false);
  }

  static SessionUsageSlice _decodeUsageSlice(Object? value) {
    if (value is! Map<String, Object?>) {
      throw const FormatException(
        'Expected each stored usage slice to be a JSON object.',
      );
    }

    final provider = value['provider'];
    final modelName = value['modelName'];
    if (provider is! String || provider.isEmpty) {
      throw const FormatException(
        'Expected stored usage slice provider to be a non-empty string.',
      );
    }
    if (modelName is! String || modelName.isEmpty) {
      throw const FormatException(
        'Expected stored usage slice modelName to be a non-empty string.',
      );
    }

    return SessionUsageSlice(
      provider: provider,
      modelName: modelName,
      inputTokens: _readNullableNonNegativeInt(
        value['inputTokens'],
        fieldPath: 'usageSlice.inputTokens',
      ),
      outputTokens: _readNullableNonNegativeInt(
        value['outputTokens'],
        fieldPath: 'usageSlice.outputTokens',
      ),
      totalCostUsd: _readNullableNonNegativeDouble(
        value['totalCostUsd'],
        fieldPath: 'usageSlice.totalCostUsd',
      ),
      requestCount: _readNullableNonNegativeInt(
        value['requestCount'],
        fieldPath: 'usageSlice.requestCount',
      ),
      toolCallCount: _readNullableNonNegativeInt(
        value['toolCallCount'],
        fieldPath: 'usageSlice.toolCallCount',
      ),
      responseCount: _readNullableNonNegativeInt(
        value['responseCount'],
        fieldPath: 'usageSlice.responseCount',
      ),
      totalResponseTimeMs: _readNullableNonNegativeInt(
        value['totalResponseTimeMs'],
        fieldPath: 'usageSlice.totalResponseTimeMs',
      ),
    );
  }

  static int? _readNullableNonNegativeInt(
    Object? value, {
    required String fieldPath,
  }) {
    if (value == null) {
      return null;
    }

    if (value is! int || value < 0) {
      throw FormatException(
        'Expected $fieldPath to be a non-negative integer.',
      );
    }

    return value;
  }

  static double? _readNullableNonNegativeDouble(
    Object? value, {
    required String fieldPath,
  }) {
    if (value == null) {
      return null;
    }

    if (value is! num) {
      throw FormatException('Expected $fieldPath to be numeric.');
    }

    final result = value.toDouble();
    if (!result.isFinite || result < 0) {
      throw FormatException(
        'Expected $fieldPath to be a finite non-negative number.',
      );
    }

    return result;
  }

  static String? _sanitizeSubagentCategory(String? value) {
    if (value == null) {
      return null;
    }

    return OpenSpentInfo.supportedSubagentCategories.contains(value)
        ? value
        : null;
  }
}
