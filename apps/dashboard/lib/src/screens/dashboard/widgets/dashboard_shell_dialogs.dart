import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../theme/dashboard_colors.dart';
import 'dashboard_chip_button.dart';
import 'dashboard_surface.dart';

class DashboardHelpDialogContent extends StatelessWidget {
  const DashboardHelpDialogContent({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: DashboardSurface(
        key: const Key('help-dialog'),
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.helpDialogTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              DashboardSurface(
                padding: EdgeInsets.zero,
                backgroundColor: dashboardBackgroundColor,
                child: TabBar(
                  indicator: BoxDecoration(
                    color: dashboardSurfaceColor,
                    border: Border.all(color: dashboardBorderColor),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: dashboardPrimaryTextColor,
                  unselectedLabelColor: dashboardSecondaryTextColor,
                  tabs: [
                    Tab(
                      key: const Key('help-tab-local'),
                      text: l10n.helpTabLocal,
                    ),
                    Tab(
                      key: const Key('help-tab-remote'),
                      text: l10n.helpTabRemote,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: TabBarView(
                  children: [
                    _HelpDialogBody(
                      key: const Key('help-panel-local'),
                      lines: [
                        l10n.helpLocalLineImport,
                        l10n.helpLocalLinePaths,
                        l10n.helpLocalLineCommandDbPath,
                        l10n.helpLocalLineCommandExport,
                        l10n.helpLocalLineCommandSessionList,
                        l10n.helpLocalLineCommandStats,
                        l10n.helpLocalLineBackup,
                      ],
                    ),
                    _HelpDialogBody(
                      key: const Key('help-panel-remote'),
                      lines: [
                        l10n.helpRemoteLineServe,
                        l10n.helpRemoteLineDefaultUrl,
                        l10n.helpRemoteLineHostUse,
                        l10n.helpRemoteLineAuthEnv,
                        l10n.helpRemoteLineAuthDefaultUsername,
                        l10n.helpRemoteLineCors(
                          Uri.base.scheme.startsWith('http')
                              ? Uri.base.origin
                              : 'http://localhost:8080',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: DashboardChipButton(
                  key: const Key('help-close-button'),
                  label: l10n.settingsClose,
                  onTap: () => Navigator.of(context, rootNavigator: true).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpDialogBody extends StatelessWidget {
  const _HelpDialogBody({super.key, required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DashboardSurface(
      padding: const EdgeInsets.all(16),
      backgroundColor: dashboardBackgroundColor,
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < lines.length; index++) ...[
                Text(lines[index], style: textTheme.bodyLarge),
                if (index < lines.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardCustomDateRangeDialog extends StatefulWidget {
  const DashboardCustomDateRangeDialog({
    super.key,
    required this.initialDateRange,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTimeRange? initialDateRange;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<DashboardCustomDateRangeDialog> createState() =>
      _DashboardCustomDateRangeDialogState();
}

class _DashboardCustomDateRangeDialogState
    extends State<DashboardCustomDateRangeDialog> {
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _start = widget.initialDateRange?.start;
    _end = widget.initialDateRange?.end;
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start ?? DateTime.now(),
      firstDate: widget.firstDate,
      lastDate: _end ?? widget.lastDate,
    );
    if (picked != null) {
      setState(() {
        _start = picked;
      });
    }
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _end ?? _start ?? DateTime.now(),
      firstDate: _start ?? widget.firstDate,
      lastDate: widget.lastDate,
    );
    if (picked != null) {
      setState(() {
        _end = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final startLabel = _start != null
        ? '${_start!.year}-${_start!.month.toString().padLeft(2, '0')}-${_start!.day.toString().padLeft(2, '0')}'
        : l10n.customRangeSelectStart;
    final endLabel = _end != null
        ? '${_end!.year}-${_end!.month.toString().padLeft(2, '0')}-${_end!.day.toString().padLeft(2, '0')}'
        : l10n.customRangeSelectEnd;

    return DashboardSurface(
      key: const Key('custom-range-dialog'),
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.windowActionCustom, style: textTheme.titleMedium),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: DashboardChipButton(
                    key: const Key('custom-range-start'),
                    label: startLabel,
                    onTap: _pickStart,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(' - '),
                ),
                Expanded(
                  child: DashboardChipButton(
                    key: const Key('custom-range-end'),
                    label: endLabel,
                    onTap: _pickEnd,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                DashboardChipButton(
                  key: const Key('custom-range-cancel'),
                  label: l10n.settingsClose,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 16),
                DashboardChipButton(
                  key: const Key('custom-range-save'),
                  label: l10n.settingsSave,
                  isSelected: true,
                  onTap: _start != null && _end != null
                      ? () => Navigator.of(
                          context,
                        ).pop(DateTimeRange(start: _start!, end: _end!))
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
