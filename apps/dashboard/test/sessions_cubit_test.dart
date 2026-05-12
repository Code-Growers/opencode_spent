import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:openspent_core/openspent_core.dart';
import 'package:openspent_dashboard/src/screens/sessions/cubit/sessions_cubit.dart';
import 'package:openspent_local/openspent_local_native.dart';
import 'package:sqlite3/sqlite3.dart';

class _FakeSessionRepository implements OpenCodeSessionRepository {
  _FakeSessionRepository([List<OpenCodeSession>? sessions])
    : _sessions = sessions ?? <OpenCodeSession>[];

  final List<OpenCodeSession> _sessions;

  @override
  Future<List<OpenCodeSession>> readSessions() async {
    return List<OpenCodeSession>.from(_sessions);
  }

  @override
  Future<void> writeSessions(Iterable<OpenCodeSession> sessions) async {
    _sessions
      ..clear()
      ..addAll(sessions);
  }
}

OpenCodeSession _session({
  required String id,
  required DateTime createdAt,
  String? provider,
  String? modelName,
  int? inputTokens,
  int? outputTokens,
  double? totalCostUsd,
  int? requestCount,
  int? toolCallCount,
  int? responseCount,
  int? totalResponseTimeMs,
  String? subagentCategory,
  List<SessionUsageSlice> usageSlices = const <SessionUsageSlice>[],
}) {
  return OpenCodeSession(
    id: id,
    createdAt: createdAt,
    provider: provider,
    modelName: modelName,
    inputTokens: inputTokens,
    outputTokens: outputTokens,
    totalCostUsd: totalCostUsd,
    requestCount: requestCount,
    toolCallCount: toolCallCount,
    responseCount: responseCount,
    totalResponseTimeMs: totalResponseTimeMs,
    subagentCategory: subagentCategory,
    usageSlices: usageSlices,
  );
}

SessionsCubit _buildCubit({
  required OpenCodeSessionRepository localRepository,
  OpenCodeSessionRepository Function(OpenCodeSettings settings)?
  remoteRepositoryFactory,
  OpenCodeSessionRepository Function(String path)?
  importedSqlitePathRepositoryFactory,
  OpenCodeSessionRepository Function(Uint8List bytes)?
  importedSqliteBytesRepositoryFactory,
}) {
  return SessionsCubit(
    dependencies: SessionsCubitDependencies(
      localRepository: localRepository,
      jsonParser: const OpenCodeSessionJsonParser(),
      remoteRepositoryFactory:
          remoteRepositoryFactory ?? (_) => _FakeSessionRepository(),
      importedSqlitePathRepositoryFactory:
          importedSqlitePathRepositoryFactory ??
          (path) => OpenCodeSqliteSessionRepository(File(path)),
      importedSqliteBytesRepositoryFactory:
          importedSqliteBytesRepositoryFactory,
    ),
  );
}

