import 'dart:typed_data';

import 'package:openspent_core/openspent_core.dart';
import 'package:openspent_local/openspent_local.dart';

import '../sessions/import_selection.dart';
import 'dashboard_platform_support_native.dart'
    if (dart.library.html) 'dashboard_platform_support_web.dart'
    as impl;

void configureWebUrlStrategy() {
  impl.configureWebUrlStrategy();
}

Future<String> resolveLocalDatabasePath() {
  return impl.resolveLocalDatabasePath();
}

Future<ImportSelection?> pickImportSource() {
  return impl.pickImportSource();
}

OpenCodeSessionRepository Function(String path)?
get importedSqlitePathRepositoryFactory {
  return impl.importedSqlitePathRepositoryFactory;
}

OpenCodeSessionRepository Function(Uint8List bytes)?
get importedSqliteBytesRepositoryFactory {
  return impl.importedSqliteBytesRepositoryFactory;
}

LocalUsageSources? createLocalUsageSources(
  KeyValueStore store,
  OpenCodeSessionRepository repository,
) => impl.createLocalUsageSources(store, repository);
Future<String?> pickSourceDirectory() => impl.pickSourceDirectory();
