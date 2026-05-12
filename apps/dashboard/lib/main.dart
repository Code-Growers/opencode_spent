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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  platform_support.configureWebUrlStrategy();

  final prefs = SharedPreferencesAsync();
  final keyValueStore = SharedPreferencesKeyValueStore(prefs);

  final dbPath = await platform_support.resolveLocalDatabasePath();
  final database = OpenSpentLocalDatabase.filePath(dbPath);

  final settingsRepository = LocalSettingsRepository(keyValueStore);
  final exchangeRateRepository = LocalExchangeRateRepository(database);
  final sessionRepository = LocalOpenCodeSessionRepository(database);
  final metricsRepository = LocalMetricsRepository(sessionRepository);

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
      remoteRepository: RemoteExchangeRateRepository(
        apiClient: CnbExchangeRateApiClient(Dio()),
      ),
      localRepository: exchangeRateRepository,
    ),
  );

  runApp(
    OpenSpentApp(
      metricsService: metricsService,
      settingsRepository: settingsRepository,
      exchangeRatesDependencies: exchangeRatesDependencies,
      sessionsDependencies: sessionsDependencies,
      pickImportSource: platform_support.pickImportSource,
    ),
  );
}
