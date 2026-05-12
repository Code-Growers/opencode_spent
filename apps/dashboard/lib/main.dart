import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:openspent_core/openspent_core.dart';
import 'package:openspent_local/openspent_local.dart';
import 'package:openspent_remote/openspent_remote.dart';

import 'src/bootstrap/dashboard_platform_support.dart' as platform_support;
import 'src/app/open_spent_app.dart';
import 'src/screens/exchange_rates/cubit/exchange_rates_cubit.dart';
import 'src/screens/sessions/cubit/sessions_cubit.dart';
import 'src/demo/dashboard_demo.dart';

const bool isWebDemoEnabled =
    kIsWeb && bool.fromEnvironment('OPENSPENT_WEB_DEMO', defaultValue: true);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  platform_support.configureWebUrlStrategy();

  final prefs = SharedPreferencesAsync();
  final keyValueStore = SharedPreferencesKeyValueStore(prefs);

  final dbPath = await platform_support.resolveLocalDatabasePath();
  final database = OpenSpentLocalDatabase.filePath(dbPath);

  final settingsRepository = LocalSettingsRepository(keyValueStore);
  final realExchangeRateRepository = LocalExchangeRateRepository(database);
  final realSessionRepository = LocalOpenCodeSessionRepository(database);
  final realMetricsRepository = LocalMetricsRepository(realSessionRepository);

  late final ExchangeRateRepository exchangeRateRepository;
  late final OpenCodeSessionRepository sessionRepository;
  late final MetricsRepository metricsRepository;
  DemoModeController? demoModeController;
  MockExchangeRateRepository? mockExchangeRateRepository;
  MockOpenCodeSessionRepository? mockSessionRepository;

  if (isWebDemoEnabled) {
    demoModeController = DemoModeController(DashboardDataMode.mock);

    final now = DateTime.now().toUtc();
    mockExchangeRateRepository = MockExchangeRateRepository(
      buildDashboardMockExchangeRates(now),
    );
    mockSessionRepository = MockOpenCodeSessionRepository(
      buildDashboardMockSessions(now),
    );
    final mockMetricsRepository = LocalMetricsRepository(mockSessionRepository);

    exchangeRateRepository = DelegatingExchangeRateRepository(
      realExchangeRateRepository,
      mockExchangeRateRepository,
      demoModeController,
    );
    sessionRepository = DelegatingSessionRepository(
      realSessionRepository,
      mockSessionRepository,
      demoModeController,
    );
    metricsRepository = DelegatingMetricsRepository(
      realMetricsRepository,
      mockMetricsRepository,
      demoModeController,
    );
  } else {
    exchangeRateRepository = realExchangeRateRepository;
    sessionRepository = realSessionRepository;
    metricsRepository = realMetricsRepository;
  }

  final composer = MonetizedMetricsComposer(
    exchangeRateRepository: exchangeRateRepository,
  );

  final metricsService = MonetizedMetricsService(
    settingsRepository: settingsRepository,
    metricsRepository: metricsRepository,
    composer: composer,
  );

  final jsonParser = const OpenCodeSessionJsonParser();

  final sessionsDependencies = SessionsCubitDependencies(
    localRepository: sessionRepository,
    jsonParser: jsonParser,
    importedSqlitePathRepositoryFactory:
        platform_support.importedSqlitePathRepositoryFactory,
    importedSqliteBytesRepositoryFactory:
        platform_support.importedSqliteBytesRepositoryFactory,
    remoteRepositoryFactory: (settings) {
      if (demoModeController != null &&
          mockSessionRepository != null &&
          demoModeController.value == DashboardDataMode.mock) {
        return mockSessionRepository;
      }

      final rawBaseUrl = settings.openCodeServerUrl.toString();
      final normalizedBaseUrl = rawBaseUrl.endsWith('/')
          ? rawBaseUrl
          : '$rawBaseUrl/';

      final dio = Dio(BaseOptions(baseUrl: normalizedBaseUrl));
      return RemoteOpenCodeSessionRepository(
        apiClient: OpenCodeSessionApiClient(
          dio,
          authorizationHeader: settings.openCodeServerAuthorizationHeader,
        ),
      );
    },
  );

  final exchangeRatesDependencies = ExchangeRatesCubitDependencies(
    metricsRepository: metricsRepository,
    settingsRepository: settingsRepository,
    localExchangeRateRepository: exchangeRateRepository,
    syncService: ExchangeRateSyncService(
      remoteRepository: demoModeController != null
          ? DelegatingExchangeRateRepository(
              RemoteExchangeRateRepository(
                apiClient: CnbExchangeRateApiClient(Dio()),
              ),
              mockExchangeRateRepository!,
              demoModeController,
            )
          : RemoteExchangeRateRepository(
              apiClient: CnbExchangeRateApiClient(Dio()),
            ),
      localRepository: exchangeRateRepository,
    ),
  );

  runApp(
    DemoModeScope(
      controller: demoModeController,
      child: OpenSpentApp(
        metricsService: metricsService,
        settingsRepository: settingsRepository,
        exchangeRatesDependencies: exchangeRatesDependencies,
        sessionsDependencies: sessionsDependencies,
        pickImportSource: platform_support.pickImportSource,
      ),
    ),
  );
}
