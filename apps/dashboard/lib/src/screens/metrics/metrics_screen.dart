import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openspent_core/openspent_core.dart';

import '../../../l10n/app_localizations.dart';
import '../../theme/dashboard_colors.dart';
import 'cubit/metrics_cubit.dart';
import 'metrics_utils.dart';
import 'widgets/metrics_chart_widgets.dart';
import 'widgets/metrics_kpi_cards.dart';
import '../dashboard/widgets/dashboard_chip_button.dart';
import '../dashboard/widgets/dashboard_surface.dart';

import 'widgets/metrics_text_summary.dart';

class MetricsScreen extends StatefulWidget {
  const MetricsScreen({
    super.key,
    required this.metricsService,
    required this.metricsRevision,
    required this.selectedCurrency,
    required this.selectedModelFilter,
    required this.onModelSelected,
    required this.selectedDay,
    required this.onDaySelected,
    required this.selectedUtcHour,
    required this.onHourSelected,
    required this.selectedWindow,
    required this.onWindowSelected,
    required this.onCustomWindowRequested,
    this.from,
    this.to,
  });

  final MonetizedMetricsService metricsService;
  final int metricsRevision;
  final SupportedCurrency selectedCurrency;
  final String? selectedModelFilter;
  final ValueChanged<String?> onModelSelected;
  final DateTime? selectedDay;
  final ValueChanged<DateTime?> onDaySelected;
  final int? selectedUtcHour;
  final ValueChanged<int> onHourSelected;
  final TimeWindow selectedWindow;
  final ValueChanged<TimeWindow> onWindowSelected;
  final VoidCallback onCustomWindowRequested;
  final DateTime? from;
  final DateTime? to;

  @override
  State<MetricsScreen> createState() => _MetricsScreenState();
}

enum _MetricsView { text, spend, tokens, models, providers }

class _MetricsScreenState extends State<MetricsScreen> {
  late MetricsCubit _metricsCubit;
  _MetricsView _view = _MetricsView.text;
  bool _pendingMissingModelFilterClear = false;

  void _loadMetrics() {
    _metricsCubit.load(from: widget.from, to: widget.to);
  }

  @override
  void initState() {
    super.initState();
    _metricsCubit = MetricsCubit(metricsService: widget.metricsService);
    _loadMetrics();
  }

