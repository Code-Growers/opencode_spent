import '../usage/harness_usage.dart';
import '../models/aggregated_metrics.dart';

abstract interface class MetricsRepository {
  Future<AggregatedMetrics> readMetrics({DateTime? from, DateTime? to});
}

abstract interface class HarnessMetricsRepository implements MetricsRepository {
  Future<AggregatedMetrics> readHarnessMetrics({
    DateTime? from,
    DateTime? to,
    required UsageHarness harness,
  });
}
