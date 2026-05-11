import 'package:openspent_core/openspent_core.dart';

import '../clients/open_code_session_api_client.dart';
import '../mappers/open_code_session_mapper.dart';

final class RemoteOpenCodeSessionRepository
    implements OpenCodeSessionRepository {
  RemoteOpenCodeSessionRepository({
    required OpenCodeSessionApiClient apiClient,
    OpenCodeSessionMapper mapper = const OpenCodeSessionMapper(),
  }) : _apiClient = apiClient,
       _mapper = mapper;

  final OpenCodeSessionApiClient _apiClient;
  final OpenCodeSessionMapper _mapper;

  @override
  Future<List<OpenCodeSession>> readSessions() async {
    final sessions = _readJsonObjectList(await _apiClient.getSessions());
    final mappedSessions = <OpenCodeSession>[];

    for (final session in sessions) {
      final sessionId = _readSessionId(session);
      final messages = _readJsonObjectList(
        await _apiClient.getSessionMessages(sessionId: sessionId),
      );
      mappedSessions.add(_mapper.map(session: session, messages: messages));
    }

    mappedSessions.sort((left, right) {
      final createdAtComparison = left.createdAt.compareTo(right.createdAt);
      if (createdAtComparison != 0) {
        return createdAtComparison;
      }

      return left.id.compareTo(right.id);
    });

    return List<OpenCodeSession>.unmodifiable(mappedSessions);
  }

  @override
  Future<void> writeSessions(Iterable<OpenCodeSession> sessions) {
    throw UnsupportedError(
      'RemoteOpenCodeSessionRepository is read-only. Use openspent_local for '
      'session persistence or caching.',
    );
  }

  static String _readSessionId(Map<String, dynamic> session) {
    final value = session['id'];
    if (value is String && value.isNotEmpty) {
      return value;
    }

    throw const FormatException(
      'Expected session.id to be a non-empty string.',
    );
  }

  static List<Map<String, dynamic>> _readJsonObjectList(List<dynamic> values) {
    return List<Map<String, dynamic>>.unmodifiable(
      values.map((value) {
        if (value is Map<String, dynamic>) {
          return value;
        }

        if (value is Map) {
          return Map<String, dynamic>.from(value);
        }

        throw const FormatException('Expected a JSON object list response.');
      }),
    );
  }
}
