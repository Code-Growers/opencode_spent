import 'dart:convert';
import 'dart:io' as io;

import 'package:openspent_core/openspent_core.dart';

import '../database/open_spent_local_database.dart';
import '../preferences/key_value_store.dart';
import '../repositories/local_open_code_session_repository.dart';
import '../repositories/native_local_usage_sources.dart';
import '../repositories/open_code_sqlite_session_repository.dart';

/// A fresh, local-only scan. Nothing is persisted or sent over the network.
/// The same parsers, response deduplication and pricing rules power the app.
final class SpendingCliRunner {
  SpendingCliRunner({
    Map<String, String>? environment,
    DateTime Function()? now,
  }) : _environment = environment ?? io.Platform.environment,
       _now = now ?? DateTime.now;

  final Map<String, String> _environment;
  final DateTime Function() _now;

  Future<int> run(
    List<String> args, {
    void Function(String)? stdout,
    void Function(String)? stderr,
  }) async {
    final out = stdout ?? io.stdout.writeln;
    final err = stderr ?? io.stderr.writeln;
    if (args.length == 1 && ['--help', '-h', 'help'].contains(args.single)) {
      out(spendingCliUsage);
      return 0;
    }
    late final _Options options;
    try {
      options = _Options.parse(args, _now().toUtc());
    } on FormatException catch (error) {
      // Argument errors contain only our fixed strings, never supplied values.
      err('${error.message}\n\n$spendingCliUsage');
      return 64;
    }
    late final PricingConfig pricing;
    try {
      pricing = options.pricingPath == null
          ? PricingConfig()
          : PricingConfig.fromJson(
              jsonDecode(await io.File(options.pricingPath!).readAsString())
                  as Map<String, dynamic>,
            );
    } catch (_) {
      err('Could not read pricing configuration. Expected valid pricing JSON.');
      return 1;
    }

    final database = OpenSpentLocalDatabase.inMemory();
    try {
      final repository = LocalOpenCodeSessionRepository(database);
      final sources = NativeLocalUsageSources(
        store: _MemoryStore(),
        sessions: repository,
        environment: _environment,
      );
      final statuses = <UsageHarness, Map<String, Object?>>{};
      for (final harness in UsageHarness.values) {
        if (options.harness != null && harness != options.harness) continue;
        if (!options.json) err('Reading ${_label(harness)} local usage…');
        if (harness == UsageHarness.openCode) {
          final home = _environment['HOME'] ?? _environment['USERPROFILE'];
          final dataHome =
              _environment['XDG_DATA_HOME'] ??
              (home == null ? null : '$home/.local/share');
          final path =
              options.openCodePath ??
              (dataHome == null ? null : '$dataHome/opencode/opencode.db');
          final exists = path != null && await io.File(path).exists();
          if (!exists) {
            statuses[harness] = _status(
              options.openCodePath == null ? 'not-found' : 'failed',
            );
            continue;
          }
          try {
            await repository.writeSessions(
              await OpenCodeSqliteSessionRepository(
                io.File(path),
              ).readSessions(),
            );
            statuses[harness] = _status('ready');
          } catch (_) {
            statuses[harness] = _status('failed');
          }
        } else {
          final directory = harness == UsageHarness.codex
              ? options.codexPath
              : options.claudePath;
          try {
            final connected = await sources.connect(
              harness,
              directory: directory,
            );
            final status = (await sources.statuses()).singleWhere(
              (s) => s.harness == harness,
            );
            statuses[harness] = {
              ..._status(
                !connected
                    ? directory == null
                          ? 'not-found'
                          : 'failed'
                    : status.unavailable
                    ? 'failed'
                    : status.failedFiles > 0 || status.skippedRecords > 0
                    ? 'partial'
                    : 'ready',
              ),
              'failedFiles': status.failedFiles,
              'skippedRecords': status.skippedRecords,
            };
          } catch (_) {
            statuses[harness] = _status('failed');
          }
        }
      }
      final sessions = (await repository.readSessions())
          .map((s) => selectSessionUsage(s, from: options.from, to: options.to))
          .whereType<OpenCodeSession>()
          .toList();
      final rows = <Map<String, Object?>>[];
      for (final entry in statuses.entries) {
        final selected = sessions.where((s) => s.harness == entry.key).toList();
        final metrics = const OpenCodeMetricsCalculator().calculate(
          selected,
          pricing: pricing,
        );
        final usage = metrics.harnessUsage[entry.key];
        rows.add({
          'harness': entry.key.name,
          'label': _label(entry.key),
          ...entry.value,
          'sessions': metrics.totalSessionCount,
          'tokens': usage?.tokens.toJson(),
          'reportedUsd': metrics.totalCostCoverageSessionCount == 0
              ? null
              : metrics.totalCostUsd,
          'reportedSessions': metrics.totalCostCoverageSessionCount,
          'estimatedUsd': usage?.estimatedUsd,
          'pricedRecords': usage?.pricedEventCount ?? 0,
          'usageRecords': usage?.eventCount ?? 0,
          'assumptionRecords': usage?.assumptionCount ?? 0,
          'customPriceRecords': usage?.customPriceCount ?? 0,
        });
      }
      double? sum(String key) {
        final known = rows.map((r) => r[key]).whereType<double>().toList();
        return known.isEmpty ? null : known.fold<double>(0, (a, b) => a + b);
      }

      int count(String key) => rows.fold<int>(0, (a, r) => a + (r[key] as int));
      final report = {
        'schemaVersion': 1,
        'currency': 'USD',
        'pricingVersion': ApiPriceCatalog.version,
        'from': options.from?.toIso8601String(),
        'to': options.to?.toIso8601String(),
        'harnesses': rows,
        'totals': {
          'sessions': sessions.length,
          'reportedUsd': sum('reportedUsd'),
          'reportedSessions': count('reportedSessions'),
          'estimatedUsd': sum('estimatedUsd'),
          'pricedRecords': count('pricedRecords'),
          'usageRecords': count('usageRecords'),
          'assumptionRecords': count('assumptionRecords'),
        },
      };
      out(
        options.json
            ? const JsonEncoder.withIndent('  ').convert(report)
            : _format(report),
      );
      // Missing optional installations are normal. Damaged sources are not.
      return rows.any(
            (r) => r['status'] == 'failed' || (r['failedFiles'] as int) > 0,
          )
          ? 1
          : 0;
    } catch (_) {
      err(
        'Could not load local usage. No sensitive source details were printed.',
      );
      return 1;
    } finally {
      await database.close();
    }
  }

