import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openspent_core/openspent_core.dart';
import 'package:openspent_local/openspent_local.dart';
import 'package:openspent_local/src/cli/ingest_cli.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  group('IngestCliRunner', () {
    test('returns usage error when --db is missing', () async {
      final result = await const IngestCliRunner().execute(<String>[
        'import-json',
        'sessions.json',
      ]);

      expect(result.exitCode, 64);
      expect(result.message, usageText);
    });

    test('imports sessions from JSON into a local database file', () async {
      final tempDirectory = await _createTempDirectory();
      final jsonFile = File('${tempDirectory.path}/sessions.json');
      final databaseFile = File('${tempDirectory.path}/local.db');

      await jsonFile.writeAsString(
        jsonEncode(<String, Object?>{
          'sessions': <Object?>[
            <String, Object?>{
              'id': 'ses-json-1',
              'createdAt': '2026-05-10T08:15:00Z',
              'modelName': 'gpt-5.4',
              'inputTokens': 11,
              'outputTokens': 7,
              'totalCostUsd': 0.42,
              'prompt': 'private prompt',
              'state': <String, Object?>{'output': 'private output'},
            },
            <String, Object?>{
              'id': 'ses-json-2',
              'createdAt': '2026-05-10T09:30:00Z',
              'metadata': <String, Object?>{
                'modelName': 'o4-mini',
                'inputTokens': 5,
                'outputTokens': 2,
                'totalCostUsd': 0.12,
              },
            },
          ],
        }),
      );

      final result = await const IngestCliRunner().execute(<String>[
        'import-json',
        jsonFile.path,
        '--db',
        databaseFile.path,
      ]);

      expect(result.exitCode, 0);
      expect(result.importedCount, 2);
      expect(result.message, 'Imported 2 sessions.');

      final database = OpenSpentLocalDatabase.file(databaseFile);
      addTearDown(database.close);

      final storedSessions = await LocalOpenCodeSessionRepository(
        database,
      ).readSessions();

      expect(storedSessions, <OpenCodeSession>[
        OpenCodeSession(
          id: 'ses-json-1',
          createdAt: DateTime.utc(2026, 5, 10, 8, 15),
          modelName: 'gpt-5.4',
          inputTokens: 11,
          outputTokens: 7,
          totalCostUsd: 0.42,
        ),
        OpenCodeSession(
          id: 'ses-json-2',
          createdAt: DateTime.utc(2026, 5, 10, 9, 30),
          modelName: 'o4-mini',
          inputTokens: 5,
          outputTokens: 2,
          totalCostUsd: 0.12,
        ),
      ]);
    });

    test('imports sessions from an OpenCode SQLite database', () async {
      final tempDirectory = await _createTempDirectory();
      final sourceDatabaseFile = File('${tempDirectory.path}/opencode.db');
      final localDatabaseFile = File('${tempDirectory.path}/local.db');

      final writer = sqlite3.open(sourceDatabaseFile.path);
      addTearDown(writer.dispose);

      writer.select('PRAGMA journal_mode = WAL;');
      writer.execute('''
        CREATE TABLE session (
          id TEXT PRIMARY KEY,
          time_created INTEGER NOT NULL,
          time_updated INTEGER NOT NULL,
          time_archived INTEGER
        )
      ''');
      writer.execute('''
        CREATE TABLE message (
          id TEXT PRIMARY KEY,
          session_id TEXT NOT NULL,
          time_created INTEGER NOT NULL,
          time_updated INTEGER NOT NULL,
          data TEXT NOT NULL
        )
      ''');
      writer.execute(
        'INSERT INTO session (id, time_created, time_updated, time_archived) VALUES (?, ?, ?, ?)',
        <Object?>['ses-sqlite', 1710000000000, 1710000000000, null],
      );
      writer.execute(
        'INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)',
        <Object?>[
          'msg-assistant',
          'ses-sqlite',
          1710000000100,
          1710000000100,
          jsonEncode(<String, Object?>{
            'role': 'assistant',
            'modelID': 'gpt-5.4',
            'cost': 0.33,
            'tokens': <String, Object?>{'input': 10, 'output': 4},
          }),
        ],
      );

      final result = await const IngestCliRunner().execute(<String>[
        'import-sqlite',
        sourceDatabaseFile.path,
        '--db',
        localDatabaseFile.path,
      ]);

      expect(result.exitCode, 0);
      expect(result.importedCount, 1);
      expect(result.message, 'Imported 1 session.');

      final database = OpenSpentLocalDatabase.file(localDatabaseFile);
      addTearDown(database.close);

      final storedSessions = await LocalOpenCodeSessionRepository(
        database,
      ).readSessions();

      expect(storedSessions, <OpenCodeSession>[
        OpenCodeSession(
          id: 'ses-sqlite',
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            1710000000000,
            isUtc: true,
          ),
          modelName: 'gpt-5.4',
          inputTokens: 10,
          outputTokens: 4,
          totalCostUsd: 0.33,
        ),
      ]);
    });

    test('fails clearly for malformed JSON input', () async {
      final tempDirectory = await _createTempDirectory();
      final jsonFile = File('${tempDirectory.path}/bad.json');
      final databaseFile = File('${tempDirectory.path}/local.db');

      await jsonFile.writeAsString('{"sessions": [}');

      final result = await const IngestCliRunner().execute(<String>[
        'import-json',
        jsonFile.path,
        '--db',
        databaseFile.path,
      ]);

      expect(result.exitCode, 1);
      expect(result.message, contains('Unexpected character'));
    });

    test('fails clearly for invalid SQLite input', () async {
      final tempDirectory = await _createTempDirectory();
      final sourceFile = File('${tempDirectory.path}/invalid.db');
      final databaseFile = File('${tempDirectory.path}/local.db');

      await sourceFile.writeAsString('not a sqlite database');

      final result = await const IngestCliRunner().execute(<String>[
        'import-sqlite',
        sourceFile.path,
        '--db',
        databaseFile.path,
      ]);

      expect(result.exitCode, 1);
      expect(
        result.message,
        'Failed to read imported OpenCode SQLite sessions.',
      );
    });
  });
}

Future<Directory> _createTempDirectory() async {
  final directory = await Directory.systemTemp.createTemp('openspent_ingest_');
  addTearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });
  return directory;
}
