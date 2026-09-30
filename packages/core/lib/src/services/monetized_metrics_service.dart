import '../usage/harness_usage.dart';
import '../models/monetized_metrics.dart';
import '../models/supported_currency.dart';
import '../repositories/metrics_repository.dart';
import '../repositories/settings_repository.dart';
import 'monetized_metrics_composer.dart';

final class MonetizedMetricsService {
  const MonetizedMetricsService({
    required this.settingsRepository,
    required this.metricsRepository,
    required this.composer,
  });

  final SettingsRepository settingsRepository;
  final MetricsRepository metricsRepository;
  final MonetizedMetricsComposer composer;

  Future<MonetizedAggregatedMetrics> readMonetizedMetrics({
    UsageHarness? harness,
    DateTime? from,
    DateTime? to,
  }) async {
    final settings = await settingsRepository.readSettings();
    final repository = metricsRepository;
    final metrics = harness != null && repository is HarnessMetricsRepository
        ? await repository.readHarnessMetrics(
            from: from,
            to: to,
            harness: harness,
          )
        : await repository.readMetrics(from: from, to: to);

    return composer.compose(
      metrics: metrics,
      selectedCurrency: settings?.selectedCurrency ?? SupportedCurrency.usd,
    );
  }
}
