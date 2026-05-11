import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openspent_core/openspent_core.dart';
import 'package:openspent_local/openspent_local.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  group('OpenCodeSqliteSessionRepository', () {
    test('reads imported sessions from a WAL-backed SQLite snapshot', () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'openspent_sqlite_import_test_',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final databaseFile = File('${tempDirectory.path}/opencode.db');
      final writer = sqlite3.open(databaseFile.path);
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
        <Object?>['ses-imported', 1710000000000, 1710000000000, null],
      );
      writer.execute(
        'INSERT INTO session (id, time_created, time_updated, time_archived) VALUES (?, ?, ?, ?)',
        <Object?>['ses-no-assistant', 1710000100000, 1710000100000, null],
      );
      writer.execute(
        'INSERT INTO session (id, time_created, time_updated, time_archived) VALUES (?, ?, ?, ?)',
        <Object?>['ses-archived', 1710000200000, 1710000200000, 1710000300000],
      );

      writer.execute(
        'INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)',
        <Object?>[
          'msg-user',
          'ses-imported',
          1710000000100,
          1710000000100,
          jsonEncode(<String, Object?>{
            'role': 'user',
            'prompt': 'private prompt',
            'state': <String, Object?>{'output': 'private output'},
          }),
        ],
      );
      writer.execute(
        'INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)',
        <Object?>[
          'msg-assistant-old',
          'ses-imported',
          1710000000200,
          1710000000200,
          jsonEncode(<String, Object?>{
            'role': 'assistant',
            'modelID': 'o4-mini',
            'providerID': 'openai',
            'cost': 0.25,
            'tokens': <String, Object?>{'input': 10, 'output': 5},
            'time': <String, Object?>{'created': 1710000000200},
            'cwd': '/private/path',
          }),
        ],
      );
      writer.execute(
        'INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)',
        <Object?>[
          'msg-assistant-new',
          'ses-imported',
          1710000000300,
          1710000000300,
          jsonEncode(<String, Object?>{
            'role': 'assistant',
            'modelID': 'gpt-5.4',
            'providerID': 'openai',
            'cost': 0.75,
            'tokens': <String, Object?>{'input': 20, 'output': 7},
            'time': <String, Object?>{'created': 1710000000300},
            'error': 'private error',
          }),
        ],
      );
      writer.execute(
        'INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)',
        <Object?>[
          'msg-archived',
          'ses-archived',
          1710000200100,
          1710000200100,
          jsonEncode(<String, Object?>{
            'role': 'assistant',
            'modelID': 'ignored-model',
            'providerID': 'openai',
            'cost': 5.0,
            'tokens': <String, Object?>{'input': 999, 'output': 999},
            'time': <String, Object?>{'created': 1710000200100},
          }),
        ],
      );

      expect(File('${databaseFile.path}-wal').existsSync(), isTrue);
      expect(File('${databaseFile.path}-shm').existsSync(), isTrue);

      final repository = OpenCodeSqliteSessionRepository(databaseFile);

      expect(await repository.readSessions(), <OpenCodeSession>[
        OpenCodeSession(
          id: 'ses-imported',
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            1710000000000,
            isUtc: true,
          ),
          modelName: 'gpt-5.4',
          inputTokens: 30,
          outputTokens: 12,
          totalCostUsd: 1.0,
        ),
        OpenCodeSession(
          id: 'ses-no-assistant',
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            1710000100000,
            isUtc: true,
          ),
        ),
      ]);
    });

    test('writeSessions fails clearly for read-only imports', () {
      final repository = OpenCodeSqliteSessionRepository(
        File('/tmp/opencode.db'),
      );

      expect(
        () => repository.writeSessions(const <OpenCodeSession>[]),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test(
      'rejects malformed assistant numeric fields instead of coercing them',
      () async {
        final tempDirectory = await Directory.systemTemp.createTemp(
          'openspent_sqlite_import_invalid_',
        );
        addTearDown(() async {
          if (await tempDirectory.exists()) {
            await tempDirectory.delete(recursive: true);
          }
        });

        final databaseFile = File('${tempDirectory.path}/opencode.db');
        final writer = sqlite3.open(databaseFile.path);
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
          <Object?>['ses-invalid', 1710000000000, 1710000000000, null],
        );
        writer.execute(
          'INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)',
          <Object?>[
            'msg-invalid',
            'ses-invalid',
            1710000000100,
            1710000000100,
            jsonEncode(<String, Object?>{
              'role': 'assistant',
              'modelID': 'gpt-5.4',
              'cost': 'bogus-cost',
              'tokens': <String, Object?>{'input': 'bogus-input', 'output': 4},
              'time': <String, Object?>{'created': 1710000000100},
            }),
          ],
        );

        final repository = OpenCodeSqliteSessionRepository(databaseFile);

        await expectLater(
          repository.readSessions(),
          throwsA(isA<FormatException>()),
        );
      },
    );
  });
}
