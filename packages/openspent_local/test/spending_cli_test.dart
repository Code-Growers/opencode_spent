import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:openspent_local/src/cli/spending_cli.dart';

void main() {
  late Directory root;
  late SpendingCliRunner runner;
  late List<String> output, errors;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('openspent_cli_test_');
    runner = SpendingCliRunner(
      environment: {'HOME': root.path},
      now: () => DateTime.utc(2026, 9, 30),
    );
    output = [];
    errors = [];
  });
  tearDown(() => root.delete(recursive: true));
  Future<int> run(List<String> args) =>
      runner.run(args, stdout: output.add, stderr: errors.add);
  Map<String, dynamic> report() =>
      jsonDecode(output.single) as Map<String, dynamic>;

  test(
    'discovers every harness, merges duplicate archives and never outputs secrets',
    () async {
      await _openCode(root);
      await _write(root, '.claude/projects/example/session.jsonl', [
        jsonEncode(_claude()),
      ]);
      await _write(root, '.codex/sessions/session.jsonl', _codex());
      await _write(root, '.codex/archived_sessions/session.jsonl', _codex());
      expect(await run(['--json']), 0);
      final result = report();
      final rows = result['harnesses'] as List;
      expect(rows, hasLength(3));
      expect(rows.map((r) => r['status']), everyElement('ready'));
      expect(result['totals']['sessions'], 3);
      expect(rows[0]['reportedUsd'], 0.25);
      expect(rows[1]['reportedUsd'], isNull);
      expect(rows[2]['tokens']['input'], 100);
      expect(rows[2]['pricedRecords'], 1);
      expect(result['totals']['reportedUsd'], 0.25);
      expect(result['totals']['estimatedUsd'], greaterThan(0));
      expect(output.single, isNot(contains('SECRET')));
      expect(output.single, isNot(contains('/private/project')));
      expect(output.single, isNot(contains(root.path)));
      expect(errors, isEmpty);
    },
  );

  test(
    'UTC date filters use usage time even when session started earlier',
    () async {
      await _write(root, '.codex/sessions/session.jsonl', _codex());
      expect(
        await run([
          '--harness',
          'codex',
          '--from',
          '2026-09-02',
          '--to',
          '2026-09-02',
          '--json',
        ]),
        0,
      );
      expect(report()['totals']['sessions'], 1);
      output.clear();
      expect(await run(['--harness', 'codex', '--days', '1', '--json']), 0);
      expect(report()['totals']['sessions'], 0);
      expect(report()['totals']['estimatedUsd'], isNull);
    },
  );

  test(
    'unknown models remain unpriced and custom rates recalculate estimates',
    () async {
      await _write(
        root,
        '.codex/sessions/session.jsonl',
        _codex(model: 'custom-model'),
      );
      expect(await run(['--harness', 'codex', '--json']), 0);
      expect(report()['totals']['estimatedUsd'], isNull);
      expect(report()['totals']['pricedRecords'], 0);
      final pricing = File('${root.path}/rates.json');
      await pricing.writeAsString(
        jsonEncode({
          'overrides': {
            'openai/custom-model': {
              'input': 2,
              'output': 10,
              'cachedInput': 0.1,
            },
          },
        }),
      );
      output.clear();
      expect(
        await run(['--harness', 'codex', '--pricing', pricing.path, '--json']),
        0,
      );
      expect(report()['totals']['estimatedUsd'], closeTo(0.000305, 1e-10));
      expect(report()['harnesses'][0]['customPriceRecords'], 1);
    },
  );

  test(
    'explicit paths and environment discovery respect custom homes',
    () async {
      await _write(root, 'custom/projects/session.jsonl', [
        jsonEncode(_claude()),
      ]);
      runner = SpendingCliRunner(
        environment: {
          'HOME': root.path,
          'CLAUDE_CONFIG_DIR': '${root.path}/custom',
        },
      );
      expect(await run(['--harness', 'claude', '--json']), 0);
      expect(report()['totals']['sessions'], 1);
      output.clear();
      runner = SpendingCliRunner(environment: {});
      expect(
        await run([
          '--harness',
          'claude',
          '--claude-dir',
          '${root.path}/custom',
          '--json',
        ]),
        0,
      );
      expect(report()['totals']['sessions'], 1);
    },
  );

  test(
    'missing installations are normal; explicit unavailable sources fail without leaking paths',
    () async {
      expect(await run(['--json']), 0);
      expect(report()['totals']['estimatedUsd'], isNull);
      expect(
        (report()['harnesses'] as List).map((r) => r['status']),
        everyElement('not-found'),
      );
      output.clear();
      expect(
        await run([
          '--harness',
          'opencode',
          '--opencode-db',
          '${root.path}/SECRET.db',
          '--json',
        ]),
        1,
      );
      expect(report()['harnesses'][0]['status'], 'failed');
      expect(output.single, isNot(contains('SECRET')));
    },
  );

  test(
    'malformed transcript lines report partial coverage and retain valid usage',
    () async {
      await _write(root, '.codex/sessions/session.jsonl', [
        ..._codex(),
        '{"SECRET":',
      ]);
      expect(await run(['--harness', 'codex', '--json']), 0);
      expect(report()['harnesses'][0]['status'], 'partial');
      expect(report()['harnesses'][0]['skippedRecords'], 1);
      expect(report()['totals']['sessions'], 1);
    },
  );

  test(
    'help succeeds and invalid dates/options fail before reading sources',
    () async {
      expect(await run(['--help']), 0);
      expect(output.single, contains('Usage: openspent'));
      for (final args in [
        ['--days', '0'],
        ['--days', '2', '--from', '2026-09-01'],
        ['--from', '2026-02-30'],
        ['--from', '2026-09-02', '--to', '2026-09-01'],
        ['--harness', 'SECRET'],
        ['--opencode-db'],
        ['--json', '--json'],
      ]) {
        output.clear();
        errors.clear();
        expect(await run(args), 64);
        expect(output, isEmpty);
        expect(errors.single, isNot(contains('SECRET')));
      }
    },
  );

  test(
    'text output separates reported money, estimates and availability',
    () async {
      await _write(root, '.codex/sessions/session.jsonl', _codex());
      expect(await run([]), 0);
      expect(output.single, contains('Reported USD'));
      expect(output.single, contains('API estimate'));
      expect(output.single, contains('1/1'));
      expect(output.single, contains('unknown'));
      expect(output.single, contains('OpenCode: not-found'));
    },
  );
}

