import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:openspent_core/openspent_core.dart';
import 'package:openspent_local/openspent_local_native.dart';
import 'package:sqlite3/sqlite3.dart';

Map<String, Object?> response(
  String id, {
  int input = 100,
  String model = 'gpt-6.1-sol',
  String timestamp = '2026-09-02T01:00:00Z',
}) => {
  'type': 'token_usage_record',
  'timestamp': timestamp,
  'payload': {
    'thread_id': 'session',
    'response_id': id,
    'model': model,
    'usage': {
      'input_tokens': input,
      'output_tokens': 20,
      'cached_input_tokens': 50,
      'cache_write_input_tokens': 0,
      'reasoning_output_tokens': 10,
    },
  },
};
String transcript(List<Map<String, Object?>> records) => [
  jsonEncode({
    'type': 'session_meta',
    'timestamp': '2026-09-01T00:00:00Z',
    'payload': {
      'id': 'session',
      'timestamp': '2026-09-01T00:00:00Z',
      'cwd': '/secret/project',
      'creator_account_id': 'SECRET_ACCOUNT',
      'base_instructions': 'SECRET_PROMPT',
    },
  }),
  ...records.map(jsonEncode),
].join('\n');

void main() {
  test(
    'connect, refresh, archiving, partial files and disconnect retain metadata exactly once',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'openspent_sources_test_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final db = OpenSpentLocalDatabase.inMemory();
      addTearDown(db.close);
      final repository = LocalOpenCodeSessionRepository(db);
      final store = _Store();
      final sessionsDir = await Directory(
        '${directory.path}/sessions',
      ).create();
      final file = File('${sessionsDir.path}/session.jsonl');
      await file.writeAsString(transcript([response('response-a')]));
      final restored = <List<String>>[];
      final released = <List<String>>[];
      final sources = NativeLocalUsageSources(
        restoreDirectoryAccess: (roots) async {
          restored.add(roots);
        },
        releaseDirectoryAccess: (roots, retained) async {
          released.add(roots);
          expect(retained, isEmpty);
        },
        store: store,
        sessions: repository,
        environment: {'HOME': directory.path, 'CODEX_HOME': directory.path},
      );
      expect(await sources.connect(UsageHarness.codex), isTrue);
      await sources.refresh();
      expect(restored, hasLength(2));
      expect(restored.first, contains(sessionsDir.path));
      var sessions = await repository.readSessions();
      expect(sessions.single.inputTokens, 100);
      expect(sessions.single.totalCostUsd, isNull);
      expect(sessions.single.tokens.reasoning, 10);
      final archive = await Directory(
        '${directory.path}/archived_sessions',
      ).create();
      await file.rename('${archive.path}/session.jsonl');
      await sources.refresh();
      expect((await repository.readSessions()).single.inputTokens, 100);
      final archivedFile = File('${archive.path}/session.jsonl');
      await archivedFile.writeAsString(
        '${transcript([response('response-a'), response('response-b', input: 200)])}\n{"prompt":"SECRET_PARTIAL',
      );
      await sources.refresh();
      sessions = await repository.readSessions();
      expect(sessions.single.inputTokens, 300);
      expect(sessions.single.usageEvents, hasLength(2));
      final status = (await sources.statuses()).singleWhere(
        (s) => s.harness == UsageHarness.codex,
      );
      expect(status.lastRefresh, isNotNull);
      expect(status.skippedRecords, 1);
      // A shorter partial snapshot must never remove prior complete usage.
      await archivedFile.writeAsString(transcript([response('response-a')]));
      await sources.refresh();
      expect((await repository.readSessions()).single.inputTokens, 300);
      await sources.disconnect(UsageHarness.codex);
      expect(released.single, contains(sessionsDir.path));
      expect(
        (await sources.statuses())
            .singleWhere((s) => s.harness == UsageHarness.codex)
            .connected,
        isFalse,
      );
      expect((await repository.readSessions()).single.inputTokens, 300);
      final persisted = jsonEncode(
        (await db.select(db.usageEvents).get())
            .map((r) => r.metadataJson)
            .toList(),
      );
      expect(persisted, isNot(contains('SECRET')));
      expect(persisted, isNot(contains('/secret/project')));
    },
  );
  test(
    'harness/date filtering and custom pricing changes use stored events',
    () async {
      final db = OpenSpentLocalDatabase.inMemory();
      addTearDown(db.close);
      final sessions = LocalOpenCodeSessionRepository(db);
      final parser = HarnessTranscriptParser(UsageHarness.codex);
      for (final line in transcript([
        response('a'),
        response('b', timestamp: '2026-09-03T01:00:00Z'),
      ]).split('\n')) {
        parser.addLine(line);
      }
      await sessions.writeSessions(parser.finish());
      await sessions.writeSessions([
        OpenCodeSession(
          id: 'legacy',
          createdAt: DateTime.utc(2026, 9, 2),
          inputTokens: 500,
          outputTokens: 50,
          totalCostUsd: 3,
        ),
      ]);
      final pricing = LocalPricingRepository(_Store());
      final metrics = LocalMetricsRepository(
        sessions,
        pricingRepository: pricing,
      );
      var data = await metrics.readHarnessMetrics(
        harness: UsageHarness.codex,
        from: DateTime.utc(2026, 9, 3),
      );
      expect(data.totalInputTokens, 100);
      expect(data.totalSessionCount, 1);
      expect(data.totalCostUsd, 0);
      final original = data.harnessUsage[UsageHarness.codex]!.estimatedUsd;
      await pricing.writePricing(
        PricingConfig(
          overrides: {
            'openai/gpt-6.1-sol': ApiRates(
              input: 100,
              output: 100,
              cachedInput: 100,
            ),
          },
        ),
      );
      data = await metrics.readHarnessMetrics(
        harness: UsageHarness.codex,
        from: DateTime.utc(2026, 9, 3),
      );
      expect(
        data.harnessUsage[UsageHarness.codex]!.estimatedUsd,
        greaterThan(original!),
      );
      expect(
        (await sessions.readSessions())
            .singleWhere((s) => s.id == 'legacy')
            .totalCostUsd,
        3,
      );
    },
  );
  test('v3 migration preserves legacy IDs, reported costs and settings keys', () async {
    final directory = await Directory.systemTemp.createTemp(
      'openspent_migration_test_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/local.db';
    final legacy = sqlite3.open(path);
    legacy.execute(
      'CREATE TABLE open_code_sessions (id TEXT PRIMARY KEY NOT NULL, created_at_utc INTEGER NOT NULL, '
      'provider TEXT, model_name TEXT, input_tokens INTEGER, output_tokens INTEGER, total_cost_usd REAL, '
      'request_count INTEGER, tool_call_count INTEGER, response_count INTEGER, total_response_time_ms INTEGER, '
      'subagent_category TEXT, usage_slices_json TEXT)',
    );
    legacy.execute(
      'CREATE TABLE exchange_rates (currency_code TEXT NOT NULL, effective_date_utc INTEGER NOT NULL, '
      'source_date_utc INTEGER NOT NULL, rate_to_czk REAL NOT NULL, PRIMARY KEY(currency_code,effective_date_utc))',
    );
    legacy.execute(
      "INSERT INTO open_code_sessions (id, created_at_utc, total_cost_usd) VALUES ('original', 1, 12.5)",
    );
    legacy.execute('PRAGMA user_version = 3');
    legacy.dispose();
    final db = OpenSpentLocalDatabase.filePath(path);
    addTearDown(db.close);
    final sessions = await LocalOpenCodeSessionRepository(db).readSessions();
    expect(sessions.single.id, 'original');
    expect(sessions.single.harness, UsageHarness.openCode);
    expect(sessions.single.totalCostUsd, 12.5);
    expect(sessions.single.tokens.cachedInput, isNull);
    final store = _Store();
    await LocalSettingsRepository(store).writeSettings(
      OpenCodeSettings(
        selectedCurrency: SupportedCurrency.usd,
        openCodeServerUrl: Uri.parse('http://localhost:4096'),
      ),
    );
    final originalSettings = store.values.values.single;
    await LocalPricingRepository(store).writePricing(PricingConfig());
    expect(store.values['openspent.settings'], originalSettings);
    expect(
      (jsonDecode(originalSettings) as Map).keys,
      containsAll(['selectedCurrency', 'openCodeServerUrl', 'languageCode']),
    );
  });
  test(
    'source failure and absent roots do not discard cached sessions',
    () async {
      final db = OpenSpentLocalDatabase.inMemory();
      addTearDown(db.close);
      final repository = LocalOpenCodeSessionRepository(db);
      await repository.writeSessions([
        OpenCodeSession(id: 'legacy', createdAt: DateTime.utc(2026)),
      ]);
      final sources = NativeLocalUsageSources(
        store: _Store(),
        sessions: repository,
        environment: {'HOME': '/nonexistent-openspent-test'},
      );
      expect(await sources.connect(UsageHarness.claudeCode), isFalse);
      expect((await repository.readSessions()).single.id, 'legacy');
    },
  );
}

class _Store implements KeyValueStore {
  final values = <String, String>{};
  @override
  Future<String?> readString(String key) async => values[key];
  @override
  Future<void> writeString(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}
