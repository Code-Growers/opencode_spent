import 'dart:io' as io;

import 'package:openspent_core/openspent_core.dart';

import '../database/open_spent_local_database.dart';
import '../repositories/local_open_code_session_repository.dart';
import '../repositories/open_code_sqlite_session_repository.dart';

typedef IngestCliOutput = void Function(String line);

final class IngestCliRunner {
  const IngestCliRunner({
    OpenCodeSessionJsonParser parser = const OpenCodeSessionJsonParser(),
  }) : _parser = parser;

  final OpenCodeSessionJsonParser _parser;

  Future<int> run(
    List<String> args, {
    IngestCliOutput? stdout,
    IngestCliOutput? stderr,
  }) async {
    final result = await execute(args);
    final writeStdout = stdout ?? io.stdout.writeln;
    final writeStderr = stderr ?? io.stderr.writeln;

    if (result.isSuccess) {
      writeStdout(result.message);
    } else {
      writeStderr(result.message);
    }

    return result.exitCode;
  }

  Future<IngestCliResult> execute(List<String> args) async {
    final request = _parseArgs(args);
    if (request case _UsageErrorRequest(:final message)) {
      return IngestCliResult.usageError(message);
    }

    final command = request as _CommandRequest;
    if (command.command == _Command.importJson) {
      return _importJson(command.sourcePath, command.databasePath);
    }

    return _importSqlite(command.sourcePath, command.databasePath);
  }

  Future<IngestCliResult> _importJson(
    String sourcePath,
    String databasePath,
  ) async {
    final sourceFile = io.File(sourcePath);

    late final String source;
    try {
      source = await sourceFile.readAsString();
    } on io.FileSystemException {
      return const IngestCliResult.failure('Failed to read JSON source.');
    }

    late final List<OpenCodeSession> sessions;
    try {
      sessions = _parser.parse(source);
    } on FormatException catch (error) {
      return IngestCliResult.failure(_formatFormatException(error));
    }

    return _writeSessions(databasePath, sessions);
  }

  Future<IngestCliResult> _importSqlite(
    String sourcePath,
    String databasePath,
  ) async {
    final sourceFile = io.File(sourcePath);

    late final List<OpenCodeSession> sessions;
    try {
      sessions = await OpenCodeSqliteSessionRepository(
        sourceFile,
      ).readSessions();
    } on ArgumentError {
      return const IngestCliResult.failure(
        'Failed to read imported OpenCode SQLite sessions.',
      );
    } on FormatException catch (error) {
      return IngestCliResult.failure(_formatFormatException(error));
    } on StateError {
      return const IngestCliResult.failure(
        'Failed to read imported OpenCode SQLite sessions.',
      );
    } on io.FileSystemException {
      return const IngestCliResult.failure(
        'Failed to read imported OpenCode SQLite sessions.',
      );
    }

    return _writeSessions(databasePath, sessions);
  }

  Future<IngestCliResult> _writeSessions(
    String databasePath,
    List<OpenCodeSession> sessions,
  ) async {
    OpenSpentLocalDatabase? database;

    try {
      database = OpenSpentLocalDatabase.file(io.File(databasePath));
      final repository = LocalOpenCodeSessionRepository(database);
      await repository.writeSessions(sessions);
      return IngestCliResult.success(sessions.length);
    } on io.FileSystemException {
      return const IngestCliResult.failure('Failed to open local database.');
    } on ArgumentError {
      return const IngestCliResult.failure(
        'Failed to persist imported sessions.',
      );
    } finally {
      await database?.close();
    }
  }

  _ParsedRequest _parseArgs(List<String> args) {
    if (args.isEmpty || _isHelpRequest(args)) {
      return const _UsageErrorRequest(usageText);
    }

    if (args.length != 4 || args[2] != '--db') {
      return const _UsageErrorRequest(usageText);
    }

    final command = _Command.values.where((value) => value.label == args[0]);
    if (command.isEmpty) {
      return _UsageErrorRequest('Unknown command: ${args[0]}\n\n$usageText');
    }

    final sourcePath = args[1].trim();
    final databasePath = args[3].trim();
    if (sourcePath.isEmpty || databasePath.isEmpty) {
      return const _UsageErrorRequest(usageText);
    }

    return _CommandRequest(
      command: command.single,
      sourcePath: sourcePath,
      databasePath: databasePath,
    );
  }

  bool _isHelpRequest(List<String> args) {
    return args.length == 1 &&
        (args.single == '--help' ||
            args.single == '-h' ||
            args.single == 'help');
  }

  String _formatFormatException(FormatException error) {
    final message = error.message.toString().trim();
    if (message.isEmpty) {
      return 'Import failed.';
    }

    return message;
  }
}

final class IngestCliResult {
  const IngestCliResult._({
    required this.exitCode,
    required this.message,
    this.importedCount,
  });

  const IngestCliResult.failure(String message)
    : this._(exitCode: _failureExitCode, message: message);

  const IngestCliResult.usageError(String message)
    : this._(exitCode: _usageExitCode, message: message);

  factory IngestCliResult.success(int importedCount) {
    return IngestCliResult._(
      exitCode: 0,
      message:
          'Imported $importedCount session${importedCount == 1 ? '' : 's'}.',
      importedCount: importedCount,
    );
  }

  final int exitCode;
  final String message;
  final int? importedCount;

  bool get isSuccess => exitCode == 0;
}

const int _usageExitCode = 64;
const int _failureExitCode = 1;

const String usageText = '''Usage:
  dart run bin/ingest.dart import-json <source.json> --db <local.db>
  dart run bin/ingest.dart import-sqlite <opencode.db> --db <local.db>''';

sealed class _ParsedRequest {
  const _ParsedRequest();
}

final class _UsageErrorRequest extends _ParsedRequest {
  const _UsageErrorRequest(this.message);

  final String message;
}

final class _CommandRequest extends _ParsedRequest {
  const _CommandRequest({
    required this.command,
    required this.sourcePath,
    required this.databasePath,
  });

  final _Command command;
  final String sourcePath;
  final String databasePath;
}

enum _Command {
  importJson('import-json'),
  importSqlite('import-sqlite');

  const _Command(this.label);

  final String label;
}
