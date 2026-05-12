import 'package:sqlite3/common.dart';
import 'package:sqlite3/wasm.dart';

const _defaultDatabaseName = 'openspent_local';
final _defaultSqlite3WasmUri = Uri.parse('sqlite3.wasm');

final class WebSqlite3Context {
  const WebSqlite3Context({required this.sqlite3, required this.fileSystem});

  final CommonSqlite3 sqlite3;
  final IndexedDbFileSystem fileSystem;
}

final _contexts = <String, Future<WebSqlite3Context>>{};

Future<WebSqlite3Context> obtainWebSqlite3Context({
  String databaseName = _defaultDatabaseName,
  Uri? sqlite3WasmUri,
}) {
  return _contexts.putIfAbsent(databaseName, () async {
    final sqlite3 = await WasmSqlite3.loadFromUrl(
      _resolveSqlite3WasmUri(sqlite3WasmUri ?? _defaultSqlite3WasmUri),
    );
    final fileSystem = await IndexedDbFileSystem.open(dbName: databaseName);
    sqlite3.registerVirtualFileSystem(fileSystem, makeDefault: true);
    return WebSqlite3Context(sqlite3: sqlite3, fileSystem: fileSystem);
  });
}

Uri _resolveSqlite3WasmUri(Uri sqlite3WasmUri) {
  if (sqlite3WasmUri.isAbsolute) {
    return sqlite3WasmUri;
  }

  return Uri.base.resolveUri(sqlite3WasmUri);
}
