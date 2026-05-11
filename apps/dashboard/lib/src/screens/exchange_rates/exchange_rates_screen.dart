import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openspent_core/openspent_core.dart';

import '../../exchange_rates/exchange_rates_panel.dart';
import 'cubit/exchange_rates_cubit.dart';

class ExchangeRatesScreen extends StatefulWidget {
  const ExchangeRatesScreen({
    super.key,
    required this.dependencies,
    required this.exchangeRatesRevision,
    required this.onCurrencyChanged,
    required this.onRatesSynced,
    this.from,
    this.to,
    required this.windowLabel,
  });

  final ExchangeRatesCubitDependencies dependencies;
  final int exchangeRatesRevision;
  final ValueChanged<SupportedCurrency> onCurrencyChanged;
  final VoidCallback onRatesSynced;
  final DateTime? from;
  final DateTime? to;
  final String windowLabel;

  @override
  State<ExchangeRatesScreen> createState() => _ExchangeRatesScreenState();
}

class _ExchangeRatesScreenState extends State<ExchangeRatesScreen> {
  late ExchangeRatesCubit _exchangeRatesCubit;

  void _loadExchangeRates() {
    _exchangeRatesCubit.load(from: widget.from, to: widget.to);
  }

  @override
  void initState() {
    super.initState();
    _exchangeRatesCubit = ExchangeRatesCubit(dependencies: widget.dependencies);
    _loadExchangeRates();
  }

  @override
  void didUpdateWidget(covariant ExchangeRatesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dependencies != widget.dependencies) {
      _exchangeRatesCubit.close();
      _exchangeRatesCubit = ExchangeRatesCubit(
        dependencies: widget.dependencies,
      );
      _loadExchangeRates();
      return;
    }

    if (oldWidget.exchangeRatesRevision != widget.exchangeRatesRevision ||
        oldWidget.from != widget.from ||
        oldWidget.to != widget.to) {
      _loadExchangeRates();
    }
  }

  @override
  void dispose() {
    _exchangeRatesCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ExchangeRatesCubit>.value(
      value: _exchangeRatesCubit,
      child: ExchangeRatesPanel(
        onCurrencyChanged: widget.onCurrencyChanged,
        onRatesSynced: widget.onRatesSynced,
        from: widget.from,
        to: widget.to,
        windowLabel: widget.windowLabel,
      ),
    );
  }
}