  Map<String, Object?> _status(String status) => {
    'status': status,
    'failedFiles': 0,
    'skippedRecords': 0,
  };

  String _format(Map<String, Object?> report) {
    final rows = report['harnesses'] as List<Map<String, Object?>>;
    final total = report['totals'] as Map<String, Object?>;
    String money(Object? value) =>
        value == null ? 'unknown' : (value as double).toStringAsFixed(4);
    String row(String label, Map<String, Object?> r) =>
        '${label.padRight(14)} ${r['sessions'].toString().padLeft(8)} ${money(r['reportedUsd']).padLeft(14)} ${money(r['estimatedUsd']).padLeft(14)} ${'${r['pricedRecords']}/${r['usageRecords']}'.padLeft(10)}';
    final lines = [
      'OpenSpent · local spending summary',
      'Window (UTC): ${report['from'] ?? 'beginning'} → ${report['to'] ?? 'latest'}',
      '',
      'Harness        Sessions   Reported USD   API estimate     Priced',
      for (final r in rows) row(r['label'] as String, r),
      row('TOTAL', total),
      '',
      'API estimate: known priced records only; missing prices remain unknown.',
      'Reported spend and API estimates are separate; do not add them together.',
      'Estimates exclude subscriptions, taxes and extra service charges.',
      'Pricing snapshot: ${report['pricingVersion']}',
      if ((total['assumptionRecords'] as int) > 0)
        'Standard context/cache assumptions used for ${total['assumptionRecords']} priced records.',
      '',
      for (final r in rows)
        '${r['label']}: ${r['status']} · failed files ${r['failedFiles']} · skipped records ${r['skippedRecords']}',
      if ((total['sessions'] as int) == 0)
        'No usage found in this window. Check source availability or select another period.',
      'Only available local records are included. No prompts or project paths are displayed.',
    ];
    return lines.join('\n');
  }
}

