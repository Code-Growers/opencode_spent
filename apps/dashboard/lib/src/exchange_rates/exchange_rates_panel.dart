import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openspent_core/openspent_core.dart';

import '../../l10n/app_localizations.dart';
import '../screens/exchange_rates/cubit/exchange_rates_cubit.dart';

const _backgroundColor = Color(0xFF000000);
const _surfaceColor = Color(0xFF0A0A0A);
const _borderColor = Color(0xFF333333);
const _primaryTextColor = Color(0xFFFFFFFF);
const _secondaryTextColor = Color(0xFFA1A1AA);
const _statusColor = Color(0xFF22C55E);

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
            : state.missingDates.map(_formatDateKey).join(', ');

        return Container(
          key: const Key('exchange-rates-panel'),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surfaceColor,
            border: Border.all(color: _borderColor),
          ),
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
                      _ActionText(
                        key: const Key('exchange-rates-currency-usd'),
                        label: '[ USD ]',
                        isEnabled: !state.isLoading,
                        isSelected:
                            state.selectedCurrency == SupportedCurrency.usd,
                        onTap: () => _handleCurrencyTap(SupportedCurrency.usd),
                      ),
                      _ActionText(
                        key: const Key('exchange-rates-currency-czk'),
                        label: '[ CZK ]',
                        isEnabled: !state.isLoading,
                        isSelected:
                            state.selectedCurrency == SupportedCurrency.czk,
                        onTap: () => _handleCurrencyTap(SupportedCurrency.czk),
                      ),
                      _ActionText(
                        key: const Key('exchange-rates-sync-button'),
                        label: l10n.exchangeRatesActionSync,
                        isEnabled: canSync,
                        isSelected: false,
                        onTap: _handleSync,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_statusMessage != null)
                Text(
                  _statusMessage!,
                  key: const Key('exchange-rates-status-message'),
                  style: textTheme.bodyLarge?.copyWith(
                    color: state.isError ? _secondaryTextColor : _statusColor,
                  ),
                ),
              if (state.isError && state.errorMessage != null) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.exchangeRatesError(state.errorMessage!),
                  key: const Key('exchange-rates-error-message'),
                  style: textTheme.bodyMedium,
                ),
              ],
              if (_statusMessage != null || state.isError)
                const SizedBox(height: 16),
              Container(
                key: const Key('exchange-rates-summary'),
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  border: Border.all(color: _borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.exchangeRatesLineStatus(statusValue),
                      key: const Key('exchange-rates-status-line'),
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.exchangeRatesLineWindow(widget.windowLabel),
                      key: const Key('exchange-rates-window-line'),
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.exchangeRatesLineDisplay(
                        state.selectedCurrency.code,
                      ),
                      key: const Key('exchange-rates-display-line'),
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.exchangeRatesLineSpendDays(
                        state.requiredDates.length,
                      ),
                      key: const Key('exchange-rates-spend-days-line'),
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.exchangeRatesLineCoverage(
                        state.coveredDateCount,
                        state.requiredDates.length,
                      ),
                      key: const Key('exchange-rates-coverage-line'),
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 6),
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

class _ActionText extends StatelessWidget {
  const _ActionText({
    super.key,
    required this.label,
    required this.isEnabled,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isEnabled;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Text(
        label,
        style: textTheme.bodyLarge?.copyWith(
          color: isEnabled
              ? (isSelected ? _statusColor : _primaryTextColor)
              : _secondaryTextColor,
          fontWeight: isSelected || isEnabled
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
    );
  }
}

String _formatDateKey(DateTime value) {
  final normalized = value.toUtc();
  return '${normalized.year}-${normalized.month.toString().padLeft(2, '0')}-${normalized.day.toString().padLeft(2, '0')}';
}
