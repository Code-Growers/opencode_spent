import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:openspent_core/openspent_core.dart';
import 'package:openspent_local/openspent_local.dart';
import 'package:openspent_remote/openspent_remote.dart';

import 'src/app/open_spent_app.dart';
import 'src/screens/exchange_rates/cubit/exchange_rates_cubit.dart';
import 'src/screens/sessions/cubit/sessions_cubit.dart';
import 'src/sessions/import_selection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = SharedPreferencesAsync();
  final keyValueStore = SharedPreferencesKeyValueStore(prefs);

  final appDir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(appDir.path, 'openspent', 'local.db');
  final dbFile = File(dbPath);
  if (!dbFile.parent.existsSync()) {
    dbFile.parent.createSync(recursive: true);
  }

  final database = OpenSpentLocalDatabase.file(dbFile);

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
      pickImportSource: () async {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['json', 'db', 'sqlite'],
        );

        final file = result?.files.single;
        final filePath = file?.path;
        if (filePath == null) {
          return null;
        }

        final fileName = file?.name ?? p.basename(filePath);

        if (filePath.endsWith('.json')) {
          final content = await File(filePath).readAsString();
          return ImportSelection.json(content, sourceLabel: fileName);
        }

        return ImportSelection.sqlite(File(filePath), sourceLabel: fileName);
      },
    ),
  );
}
