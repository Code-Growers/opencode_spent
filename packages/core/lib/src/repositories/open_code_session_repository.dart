import '../models/open_code_session.dart';

abstract interface class OpenCodeSessionRepository {
  Future<List<OpenCodeSession>> readSessions();

  Future<void> writeSessions(Iterable<OpenCodeSession> sessions);
}
