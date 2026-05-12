import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

import 'web_sqlite3_context.dart';

QueryExecutor createInMemoryOpenSpentLocalDatabaseExecutor() {
  return LazyDatabase(() async {
    final context = await obtainWebSqlite3Context(
      databaseName: 'openspent_local_memory',
    );
    return WasmDatabase.inMemory(context.sqlite3);
  });
}

QueryExecutor createFileOpenSpentLocalDatabaseExecutor(String path) {
  return LazyDatabase(() async {
    final context = await obtainWebSqlite3Context();
    return WasmDatabase(
      sqlite3: context.sqlite3,
      path: _normalizePath(path),
      fileSystem: context.fileSystem,
    );
  });
}

String _normalizePath(String path) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) {
    return '/openspent_local.db';
  }

  return trimmed.startsWith('/') ? trimmed : '/$trimmed';
}
