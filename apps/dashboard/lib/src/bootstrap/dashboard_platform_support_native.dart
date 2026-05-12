import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:openspent_core/openspent_core.dart';
import 'package:openspent_local/openspent_local_native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../sessions/import_selection.dart';

void configureWebUrlStrategy() {}

Future<String> resolveLocalDatabasePath() async {
  final appDir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(appDir.path, 'openspent', 'local.db');
  final dbDirectory = Directory(p.dirname(dbPath));
  if (!dbDirectory.existsSync()) {
    dbDirectory.createSync(recursive: true);
  }

  return dbPath;
}

Future<ImportSelection?> pickImportSource() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['json', 'db', 'sqlite'],
  );

  final file = result?.files.single;
  final filePath = file?.path;
  if (file == null || filePath == null) {
    return null;
  }

  if (_isJsonFile(file.name)) {
    final content = await File(filePath).readAsString();
    return ImportSelection.json(content, sourceLabel: file.name);
  }

  return ImportSelection.sqlitePath(filePath, sourceLabel: file.name);
}

OpenCodeSessionRepository importedSqlitePathRepositoryFactory(String path) {
  return OpenCodeSqliteSessionRepository(File(path));
}

OpenCodeSessionRepository Function(Uint8List bytes)?
importedSqliteBytesRepositoryFactory;

bool _isJsonFile(String fileName) {
  return p.extension(fileName).toLowerCase() == '.json';
}
