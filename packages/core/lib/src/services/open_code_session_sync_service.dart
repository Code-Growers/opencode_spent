import '../repositories/open_code_session_repository.dart';

final class OpenCodeSessionSyncService {
  const OpenCodeSessionSyncService({
    required this.remoteRepository,
    required this.localRepository,
  });

  final OpenCodeSessionRepository remoteRepository;
  final OpenCodeSessionRepository localRepository;

  Future<void> syncSessions() async {
    final sessions = await remoteRepository.readSessions();
    await localRepository.writeSessions(sessions);
  }
}
