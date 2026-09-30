import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openspent_core/openspent_core.dart';

final class MetricsState {
  const MetricsState({this.isLoading = false, this.data, this.error});

  final bool isLoading;
  final MetricsLoadResult? data;
  final Object? error;

  bool get hasData => data != null;
  bool get hasError => error != null;

  MetricsState copyWith({
    bool? isLoading,
    Object? data = _unchanged,
    Object? error = _unchanged,
  }) {
    return MetricsState(
      isLoading: isLoading ?? this.isLoading,
      data: identical(data, _unchanged)
          ? this.data
          : data as MetricsLoadResult?,
      error: identical(error, _unchanged) ? this.error : error,
    );
  }

  static const Object _unchanged = Object();
}

final class MetricsLoadResult {
  const MetricsLoadResult({
    required this.currentMetrics,
    required this.priorMetrics,
  });

  final MonetizedAggregatedMetrics currentMetrics;
  final MonetizedAggregatedMetrics? priorMetrics;
}

final class MetricsCubit extends Cubit<MetricsState> {
  MetricsCubit({required MonetizedMetricsService metricsService})
    : _metricsService = metricsService,
      super(const MetricsState());

  final MonetizedMetricsService _metricsService;

  int _activeRequestId = 0;

  Future<void> load({
    DateTime? from,
    DateTime? to,
    UsageHarness? harness,
  }) async {
    final requestId = ++_activeRequestId;
    emit(const MetricsState(isLoading: true));

    try {
      final currentMetrics = await _metricsService.readMonetizedMetrics(
        from: from,
        to: to,
        harness: harness,
      );

      MonetizedAggregatedMetrics? priorMetrics;
      final priorWindow = _buildPriorWindow(from: from, to: to);
      if (priorWindow != null) {
        try {
          priorMetrics = await _metricsService.readMonetizedMetrics(
            harness: harness,
            from: priorWindow.$1,
            to: priorWindow.$2,
          );
        } catch (_) {
          priorMetrics = null;
        }
      }

      if (isClosed || requestId != _activeRequestId) {
        return;
      }

      emit(
        MetricsState(
          isLoading: false,
          data: MetricsLoadResult(
            currentMetrics: currentMetrics,
            priorMetrics: priorMetrics,
          ),
        ),
      );
    } catch (error) {
      if (isClosed || requestId != _activeRequestId) {
        return;
      }

      emit(MetricsState(isLoading: false, error: error));
    }
  }

  static (DateTime, DateTime)? _buildPriorWindow({
    DateTime? from,
    DateTime? to,
  }) {
    if (from == null || to == null) {
      return null;
    }

    final span = to.difference(from);
    final priorTo = from.subtract(const Duration(milliseconds: 1));
    final priorFrom = priorTo.subtract(span);
    return (priorFrom, priorTo);
  }
}
