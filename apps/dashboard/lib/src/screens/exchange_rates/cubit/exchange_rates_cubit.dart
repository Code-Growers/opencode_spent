import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openspent_core/openspent_core.dart';

const _defaultOpenCodeServerUrl = 'http://localhost:4096';

final class ExchangeRatesCubitDependencies {
  const ExchangeRatesCubitDependencies({
    required this.metricsRepository,
    required this.settingsRepository,
    required this.localExchangeRateRepository,
    required this.syncService,
  });

  final MetricsRepository metricsRepository;
  final SettingsRepository settingsRepository;
  final ExchangeRateRepository localExchangeRateRepository;
  final ExchangeRateSyncService syncService;
}

final class ExchangeRatesState {
  static const Object _errorMessageUnchanged = Object();

  const ExchangeRatesState({
    this.isLoading = false,
    this.selectedCurrency = SupportedCurrency.usd,
    this.requiredDates = const <DateTime>[],
    this.missingDates = const <DateTime>[],
    this.ratesByDate = const <DateTime, List<ExchangeRate>>{},
    this.isError = false,
    this.errorMessage,
    this.visibleDates = const <DateTime>[],
  });

  final bool isLoading;
  final SupportedCurrency selectedCurrency;
  final List<DateTime> requiredDates;
  final List<DateTime> missingDates;
  final Map<DateTime, List<ExchangeRate>> ratesByDate;
  final bool isError;
  final String? errorMessage;
  final List<DateTime> visibleDates;

  int get coveredDateCount => requiredDates.length - missingDates.length;

  ExchangeRatesState copyWith({
    bool? isLoading,
    SupportedCurrency? selectedCurrency,
    List<DateTime>? requiredDates,
    List<DateTime>? missingDates,
    Map<DateTime, List<ExchangeRate>>? ratesByDate,
    bool? isError,
    Object? errorMessage = _errorMessageUnchanged,
    List<DateTime>? visibleDates,
  }) {
    return ExchangeRatesState(
      isLoading: isLoading ?? this.isLoading,
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
      requiredDates: requiredDates ?? this.requiredDates,
      missingDates: missingDates ?? this.missingDates,
      ratesByDate: ratesByDate ?? this.ratesByDate,
      isError: isError ?? this.isError,
      errorMessage: identical(errorMessage, _errorMessageUnchanged)
          ? this.errorMessage
          : errorMessage as String?,
      visibleDates: visibleDates ?? this.visibleDates,
    );
  }
}

final class ExchangeRatesCubit extends Cubit<ExchangeRatesState> {
  ExchangeRatesCubit({required ExchangeRatesCubitDependencies dependencies})
    : _dependencies = dependencies,
      super(const ExchangeRatesState());

  final ExchangeRatesCubitDependencies _dependencies;

  int _activeRequestId = 0;

