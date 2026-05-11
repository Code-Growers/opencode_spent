import 'package:flutter/widgets.dart';
import 'package:openspent_core/openspent_core.dart';

import '../screens/exchange_rates/cubit/exchange_rates_cubit.dart';
import '../screens/sessions/cubit/sessions_cubit.dart';
import '../sessions/import_selection.dart';
import '../screens/dashboard/dashboard_shell_screen.dart';

class OpenSpentAppScope extends InheritedWidget {
  const OpenSpentAppScope({
    super.key,
    required super.child,
    required this.metricsService,
    required this.onLocaleChanged,
    this.settingsRepository,
    this.serverProbe,
    this.exchangeRatesDependencies,
    this.sessionsDependencies,
    this.pickImportSource,
  });

  final MonetizedMetricsService metricsService;
  final ValueChanged<String?> onLocaleChanged;
  final SettingsRepository? settingsRepository;
  final Future<ServerProbeState> Function(OpenCodeSettings settings)?
  serverProbe;
  final ExchangeRatesCubitDependencies? exchangeRatesDependencies;
  final SessionsCubitDependencies? sessionsDependencies;
  final Future<ImportSelection?> Function()? pickImportSource;

  static OpenSpentAppScope of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<OpenSpentAppScope>();
    assert(scope != null, 'OpenSpentAppScope is missing in the widget tree.');
    return scope!;
  }

  @override
  bool updateShouldNotify(OpenSpentAppScope oldWidget) {
    return metricsService != oldWidget.metricsService ||
        onLocaleChanged != oldWidget.onLocaleChanged ||
        settingsRepository != oldWidget.settingsRepository ||
        serverProbe != oldWidget.serverProbe ||
        exchangeRatesDependencies != oldWidget.exchangeRatesDependencies ||
        sessionsDependencies != oldWidget.sessionsDependencies ||
        pickImportSource != oldWidget.pickImportSource;
  }
}
