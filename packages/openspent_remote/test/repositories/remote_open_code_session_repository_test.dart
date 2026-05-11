import 'package:openspent_core/openspent_core.dart';
import 'package:openspent_remote/openspent_remote.dart';
import 'package:test/test.dart';

void main() {
  group('RemoteOpenCodeSessionRepository', () {
    test(
      'fetches sessions and returns deterministic aggregated results',
      () async {
        final apiClient = _FakeOpenCodeSessionApiClient(
          sessions: <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'session-b',
              'time': <String, dynamic>{'created': 1715000200000},
            },
            <String, dynamic>{
              'id': 'session-a',
              'time': <String, dynamic>{'created': 1715000100000},
            },
          ],
          messagesBySessionId: <String, List<Map<String, dynamic>>>{
            'session-a': <Map<String, dynamic>>[
              <String, dynamic>{
                'info': <String, dynamic>{
                  'role': 'assistant',
                  'time': <String, dynamic>{'created': 1715000100100},
                  'modelID': 'gpt-5.4',
                  'cost': 0.4,
                  'tokens': <String, dynamic>{'input': 12, 'output': 34},
                },
                'parts': <Map<String, dynamic>>[],
              },
            ],
            'session-b': <Map<String, dynamic>>[
              <String, dynamic>{
                'info': <String, dynamic>{
                  'role': 'assistant',
                  'time': <String, dynamic>{'created': 1715000200100},
                  'modelID': 'o4-mini',
                  'cost': 0.1,
                  'tokens': <String, dynamic>{'input': 4, 'output': 5},
                },
                'parts': <Map<String, dynamic>>[],
              },
              <String, dynamic>{
                'info': <String, dynamic>{
                  'role': 'assistant',
                  'time': <String, dynamic>{'created': 1715000200200},
                  'modelID': 'o4',
                  'cost': 0.2,
                  'tokens': <String, dynamic>{'input': 6, 'output': 7},
                },
                'parts': <Map<String, dynamic>>[],
              },
            ],
          },
        );
        final repository = RemoteOpenCodeSessionRepository(
          apiClient: apiClient,
        );

        final sessions = await repository.readSessions();

        expect(apiClient.requestedSessionIds, <String>[
          'session-b',
          'session-a',
        ]);
        expect(sessions, <OpenCodeSession>[
          OpenCodeSession(
            id: 'session-a',
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              1715000100000,
              isUtc: true,
            ),
            modelName: 'gpt-5.4',
            inputTokens: 12,
            outputTokens: 34,
            totalCostUsd: 0.4,
          ),
          OpenCodeSession(
            id: 'session-b',
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              1715000200000,
              isUtc: true,
            ),
            modelName: 'o4',
            inputTokens: 10,
            outputTokens: 12,
            totalCostUsd: 0.30000000000000004,
          ),
        ]);
      },
    );

    test(
      'leaves assistant aggregate fields null when a session has no assistant messages',
      () async {
        final repository = RemoteOpenCodeSessionRepository(
          apiClient: _FakeOpenCodeSessionApiClient(
            sessions: <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'session-1',
                'time': <String, dynamic>{'created': 1715000000000},
              },
            ],
            messagesBySessionId: <String, List<Map<String, dynamic>>>{
              'session-1': <Map<String, dynamic>>[
                <String, dynamic>{
                  'info': <String, dynamic>{
                    'role': 'user',
                    'time': <String, dynamic>{'created': 1715000000100},
                  },
                  'parts': <Map<String, dynamic>>[],
                },
              ],
            },
          ),
        );

        final sessions = await repository.readSessions();

        expect(sessions, <OpenCodeSession>[
          OpenCodeSession(
            id: 'session-1',
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              1715000000000,
              isUtc: true,
            ),
          ),
        ]);
      },
    );

    test('rejects writeSessions with openspent_local guidance', () async {
      final repository = RemoteOpenCodeSessionRepository(
        apiClient: _FakeOpenCodeSessionApiClient(
          sessions: const <Map<String, dynamic>>[],
          messagesBySessionId: const <String, List<Map<String, dynamic>>>{},
        ),
      );

      await expectLater(
        () => repository.writeSessions(const <OpenCodeSession>[]),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            'RemoteOpenCodeSessionRepository is read-only. Use openspent_local for session persistence or caching.',
          ),
        ),
      );
    });
  });
}

final class _FakeOpenCodeSessionApiClient implements OpenCodeSessionApiClient {
  _FakeOpenCodeSessionApiClient({
    required this.sessions,
    required this.messagesBySessionId,
  });

  final List<Map<String, dynamic>> sessions;
  final Map<String, List<Map<String, dynamic>>> messagesBySessionId;
  final List<String> requestedSessionIds = <String>[];

  @override
  Future<List<dynamic>> getSessions() async => sessions;

  @override
  Future<List<dynamic>> getSessionMessages({required String sessionId}) async {
    requestedSessionIds.add(sessionId);
    return messagesBySessionId[sessionId] ?? const <Map<String, dynamic>>[];
  }
}
