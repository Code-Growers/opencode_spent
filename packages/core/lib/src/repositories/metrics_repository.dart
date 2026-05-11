import '../models/aggregated_metrics.dart';

abstract interface class MetricsRepository {
  Future<AggregatedMetrics> readMetrics({
    DateTime? from,
    DateTime? to,
  });
}
