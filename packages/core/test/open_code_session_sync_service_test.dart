import 'package:openspent_core/openspent_core.dart';
import 'package:test/test.dart';

void main() {
  group('OpenCodeSessionSyncService', () {
    test('passes remote sessions through to local write', () async {
      final sessions = <OpenCodeSession>[
        OpenCodeSession(
          id: 'session-1',
          createdAt: DateTime.utc(2026, 5, 2, 10, 15),
          modelName: 'gpt-5.4',
          inputTokens: 120,
          outputTokens: 30,
          totalCostUsd: 0.42,
          subagentCategory: 'quick',
        ),
      ];
      final remoteRepository = _SpyOpenCodeSessionRepository(
        readSessionsResult: sessions,
      );
      final localRepository = _SpyOpenCodeSessionRepository();
      final service = OpenCodeSessionSyncService(
        remoteRepository: remoteRepository,
        localRepository: localRepository,
      );

      await service.syncSessions();

      expect(remoteRepository.readSessionsCallCount, 1);
      expect(localRepository.writeSessionsCallCount, 1);
      expect(localRepository.writtenSessions, same(sessions));
    });

    test('does not call local write when remote read fails', () async {
      final error = StateError('remote read failed');
      final remoteRepository = _SpyOpenCodeSessionRepository(readError: error);
      final localRepository = _SpyOpenCodeSessionRepository();
      final service = OpenCodeSessionSyncService(
        remoteRepository: remoteRepository,
        localRepository: localRepository,
      );

      await expectLater(service.syncSessions(), throwsA(same(error)));

      expect(remoteRepository.readSessionsCallCount, 1);
      expect(localRepository.writeSessionsCallCount, 0);
      expect(localRepository.writtenSessions, isNull);
    });

    test('bubbles local write failures unchanged', () async {
      final sessions = <OpenCodeSession>[
        OpenCodeSession(
          id: 'session-1',
          createdAt: DateTime.utc(2026, 5, 2, 10, 15),
        ),
      ];
      final error = StateError('local write failed');
      final remoteRepository = _SpyOpenCodeSessionRepository(
        readSessionsResult: sessions,
      );
      final localRepository = _SpyOpenCodeSessionRepository(writeError: error);
      final service = OpenCodeSessionSyncService(
        remoteRepository: remoteRepository,
        localRepository: localRepository,
      );

      await expectLater(service.syncSessions(), throwsA(same(error)));

      expect(remoteRepository.readSessionsCallCount, 1);
      expect(localRepository.writeSessionsCallCount, 1);
      expect(localRepository.writtenSessions, same(sessions));
    });
  });
}

final class _SpyOpenCodeSessionRepository implements OpenCodeSessionRepository {
  _SpyOpenCodeSessionRepository({
    List<OpenCodeSession>? readSessionsResult,
    this.readError,
    this.writeError,
  }) : _readSessionsResult = readSessionsResult ?? <OpenCodeSession>[];

  final List<OpenCodeSession> _readSessionsResult;
  final Object? readError;
  final Object? writeError;

  int readSessionsCallCount = 0;
  int writeSessionsCallCount = 0;
  Iterable<OpenCodeSession>? writtenSessions;

  @override
  Future<List<OpenCodeSession>> readSessions() async {
    readSessionsCallCount += 1;

    if (readError != null) {
      throw readError!;
    }

    return _readSessionsResult;
  }

  @override
  Future<void> writeSessions(Iterable<OpenCodeSession> sessions) async {
    writeSessionsCallCount += 1;
    writtenSessions = sessions;

    if (writeError != null) {
      throw writeError!;
    }
  }
}
