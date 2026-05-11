import 'package:openspent_core/openspent_core.dart';

final class LocalMetricsRepository implements MetricsRepository {
  LocalMetricsRepository(
    this._sessionRepository, {
    OpenCodeMetricsCalculator calculator = const OpenCodeMetricsCalculator(),
  }) : _calculator = calculator;

  final OpenCodeSessionRepository _sessionRepository;
  final OpenCodeMetricsCalculator _calculator;

  @override
  Future<AggregatedMetrics> readMetrics({DateTime? from, DateTime? to}) async {
    final sessions = await _sessionRepository.readSessions();
    final filteredSessions = sessions.where((session) {
      if (from != null && session.createdAt.isBefore(from)) {
        return false;
      }
      if (to != null && session.createdAt.isAfter(to)) {
        return false;
      }

      return true;
    });

    return _calculator.calculate(filteredSessions);
  }
}
