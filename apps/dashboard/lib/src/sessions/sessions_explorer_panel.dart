import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openspent_core/openspent_core.dart';

import '../../l10n/app_localizations.dart';
import '../screens/metrics/widgets/metrics_chart_widgets.dart';
import '../screens/sessions/cubit/sessions_cubit.dart';
import 'import_selection.dart';

const _backgroundColor = Color(0xFF000000);
const _surfaceColor = Color(0xFF0A0A0A);
const _borderColor = Color(0xFF333333);
const _primaryTextColor = Color(0xFFFFFFFF);
const _secondaryTextColor = Color(0xFFA1A1AA);
const _statusColor = Color(0xFF22C55E);

String? _normalizeModelName(String? modelName) {
  final normalized = modelName?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  return normalized.toLowerCase();
}

String? _displayModelName(String? modelName) {
  final normalized = modelName?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  return normalized;
}

String _getOpTypeLabel(AppLocalizations l10n, String type) {
  switch (type) {
    case 'load':
      return l10n.opTypeLoad;
    case 'sync':
      return l10n.opTypeSync;
    case 'import-json':
      return l10n.opTypeImportJson;
    case 'import-sqlite':
      return l10n.opTypeImportSqlite;
    default:
      return type.toUpperCase();
  }
}

DateTime _normalizeUtcDay(DateTime value) {
  final utc = value.toUtc();
  return DateTime.utc(utc.year, utc.month, utc.day);
}

bool _isSameUtcDay(DateTime left, DateTime right) {
  return _normalizeUtcDay(left) == _normalizeUtcDay(right);
}

String _formatDateKey(DateTime value) {
  final normalized = _normalizeUtcDay(value);
  return '${normalized.year}-${normalized.month.toString().padLeft(2, '0')}-${normalized.day.toString().padLeft(2, '0')}';
}

enum _SessionSort { latest, cost, tokens }

class SessionsExplorerPanel extends StatefulWidget {
  const SessionsExplorerPanel({
    super.key,
    this.serverSettings,
    this.serverUrl,
    required this.isConnected,
    required this.onDataChanged,
    required this.pickImportSource,
    this.selectedModelFilter,
    this.selectedDay,
    this.selectedUtcHour,
    this.onClearModelFilter,
    this.windowFrom,
    this.windowTo,
  });

  final OpenCodeSettings? serverSettings;
  final Uri? serverUrl;
  final bool isConnected;
  final VoidCallback onDataChanged;
  final Future<ImportSelection?> Function() pickImportSource;
  final String? selectedModelFilter;
  final DateTime? selectedDay;
  final int? selectedUtcHour;
  final VoidCallback? onClearModelFilter;
  final DateTime? windowFrom;
  final DateTime? windowTo;

  @override
  State<SessionsExplorerPanel> createState() => _SessionsExplorerPanelState();
}

class _SessionsExplorerPanelState extends State<SessionsExplorerPanel> {
  String? _statusMessage;
  _SessionSort _sortMode = _SessionSort.latest;

  Future<void> _handleSync() async {
    if (!widget.isConnected) {
      return;
    }

    final settings =
        widget.serverSettings ??
        OpenCodeSettings(
          selectedCurrency: SupportedCurrency.usd,
          openCodeServerUrl:
              widget.serverUrl ?? Uri.parse('http://localhost:4096'),
        );

    final success = await context.read<SessionsCubit>().syncNow(settings);
    if (!mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _statusMessage = success
          ? l10n.sessionsExplorerSyncSuccess
          : l10n.sessionsExplorerSyncError;
    });