  @override
  void didUpdateWidget(covariant MetricsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.metricsService != widget.metricsService) {
      _metricsCubit.close();
      _metricsCubit = MetricsCubit(metricsService: widget.metricsService);
      _loadMetrics();
    } else if (oldWidget.metricsRevision != widget.metricsRevision ||
        oldWidget.from != widget.from ||
        oldWidget.to != widget.to ||
        oldWidget.selectedCurrency != widget.selectedCurrency) {
      _loadMetrics();
      if (widget.selectedDay != null) {
        if (widget.from != null && widget.selectedDay!.isBefore(widget.from!)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && widget.selectedDay != null) {
              widget.onDaySelected(null);
            }
          });
        } else if (widget.to != null &&
            widget.selectedDay!.isAfter(widget.to!)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && widget.selectedDay != null) {
              widget.onDaySelected(null);
            }
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _metricsCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider<MetricsCubit>.value(
      value: _metricsCubit,
      child: DashboardSurface(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 160),
          child: BlocBuilder<MetricsCubit, MetricsState>(
            builder: (context, state) {
              if (state.isLoading) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: DashboardSurface(
                    backgroundColor: dashboardBackgroundColor,
                    borderColor: dashboardBorderColor,
                    child: Text(l10n.metricsLoad, style: textTheme.bodyLarge),
                  ),
                );
              } else if (state.hasError) {
                final errorText =
                    widget.selectedCurrency == SupportedCurrency.czk &&
                        isMissingExchangeRateError(state.error)
                    ? l10n.metricsMissingExchangeRatesHelper
                    : l10n.metricsUnavailable;
                return Align(
                  alignment: Alignment.topLeft,
                  child: DashboardSurface(
                    backgroundColor: dashboardBackgroundColor,
                    borderColor: dashboardErrorColor,
                    child: Text(
                      errorText,
                      key: const Key('metrics-error-text'),
                      style: textTheme.bodyLarge?.copyWith(
                        color: dashboardErrorColor,
                      ),
                    ),
                  ),
                );
              } else if (!state.hasData) {
                return const SizedBox.shrink();
              }

              final metrics = state.data!.currentMetrics;
              final priorMetrics = state.data!.priorMetrics;
              final hasMissingSelectedModel =
                  widget.selectedModelFilter != null &&
                  !metrics.perModelDailyBreakdown.containsKey(
                    widget.selectedModelFilter,
                  );

              if (hasMissingSelectedModel) {
                if (!_pendingMissingModelFilterClear) {
                  _pendingMissingModelFilterClear = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) {
                      return;
                    }

                    _pendingMissingModelFilterClear = false;
                    if (widget.selectedModelFilter != null) {
                      widget.onModelSelected(null);
                    }
                  });
                }
              } else {
                _pendingMissingModelFilterClear = false;
              }

              final displayCurrency = metrics.displayCurrency.code;
              final visibleDays = buildVisibleWindowDays(
                metrics.dailyBreakdown,
                widget.selectedWindow,
                widget.from,
                widget.to,
              );
              final hasPersistedSelectedDay = widget.selectedDay != null;
              final persistedSelectedDayVisible =
                  hasPersistedSelectedDay &&
                  containsUtcDay(visibleDays, widget.selectedDay!);
              final safeSelectedDay = persistedSelectedDayVisible
                  ? widget.selectedDay
                  : null;
              if (hasPersistedSelectedDay && !persistedSelectedDayVisible) {
                final nextSelectedDay = visibleDays.isNotEmpty
                    ? visibleDays.last
                    : null;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) {
                    return;
                  }

                  final currentSelectedDay = widget.selectedDay;
                  if (currentSelectedDay == null ||
                      containsUtcDay(visibleDays, currentSelectedDay)) {
                    return;
                  }

                  widget.onDaySelected(nextSelectedDay);
                });
              }

              final selectedDay =
                  safeSelectedDay ??
                  (visibleDays.isNotEmpty ? visibleDays.last : null);

              void handleHourSelected(int hour) {
                if (selectedDay == null) {
                  return;
                }

                final persistedDay = widget.selectedDay;
                if (persistedDay == null ||
                    !isSameUtcDay(persistedDay, selectedDay)) {
                  widget.onDaySelected(selectedDay);
                }

                widget.onHourSelected(hour);
              }

              Widget daySelector = const SizedBox.shrink();
              if (selectedDay != null && visibleDays.isNotEmpty) {
                final firstDate = visibleDays.first;
                final lastDate = visibleDays.last;
                daySelector = Semantics(
                  button: true,
                  value: formatDayChipLabel(selectedDay),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const Key('metrics-day-picker-button'),
                      borderRadius: BorderRadius.circular(4.0),
                      hoverColor: dashboardPrimaryTextColor.withValues(
                        alpha: 0.05,
                      ),
                      focusColor: dashboardPrimaryTextColor.withValues(
                        alpha: 0.1,
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDay,
                          firstDate: firstDate,
                          lastDate: lastDate,
                        );
                        if (picked != null && mounted) {
                          final utcDay = DateTime.utc(
                            picked.year,
                            picked.month,
                            picked.day,
                          );
                          if (containsUtcDay(visibleDays, utcDay)) {
                            widget.onDaySelected(utcDay);
                          }
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: dashboardBorderColor),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: dashboardSecondaryTextColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '[ ${formatDayChipLabel(selectedDay)} ]',
                              style: textTheme.bodyMedium?.copyWith(
                                color: dashboardPrimaryTextColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: DashboardSpacing.controlGap,
                    runSpacing: DashboardSpacing.controlGap,
                    children: [
                      Text(l10n.metricsTitle, style: textTheme.titleMedium),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: DashboardSpacing.controlGap,
                        runSpacing: DashboardSpacing.controlGap,
                        children: [
                          DashboardChipButton(
                            key: const Key('metrics-window-7d'),
                            label: l10n.windowAction7d,
                            isSelected: widget.selectedWindow == TimeWindow.days7,
                            onTap: () =>
                                widget.onWindowSelected(TimeWindow.days7),
                          ),
                          DashboardChipButton(
                            key: const Key('metrics-window-30d'),
                            label: l10n.windowAction30d,
                            isSelected:
                                widget.selectedWindow == TimeWindow.days30,
                            onTap: () =>
                                widget.onWindowSelected(TimeWindow.days30),
                          ),
                          DashboardChipButton(
                            key: const Key('metrics-window-90d'),
                            label: l10n.windowAction90d,
                            isSelected:
                                widget.selectedWindow == TimeWindow.days90,
                            onTap: () =>
                                widget.onWindowSelected(TimeWindow.days90),
                          ),
                          DashboardChipButton(
                            key: const Key('metrics-window-all'),
                            label: l10n.windowActionAll,
                            isSelected: widget.selectedWindow == TimeWindow.all,
                            onTap: () =>
                                widget.onWindowSelected(TimeWindow.all),
                          ),
                          DashboardChipButton(
                            key: const Key('metrics-window-custom'),
                            label: l10n.windowActionCustom,
                            isSelected:
                                widget.selectedWindow == TimeWindow.custom,
                            onTap: widget.onCustomWindowRequested,
                          ),
                        ],
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: DashboardSpacing.nestedPanelPadding,
                    ),
                    child: Text(
                      l10n.lineVisibleWindow(
                        formatWindowLabel(
                          context,
                          widget.selectedWindow,
                          widget.from,
                          widget.to,
                        ),
                      ),
                      key: const Key('metrics-window-line'),
                      style: textTheme.bodyLarge,
                    ),
                  ),
                  KeyedSubtree(
                    key: const Key('metrics-kpi-section'),
                    child: MetricsKpiCards(
                      metrics: metrics,
                      displayCurrency: displayCurrency,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: DashboardSpacing.controlGap,
                    runSpacing: DashboardSpacing.controlGap,
                    children: [
                      daySelector,
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: DashboardSpacing.controlGap,
                        runSpacing: DashboardSpacing.controlGap,
                        children: [
                          DashboardChipButton(
                            key: const Key('metrics-tab-text'),
                            label: l10n.textTab,
                            isSelected: _view == _MetricsView.text,
                            onTap: () =>
                                setState(() => _view = _MetricsView.text),
                          ),
                          DashboardChipButton(
                            key: const Key('metrics-tab-spend'),
                            label: l10n.spendTab,
                            isSelected: _view == _MetricsView.spend,
                            onTap: () =>
                                setState(() => _view = _MetricsView.spend),
                          ),
                          DashboardChipButton(
                            key: const Key('metrics-tab-tokens'),
                            label: l10n.tokensTab,
                            isSelected: _view == _MetricsView.tokens,
                            onTap: () =>
                                setState(() => _view = _MetricsView.tokens),
                          ),
                          DashboardChipButton(
                            key: const Key('metrics-tab-models'),
                            label: l10n.modelsTab,
                            isSelected: _view == _MetricsView.models,
                            onTap: () =>
                                setState(() => _view = _MetricsView.models),
                          ),
                          DashboardChipButton(
                            key: const Key('metrics-tab-providers'),
                            label: l10n.metricsProvidersTab,
                            isSelected: _view == _MetricsView.providers,
                            onTap: () =>
                                setState(() => _view = _MetricsView.providers),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  KeyedSubtree(
                    key: const Key('metrics-view-section'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_view == _MetricsView.text) ...[
                          MetricsTextSummary(
                            visibleDays: visibleDays,
                            metrics: metrics,
                            priorMetrics: priorMetrics,
                            displayCurrency: displayCurrency,
                            selectedDay: selectedDay,
                            selectedModelFilter: widget.selectedModelFilter,
                            onModelSelected: widget.onModelSelected,
                            from: widget.from,
                            to: widget.to,
                          ),
                        ] else if (_view == _MetricsView.spend) ...[
                          SpendTrendChart(
                            dailyBreakdown: metrics.dailyBreakdown,
                            visibleDays: visibleDays,
                            displayCurrency: displayCurrency,
                          ),
                          const SizedBox(height: 24),
                          if (selectedDay != null)
                            HourlySpendChart(
                              hourlyBreakdown: metrics.hourlyBreakdown,
                              selectedDay: selectedDay,
                              selectedUtcHour: widget.selectedUtcHour,
                              onHourSelected: handleHourSelected,
                              displayCurrency: displayCurrency,
                            ),
                        ] else if (_view == _MetricsView.tokens) ...[
                          TokenTrendChart(
                            dailyBreakdown: metrics.dailyBreakdown,
                            visibleDays: visibleDays,
                          ),
                          const SizedBox(height: 24),
                          if (selectedDay != null) ...[
                            HourlyTokenChart(
                              hourlyBreakdown: metrics.hourlyBreakdown,
                              selectedDay: selectedDay,
                              selectedUtcHour: widget.selectedUtcHour,
                              onHourSelected: handleHourSelected,
                            ),
                            const SizedBox(height: 16),
                            MetricsTokensTopDrivers(
                              metrics: metrics,
                              selectedDay: selectedDay,
                              displayCurrency: displayCurrency,
                              selectedModelFilter: widget.selectedModelFilter,
                              onModelSelected: widget.onModelSelected,
                            ),
                          ],
                        ] else if (_view == _MetricsView.models) ...[
                          ModelSpendChart(
                            perModelDailyBreakdown:
                                metrics.perModelDailyBreakdown,
                            perModelHourlyBreakdown:
                                metrics.perModelHourlyBreakdown,
                            currencyCode: displayCurrency,
                            grandTotalCost: metrics.displayTotalCost,
                            selectedModelFilter: widget.selectedModelFilter,
                            onModelSelected: widget.onModelSelected,
                            visibleDays: visibleDays,
                            selectedDay: selectedDay,
                          ),
                        ] else if (_view == _MetricsView.providers) ...[
                          ProvidersUsageChart(
                            providerBreakdowns: metrics.providerBreakdowns,
                          ),
                          const SizedBox(height: 24),
                          ProvidersPriceChart(
                            providerBreakdowns: metrics.providerBreakdowns,
                            displayCurrency: displayCurrency,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
