import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openspent_core/openspent_core.dart';

import '../../l10n/app_localizations.dart';
import '../screens/metrics/widgets/metrics_chart_widgets.dart';
import '../screens/metrics/metrics_utils.dart';
import '../screens/sessions/cubit/sessions_cubit.dart';
import '../theme/dashboard_colors.dart';
import '../screens/dashboard/widgets/dashboard_chip_button.dart';
import '../screens/dashboard/widgets/dashboard_surface.dart';
import 'import_selection.dart';

const _backgroundColor = dashboardBackgroundColor;
const _borderColor = dashboardBorderColor;
const _secondaryTextColor = dashboardSecondaryTextColor;
const _statusColor = dashboardStatusColor;
const _errorColor = dashboardErrorColor;

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

class _Callout extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;

  const _Callout({
    required this.child,
    this.backgroundColor,
    this.borderColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardSurface(
      padding: padding ?? const EdgeInsets.all(16),
      backgroundColor: backgroundColor ?? dashboardBackgroundColor,
      borderColor: borderColor ?? dashboardBorderColor,
      child: child,
    );
  }
}

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

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

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
    } else if (source.sqlitePath != null) {
      success = await cubit.importSqlitePath(
        source.sqlitePath!,
        sourceLabel: source.sourceLabel,
      );
    } else if (source.sqliteBytes != null) {
      success = await cubit.importSqliteBytes(
        source.sqliteBytes!,
        sourceLabel: source.sourceLabel,
      );
    }

    if (!mounted) {
      return;
    }

    if (success) {
      widget.onDataChanged();
    }
  }

  String? _statusMessageForState(AppLocalizations l10n, SessionsState state) {
    if (_statusMessage != null) {
      return _statusMessage;
    }

    return switch (state.lastOperationType) {
      'sync' =>
        state.lastOperationSuccess == true
            ? l10n.sessionsExplorerSyncSuccess
            : l10n.sessionsExplorerSyncError,
      'import-json' || 'import-sqlite' =>
        state.lastOperationSuccess == true
            ? l10n.sessionsExplorerImportSuccess
            : (state.isWalModeImportError
                  ? l10n.sessionsExplorerImportWalModeError
                  : l10n.sessionsExplorerImportError),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<SessionsCubit, SessionsState>(
      listener: (context, state) {
        if (state.isLoading ||
            state.lastOperationType != null ||
            state.isError) {
          if (_statusMessage != null) {
            setState(() {
              _statusMessage = null;
            });
          }
        }
      },
      builder: (context, state) {
        final effectiveStatusMessage = _statusMessageForState(l10n, state);
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

        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          sessions = sessions.where((s) {
            final tokens = (s.inputTokens ?? 0) + (s.outputTokens ?? 0);
            return s.id.toLowerCase().contains(query) ||
                s.createdAt.toIso8601String().toLowerCase().contains(query) ||
                (s.provider?.toLowerCase().contains(query) ?? false) ||
                (s.modelName?.toLowerCase().contains(query) ?? false) ||
                (s.subagentCategory?.toLowerCase().contains(query) ?? false) ||
                (s.inputTokens?.toString().contains(query) ?? false) ||
                (s.outputTokens?.toString().contains(query) ?? false) ||
                tokens.toString().contains(query) ||
                (s.totalCostUsd?.toString().contains(query) ?? false) ||
                (s.requestCount?.toString().contains(query) ?? false) ||
                (s.toolCallCount?.toString().contains(query) ?? false) ||
                (s.responseCount?.toString().contains(query) ?? false) ||
                (s.totalResponseTimeMs?.toString().contains(query) ?? false);
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '$modelName • ${compactNumber(tokens.toDouble())} TOK',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'USD ${(session.totalCostUsd ?? 0).toStringAsFixed(4)}',
                      style: textTheme.bodyLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'ID: $sessionId',
                        style: textTheme.bodyMedium?.copyWith(
                          color: _secondaryTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      session.createdAt.toIso8601String(),
                      style: textTheme.bodyMedium?.copyWith(
                        color: _secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                if (session.subagentCategory != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l10n.sessionsExplorerSubagent(session.subagentCategory!),
                      style: textTheme.bodyMedium?.copyWith(
                        color: _secondaryTextColor,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isBounded = constraints.hasBoundedHeight;
            final isDesktop = constraints.maxWidth >= 1100;

            Widget listContent = DashboardSurface(
              backgroundColor: _backgroundColor,
              child: sessions.isEmpty && !state.isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: _Callout(
                        child: Text(
                          (selectedModelFilterLabel != null ||
                                  widget.selectedDay != null ||
                                  hasActiveHourFilter ||
                                  _searchQuery.isNotEmpty)
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

            Widget listToolbar = DashboardSurface(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.sessionsListHeader,
                    key: const Key("sessions-list-header"),
                    style: textTheme.titleMedium,
                  ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    children: [
                      SizedBox(
                        width: constraints.maxWidth < 600 ? 200 : 300,
                        child: TextField(
                          key: const Key("sessions-search-field"),
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          style: textTheme.bodyLarge,
                          decoration: const InputDecoration()
                              .applyDefaults(
                                Theme.of(context).inputDecorationTheme,
                              )
                              .copyWith(
                                hintText: l10n.sessionsSearchPlaceholder,
                                isDense: true,
                                filled: true,
                                fillColor: _backgroundColor,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: _borderColor,
                                  ),
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: dashboardAccentColor,
                                  ),
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        key: const Key(
                                          "sessions-search-clear-button",
                                        ),
                                        icon: const Icon(Icons.close, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          _searchFocusNode.unfocus();
                                        },
                                        tooltip: l10n.sessionsSearchClear,
                                      )
                                    : null,
                              ),
                        ),
                      ),
                      Text(
                        l10n.sessionsSearchResultsCount(sessions.length),
                        key: const Key("sessions-search-results-count"),
                        style: textTheme.bodyLarge?.copyWith(
                          color: _secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );

            Widget listColumn = Column(
              key: const Key("sessions-list-column"),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                listToolbar,
                const SizedBox(height: 8),
                if (isBounded)
                  Expanded(child: listContent)
                else
                  SizedBox(height: 500, child: listContent),
              ],
            );

            Widget sidebarSummary = DashboardSurface(
              padding: const EdgeInsets.all(12),
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
                          DashboardChipButton(
                            key: const Key("sessions-sync-button"),
                            label: l10n.sessionsExplorerActionSync,
                            isSelected: false,
                            onTap: canSync ? _handleSync : null,
                          ),
                          DashboardChipButton(
                            key: const Key("sessions-import-button"),
                            label: l10n.sessionsExplorerActionImport,
                            isSelected: false,
                            onTap: state.isLoading ? null : _handleImport,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (state.isLoading ||
                      effectiveStatusMessage != null ||
                      (state.isError && state.message != null)) ...[
                    const SizedBox(height: 12),
                    _Callout(
                      borderColor: state.isError
                          ? _errorColor
                          : (state.isLoading ? _borderColor : _statusColor),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (state.isLoading)
                            Text(
                              l10n.sessionsExplorerLoading,
                              style: textTheme.bodyLarge,
                            )
                          else if (effectiveStatusMessage != null)
                            Text(
                              effectiveStatusMessage,
                              style: textTheme.bodyLarge?.copyWith(
                                color: state.isError
                                    ? _errorColor
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
                        ],
                      ),
                    ),
                  ],
                  if (selectedModelFilterLabel != null ||
                      widget.selectedDay != null ||
                      hasActiveHourFilter) ...[
                    const SizedBox(height: 12),
                    _Callout(
                      backgroundColor: _backgroundColor,
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
                            DashboardChipButton(
                              key: const Key("sessions-clear-filter"),
                              label: l10n.clearFilterAction,
                              onTap: widget.onClearModelFilter,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );

            Widget sidebarHistory = _Callout(
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.all(8),
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
                      l10n.sessionsExplorerCachedCount(rawSessions.length),
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
            );

            Widget sidebarLastOp = _Callout(
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.all(8),
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
                        _getOpTypeLabel(l10n, state.lastOperationType!),
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
                            : _errorColor,
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
            );

            Widget sidebarSpotlight = Container(
              key: const Key("sessions-spotlight-panel"),
              child: _Callout(
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text("-- TOP SESSIONS --", style: textTheme.bodyMedium),
                        Wrap(
                          spacing: 8,
                          children: [
                            DashboardChipButton(
                              key: const Key("sessions-sort-latest"),
                              label: "[ LATEST ]",
                              isSelected: _sortMode == _SessionSort.latest,
                              onTap: () => setState(
                                () => _sortMode = _SessionSort.latest,
                              ),
                            ),
                            DashboardChipButton(
                              key: const Key("sessions-sort-cost"),
                              label: "[ COST ]",
                              isSelected: _sortMode == _SessionSort.cost,
                              onTap: () =>
                                  setState(() => _sortMode = _SessionSort.cost),
                            ),
                            DashboardChipButton(
                              key: const Key("sessions-sort-tokens"),
                              label: "[ TOKENS ]",
                              isSelected: _sortMode == _SessionSort.tokens,
                              onTap: () => setState(
                                () => _sortMode = _SessionSort.tokens,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    !isDesktop
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (rawSessions.isNotEmpty &&
                                      topSessions.isEmpty)
                                    _Callout(
                                      child: Text(
                                        l10n.sessionsSpotlightEmptyScope,
                                        style: textTheme.bodyLarge,
                                      ),
                                    )
                                  else if (topSessions.isEmpty)
                                    _Callout(
                                      child: Text(
                                        l10n.sessionsSpotlightEmpty,
                                        style: textTheme.bodyLarge,
                                      ),
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
                              const SizedBox(height: 16, width: 16),
                              ModelUsagePieChart(
                                usageByModel: usageByModel,
                                chartKey: const Key("sessions-top-model-pie"),
                                expanded: true,
                              ),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (rawSessions.isNotEmpty &&
                                        topSessions.isEmpty)
                                      _Callout(
                                        child: Text(
                                          l10n.sessionsSpotlightEmptyScope,
                                          style: textTheme.bodyLarge,
                                        ),
                                      )
                                    else if (topSessions.isEmpty)
                                      _Callout(
                                        child: Text(
                                          l10n.sessionsSpotlightEmpty,
                                          style: textTheme.bodyLarge,
                                        ),
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
                                  expanded: true,
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            );

            Widget sidebarColumn = Column(
              key: const Key("sessions-sidebar-column"),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                sidebarSummary,
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [sidebarHistory, sidebarLastOp],
                ),
                const SizedBox(height: 8),
                sidebarSpotlight,
              ],
            );

            return Container(
              key: const Key("sessions-panel"),
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  sidebarColumn,
                  const SizedBox(height: 16),
                  if (isBounded) Expanded(child: listColumn) else listColumn,
                ],
              ),
            );
          },
        );
      },
    );
  }
}
