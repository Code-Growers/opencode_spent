import 'package:flutter/foundation.dart';
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
        builder: (context, child) {
          if (kIsWeb && child != null) {
            return SelectionArea(child: child);
          }
          return child ?? const SizedBox.shrink();
        },
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        debugShowCheckedModeBanner: false,
        locale: _locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Necto Mono',
          splashFactory: NoSplash.splashFactory,
          dialogTheme: const DialogThemeData(
            backgroundColor: dashboardSurfaceColor,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: dashboardBorderColor),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              shape: const RoundedRectangleBorder(),
              foregroundColor: dashboardBackgroundColor,
              backgroundColor: dashboardAccentColor,
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              shape: const RoundedRectangleBorder(),
              side: const BorderSide(color: dashboardBorderColor),
            ),
          ),
          scaffoldBackgroundColor: dashboardBackgroundColor,
          dividerColor: dashboardBorderColor,
          colorScheme: const ColorScheme.dark(
            primary: dashboardAccentColor,
            onPrimary: dashboardBackgroundColor,
            surface: dashboardSurfaceColor,
            onSurface: dashboardPrimaryTextColor,
            surfaceContainer: dashboardSurfaceElevatedColor,
            surfaceContainerHighest: dashboardSurfaceHighlightColor,
            outline: dashboardBorderColor,
            secondary: dashboardSecondaryTextColor,
            onSecondary: dashboardBackgroundColor,
            error: dashboardErrorColor,
            tertiary: dashboardStatusColor,
            onTertiary: dashboardBackgroundColor,
          ),
          inputDecorationTheme: const InputDecorationTheme(
            isDense: true,
            filled: true,
            fillColor: dashboardBackgroundColor,
            hintStyle: TextStyle(color: dashboardSecondaryTextColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: dashboardBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: dashboardBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: dashboardAccentColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: dashboardErrorColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: dashboardErrorColor),
            ),
          ),
          iconButtonTheme: IconButtonThemeData(
            style: IconButton.styleFrom(
              foregroundColor: dashboardSecondaryTextColor,
              hoverColor: dashboardSurfaceHighlightColor,
              focusColor: dashboardAccentColor.withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
          ),
          cardTheme: CardThemeData(
            color: dashboardSurfaceElevatedColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: dashboardBorderColor),
              borderRadius: BorderRadius.zero,
            ),
          ),
          textTheme: const TextTheme(
            headlineSmall: TextStyle(
              color: dashboardPrimaryTextColor,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.8,
              fontFamilyFallback: <String>['Courier New', 'monospace'],
            ),
            titleMedium: TextStyle(
              color: dashboardPrimaryTextColor,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.3,
              fontFamilyFallback: <String>['Courier New', 'monospace'],
            ),
            titleLarge: TextStyle(
              color: dashboardPrimaryTextColor,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.2,
              fontFamilyFallback: <String>['Courier New', 'monospace'],
            ),
            labelLarge: TextStyle(
              color: dashboardPrimaryTextColor,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.4,
              fontFamilyFallback: <String>['Courier New', 'monospace'],
            ),
            bodyLarge: TextStyle(
              color: dashboardPrimaryTextColor,
              height: 1.5,
              fontFamilyFallback: <String>['Courier New', 'monospace'],
            ),
            bodyMedium: TextStyle(
              color: dashboardSecondaryTextColor,
              height: 1.5,
              fontFamilyFallback: <String>['Courier New', 'monospace'],
            ),
          ),
        ),
        routerConfig: _appRouter.config(),
      ),
    );
  }
}