void main() {
  test('load clears stale source label', () async {
    final cubit = _buildCubit(
      localRepository: _FakeSessionRepository([
        _session(id: 'new', createdAt: DateTime.utc(2026, 5, 8)),
      ]),
    );
    addTearDown(cubit.close);

    cubit.emit(
      const SessionsState(
        lastOperationSourceLabel: 'stale.json',
        lastOperationCachedCount: 0,
      ),
    );

    await cubit.load();

    expect(cubit.state.lastOperationSourceLabel, isNull);
    expect(cubit.state.lastOperationCachedCount, 1);
  });

  test('syncNow clears stale source label', () async {
    final cubit = _buildCubit(
      localRepository: _FakeSessionRepository(),
      remoteRepositoryFactory: (_) => _FakeSessionRepository([
        _session(id: 'ses_synced', createdAt: DateTime.utc(2026, 5, 8, 12)),
      ]),
    );
    addTearDown(cubit.close);

    cubit.emit(
      const SessionsState(
        lastOperationSourceLabel: 'stale.json',
        lastOperationCachedCount: 0,
      ),
    );

    await cubit.syncNow(
      OpenCodeSettings(
        selectedCurrency: SupportedCurrency.usd,
        openCodeServerUrl: Uri.parse('http://localhost:4096'),
      ),
    );

    expect(cubit.state.lastOperationSourceLabel, isNull);
    expect(cubit.state.lastOperationCachedCount, 1);
  });

  test('importJson error retains current session count', () async {
    final cubit = _buildCubit(
      localRepository: _FakeSessionRepository([
        _session(id: 'existing', createdAt: DateTime.utc(2026, 5, 8)),
      ]),
    );
    addTearDown(cubit.close);

    await cubit.load();
    expect(cubit.state.lastOperationCachedCount, 1);

    final success = await cubit.importJson('{bad json}');
    expect(success, isFalse);
    expect(cubit.state.lastOperationCachedCount, 1);
  });

  test('load sorts sessions newest first', () async {
    final cubit = _buildCubit(
      localRepository: _FakeSessionRepository([
        _session(id: 'old', createdAt: DateTime.utc(2026, 5, 7)),
        _session(id: 'new', createdAt: DateTime.utc(2026, 5, 8)),
      ]),
    );
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.sessions.map((s) => s.id).toList(), ['new', 'old']);
    expect(cubit.state.lastOperationType, 'load');
    expect(cubit.state.lastOperationSuccess, isTrue);
    expect(cubit.state.lastOperationCachedCount, 2);
  });

  test('importJson writes parsed sessions to local repository', () async {
    final localRepository = _FakeSessionRepository();
    final cubit = _buildCubit(localRepository: localRepository);
    addTearDown(cubit.close);

    final success = await cubit.importJson(
      '[{"id":"ses_imported","createdAt":"2026-05-08T12:00:00Z","modelName":"o4-mini","inputTokens":10,"outputTokens":5,"totalCostUsd":0.05}]',
      sourceLabel: 'test.json',
    );

    expect(success, isTrue);
    expect(cubit.state.sessions.single.id, 'ses_imported');
    expect(cubit.state.lastOperationType, 'import-json');
    expect(cubit.state.lastOperationSuccess, isTrue);
    expect(cubit.state.lastOperationSourceLabel, 'test.json');
    expect(cubit.state.lastOperationCachedCount, 1);
  });

  test('importJson reports invalid json as error', () async {
    final cubit = _buildCubit(localRepository: _FakeSessionRepository());
    addTearDown(cubit.close);

    final success = await cubit.importJson('{bad json}');

    expect(success, isFalse);
    expect(cubit.state.isError, isTrue);
  });

  test('importSqlite copies imported sessions into local repository', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'openspent_dashboard_sqlite_test_',
    );
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final databaseFile = await _createImportedSqliteDatabase(
      directory: tempDirectory,
      sessionId: 'ses_sqlite',
      createdAtMs: 1710001000000,
      modelId: 'o4-mini',
      inputTokens: 11,
      outputTokens: 7,
      totalCostUsd: 0.42,
    );

    final cubit = _buildCubit(localRepository: _FakeSessionRepository());
    addTearDown(cubit.close);

    final success = await cubit.importSqlitePath(
      databaseFile.path,
      sourceLabel: 'local.db',
    );

    expect(success, isTrue);
    expect(cubit.state.isError, isFalse);
    expect(cubit.state.sessions, <OpenCodeSession>[
      _session(
        id: 'ses_sqlite',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          1710001000000,
          isUtc: true,
        ),
        provider: 'openai',
        requestCount: 0,
        toolCallCount: 0,
        responseCount: 1,
        modelName: 'o4-mini',
        inputTokens: 11,
        outputTokens: 7,
        totalCostUsd: 0.42,
        usageSlices: <SessionUsageSlice>[
          SessionUsageSlice(
            provider: 'openai',
            modelName: 'o4-mini',
            inputTokens: 11,
            outputTokens: 7,
            totalCostUsd: 0.42,
            requestCount: 0,
            toolCallCount: 0,
            responseCount: 1,
            totalResponseTimeMs: null,
          ),
        ],
      ),
    ]);
    expect(cubit.state.lastOperationType, 'import-sqlite');
    expect(cubit.state.lastOperationSuccess, isTrue);
    expect(cubit.state.lastOperationSourceLabel, 'local.db');
    expect(cubit.state.lastOperationCachedCount, 1);
  });

  test('importSqlite reports missing database as error', () async {
    final cubit = _buildCubit(localRepository: _FakeSessionRepository());
    addTearDown(cubit.close);

    final success = await cubit.importSqlitePath(
      '/definitely-missing/opencode.db',
    );

    expect(success, isFalse);
    expect(cubit.state.isError, isTrue);
  });

  test('importSqliteBytes uses uploaded-byte repository path', () async {
    final sqliteBytes = Uint8List.fromList(<int>[1, 2, 3, 4]);
    Uint8List? capturedBytes;

    final cubit = _buildCubit(
      localRepository: _FakeSessionRepository(),
      importedSqliteBytesRepositoryFactory: (bytes) {
        capturedBytes = bytes;
        return _FakeSessionRepository([
          _session(
            id: 'ses_sqlite_web',
            createdAt: DateTime.utc(2026, 5, 8, 13),
            modelName: 'o4-mini',
            inputTokens: 5,
            outputTokens: 3,
            totalCostUsd: 0.11,
          ),
        ]);
      },
    );
    addTearDown(cubit.close);

    final success = await cubit.importSqliteBytes(
      sqliteBytes,
      sourceLabel: 'upload.db',
    );

    expect(success, isTrue);
    expect(capturedBytes, same(sqliteBytes));
    expect(cubit.state.sessions.single.id, 'ses_sqlite_web');
    expect(cubit.state.lastOperationType, 'import-sqlite');
    expect(cubit.state.lastOperationSuccess, isTrue);
    expect(cubit.state.lastOperationSourceLabel, 'upload.db');
    expect(cubit.state.lastOperationCachedCount, 1);
  });

  test('syncNow clears stale message and loads remote sessions', () async {
    final cubit = _buildCubit(
      localRepository: _FakeSessionRepository(),
      remoteRepositoryFactory: (_) => _FakeSessionRepository([
        _session(id: 'ses_synced', createdAt: DateTime.utc(2026, 5, 8, 12)),
      ]),
    );
    addTearDown(cubit.close);

    cubit.emit(const SessionsState(isError: true, message: 'stale error'));

    final success = await cubit.syncNow(
      OpenCodeSettings(
        selectedCurrency: SupportedCurrency.usd,
        openCodeServerUrl: Uri.parse('http://localhost:4096'),
      ),
    );

    expect(success, isTrue);
    expect(cubit.state.isError, isFalse);
    expect(cubit.state.message, isNull);
    expect(cubit.state.sessions.single.id, 'ses_synced');
    expect(cubit.state.lastOperationType, 'sync');
    expect(cubit.state.lastOperationSuccess, isTrue);
    expect(cubit.state.lastOperationCachedCount, 1);
  });

  test('syncNow passes full settings into remote factory', () async {
    OpenCodeSettings? capturedSettings;
    final cubit = _buildCubit(
      localRepository: _FakeSessionRepository(),
      remoteRepositoryFactory: (settings) {
        capturedSettings = settings;
        return _FakeSessionRepository();
      },
    );
    addTearDown(cubit.close);

    final settings = OpenCodeSettings(
      selectedCurrency: SupportedCurrency.usd,
      openCodeServerUrl: Uri.parse('http://localhost:4096'),
      openCodeServerPassword: 'secret',
    );

    await cubit.syncNow(settings);

    expect(capturedSettings, same(settings));
    expect(capturedSettings?.effectiveOpenCodeServerUsername, 'opencode');
  });
}