  Future<void> load({
    DateTime? from,
    DateTime? to,
    DateTime? visibleFrom,
    DateTime? visibleTo,
  }) async {
    final requestId = ++_activeRequestId;
    emit(state.copyWith(isLoading: true, isError: false, errorMessage: null));

    try {
      final snapshot = await _readSnapshot(
        from: from,
        to: to,
        visibleFrom: visibleFrom,
        visibleTo: visibleTo,
      );
      if (!_isActive(requestId)) {
        return;
      }

      emit(
        state.copyWith(
          isLoading: false,
          selectedCurrency: snapshot.selectedCurrency,
          requiredDates: snapshot.requiredDates,
          missingDates: snapshot.missingDates,
          ratesByDate: snapshot.ratesByDate,
          isError: false,
          errorMessage: null,
          visibleDates: snapshot.visibleDates,
        ),
      );
    } catch (error) {
      if (!_isActive(requestId)) {
        return;
      }

      emit(
        state.copyWith(
          isLoading: false,
          isError: true,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<bool> selectCurrency(
    SupportedCurrency currency, {
    DateTime? from,
    DateTime? to,
    DateTime? visibleFrom,
    DateTime? visibleTo,
  }) async {
    final requestId = ++_activeRequestId;
    emit(state.copyWith(isLoading: true, isError: false, errorMessage: null));

    try {
      final settings = await _dependencies.settingsRepository.readSettings();
      final nextSettings =
          (settings ??
                  OpenCodeSettings(
                    selectedCurrency: SupportedCurrency.usd,
                    openCodeServerUrl: Uri.parse(_defaultOpenCodeServerUrl),
                  ))
              .copyWith(selectedCurrency: currency);
      await _dependencies.settingsRepository.writeSettings(nextSettings);

      final snapshot = await _readSnapshot(
        selectedCurrencyOverride: currency,
        from: from,
        to: to,
        visibleFrom: visibleFrom,
        visibleTo: visibleTo,
      );
      if (!_isActive(requestId)) {
        return false;
      }

      emit(
        state.copyWith(
          isLoading: false,
          selectedCurrency: snapshot.selectedCurrency,
          requiredDates: snapshot.requiredDates,
          missingDates: snapshot.missingDates,
          ratesByDate: snapshot.ratesByDate,
          isError: false,
          errorMessage: null,
          visibleDates: snapshot.visibleDates,
        ),
      );
      return true;
    } catch (error) {
      if (!_isActive(requestId)) {
        return false;
      }

      emit(
        state.copyWith(
          isLoading: false,
          isError: true,
          errorMessage: error.toString(),
        ),
      );
      return false;
    }
  }

  Future<bool> syncMissingRates({
    DateTime? from,
    DateTime? to,
    DateTime? visibleFrom,
    DateTime? visibleTo,
  }) async {
    final requestId = ++_activeRequestId;
    emit(state.copyWith(isLoading: true, isError: false, errorMessage: null));

    final selectedCurrency = state.selectedCurrency;
    try {
      final snapshotBeforeSync = await _readSnapshot(
        selectedCurrencyOverride: selectedCurrency,
        from: from,
        to: to,
        visibleFrom: visibleFrom,
        visibleTo: visibleTo,
      );

      for (final date in snapshotBeforeSync.missingDates) {
        await _dependencies.syncService.syncExchangeRatesForDate(date);
      }

      final refreshedSnapshot = await _readSnapshot(
        selectedCurrencyOverride: snapshotBeforeSync.selectedCurrency,
        from: from,
        to: to,
        visibleFrom: visibleFrom,
        visibleTo: visibleTo,
      );
      if (!_isActive(requestId)) {
        return false;
      }

      emit(
        state.copyWith(
          isLoading: false,
          selectedCurrency: refreshedSnapshot.selectedCurrency,
          requiredDates: refreshedSnapshot.requiredDates,
          missingDates: refreshedSnapshot.missingDates,
          ratesByDate: refreshedSnapshot.ratesByDate,
          isError: false,
          errorMessage: null,
          visibleDates: refreshedSnapshot.visibleDates,
        ),
      );
      return true;
    } catch (error) {
      try {
        final refreshedSnapshot = await _readSnapshot(
          selectedCurrencyOverride: selectedCurrency,
          from: from,
          to: to,
          visibleFrom: visibleFrom,
          visibleTo: visibleTo,
        );
        if (!_isActive(requestId)) {
          return false;
        }

        emit(
          state.copyWith(
            isLoading: false,
            selectedCurrency: refreshedSnapshot.selectedCurrency,
            requiredDates: refreshedSnapshot.requiredDates,
            missingDates: refreshedSnapshot.missingDates,
            ratesByDate: refreshedSnapshot.ratesByDate,
            visibleDates: refreshedSnapshot.visibleDates,
            isError: true,
            errorMessage: error.toString(),
          ),
        );
      } catch (_) {
        if (!_isActive(requestId)) {
          return false;
        }

        emit(
          state.copyWith(
            isLoading: false,
            isError: true,
            errorMessage: error.toString(),
          ),
        );
      }

      return false;
    }
  }

  bool _isActive(int requestId) {
    return !isClosed && requestId == _activeRequestId;
  }

  List<DateTime> _buildVisibleDates(
    List<DateTime> requiredDates, {
    DateTime? visibleFrom,
    DateTime? visibleTo,
  }) {
    if (visibleFrom == null || visibleTo == null) {
      return requiredDates;
    }

    final start = _normalizeUtcDay(visibleFrom);
    final end = _normalizeUtcDay(visibleTo);

    final result = <DateTime>[];
    var current = start;
    while (!current.isAfter(end)) {
      result.add(current);
      current = current.add(const Duration(days: 1));
    }
    return result;
  }

  Future<_ExchangeRateSnapshot> _readSnapshot({
    SupportedCurrency? selectedCurrencyOverride,
    DateTime? from,
    DateTime? to,
    DateTime? visibleFrom,
    DateTime? visibleTo,
  }) async {
    final settings = await _dependencies.settingsRepository.readSettings();
    final selectedCurrency =
        selectedCurrencyOverride ??
        settings?.selectedCurrency ??
        SupportedCurrency.usd;
    final metrics = await _dependencies.metricsRepository.readMetrics(
      from: from,
      to: to,
    );

    final requiredDates = <DateTime>[];
    for (final daily in metrics.dailyBreakdown) {
      if (daily.totalCostUsd <= 0) {
        continue;
      }

      final normalizedDate = _normalizeUtcDay(daily.date);
      if (!requiredDates.contains(normalizedDate)) {
        requiredDates.add(normalizedDate);
      }
    }
    requiredDates.sort((left, right) => left.compareTo(right));

    final visibleDates = _buildVisibleDates(
      requiredDates,
      visibleFrom: visibleFrom,
      visibleTo: visibleTo,
    );

    final datesToFetch = <DateTime>{...requiredDates, ...visibleDates}.toList();
    datesToFetch.sort((left, right) => left.compareTo(right));

    final missingDates = <DateTime>[];
    final ratesByDate = <DateTime, List<ExchangeRate>>{};

    for (final date in datesToFetch) {
      final rates = await _dependencies.localExchangeRateRepository
          .readExchangeRatesForDate(date);
      ratesByDate[date] = rates;

      if (requiredDates.contains(date)) {
        final hasUsdRate = rates.any(
          (rate) => rate.currency == SupportedCurrency.usd,
        );
        final hasEurRate = rates.any(
          (rate) => rate.currency == SupportedCurrency.eur,
        );

        bool isMissing = false;
        switch (selectedCurrency) {
          case SupportedCurrency.usd:
          case SupportedCurrency.czk:
            if (!hasUsdRate) isMissing = true;
            break;
          case SupportedCurrency.eur:
            if (!hasUsdRate || !hasEurRate) isMissing = true;
            break;
        }

        if (isMissing) {
          missingDates.add(date);
        }
      }
    }

    return _ExchangeRateSnapshot(
      selectedCurrency: selectedCurrency,
      requiredDates: List<DateTime>.unmodifiable(requiredDates),
      missingDates: List<DateTime>.unmodifiable(missingDates),
      ratesByDate: Map<DateTime, List<ExchangeRate>>.unmodifiable(ratesByDate),
      visibleDates: List<DateTime>.unmodifiable(visibleDates),
    );
  }

  static DateTime _normalizeUtcDay(DateTime value) {
    final utc = value.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day);
  }
}

final class _ExchangeRateSnapshot {
  const _ExchangeRateSnapshot({
    required this.selectedCurrency,
    required this.requiredDates,
    required this.missingDates,
    required this.ratesByDate,
    required this.visibleDates,
  });

  final SupportedCurrency selectedCurrency;
  final List<DateTime> requiredDates;
  final List<DateTime> missingDates;
  final Map<DateTime, List<ExchangeRate>> ratesByDate;
  final List<DateTime> visibleDates;
}
