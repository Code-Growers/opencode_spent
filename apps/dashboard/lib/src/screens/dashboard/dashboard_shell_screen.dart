import 'dart:async';
import 'dart:ui';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:openspent_core/openspent_core.dart';

import '../../../l10n/app_localizations.dart';
import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../screens/exchange_rates/cubit/exchange_rates_cubit.dart';
import '../../screens/exchange_rates/exchange_rates_screen.dart';
import '../../screens/sessions/cubit/sessions_cubit.dart';
import '../../screens/sessions/sessions_screen.dart';
import '../../sessions/import_selection.dart';
import '../../theme/dashboard_colors.dart';
import '../metrics/metrics_screen.dart';
import '../metrics/metrics_utils.dart';
import '../settings/settings_screen.dart';
import 'widgets/terminal_pane.dart';

enum ServerProbeState { unknown, disconnected, connected, error }

typedef _DashboardShellContentBuilder = Widget Function(BuildContext context);

class _DashboardShellScopeData {
  const _DashboardShellScopeData({
    required this.buildMetricsContent,
    required this.buildSessionsContent,
    required this.buildExchangeRatesContent,
    required this.buildStateContent,
  });

  final _DashboardShellContentBuilder buildMetricsContent;
  final _DashboardShellContentBuilder buildSessionsContent;
  final _DashboardShellContentBuilder buildExchangeRatesContent;
  final _DashboardShellContentBuilder buildStateContent;
}

class _DashboardShellScope extends InheritedWidget {
  const _DashboardShellScope({required this.data, required super.child});

  final _DashboardShellScopeData data;

  static _DashboardShellScopeData of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_DashboardShellScope>();
    assert(scope != null, 'Dashboard shell scope is missing.');
    return scope!.data;
  }

  @override
  bool updateShouldNotify(covariant _DashboardShellScope oldWidget) {
    return !identical(data, oldWidget.data);
  }
}

@RoutePage()
class DashboardShellScreen extends StatefulWidget {
  const DashboardShellScreen({
    super.key,
    this.metricsService,
    this.settingsRepository,
    this.serverProbe,
    this.exchangeRatesDependencies,
    this.sessionsDependencies,
    this.pickImportSource,
  });

  final MonetizedMetricsService? metricsService;
  final SettingsRepository? settingsRepository;
  final Future<ServerProbeState> Function(OpenCodeSettings settings)?
  serverProbe;
  final ExchangeRatesCubitDependencies? exchangeRatesDependencies;
  final SessionsCubitDependencies? sessionsDependencies;
  final Future<ImportSelection?> Function()? pickImportSource;

  @override
  State<DashboardShellScreen> createState() => _DashboardShellScreenState();
}

class _DashboardShellScreenState extends State<DashboardShellScreen> {
  OpenCodeSettings? _settings;
  ServerProbeState _probeState = ServerProbeState.unknown;
  bool _settingsLoaded = false;
  int _metricsRevision = 0;
  int _sessionsRevision = 0;
  int _exchangeRatesRevision = 0;
  int _windowUpdateSerial = 0;
  String? _selectedModelFilter;
  DateTime? _selectedDay;
  int? _selectedUtcHour;
  TimeWindow _selectedWindow = TimeWindow.all;
  DateTime? _windowFrom;
  DateTime? _windowTo;
  Timer? _probeTimer;
  bool _probeInProgress = false;
  bool _didInitializeScopeState = false;

  OpenCodeSettings get _effectiveSettings =>
      _settings ?? defaultOpenCodeSettings();

  MonetizedMetricsService get _metricsService =>
      widget.metricsService ?? OpenSpentAppScope.of(context).metricsService;

  SettingsRepository? get _settingsRepository =>
      widget.settingsRepository ??
      OpenSpentAppScope.of(context).settingsRepository;

  Future<ServerProbeState> Function(OpenCodeSettings settings)?
  get _serverProbe =>
      widget.serverProbe ?? OpenSpentAppScope.of(context).serverProbe;

