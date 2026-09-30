import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:openspent_core/openspent_core.dart';
import '../preferences/key_value_store.dart';

final class NativeLocalUsageSources implements LocalUsageSources {
  NativeLocalUsageSources({
    required this.store,
    required this.sessions,
    Map<String, String>? environment,
    this.resolveHomeDirectory,
    this.restoreDirectoryAccess,
    this.releaseDirectoryAccess,
  }) : environment = environment ?? Platform.environment;
  final KeyValueStore store;
  final OpenCodeSessionRepository sessions;
  final Map<String, String> environment;
  final Future<String?> Function()? resolveHomeDirectory;
  final Future<void> Function(List<String>)? restoreDirectoryAccess;
  final Future<void> Function(List<String>, List<String>)?
  releaseDirectoryAccess;
  static const storageKey = 'openspent.localSources.v1';
  Future<void>? _activeRefresh;

  Future<Map<String, dynamic>> _config() async {
    final raw = await store.readString(storageKey);
    if (raw == null) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> _save(Map<String, dynamic> config) =>
      store.writeString(storageKey, jsonEncode(config));

  Future<List<String>> _discover(UsageHarness harness) async {
    final home =
        await resolveHomeDirectory?.call() ??
        environment['HOME'] ??
        environment['USERPROFILE'];
    if (home == null) return [];
    if (harness == UsageHarness.claudeCode) {
      final config = environment['CLAUDE_CONFIG_DIR'] ?? '$home/.claude';
      return ['$config/projects'];
    }
    if (harness == UsageHarness.codex) {
      final config = environment['CODEX_HOME'] ?? '$home/.codex';
      return ['$config/sessions', '$config/archived_sessions'];
    }
    return [];
  }

  @override
  Future<List<LocalUsageSourceStatus>> statuses() async {
    final config = await _config();
    return [
      for (final h in [UsageHarness.claudeCode, UsageHarness.codex])
        _status(h, config[h.name] as Map<String, dynamic>?),
    ];
  }

  LocalUsageSourceStatus _status(UsageHarness h, Map<String, dynamic>? entry) =>
      LocalUsageSourceStatus(
        harness: h,
        connected: entry != null,
        lastRefresh: DateTime.tryParse(entry?['lastRefresh'] as String? ?? ''),
        sessions: entry?['sessions'] as int? ?? 0,
        skippedRecords: entry?['skipped'] as int? ?? 0,
        failedFiles: entry?['failed'] as int? ?? 0,
        unavailable: entry?['unavailable'] == true,
      );

  @override
  Future<bool> connect(UsageHarness harness, {String? directory}) async {
    if (harness == UsageHarness.openCode) return false;
    await _activeRefresh;
    var candidates = directory == null ? await _discover(harness) : [directory];
    // Folder selections can be a harness home or its transcript root.
    if (directory != null) {
      if (harness == UsageHarness.codex &&
          await Directory('$directory/sessions').exists()) {
        candidates = ['$directory/sessions', '$directory/archived_sessions'];
      } else if (harness == UsageHarness.claudeCode &&
          await Directory('$directory/projects').exists()) {
        candidates = ['$directory/projects'];
      }
    }
    final existing = <String>[];
    for (final path in candidates) {
      if (await Directory(path).exists()) existing.add(path);
    }
    if (existing.isEmpty) return false;
    final config = await _config();
    config[harness.name] = {'directories': candidates};
    await _save(config);
    await refresh(harness: harness);
    return true;
  }

  @override
  Future<void> disconnect(UsageHarness harness) async {
    await _activeRefresh;
    final config = await _config();
    final removed = config.remove(harness.name) as Map<String, dynamic>?;
    await _save(config);
    final retained = config.values
        .expand(
          (entry) => ((entry as Map)['directories'] as List).cast<String>(),
        )
        .toSet();
    final directories = (removed?['directories'] as List? ?? [])
        .cast<String>()
        .where((path) => !retained.contains(path))
        .toList();
    await releaseDirectoryAccess?.call(directories, retained.toList());
  }

  @override
  Future<void> refresh({UsageHarness? harness}) async {
    final active = _activeRefresh;
    if (active != null) {
      await active;
      return;
    }
    final operation = _refresh(harness);
    _activeRefresh = operation;
    try {
      await operation;
    } finally {
      _activeRefresh = null;
    }
  }

  Future<void> _refresh(UsageHarness? selected) async {
    final config = await _config();
    for (final h in [UsageHarness.claudeCode, UsageHarness.codex]) {
      final entry = config[h.name] as Map<String, dynamic>?;
      if (entry == null || (selected != null && selected != h)) continue;
      try {
        final roots = (entry['directories'] as List).cast<String>();
        await restoreDirectoryAccess?.call(roots);
        // Capture only transferable configuration, never the service/database.
        final result = await _scanInBackground(h, roots);
        await sessions.writeSessions(result.sessions);
        entry.addAll({
          'lastRefresh': DateTime.now().toUtc().toIso8601String(),
          'sessions': result.sessions.map((s) => s.id).toSet().length,
          'skipped': result.skipped,
          'failed': result.failed,
          'unavailable': result.unavailable,
        });
      } catch (_) {
        entry['unavailable'] = true;
      }
    }
    await _save(config);
  }
}

final class _ScanResult {
  const _ScanResult(this.sessions, this.skipped, this.failed, this.unavailable);
  final List<OpenCodeSession> sessions;
  final int skipped, failed;
  final bool unavailable;
}

Future<_ScanResult> _scan(UsageHarness harness, List<String> roots) async {
  final result = <OpenCodeSession>[];
  var skipped = 0, failed = 0, foundRoot = false;
  for (final path in roots) {
    final directory = Directory(path);
    if (!await directory.exists()) continue;
    foundRoot = true;
    try {
      await for (final entity in directory.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File || !entity.path.endsWith('.jsonl')) continue;
        final parser = HarnessTranscriptParser(harness);
        try {
          await for (final line
              in entity
                  .openRead()
                  .transform(utf8.decoder)
                  .transform(const LineSplitter())) {
            parser.addLine(line);
          }
        } catch (_) {
          failed++;
        }
        result.addAll(parser.finish());
        skipped += parser.skippedRecords;
      }
    } catch (_) {
      failed++;
    }
  }
  return _ScanResult(result, skipped, failed, !foundRoot);
}

Future<_ScanResult> _scanInBackground(
  UsageHarness harness,
  List<String> roots,
) => Isolate.run(() => _scan(harness, roots));
