// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [DashboardExchangeRatesScreen]
class DashboardExchangeRatesRoute extends PageRouteInfo<void> {
  const DashboardExchangeRatesRoute({List<PageRouteInfo>? children})
    : super(DashboardExchangeRatesRoute.name, initialChildren: children);

  static const String name = 'DashboardExchangeRatesRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const DashboardExchangeRatesScreen();
    },
  );
}

/// generated route for
/// [DashboardMetricsScreen]
class DashboardMetricsRoute extends PageRouteInfo<void> {
  const DashboardMetricsRoute({List<PageRouteInfo>? children})
    : super(DashboardMetricsRoute.name, initialChildren: children);

  static const String name = 'DashboardMetricsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const DashboardMetricsScreen();
    },
  );
}

/// generated route for
/// [DashboardSessionsScreen]
class DashboardSessionsRoute extends PageRouteInfo<void> {
  const DashboardSessionsRoute({List<PageRouteInfo>? children})
    : super(DashboardSessionsRoute.name, initialChildren: children);

  static const String name = 'DashboardSessionsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const DashboardSessionsScreen();
    },
  );
}

/// generated route for
/// [DashboardShellScreen]
class DashboardShellRoute extends PageRouteInfo<DashboardShellRouteArgs> {
  DashboardShellRoute({
    Key? key,
    MonetizedMetricsService? metricsService,
    SettingsRepository? settingsRepository,
    Future<ServerProbeState> Function(OpenCodeSettings)? serverProbe,
    ExchangeRatesCubitDependencies? exchangeRatesDependencies,
    SessionsCubitDependencies? sessionsDependencies,
    Future<ImportSelection?> Function()? pickImportSource,
    List<PageRouteInfo>? children,
  }) : super(
         DashboardShellRoute.name,
         args: DashboardShellRouteArgs(
           key: key,
           metricsService: metricsService,
           settingsRepository: settingsRepository,
           serverProbe: serverProbe,
           exchangeRatesDependencies: exchangeRatesDependencies,
           sessionsDependencies: sessionsDependencies,
           pickImportSource: pickImportSource,
         ),
         initialChildren: children,
       );

  static const String name = 'DashboardShellRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DashboardShellRouteArgs>(
        orElse: () => const DashboardShellRouteArgs(),
      );
      return DashboardShellScreen(
        key: args.key,
        metricsService: args.metricsService,
        settingsRepository: args.settingsRepository,
        serverProbe: args.serverProbe,
        exchangeRatesDependencies: args.exchangeRatesDependencies,
        sessionsDependencies: args.sessionsDependencies,
        pickImportSource: args.pickImportSource,
      );
    },
  );
}

class DashboardShellRouteArgs {
  const DashboardShellRouteArgs({
    this.key,
    this.metricsService,
    this.settingsRepository,
    this.serverProbe,
    this.exchangeRatesDependencies,
    this.sessionsDependencies,
    this.pickImportSource,
  });

  final Key? key;

  final MonetizedMetricsService? metricsService;

  final SettingsRepository? settingsRepository;

  final Future<ServerProbeState> Function(OpenCodeSettings)? serverProbe;

  final ExchangeRatesCubitDependencies? exchangeRatesDependencies;

  final SessionsCubitDependencies? sessionsDependencies;

  final Future<ImportSelection?> Function()? pickImportSource;

  @override
  String toString() {
    return 'DashboardShellRouteArgs{key: $key, metricsService: $metricsService, settingsRepository: $settingsRepository, serverProbe: $serverProbe, exchangeRatesDependencies: $exchangeRatesDependencies, sessionsDependencies: $sessionsDependencies, pickImportSource: $pickImportSource}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DashboardShellRouteArgs) return false;
    return key == other.key &&
        metricsService == other.metricsService &&
        settingsRepository == other.settingsRepository &&
        exchangeRatesDependencies == other.exchangeRatesDependencies &&
        sessionsDependencies == other.sessionsDependencies;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      metricsService.hashCode ^
      settingsRepository.hashCode ^
      exchangeRatesDependencies.hashCode ^
      sessionsDependencies.hashCode;
}

/// generated route for
/// [DashboardStateScreen]
class DashboardStateRoute extends PageRouteInfo<void> {
  const DashboardStateRoute({List<PageRouteInfo>? children})
    : super(DashboardStateRoute.name, initialChildren: children);

  static const String name = 'DashboardStateRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const DashboardStateScreen();
    },
  );
}
