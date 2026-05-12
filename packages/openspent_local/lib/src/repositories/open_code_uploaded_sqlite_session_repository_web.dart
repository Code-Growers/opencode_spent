import 'dart:typed_data';

import 'package:openspent_core/openspent_core.dart';
import 'package:sqlite3/common.dart';

import '../database/web_sqlite3_context.dart';
import 'open_code_sqlite_session_reader.dart';

Future<List<OpenCodeSession>> readUploadedOpenCodeSessions(
  Uint8List databaseBytes, {
  void Function()? onWillAttemptDatabaseOpen,
}) async {
  onWillAttemptDatabaseOpen?.call();

  final context = await obtainWebSqlite3Context();
  final vfs = InMemoryFileSystem(
    name: 'openspent-upload-${DateTime.now().microsecondsSinceEpoch}',
  );
  context.sqlite3.registerVirtualFileSystem(vfs);

  final file = vfs
      .xOpen(Sqlite3Filename('/import.db'), SqlFlag.SQLITE_OPEN_CREATE)
      .file;
  file.xWrite(databaseBytes, 0);
  file.xClose();

  CommonDatabase? database;

  try {
    database = context.sqlite3.open(
      '/import.db',
      vfs: vfs.name,
      mode: OpenMode.readOnly,
    );
    return readOpenCodeSessions(database);
  } on SqliteException {
    throw const FormatException(
      'Failed to read imported OpenCode SQLite sessions.',
    );
  } finally {
    database?.dispose();
    context.sqlite3.unregisterVirtualFileSystem(vfs);
  }
}
