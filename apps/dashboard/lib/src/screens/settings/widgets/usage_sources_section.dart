import 'package:flutter/material.dart';
import 'package:openspent_core/openspent_core.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../usage/harness_labels.dart';

class UsageSourcesSection extends StatefulWidget {
  const UsageSourcesSection({
    super.key,
    this.sources,
    this.pickDirectory,
    required this.onChanged,
  });
  final LocalUsageSources? sources;
  final Future<String?> Function()? pickDirectory;
  final VoidCallback onChanged;
  @override
  State<UsageSourcesSection> createState() => _UsageSourcesSectionState();
}

class _UsageSourcesSectionState extends State<UsageSourcesSection> {
  List<LocalUsageSourceStatus> _statuses = [];
  bool _busy = false;
  bool _error = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final statuses = await widget.sources?.statuses() ?? [];
    if (mounted) setState(() => _statuses = statuses);
  }

  Future<void> _run(Future<void> Function() operation) async {
    setState(() {
      _busy = true;
      _error = false;
    });
    try {
      await operation();
      widget.onChanged();
      await _load();
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _connect(UsageHarness harness) => _run(() async {
    var connected = await widget.sources!.connect(harness);
    if (!connected) {
      final directory = await widget.pickDirectory?.call();
      if (directory == null) return;
      connected = await widget.sources!.connect(harness, directory: directory);
      if (!connected && mounted) setState(() => _error = true);
    }
  });
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.usageSourcesTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          widget.sources == null ? l.usageSourcesBrowser : l.usageSourcesHelp,
        ),
        if (_busy) ...[
          const LinearProgressIndicator(),
          Text(l.usageSourceBusy),
        ],
        if (_error) Text(l.usageSourceError),
        for (final status in _statuses) ...[
          const SizedBox(height: 16),
          Text(harnessLabel(status.harness)),
          Text(status.connected ? l.usageConnected : l.usageNotConnected),
          if (status.connected) ...[
            Text(
              status.lastRefresh == null
                  ? l.usageNeverRefreshed
                  : l.usageLastRefresh(
                      '${MaterialLocalizations.of(context).formatShortDate(status.lastRefresh!.toLocal())} ${TimeOfDay.fromDateTime(status.lastRefresh!.toLocal()).format(context)}',
                    ),
            ),
            Text(
              l.usageSourceResult(
                status.sessions,
                status.skippedRecords,
                status.failedFiles,
              ),
            ),
            if (status.unavailable) Text(l.usageSourceError),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!status.connected)
                OutlinedButton(
                  key: Key('connect-${status.harness.name}'),
                  onPressed: _busy ? null : () => _connect(status.harness),
                  child: Text(l.usageConnect),
                ),
              if (status.connected) ...[
                OutlinedButton(
                  key: Key('refresh-${status.harness.name}'),
                  onPressed: _busy
                      ? null
                      : () => _run(
                          () =>
                              widget.sources!.refresh(harness: status.harness),
                        ),
                  child: Text(l.usageRefresh),
                ),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _run(
                          () => widget.sources!.disconnect(status.harness),
                        ),
                  child: Text(l.usageDisconnect),
                ),
              ],
              if (widget.pickDirectory != null)
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                          final directory = await widget.pickDirectory!();
                          if (directory != null &&
                              !await widget.sources!.connect(
                                status.harness,
                                directory: directory,
                              ) &&
                              mounted) {
                            setState(() => _error = true);
                          }
                        }),
                  child: Text(l.usageChooseFolder),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