Future<void> _write(Directory root, String relative, List<String> lines) async {
  final file = File('${root.path}/$relative');
  await file.parent.create(recursive: true);
  await file.writeAsString(lines.join('\n'));
}

List<String> _codex({String model = 'gpt-6.1-sol'}) => [
  jsonEncode({
    'type': 'session_meta',
    'timestamp': '2026-09-01T00:00:00Z',
    'payload': {
      'id': 'codex-session',
      'cwd': '/private/project',
      'base_instructions': 'SECRET',
    },
  }),
  jsonEncode({
    'type': 'token_usage_record',
    'timestamp': '2026-09-02T23:59:59Z',
    'payload': {
      'thread_id': 'codex-session',
      'response_id': 'response-a',
      'model': model,
      'usage': {
        'input_tokens': 100,
        'output_tokens': 20,
        'cached_input_tokens': 50,
        'cache_write_input_tokens': 0,
        'reasoning_output_tokens': 10,
      },
    },
  }),
];
Map<String, Object?> _claude() => {
  'type': 'assistant',
  'sessionId': 'claude-session',
  'timestamp': '2026-09-02T00:00:00Z',
  'cwd': '/private/project',
  'message': {
    'id': 'msg-a',
    'model': 'claude-opus-5-5',
    'content': [
      {'text': 'SECRET'},
    ],
    'usage': {
      'input_tokens': 100,
      'output_tokens': 10,
      'cache_read_input_tokens': 50,
      'cache_creation_input_tokens': 0,
    },
  },
};
Future<void> _openCode(Directory root) async {
  final file = File('${root.path}/.local/share/opencode/opencode.db');
  await file.parent.create(recursive: true);
  final db = sqlite3.open(file.path);
  try {
    db.execute(
      'CREATE TABLE session (id TEXT PRIMARY KEY, time_created INTEGER, time_updated INTEGER, time_archived INTEGER)',
    );
    db.execute(
      'CREATE TABLE message (id TEXT PRIMARY KEY, session_id TEXT, time_created INTEGER, time_updated INTEGER, data TEXT)',
    );
    final time = DateTime.utc(2026, 9, 2).millisecondsSinceEpoch;
    db.execute('INSERT INTO session VALUES (?, ?, ?, NULL)', [
      'opencode-session',
      time,
      time,
    ]);
    db.execute('INSERT INTO message VALUES (?, ?, ?, ?, ?)', [
      'msg-oc',
      'opencode-session',
      time,
      time,
      jsonEncode({
        'role': 'assistant',
        'modelID': 'gpt-6.1-sol',
        'providerID': 'openai',
        'cost': 0.25,
        'tokens': {
          'input': 100,
          'output': 10,
          'cache': {'read': 0, 'write': 0},
        },
        'prompt': 'SECRET',
        'time': {'created': time},
      }),
    ]);
  } finally {
    db.dispose();
  }
}
