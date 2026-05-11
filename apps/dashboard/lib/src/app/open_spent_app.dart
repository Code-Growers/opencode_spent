import 'package:flutter/material.dart';
import 'package:openspent_core/openspent_core.dart';

import '../../l10n/app_localizations.dart';
import 'app_router.dart';
import 'app_scope.dart';
import '../screens/exchange_rates/cubit/exchange_rates_cubit.dart';
import '../screens/dashboard/dashboard_shell_screen.dart';
import '../screens/sessions/cubit/sessions_cubit.dart';
import '../sessions/import_selection.dart';
import '../theme/dashboard_colors.dart';

class OpenSpentApp extends StatefulWidget {
  const OpenSpentApp({
    super.key,
    required this.metricsService,
    this.settingsRepository,
    this.serverProbe,
    this.exchangeRatesDependencies,
    this.sessionsDependencies,
    this.pickImportSource,
  });

  final MonetizedMetricsService metricsService;
  final SettingsRepository? settingsRepository;
  final Future<ServerProbeState> Function(OpenCodeSettings settings)?
  serverProbe;
  final ExchangeRatesCubitDependencies? exchangeRatesDependencies;
  final SessionsCubitDependencies? sessionsDependencies;
  final Future<ImportSelection?> Function()? pickImportSource;

  @override
  State<OpenSpentApp> createState() => _OpenSpentAppState();
}

class _OpenSpentAppState extends State<OpenSpentApp> {
  late final AppRouter _appRouter;
  String? _languageCode;

  Locale? get _locale {
    return switch (_languageCode) {
      'en' => const Locale('en'),
      'cs' => const Locale('cs'),
      _ => null,
    };
  }

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter();
  }

  void _handleLocaleChanged(String? languageCode) {
    if (_languageCode == languageCode) {
      return;
    }

    setState(() {
      _languageCode = languageCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return OpenSpentAppScope(
      metricsService: widget.metricsService,
      onLocaleChanged: _handleLocaleChanged,
      settingsRepository: widget.settingsRepository,
      serverProbe: widget.serverProbe,
      exchangeRatesDependencies: widget.exchangeRatesDependencies,
      sessionsDependencies: widget.sessionsDependencies,
      pickImportSource: widget.pickImportSource,
      child: MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        debugShowCheckedModeBanner: false,
        locale: _locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: dashboardBackgroundColor,
          dividerColor: dashboardBorderColor,
          colorScheme: const ColorScheme.dark(
            primary: dashboardPrimaryTextColor,
            surface: dashboardSurfaceColor,
            outline: dashboardBorderColor,
            secondary: dashboardStatusColor,
            onSurface: dashboardPrimaryTextColor,
          ),
          textTheme: const TextTheme(
            headlineSmall: TextStyle(
              color: dashboardPrimaryTextColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.4,
              fontFamilyFallback: <String>['Menlo', 'Courier'],
            ),
            titleMedium: TextStyle(
              color: dashboardPrimaryTextColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
              fontFamilyFallback: <String>['Menlo', 'Courier'],
            ),
            bodyLarge: TextStyle(
              color: dashboardPrimaryTextColor,
              height: 1.5,
              fontFamilyFallback: <String>['Menlo', 'Courier'],
            ),
            bodyMedium: TextStyle(
              color: dashboardSecondaryTextColor,
              height: 1.5,
              fontFamilyFallback: <String>['Menlo', 'Courier'],
            ),
          ),
        ),
        routerConfig: _appRouter.config(),
      ),
    );
  }
}
