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
              modelName: Value<String?>(session.modelName),
              inputTokens: Value<int?>(session.inputTokens),
              outputTokens: Value<int?>(session.outputTokens),
              totalCostUsd: Value<double?>(session.totalCostUsd),
              subagentCategory: Value<String?>(
                _sanitizeSubagentCategory(session.subagentCategory),
              ),
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
      modelName: row.modelName,
      inputTokens: row.inputTokens,
      outputTokens: row.outputTokens,
      totalCostUsd: row.totalCostUsd,
      subagentCategory: _sanitizeSubagentCategory(row.subagentCategory),
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