Future<File> _createImportedSqliteDatabase({
  required Directory directory,
  required String sessionId,
  required int createdAtMs,
  required String modelId,
  required int inputTokens,
  required int outputTokens,
  required double totalCostUsd,
}) async {
  final databaseFile = File('${directory.path}/opencode.db');
  final database = sqlite3.open(databaseFile.path);
  addTearDown(database.dispose);

  database.execute('''
    CREATE TABLE session (
      id TEXT PRIMARY KEY,
      time_created INTEGER NOT NULL,
      time_updated INTEGER NOT NULL,
      time_archived INTEGER
    )
  ''');
  database.execute('''
    CREATE TABLE message (
      id TEXT PRIMARY KEY,
      session_id TEXT NOT NULL,
      time_created INTEGER NOT NULL,
      time_updated INTEGER NOT NULL,
      data TEXT NOT NULL
    )
  ''');

  database.execute(
    'INSERT INTO session (id, time_created, time_updated, time_archived) VALUES (?, ?, ?, ?)',
    <Object?>[sessionId, createdAtMs, createdAtMs, null],
  );
  database.execute(
    'INSERT INTO message (id, session_id, time_created, time_updated, data) VALUES (?, ?, ?, ?, ?)',
    <Object?>[
      'msg-assistant',
      sessionId,
      createdAtMs + 10,
      createdAtMs + 10,
      jsonEncode(<String, Object?>{
        'role': 'assistant',
        'modelID': modelId,
        'providerID': 'openai',
        'cost': totalCostUsd,
        'tokens': <String, Object?>{
          'input': inputTokens,
          'output': outputTokens,
        },
        'time': <String, Object?>{'created': createdAtMs + 10},
      }),
    ],
  );

  return databaseFile;
}