    if (success) {
      widget.onDataChanged();
    }
  }

  Future<void> _handleImport() async {
    final l10n = AppLocalizations.of(context)!;
    final source = await widget.pickImportSource();

    if (!mounted) {
      return;
    }

    if (source == null) {
      setState(() {
        _statusMessage = l10n.sessionsExplorerImportNoFile;
      });
      return;
    }

    bool success = false;
    final cubit = context.read<SessionsCubit>();
    if (source.jsonContent != null) {
      success = await cubit.importJson(
        source.jsonContent!,
        sourceLabel: source.sourceLabel,
      );
    } else if (source.sqliteFile != null) {
      success = await cubit.importSqlite(
        source.sqliteFile!,
        sourceLabel: source.sourceLabel,
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _statusMessage = success
          ? l10n.sessionsExplorerImportSuccess
          : l10n.sessionsExplorerImportError;
    });

    if (success) {
      widget.onDataChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<SessionsCubit, SessionsState>(
      builder: (context, state) {
        final canSync = widget.isConnected && !state.isLoading;
        final selectedModelFilterLabel = _displayModelName(
          widget.selectedModelFilter,
        );
        final selectedModelFilter = _normalizeModelName(
          widget.selectedModelFilter,
        );
        final hasActiveHourFilter =
            widget.selectedDay != null && widget.selectedUtcHour != null;

        final rawSessions = state.sessions;
        var sessions = rawSessions.toList();

        if (selectedModelFilter != null) {
          sessions = sessions.where((s) {
            return _normalizeModelName(s.modelName) == selectedModelFilter;
          }).toList();
        }

        if (widget.windowFrom != null && widget.windowTo != null) {
          final from = widget.windowFrom!;
          final to = widget.windowTo!;
          sessions = sessions.where((s) {
            final d = _normalizeUtcDay(s.createdAt);
            return (d.isAfter(from) || _isSameUtcDay(d, from)) &&
                (d.isBefore(to) || _isSameUtcDay(d, to));
          }).toList();
        }

        if (widget.selectedDay != null) {
          sessions = sessions.where((s) {
            return _isSameUtcDay(s.createdAt, widget.selectedDay!);
          }).toList();
        }

        if (hasActiveHourFilter) {
          sessions = sessions.where((s) {
            return s.createdAt.toUtc().hour == widget.selectedUtcHour;
          }).toList();
        }

        switch (_sortMode) {
          case _SessionSort.latest:
            sessions.sort((a, b) {
              final cmp = b.createdAt.compareTo(a.createdAt);
              if (cmp != 0) return cmp;
              return a.id.compareTo(b.id);
            });
            break;
          case _SessionSort.cost:
            sessions.sort((a, b) {
              final aCost = a.totalCostUsd ?? 0.0;
              final bCost = b.totalCostUsd ?? 0.0;
              final cmp = bCost.compareTo(aCost);
              if (cmp != 0) return cmp;
              final cmp2 = b.createdAt.compareTo(a.createdAt);
              if (cmp2 != 0) return cmp2;
              return a.id.compareTo(b.id);
            });
            break;
          case _SessionSort.tokens:
            sessions.sort((a, b) {
              final aTokens = (a.inputTokens ?? 0) + (a.outputTokens ?? 0);
              final bTokens = (b.inputTokens ?? 0) + (b.outputTokens ?? 0);
              final cmp = bTokens.compareTo(aTokens);
              if (cmp != 0) return cmp;
              final cmp2 = b.createdAt.compareTo(a.createdAt);
              if (cmp2 != 0) return cmp2;
              return a.id.compareTo(b.id);
            });
            break;
        }

        final usageByModel = <String, int>{};
        for (final s in sessions) {
          final modelName = s.modelName ?? l10n.sessionsExplorerUnknownModel;
          final tokens = (s.inputTokens ?? 0) + (s.outputTokens ?? 0);
          usageByModel[modelName] = (usageByModel[modelName] ?? 0) + tokens;
        }

        final topSessions = sessions.take(3).toList();

        Widget buildSessionRow(
          OpenCodeSession session,
          int index, {
          bool isSpotlight = false,
        }) {
          final tokens =
              (session.inputTokens ?? 0) + (session.outputTokens ?? 0);
          final sessionId = session.id.length > 8
              ? session.id.substring(0, 8)
              : session.id;
          final modelName =
              session.modelName ?? l10n.sessionsExplorerUnknownModel;

          return Padding(
            key: isSpotlight ? Key("sessions-spotlight-row-$index") : null,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.sessionRowData(
                    session.createdAt.toIso8601String(),
                    modelName,
                    tokens.toString(),
                    "USD",
                    (session.totalCostUsd ?? 0).toStringAsFixed(4),
                    sessionId,
                  ),
                  style: textTheme.bodyLarge,
                ),
                if (session.subagentCategory != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l10n.sessionsExplorerSubagent(session.subagentCategory!),
                      style: textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isBounded = constraints.hasBoundedHeight;

            Widget listContent = Container(
              decoration: BoxDecoration(
                color: _backgroundColor,
                border: Border.all(color: _borderColor),
              ),
              child: sessions.isEmpty && !state.isLoading
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          (selectedModelFilterLabel != null ||
                                  widget.selectedDay != null ||
                                  hasActiveHourFilter)
                              ? l10n.sessionsExplorerFilteredEmpty
                              : widget.isConnected
                              ? l10n.sessionsExplorerEmptyConnected
                              : l10n.sessionsExplorerEmptyDisconnected,
                          key: const Key("sessions-empty-state"),
                          style: textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.separated(
                      key: const Key("sessions-list"),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: sessions.length,
                      separatorBuilder: (_, index) =>
                          const Divider(height: 1, color: _borderColor),
                      itemBuilder: (context, index) {
                        return buildSessionRow(sessions[index], index);
                      },
                    ),
            );

            return Container(
              key: const Key("sessions-panel"),
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _surfaceColor,
                border: Border.all(color: _borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        l10n.sessionsExplorerTitle,
                        style: textTheme.titleMedium,
                      ),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          GestureDetector(
                            key: const Key("sessions-sync-button"),
                            onTap: canSync ? _handleSync : null,
                            child: Text(
                              l10n.sessionsExplorerActionSync,
                              style: textTheme.bodyLarge?.copyWith(
                                color: canSync
                                    ? _primaryTextColor
                                    : _secondaryTextColor,
                                fontWeight: canSync
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          GestureDetector(
                            key: const Key("sessions-import-button"),
                            onTap: state.isLoading ? null : _handleImport,
                            child: Text(
                              l10n.sessionsExplorerActionImport,
                              style: textTheme.bodyLarge?.copyWith(
                                color: state.isLoading
                                    ? _secondaryTextColor
                                    : _primaryTextColor,
                                fontWeight: state.isLoading
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (state.isLoading)
                    Text(
                      l10n.sessionsExplorerLoading,
                      style: textTheme.bodyLarge,
                    )
                  else if (_statusMessage != null)
                    Text(
                      _statusMessage!,
                      style: textTheme.bodyLarge?.copyWith(
                        color: state.isError
                            ? _secondaryTextColor
                            : _statusColor,
                      ),
                    ),
                  if (!state.isLoading &&
                      state.isError &&
                      state.message != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      l10n.sessionsExplorerError,
                      style: textTheme.bodyMedium,
                    ),
                  ],
                  if (selectedModelFilterLabel != null ||
                      widget.selectedDay != null ||
                      hasActiveHourFilter) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _backgroundColor,
                        border: Border.all(color: _borderColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (selectedModelFilterLabel != null)
                                  Text(
                                    l10n.activeModelFilter(
                                      selectedModelFilterLabel,
                                    ),
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: _statusColor,
                                    ),
                                  ),
                                if (widget.selectedDay != null)
                                  Text(
                                    l10n.activeDayFilter(
                                      _formatDateKey(widget.selectedDay!),
                                    ),
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: _statusColor,
                                    ),
                                  ),
                                if (hasActiveHourFilter)
                                  Text(
                                    l10n.activeHourFilter(
                                      widget.selectedUtcHour!
                                          .toString()
                                          .padLeft(2, '0'),
                                    ),
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: _statusColor,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (selectedModelFilterLabel != null) ...[
                            const SizedBox(width: 12),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                key: const Key("sessions-clear-filter"),
                                onTap: widget.onClearModelFilter,
                                child: Text(
                                  l10n.clearFilterAction,
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: _secondaryTextColor,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      Container(
                        width: 300,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: _borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.sessionsExplorerCachedHistoryTitle,
                              style: textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            if (rawSessions.isEmpty)
                              Text(
                                l10n.sessionsExplorerCachedEmpty,
                                style: textTheme.bodyLarge,
                              )
                            else ...[
                              Text(
                                l10n.sessionsExplorerCachedCount(
                                  rawSessions.length,
                                ),
                                style: textTheme.bodyLarge,
                              ),
                              Text(
                                l10n.sessionsExplorerCachedNewest(
                                  rawSessions.first.createdAt
                                      .toIso8601String()
                                      .split("T")
                                      .first,
                                ),
                                style: textTheme.bodyLarge,
                              ),
                              Text(
                                l10n.sessionsExplorerCachedOldest(
                                  rawSessions.last.createdAt
                                      .toIso8601String()
                                      .split("T")
                                      .first,
                                ),
                                style: textTheme.bodyLarge,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        width: 300,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: _borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.sessionsExplorerLastOpTitle,
                              style: textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            if (state.lastOperationType == null)
                              Text(
                                l10n.sessionsExplorerLastOpNone,
                                style: textTheme.bodyLarge,
                              )
                            else ...[
                              Text(
                                l10n.sessionsExplorerLastOpType(
                                  _getOpTypeLabel(
                                    l10n,
                                    state.lastOperationType!,
                                  ),
                                ),
                                style: textTheme.bodyLarge,
                              ),
                              Text(
                                l10n.sessionsExplorerLastOpStatus(
                                  state.lastOperationSuccess == true
                                      ? l10n.opStatusSuccess
                                      : l10n.opStatusFailure,
                                ),
                                style: textTheme.bodyLarge?.copyWith(
                                  color: state.lastOperationSuccess == true
                                      ? _statusColor
                                      : _secondaryTextColor,
                                ),
                              ),
                              if (state.lastOperationSourceLabel != null)
                                Text(
                                  l10n.sessionsExplorerLastOpSource(
                                    state.lastOperationSourceLabel!,
                                  ),
                                  style: textTheme.bodyLarge,
                                ),
                              if (state.lastOperationCachedCount != null)
                                Text(
                                  l10n.sessionsExplorerLastOpCount(
                                    state.lastOperationCachedCount!,
                                  ),
                                  style: textTheme.bodyLarge,
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    key: const Key("sessions-spotlight-panel"),
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: _borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              "-- TOP SESSIONS --",
                              style: textTheme.bodyMedium,
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                GestureDetector(
                                  key: const Key("sessions-sort-latest"),
                                  onTap: () => setState(
                                    () => _sortMode = _SessionSort.latest,
                                  ),
                                  child: Text(
                                    "[ LATEST ]",
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: _sortMode == _SessionSort.latest
                                          ? _primaryTextColor
                                          : _secondaryTextColor,
                                      fontWeight:
                                          _sortMode == _SessionSort.latest
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  key: const Key("sessions-sort-cost"),
                                  onTap: () => setState(
                                    () => _sortMode = _SessionSort.cost,
                                  ),
                                  child: Text(
                                    "[ COST ]",
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: _sortMode == _SessionSort.cost
                                          ? _primaryTextColor
                                          : _secondaryTextColor,
                                      fontWeight: _sortMode == _SessionSort.cost
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  key: const Key("sessions-sort-tokens"),
                                  onTap: () => setState(
                                    () => _sortMode = _SessionSort.tokens,
                                  ),
                                  child: Text(
                                    "[ TOKENS ]",
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: _sortMode == _SessionSort.tokens
                                          ? _primaryTextColor
                                          : _secondaryTextColor,
                                      fontWeight:
                                          _sortMode == _SessionSort.tokens
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (rawSessions.isNotEmpty &&
                                      topSessions.isEmpty)
                                    Text(
                                      l10n.sessionsSpotlightEmptyScope,
                                      style: textTheme.bodyLarge,
                                    )
                                  else if (topSessions.isEmpty)
                                    Text(
                                      l10n.sessionsSpotlightEmpty,
                                      style: textTheme.bodyLarge,
                                    )
                                  else
                                    ...List.generate(topSessions.length, (
                                      index,
                                    ) {
                                      return buildSessionRow(
                                        topSessions[index],
                                        index,
                                        isSpotlight: true,
                                      );
                                    }),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: ModelUsagePieChart(
                                usageByModel: usageByModel,
                                chartKey: const Key("sessions-top-model-pie"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isBounded)
                    Expanded(child: listContent)
                  else
                    SizedBox(height: 300, child: listContent),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