String _label(UsageHarness harness) => switch (harness) {
  UsageHarness.openCode => 'OpenCode',
  UsageHarness.claudeCode => 'Claude Code',
  UsageHarness.codex => 'Codex',
};

final class _MemoryStore implements KeyValueStore {
  final _values = <String, String>{};
  @override
  Future<String?> readString(String key) async => _values[key];
  @override
  Future<void> writeString(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }
}

final class _Options {
  const _Options({
    this.from,
    this.to,
    this.harness,
    this.openCodePath,
    this.claudePath,
    this.codexPath,
    this.pricingPath,
    this.json = false,
  });
  final DateTime? from, to;
  final UsageHarness? harness;
  final String? openCodePath, claudePath, codexPath, pricingPath;
  final bool json;
  static _Options parse(List<String> args, DateTime now) {
    final values = <String, String>{};
    var json = false;
    for (var i = 0; i < args.length; i++) {
      final flag = args[i];
      if (flag == 'spend' && i == 0) continue;
      if (flag == '--json' && !json) {
        json = true;
        continue;
      }
      if (![
            '--days',
            '--from',
            '--to',
            '--harness',
            '--opencode-db',
            '--claude-dir',
            '--codex-dir',
            '--pricing',
          ].contains(flag) ||
          values.containsKey(flag) ||
          i + 1 == args.length ||
          args[i + 1].startsWith('--') ||
          args[i + 1].trim().isEmpty) {
        throw const FormatException('Unknown, repeated or incomplete option.');
      }
      values[flag] = args[++i];
    }
    DateTime? date(String flag, {bool endOfDay = false}) {
      final value = values[flag];
      if (value == null) return null;
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
        throw const FormatException('Dates must use YYYY-MM-DD (UTC).');
      }
      final parsed = DateTime.tryParse('${value}T00:00:00Z');
      if (parsed == null ||
          parsed.toIso8601String().substring(0, 10) != value) {
        throw const FormatException('Invalid UTC date.');
      }
      return endOfDay
          ? parsed
                .add(const Duration(days: 1))
                .subtract(const Duration(microseconds: 1))
          : parsed;
    }

    var from = date('--from'), to = date('--to', endOfDay: true);
    if (values.containsKey('--days')) {
      final days = int.tryParse(values['--days']!);
      if (days == null ||
          days < 1 ||
          days > 36500 ||
          from != null ||
          to != null) {
        throw const FormatException(
          '--days must be 1–36500 and cannot be combined with --from or --to.',
        );
      }
      from = now.subtract(Duration(days: days));
      to = now;
    }
    if (from != null && to != null && from.isAfter(to)) {
      throw const FormatException('--from must be on or before --to.');
    }
    final harness = switch (values['--harness']) {
      null || 'all' => null,
      'opencode' => UsageHarness.openCode,
      'claude' || 'claude-code' => UsageHarness.claudeCode,
      'codex' => UsageHarness.codex,
      _ => throw const FormatException(
        'Harness must be all, opencode, claude or codex.',
      ),
    };
    return _Options(
      from: from,
      to: to,
      harness: harness,
      json: json,
      openCodePath: values['--opencode-db'],
      claudePath: values['--claude-dir'],
      codexPath: values['--codex-dir'],
      pricingPath: values['--pricing'],
    );
  }
}

const spendingCliUsage = '''Usage: openspent [spend] [options]

Read all supported local harnesses on demand (no server or account needed).
  --days N             Last N rolling days (UTC); default: all available usage
  --from YYYY-MM-DD    Start date, inclusive (UTC)
  --to YYYY-MM-DD      End date, inclusive (UTC)
  --harness NAME       all, opencode, claude or codex
  --opencode-db FILE   OpenCode SQLite database
  --claude-dir DIR     Claude config directory or projects folder
  --codex-dir DIR      Codex home or sessions folder (home includes archives)
  --pricing FILE       PricingConfig JSON with overrides and model mappings
  --json               Machine-readable numeric summaries
  --help, -h           Show this help

Discovery respects XDG_DATA_HOME, CLAUDE_CONFIG_DIR, CODEX_HOME and HOME.
Prints reported USD spend and estimated API cost separately, with coverage.
Exit codes: 0 success/no sources, 1 read failure, 64 invalid options.''';
