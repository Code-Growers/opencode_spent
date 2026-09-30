import 'package:openspent_core/openspent_core.dart';

final class LocalMetricsRepository implements HarnessMetricsRepository {
  LocalMetricsRepository(
    this._sessionRepository, {
    OpenCodeMetricsCalculator calculator = const OpenCodeMetricsCalculator(),
    PricingRepository? pricingRepository,
  }) : _calculator = calculator,
       _pricingRepository = pricingRepository;
  final OpenCodeSessionRepository _sessionRepository;
  final OpenCodeMetricsCalculator _calculator;
  final PricingRepository? _pricingRepository;
  @override
  Future<AggregatedMetrics> readMetrics({DateTime? from, DateTime? to}) =>
      _read(from: from, to: to);
  @override
  Future<AggregatedMetrics> readHarnessMetrics({
    DateTime? from,
    DateTime? to,
    required UsageHarness harness,
  }) => _read(from: from, to: to, harness: harness);
  Future<AggregatedMetrics> _read({
    DateTime? from,
    DateTime? to,
    UsageHarness? harness,
  }) async {
    final sessions = await _sessionRepository.readSessions();
    final selected = sessions
        .where((s) => harness == null || s.harness == harness)
        .map((s) => selectSessionUsage(s, from: from, to: to))
        .whereType<OpenCodeSession>();
    return _calculator.calculate(
      selected,
      pricing: await _pricingRepository?.readPricing(),
    );
  }
}