  ExchangeRatesCubitDependencies? get _exchangeRatesDependencies =>
      widget.exchangeRatesDependencies ??
      OpenSpentAppScope.of(context).exchangeRatesDependencies;

  SessionsCubitDependencies? get _sessionsDependencies =>
      widget.sessionsDependencies ??
      OpenSpentAppScope.of(context).sessionsDependencies;

  Future<ImportSelection?> Function()? get _pickImportSource =>
      widget.pickImportSource ?? OpenSpentAppScope.of(context).pickImportSource;

  ValueChanged<String?> get _onLocaleChanged =>
      OpenSpentAppScope.of(context).onLocaleChanged;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitializeScopeState) {
      return;
    }

    _didInitializeScopeState = true;
    _loadSettings();
  }

  @override
  void dispose() {
    _probeTimer?.cancel();
    super.dispose();
  }

  void _startProbeLoop() {
    _probeTimer?.cancel();
    _probeTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _tickProbe(),
    );
  }

  Future<void> _handleProbeTransition({
    required ServerProbeState oldState,
    required ServerProbeState newState,
  }) async {
    if (newState != ServerProbeState.connected) {
      return;
    }

    if (oldState != ServerProbeState.unknown &&
        oldState != ServerProbeState.disconnected &&
        oldState != ServerProbeState.error) {
      return;
    }

    if (_sessionsDependencies == null) {
      return;
    }

    final synced = await _syncSessionsNow(_effectiveSettings);
    if (!mounted || !synced) {
      return;
    }

    _invalidateMetrics(reloadExchangeRates: true);
  }

  Future<void> _tickProbe() async {
    if (_probeInProgress || !_settingsLoaded) {
      return;
    }
    _probeInProgress = true;
    try {
      final oldState = _probeState;
      final newState = await _probeServer(_effectiveSettings);
      if (!mounted) {
        return;
      }

      if (oldState != newState) {
        setState(() {
          _probeState = newState;
        });

        await _handleProbeTransition(oldState: oldState, newState: newState);
      }
    } finally {
      if (mounted) {
        _probeInProgress = false;
      }
    }
  }

  Future<void> _loadSettings() async {
    OpenCodeSettings? persistedSettings;
    if (_settingsRepository != null) {
      try {
        persistedSettings = await _settingsRepository!.readSettings();
      } catch (_) {
        persistedSettings = null;
      }
    }

    final effectiveSettings = persistedSettings ?? defaultOpenCodeSettings();
    await _applySettings(effectiveSettings);
  }

  Future<void> _applySettings(OpenCodeSettings settings) async {
    final previousProbeState = _probeState;
    final probeState = await _probeServer(settings);
    if (!mounted) {
      return;
    }
    setState(() {
      _settings = settings;
      _probeState = probeState;
      _settingsLoaded = true;
    });
    _onLocaleChanged(settings.languageCode);
    _refreshSessions();
    await _handleProbeTransition(
      oldState: previousProbeState,
      newState: probeState,
    );
    _startProbeLoop();
  }

  Future<void> _updateWindowDates({
    bool refreshMetrics = false,
    bool reloadExchangeRates = false,
  }) async {
    final requestedWindow = _selectedWindow;
    final requestSerial = ++_windowUpdateSerial;

    DateTime? nextFrom;
    DateTime? nextTo;

    if (requestedWindow == TimeWindow.custom) {
      nextFrom = _windowFrom;
      nextTo = _windowTo;
    } else if (requestedWindow != TimeWindow.all) {
      final allMetrics = await _metricsService.metricsRepository.readMetrics();
      if (!mounted ||
          requestSerial != _windowUpdateSerial ||
          requestedWindow != _selectedWindow) {
        return;
      }

      if (allMetrics.dailyBreakdown.isNotEmpty) {
        final latestDay = allMetrics.dailyBreakdown
            .map((daily) => daily.date)
            .reduce((a, b) => a.isAfter(b) ? a : b);
        final normalizedLatest = normalizeUtcDay(latestDay);

        switch (requestedWindow) {
          case TimeWindow.days7:
            nextFrom = normalizedLatest.subtract(const Duration(days: 6));
            break;
          case TimeWindow.days30:
            nextFrom = normalizedLatest.subtract(const Duration(days: 29));
            break;
          case TimeWindow.days90:
            nextFrom = normalizedLatest.subtract(const Duration(days: 89));
            break;
          case TimeWindow.all:
          case TimeWindow.custom:
            nextFrom = null;
            break;
        }

        nextTo = normalizedLatest
            .add(const Duration(days: 1))
            .subtract(const Duration(milliseconds: 1));
      }
    }

    if (!mounted ||
        requestSerial != _windowUpdateSerial ||
        requestedWindow != _selectedWindow) {
      return;
    }

    setState(() {
      _windowFrom = nextFrom;
      _windowTo = nextTo;
      if (refreshMetrics) {
        _metricsRevision++;
      }
      if (reloadExchangeRates) {
        _exchangeRatesRevision++;
      }
    });
  }

  DateTime? _effectiveExchangeRateFrom(DateTime? from, DateTime? to) {
    if (from == null || to == null) {
      return from;
    }
    final durationDays = to.difference(from).inDays + 1;
    final priorTo = from.subtract(const Duration(days: 1));
    return priorTo.subtract(Duration(days: durationDays - 1));
  }

  void _handleWindowChanged(TimeWindow window) {
    if (_selectedWindow == window) {
      return;
    }

    setState(() {
      _selectedWindow = window;
    });
    unawaited(_updateWindowDates());
  }

  Future<void> _handleCustomWindowRequested() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 5);
    final lastDate = DateTime(now.year + 1);

    final initialDateRange =
        _selectedWindow == TimeWindow.custom &&
            _windowFrom != null &&
            _windowTo != null
        ? DateTimeRange(start: _windowFrom!, end: _windowTo!)
        : null;

    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: initialDateRange,
    );

    if (pickedRange != null && mounted) {
      ++_windowUpdateSerial;
      final nextFrom = DateTime.utc(
        pickedRange.start.year,
        pickedRange.start.month,
        pickedRange.start.day,
      );
      final nextTo = DateTime.utc(
        pickedRange.end.year,
        pickedRange.end.month,
        pickedRange.end.day,
      ).add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

      setState(() {
        _selectedWindow = TimeWindow.custom;
        _windowFrom = nextFrom;
        _windowTo = nextTo;
        _metricsRevision++;
        _exchangeRatesRevision++;
      });
    }
  }

  Future<ServerProbeState> _probeServer(OpenCodeSettings settings) async {
    if (_serverProbe != null) {
      return _serverProbe!(settings);
    }

    final rawUrl = settings.openCodeServerUrl.toString().trim();
    if (rawUrl.isEmpty) {
      return ServerProbeState.disconnected;
    }

    try {
      final normalizedBaseUrl = rawUrl.endsWith('/') ? rawUrl : '$rawUrl/';
      final probeUri = Uri.parse(normalizedBaseUrl).resolve('session');
      final authorizationHeader = settings.openCodeServerAuthorizationHeader;
      final response = await http
          .get(
            probeUri,
            headers: authorizationHeader == null
                ? null
                : <String, String>{'Authorization': authorizationHeader},
          )
          .timeout(const Duration(seconds: 3));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ServerProbeState.connected;
      }

      return ServerProbeState.error;
    } on SocketException {
      return ServerProbeState.disconnected;
    } on HttpException {
      return ServerProbeState.disconnected;
    } on TimeoutException {
      return ServerProbeState.disconnected;
    } catch (_) {
      return ServerProbeState.error;
    }
  }

  Future<void> _openSettingsDialog() async {
    if (_settingsRepository == null) {
      return;
    }

    await _showDashboardDialog(
      keyValue: 'settings-modal-overlay',
      child: SettingsScreen(
        settingsRepository: _settingsRepository!,
        currentSettings: _settings,
        onSettingsSaved: (settings) async {
          await _applySettings(settings);
        },
        onCloseRequested: () {
          Navigator.of(context, rootNavigator: true).pop();
        },
      ),
    );
  }

  Future<void> _openHelpDialog() async {
    final l10n = AppLocalizations.of(context)!;
    await _showDashboardDialog(
      keyValue: 'help-modal-overlay',
      child: DefaultTabController(
        length: 2,
        child: Container(
          key: const Key('help-dialog'),
          constraints: const BoxConstraints(maxWidth: 720),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: dashboardSurfaceColor,
            border: Border.all(color: dashboardBorderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.helpDialogTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: dashboardBackgroundColor,
                  border: Border.all(color: dashboardBorderColor),
                ),
                child: TabBar(
                  indicator: const BoxDecoration(color: dashboardSurfaceColor),
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
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  key: const Key('help-close-button'),
                  onTap: () => Navigator.of(context, rootNavigator: true).pop(),
                  child: Text(
                    l10n.settingsClose,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: dashboardSecondaryTextColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDashboardDialog({
    required String keyValue,
    required Widget child,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(color: Colors.black.withValues(alpha: 0.15)),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: KeyedSubtree(key: Key(keyValue), child: child),
                ),
              ),
            ],
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 140),
      transitionBuilder: (context, animation, _, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }

  void _invalidateMetrics({bool reloadExchangeRates = false}) {
    if (_selectedWindow == TimeWindow.all) {
      setState(() {
        _metricsRevision++;
        if (reloadExchangeRates) {
          _exchangeRatesRevision++;
        }
      });
      return;
    }

    unawaited(
      _updateWindowDates(
        refreshMetrics: true,
        reloadExchangeRates: reloadExchangeRates,
      ),
    );
  }

  Future<bool> _syncSessionsNow(OpenCodeSettings settings) async {
    final dependencies = _sessionsDependencies;
    if (dependencies == null) {
      return false;
    }

    try {
      final remoteRepository = dependencies.remoteRepositoryFactory(settings);
      final syncService = OpenCodeSessionSyncService(
        remoteRepository: remoteRepository,
        localRepository: dependencies.localRepository,
      );
      await syncService.syncSessions();
      if (!mounted) {
        return false;
      }

      _refreshSessions();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _refreshSessions() {
    if (!mounted) {
      return;
    }

    setState(() {
      _sessionsRevision++;
    });
  }

  void _handleCurrencyChanged(SupportedCurrency currency) {
    setState(() {
      _settings = (_settings ?? defaultOpenCodeSettings()).copyWith(
        selectedCurrency: currency,
      );
      _metricsRevision++;
    });
  }

  bool get _hasSessionsRoute =>
      _sessionsDependencies != null && _pickImportSource != null;

  bool get _hasExchangeRatesRoute => _exchangeRatesDependencies != null;

  bool get _hasSettingsRoute => _settingsRepository != null;

  Widget _buildMetricsContent() {
    return SingleChildScrollView(
      child: MetricsScreen(
        metricsService: _metricsService,
        metricsRevision: _metricsRevision,
        selectedCurrency: _effectiveSettings.selectedCurrency,
        selectedModelFilter: _selectedModelFilter,
        selectedDay: _selectedDay,
        selectedWindow: _selectedWindow,
        onWindowSelected: _handleWindowChanged,
        onCustomWindowRequested: _handleCustomWindowRequested,
        from: _windowFrom,
        to: _windowTo,
        onModelSelected: (model) {
          setState(() {
            _selectedModelFilter = model;
          });
        },
        onDaySelected: (day) {
          setState(() {
            _selectedDay = day;
            _selectedUtcHour = null;
          });
        },
        selectedUtcHour: _selectedUtcHour,
        onHourSelected: (hour) {
          setState(() {
            _selectedUtcHour = _selectedUtcHour == hour ? null : hour;
          });
        },
      ),
    );
  }

  Widget _buildSessionsContent() {
    final sessionsDependencies = _sessionsDependencies;
    final pickImportSource = _pickImportSource;

    if (sessionsDependencies == null || pickImportSource == null) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      child: SessionsScreen(
        dependencies: sessionsDependencies,
        dataRevision: _sessionsRevision,
        serverSettings: _effectiveSettings,
        isConnected: _probeState == ServerProbeState.connected,
        pickImportSource: pickImportSource,
        selectedModelFilter: _selectedModelFilter,
        selectedDay: _selectedDay,
        selectedUtcHour: _selectedUtcHour,
        onClearModelFilter: () {
          setState(() {
            _selectedModelFilter = null;
          });
        },
        windowFrom: _windowFrom,
        windowTo: _windowTo,
        onDataChanged: () {
          _invalidateMetrics(reloadExchangeRates: true);
        },
      ),
    );
  }

  Widget _buildExchangeRatesContent(BuildContext context) {
    final dependencies = _exchangeRatesDependencies;
    if (dependencies == null) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      child: ExchangeRatesScreen(
        dependencies: dependencies,
        exchangeRatesRevision: _exchangeRatesRevision,
        onCurrencyChanged: _handleCurrencyChanged,
        onRatesSynced: () => _invalidateMetrics(),
        from: _effectiveExchangeRateFrom(_windowFrom, _windowTo),
        to: _windowTo,
        windowLabel: formatWindowLabel(
          context,
          _selectedWindow,
          _windowFrom,
          _windowTo,
        ),
      ),
    );
  }

  Widget _buildStateContent(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final serverLabel = _settingsLoaded
        ? _effectiveSettings.openCodeServerUrl.toString()
        : l10n.statusServerLoading;
    final displayProbe = switch (_probeState) {
      ServerProbeState.connected => l10n.statusProbeConnected,
      ServerProbeState.disconnected =>
        _settingsLoaded
            ? l10n.statusProbeDisconnected
            : l10n.statusProbeLoading,
      ServerProbeState.error => l10n.statusProbeError,
      ServerProbeState.unknown => l10n.statusProbeUnknown,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final wideLayout = constraints.maxWidth >= 680;
        final paneWidth = wideLayout
            ? (constraints.maxWidth - 16) / 2
            : constraints.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: paneWidth,
                  child: TerminalPane(
                    title: l10n.statusPaneTitle,
                    lines: [
                      l10n.statusLineReady(
                        _settingsLoaded ? l10n.statusReady : l10n.statusLoading,
                      ),
                      l10n.statusLineMode(l10n.statusModeLocalCache),
                      l10n.statusLineServer(serverLabel),
                      l10n.statusLineProbe(displayProbe),
                    ],
                    lineStyles: [
                      null,
                      null,
                      null,
                      _probeState == ServerProbeState.connected
                          ? textTheme.bodyLarge?.copyWith(
                              color: dashboardStatusColor,
                            )
                          : null,
                    ],
                  ),
                ),
                SizedBox(
                  width: paneWidth,
                  child: TerminalPane(
                    title: l10n.privacyPaneTitle,
                    lines: [
                      l10n.privacyLinePrompts,
                      l10n.privacyLineToolOutput,
                      l10n.privacyLineErrors,
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dashboardSurfaceColor,
                border: Border.all(color: dashboardBorderColor),
              ),
              child: Text(
                l10n.persistedAllowlist(
                  OpenSpentInfo.persistedMetadataAllowlist.length,
                ),
                style: textTheme.bodyLarge,
              ),
            ),
          ],
        );
      },
    );
  }

  _DashboardShellScopeData _buildShellScopeData() {
    return _DashboardShellScopeData(
      buildMetricsContent: (_) => _buildMetricsContent(),
      buildSessionsContent: (_) => _buildSessionsContent(),
      buildExchangeRatesContent: _buildExchangeRatesContent,
      buildStateContent: _buildStateContent,
    );
  }

  int _resolveNavIndex(BuildContext context) {
    final routeName = context.topRoute.name;
    if (routeName == DashboardSessionsRoute.name) {
      return 1;
    }
    if (routeName == DashboardExchangeRatesRoute.name) {
      return 2;
    }
    if (routeName == DashboardStateRoute.name) {
      return 3;
    }
    return 0;
  }

  Widget _buildNavLink({
    required String label,
    required int semanticIndex,
    required int selectedIndex,
    required VoidCallback onTap,
    required String keyValue,
  }) {
    final isSelected = selectedIndex == semanticIndex;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      key: Key(keyValue),
      onTap: onTap,
      child: Text(
        label,
        style: textTheme.bodyLarge?.copyWith(
          color: isSelected
              ? dashboardPrimaryTextColor
              : dashboardSecondaryTextColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final selectedIndex = _resolveNavIndex(context);

            final shellScopeData = _buildShellScopeData();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '[ ${OpenSpentInfo.productName.toUpperCase()} ]',
                        style: textTheme.headlineSmall?.copyWith(height: 1),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: dashboardBorderColor),
                        ),
                        child: Text(
                          l10n.localLabel,
                          style: textTheme.titleMedium?.copyWith(
                            color: dashboardStatusColor,
                            height: 1,
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        key: const Key('help-open-button'),
                        onTap: _openHelpDialog,
                        child: const Icon(
                          Icons.info_outline,
                          color: dashboardSecondaryTextColor,
                          size: 24,
                        ),
                      ),
                      if (_hasSettingsRoute) ...[
                        const SizedBox(width: 12),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            key: const Key('settings-open-button'),
                            onTap: _openSettingsDialog,
                            child: const Icon(
                              Icons.settings,
                              color: dashboardSecondaryTextColor,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.heroTitle,
                    style: textTheme.headlineSmall?.copyWith(
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(l10n.heroDescription, style: textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: dashboardSurfaceColor,
                      border: Border.all(color: dashboardBorderColor),
                    ),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _buildNavLink(
                          label: '[ METRICS ]',
                          semanticIndex: 0,
                          selectedIndex: selectedIndex,
                          onTap: () =>
                              context.navigateTo(const DashboardMetricsRoute()),
                          keyValue: 'dashboard-nav-metrics',
                        ),
                        if (_hasSessionsRoute)
                          _buildNavLink(
                            label: '[ SESSIONS ]',
                            semanticIndex: 1,
                            selectedIndex: selectedIndex,
                            onTap: () => context.navigateTo(
                              const DashboardSessionsRoute(),
                            ),
                            keyValue: 'dashboard-nav-sessions',
                          ),
                        if (_hasExchangeRatesRoute)
                          _buildNavLink(
                            label: '[ EXCHANGE ]',
                            semanticIndex: 2,
                            selectedIndex: selectedIndex,
                            onTap: () => context.navigateTo(
                              const DashboardExchangeRatesRoute(),
                            ),
                            keyValue: 'dashboard-nav-exchange-rates',
                          ),
                        _buildNavLink(
                          label: '[ STATE ]',
                          semanticIndex: 3,
                          selectedIndex: selectedIndex,
                          onTap: () =>
                              context.navigateTo(const DashboardStateRoute()),
                          keyValue: 'dashboard-nav-state',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DashboardShellScope(
                    data: shellScopeData,
                    child: const AutoRouter(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

@RoutePage()
class DashboardMetricsScreen extends StatelessWidget {
  const DashboardMetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _DashboardShellScope.of(context).buildMetricsContent(context);
  }
}

@RoutePage()
class DashboardSessionsScreen extends StatelessWidget {
  const DashboardSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _DashboardShellScope.of(context).buildSessionsContent(context);
  }
}

@RoutePage()
class DashboardExchangeRatesScreen extends StatelessWidget {
  const DashboardExchangeRatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _DashboardShellScope.of(context).buildExchangeRatesContent(context);
  }
}

@RoutePage()
class DashboardStateScreen extends StatelessWidget {
  const DashboardStateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _DashboardShellScope.of(context).buildStateContent(context);
  }
}

class _HelpDialogBody extends StatelessWidget {
  const _HelpDialogBody({super.key, required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dashboardBackgroundColor,
        border: Border.all(color: dashboardBorderColor),
      ),
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
    );
  }
}
