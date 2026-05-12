import 'dart:typed_data';

import 'package:openspent_core/openspent_core.dart';
import 'open_code_uploaded_sqlite_session_repository_native.dart'
    if (dart.library.html) 'open_code_uploaded_sqlite_session_repository_web.dart'
    as impl;

const _sqliteFileHeader = <int>[
  0x53,
  0x51,
  0x4c,
  0x69,
  0x74,
  0x65,
  0x20,
  0x66,
  0x6f,
  0x72,
  0x6d,
  0x61,
  0x74,
  0x20,
  0x33,
  0x00,
];
const _sqliteWriteVersionOffset = 18;
const _sqliteReadVersionOffset = 19;
const _sqliteWalVersion = 2;

final class OpenCodeUploadedSqliteSessionRepository
    implements OpenCodeSessionRepository {
  OpenCodeUploadedSqliteSessionRepository(
    this._databaseBytes, {
    void Function()? onWillAttemptDatabaseOpen,
  }) : _onWillAttemptDatabaseOpen = onWillAttemptDatabaseOpen;

  static const walModeUploadErrorMessage =
      'Uploaded OpenCode SQLite WAL-mode databases are not supported for single-file browser imports.';

  static bool isWalModeUploadError(Object error) {
    return error is FormatException &&
        error.message == walModeUploadErrorMessage;
  }

  final Uint8List _databaseBytes;
  final void Function()? _onWillAttemptDatabaseOpen;

  @override
  Future<List<OpenCodeSession>> readSessions() async {
    if (_databaseBytes.isEmpty) {
      throw const FormatException(
        'Failed to read imported OpenCode SQLite sessions.',
      );
    }

    if (_isWalModeMainDatabase(_databaseBytes)) {
      throw const FormatException(walModeUploadErrorMessage);
    }

    return impl.readUploadedOpenCodeSessions(
      _databaseBytes,
      onWillAttemptDatabaseOpen: _onWillAttemptDatabaseOpen,
    );
  }

  @override
  Future<void> writeSessions(Iterable<OpenCodeSession> sessions) {
    throw UnsupportedError(
      'OpenCodeUploadedSqliteSessionRepository is read-only and cannot write sessions.',
    );
  }
}

bool _isWalModeMainDatabase(Uint8List databaseBytes) {
  if (databaseBytes.length <= _sqliteReadVersionOffset) {
    return false;
  }

  for (var index = 0; index < _sqliteFileHeader.length; index++) {
    if (databaseBytes[index] != _sqliteFileHeader[index]) {
      return false;
    }
  }

  return databaseBytes[_sqliteWriteVersionOffset] == _sqliteWalVersion &&
      databaseBytes[_sqliteReadVersionOffset] == _sqliteWalVersion;
}
