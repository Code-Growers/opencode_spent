import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:openspent_core/openspent_core.dart';
import 'package:openspent_local/openspent_local_web.dart';
import 'package:path/path.dart' as p;

import '../sessions/import_selection.dart';

void configureWebUrlStrategy() {
  usePathUrlStrategy();
}

Future<String> resolveLocalDatabasePath() async {
  return '/openspent/local.db';
}

Future<ImportSelection?> pickImportSource() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['json', 'db', 'sqlite'],
    withData: true,
  );

  final file = result?.files.single;
  final bytes = file?.bytes;
  if (file == null || bytes == null) {
    return null;
  }

  if (_isJsonFile(file.name)) {
    return ImportSelection.json(utf8.decode(bytes), sourceLabel: file.name);
  }

  return ImportSelection.sqliteBytes(bytes, sourceLabel: file.name);
}

OpenCodeSessionRepository Function(String path)?
importedSqlitePathRepositoryFactory;

OpenCodeSessionRepository importedSqliteBytesRepositoryFactory(
  Uint8List bytes,
) {
  return OpenCodeUploadedSqliteSessionRepository(bytes);
}

bool _isJsonFile(String fileName) {
  return p.extension(fileName).toLowerCase() == '.json';
}
