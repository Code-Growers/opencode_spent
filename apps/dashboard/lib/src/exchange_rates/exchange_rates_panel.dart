import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openspent_core/openspent_core.dart';

import '../../l10n/app_localizations.dart';
import '../app/date_time_extensions.dart';
import '../screens/dashboard/widgets/dashboard_chip_button.dart';
import '../screens/dashboard/widgets/dashboard_surface.dart';
import '../screens/exchange_rates/cubit/exchange_rates_cubit.dart';
import '../theme/dashboard_colors.dart';

class ExchangeRatesPanel extends StatefulWidget {
  const ExchangeRatesPanel({
    super.key,
    required this.onCurrencyChanged,
    required this.onRatesSynced,
    this.from,
    this.to,
    required this.windowLabel,
  });

  final ValueChanged<SupportedCurrency> onCurrencyChanged;
  final VoidCallback onRatesSynced;
  final DateTime? from;
  final DateTime? to;
  final String windowLabel;

  @override
  State<ExchangeRatesPanel> createState() => _ExchangeRatesPanelState();
}

class _ExchangeRatesPanelState extends State<ExchangeRatesPanel> {
  String? _statusMessage;
  ExchangeRatesState? _statusAnchorState;

  void _handleExternalStateChange(ExchangeRatesState state) {
    final shouldClearStatus =
        _statusMessage != null &&
        _statusAnchorState != null &&
        !identical(_statusAnchorState, state);

    if (shouldClearStatus && _statusMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _statusMessage == null) {
          return;
        }
        setState(() {
          _statusMessage = null;
          _statusAnchorState = null;
        });
      });
    }
  }

  Future<void> _handleCurrencyTap(SupportedCurrency currency) async {
    final cubit = context.read<ExchangeRatesCubit>();
    final state = cubit.state;
    if (state.isLoading || state.selectedCurrency == currency) {
      return;
    }

    final success = await cubit.selectCurrency(
      currency,
      from: widget.from,
      to: widget.to,
    );
    if (!mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _statusMessage = success
          ? l10n.exchangeRatesCurrencyChanged(currency.code)
          : l10n.exchangeRatesCurrencyChangeError;
      _statusAnchorState = cubit.state;
    });

    if (success) {
      widget.onCurrencyChanged(currency);
    }
  }

  Future<void> _handleSync() async {
    final cubit = context.read<ExchangeRatesCubit>();
    final state = cubit.state;
    final missingCount = state.missingDates.length;
    if (state.isLoading || missingCount == 0) {
      return;
    }

    final success = await cubit.syncMissingRates(
      from: widget.from,
      to: widget.to,
    );
    if (!mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _statusMessage = success
          ? l10n.exchangeRatesSyncSuccess(missingCount)
          : l10n.exchangeRatesSyncError;
      _statusAnchorState = cubit.state;
    });

    if (success) {
      widget.onRatesSynced();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<ExchangeRatesCubit, ExchangeRatesState>(
      builder: (context, state) {
        _handleExternalStateChange(state);
        final canSync = !state.isLoading && state.missingDates.isNotEmpty;
        final statusValue = state.isLoading
            ? l10n.exchangeRatesStatusLoading
            : state.isError
            ? l10n.exchangeRatesStatusError
            : state.missingDates.isEmpty
            ? l10n.exchangeRatesStatusReady
            : l10n.exchangeRatesStatusMissing(state.missingDates.length);
        final missingDaysText = state.missingDates.isEmpty
            ? l10n.exchangeRatesMissingDaysNone
            : state.missingDates
                  .map((date) => date.formatDashboardUtcDay(context))
                  .join(', ');

        return DashboardSurface(
          key: const Key('exchange-rates-panel'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(l10n.exchangeRatesTitle, style: textTheme.titleMedium),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      DashboardChipButton(
                        key: const Key('exchange-rates-currency-usd'),
                        label: 'USD',
                        isSelected:
                            state.selectedCurrency == SupportedCurrency.usd,
                        onTap: !state.isLoading
                            ? () => _handleCurrencyTap(SupportedCurrency.usd)
                            : null,
                      ),
                      DashboardChipButton(
                        key: const Key('exchange-rates-currency-czk'),
                        label: 'CZK',
                        isSelected:
                            state.selectedCurrency == SupportedCurrency.czk,
                        onTap: !state.isLoading
                            ? () => _handleCurrencyTap(SupportedCurrency.czk)
                            : null,
                      ),
                      DashboardChipButton(
                        key: const Key('exchange-rates-sync-button'),
                        label: l10n.exchangeRatesActionSync,
                        isSelected: false,
                        onTap: canSync ? _handleSync : null,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_statusMessage != null || state.isError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DashboardSurface(
                    key: const Key('exchange-rates-status-surface'),
                    backgroundColor: dashboardBackgroundColor,
                    borderColor: state.isError
                        ? dashboardErrorColor
                        : dashboardStatusColor,
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_statusMessage != null)
                            Text(
                              _statusMessage!,
                              key: const Key('exchange-rates-status-message'),
                              style: textTheme.bodyLarge?.copyWith(
                                color: state.isError
                                    ? dashboardErrorColor
                                    : dashboardStatusColor,
                              ),
                            ),
                          if (state.isError && state.errorMessage != null) ...[
                            if (_statusMessage != null)
                              const SizedBox(height: 8),
                            Text(
                              l10n.exchangeRatesError(
                                formatDashboardUtcDayIsoStrings(
                                  context,
                                  state.errorMessage!,
                                ),
                              ),
                              key: const Key('exchange-rates-error-message'),
                              style: textTheme.bodyMedium?.copyWith(
                                color: dashboardSecondaryTextColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              DashboardSurface(
                key: const Key('exchange-rates-summary'),
                backgroundColor: dashboardBackgroundColor,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.exchangeRatesLineStatus(statusValue),
                      key: const Key('exchange-rates-status-line'),
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.exchangeRatesLineWindow(widget.windowLabel),
                      key: const Key('exchange-rates-window-line'),
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.exchangeRatesLineDisplay(
                        state.selectedCurrency.code,
                      ),
                      key: const Key('exchange-rates-display-line'),
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.exchangeRatesLineSpendDays(
                        state.requiredDates.length,
                      ),
                      key: const Key('exchange-rates-spend-days-line'),
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.exchangeRatesLineCoverage(
                        state.coveredDateCount,
                        state.requiredDates.length,
                      ),
                      key: const Key('exchange-rates-coverage-line'),
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.exchangeRatesLineMissingDays(missingDaysText),
                      key: const Key('exchange-rates-missing-days-line'),
                      style: textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
