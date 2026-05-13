import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openspent_core/openspent_core.dart';

import '../../../l10n/app_localizations.dart';
import '../../theme/dashboard_colors.dart';
import 'cubit/metrics_cubit.dart';
import 'metrics_utils.dart';
import 'widgets/metrics_chart_widgets.dart';
import 'widgets/metrics_kpi_cards.dart';
import '../dashboard/widgets/dashboard_surface.dart';
import 'widgets/metrics_screen_sections.dart';
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
                    widget.selectedCurrency != SupportedCurrency.usd &&
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

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  MetricsWindowControls(
                    selectedWindow: widget.selectedWindow,
                    onWindowSelected: widget.onWindowSelected,
                    onCustomWindowRequested: widget.onCustomWindowRequested,
                  ),
                  MetricsVisibleWindowLine(
                    selectedWindow: widget.selectedWindow,
                    from: widget.from,
                    to: widget.to,
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
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      if (selectedDay != null && visibleDays.isNotEmpty)
                        MetricsDayPickerButton(
                          selectedDay: selectedDay,
                          visibleDays: visibleDays,
                          onDaySelected: widget.onDaySelected,
                        )
                      else
                        const SizedBox.shrink(),
                      MetricsViewTabs(
                        selectedViewIndex: _view.index,
                        onViewSelected: (index) {
                          setState(() {
                            _view = _MetricsView.values[index];
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  MetricsViewSection(
                    child: Builder(
                      builder: (context) {
                        if (_view == _MetricsView.text) {
                          return MetricsTextSummary(
                            visibleDays: visibleDays,
                            metrics: metrics,
                            priorMetrics: priorMetrics,
                            displayCurrency: displayCurrency,
                            selectedDay: selectedDay,
                            selectedModelFilter: widget.selectedModelFilter,
                            onModelSelected: widget.onModelSelected,
                            from: widget.from,
                            to: widget.to,
                          );
                        } else if (_view == _MetricsView.spend) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                            ],
                          );
                        } else if (_view == _MetricsView.tokens) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                  selectedModelFilter:
                                      widget.selectedModelFilter,
                                  onModelSelected: widget.onModelSelected,
                                ),
                              ],
                            ],
                          );
                        } else if (_view == _MetricsView.models) {
                          return ModelSpendChart(
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
                          );
                        } else if (_view == _MetricsView.providers) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ProvidersUsageChart(
                                providerBreakdowns: metrics.providerBreakdowns,
                              ),
                              const SizedBox(height: 24),
                              ProvidersPriceChart(
                                providerBreakdowns: metrics.providerBreakdowns,
                                displayCurrency: displayCurrency,
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
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
