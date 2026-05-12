import 'dart:io';

import 'package:openspent_core/openspent_core.dart';
import 'package:sqlite3/sqlite3.dart';

import 'open_code_sqlite_session_reader.dart';

final class OpenCodeSqliteSessionRepository
    implements OpenCodeSessionRepository {
  OpenCodeSqliteSessionRepository(this._databaseFile);

  final File _databaseFile;

  @override
  Future<List<OpenCodeSession>> readSessions() async {
    _validateDatabaseFile(_databaseFile);

    final snapshotDirectory = await _createSnapshot(_databaseFile);
    final snapshotDatabaseFile = File(
      '${snapshotDirectory.path}/${_databaseFile.uri.pathSegments.last}',
    );

    Database? database;

    try {
      database = sqlite3.open(
        snapshotDatabaseFile.path,
        mode: OpenMode.readOnly,
      );

      return readOpenCodeSessions(database);
    } on SqliteException {
      throw const FormatException(
        'Failed to read imported OpenCode SQLite sessions.',
      );
    } finally {
      database?.dispose();
      if (await snapshotDirectory.exists()) {
        await snapshotDirectory.delete(recursive: true);
      }
    }
  }

  @override
  Future<void> writeSessions(Iterable<OpenCodeSession> sessions) {
    throw UnsupportedError(
      'OpenCodeSqliteSessionRepository is read-only and cannot write sessions.',
    );
  }

  static void _validateDatabaseFile(File databaseFile) {
    if (!databaseFile.existsSync()) {
      throw ArgumentError(
        'Expected an existing SQLite database file for import.',
      );
    }
  }

  static Future<Directory> _createSnapshot(File databaseFile) async {
    final snapshotDirectory = await Directory.systemTemp.createTemp(
      'openspent_opencode_import_',
    );

    try {
      final snapshotDatabaseFile = File(
        '${snapshotDirectory.path}/${databaseFile.uri.pathSegments.last}',
      );
      await databaseFile.copy(snapshotDatabaseFile.path);
      await _copySiblingIfPresent(
        source: File('${databaseFile.path}-wal'),
        target: File('${snapshotDatabaseFile.path}-wal'),
      );
      await _copySiblingIfPresent(
        source: File('${databaseFile.path}-shm'),
        target: File('${snapshotDatabaseFile.path}-shm'),
      );
      return snapshotDirectory;
    } on FileSystemException {
      if (await snapshotDirectory.exists()) {
        await snapshotDirectory.delete(recursive: true);
      }
      throw StateError('Failed to snapshot imported SQLite database.');
    }
  }

  static Future<void> _copySiblingIfPresent({
    required File source,
    required File target,
  }) async {
    if (await source.exists()) {
      await source.copy(target.path);
    }
  }
}
