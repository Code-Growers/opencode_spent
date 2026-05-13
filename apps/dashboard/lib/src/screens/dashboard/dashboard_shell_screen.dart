import 'dart:async';
import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:openspent_core/openspent_core.dart';

import '../../../l10n/app_localizations.dart';
import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../demo/dashboard_demo.dart';
import '../../screens/exchange_rates/cubit/exchange_rates_cubit.dart';
import '../../screens/exchange_rates/exchange_rates_screen.dart';
import '../../screens/sessions/cubit/sessions_cubit.dart';
import '../../screens/sessions/sessions_screen.dart';
import '../../sessions/import_selection.dart';
import '../metrics/metrics_screen.dart';
import '../metrics/metrics_utils.dart';
import '../settings/settings_screen.dart';
import 'widgets/dashboard_shell_chrome.dart';
import 'widgets/dashboard_shell_dialogs.dart';
import 'widgets/dashboard_state_panel.dart';
import 'widgets/dashboard_surface.dart';

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

  DemoModeController? _demoModeController;

  bool get _isMockDataMode =>
      _demoModeController?.value == DashboardDataMode.mock;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newDemoModeController = DemoModeScope.of(context);
    if (_demoModeController != newDemoModeController) {
      _demoModeController?.removeListener(_onDemoModeChanged);
      _demoModeController = newDemoModeController;
      _demoModeController?.addListener(_onDemoModeChanged);
    }

    if (_didInitializeScopeState) {
      return;
    }

    _didInitializeScopeState = true;
    _loadSettings();
  }

  void _onDemoModeChanged() {
    if (!mounted) {
      return;
    }

    unawaited(_refreshProbeStateForCurrentMode());
    _invalidateMetrics(reloadExchangeRates: true);
    _refreshSessions();
  }

  Future<void> _refreshProbeStateForCurrentMode() async {
    final probeState = await _probeServer(_effectiveSettings);
    if (!mounted) {
      return;
    }

    setState(() {
      _probeState = probeState;
    });
  }

  @override
  void dispose() {
    _demoModeController?.removeListener(_onDemoModeChanged);
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

    final pickedRange = await _showDashboardDialog<DateTimeRange>(
      keyValue: 'custom-range-modal-overlay',
      child: DashboardCustomDateRangeDialog(
        initialDateRange: initialDateRange,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
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
    if (_isMockDataMode) {
      return ServerProbeState.connected;
    }

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
    } on http.ClientException {
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
    await _showDashboardDialog(
      keyValue: 'help-modal-overlay',
      child: const DashboardHelpDialogContent(),
    );
  }

  Future<T?> _showDashboardDialog<T>({
    required String keyValue,
    required Widget child,
  }) {
    return showGeneralDialog<T>(
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
        isConnected:
            _isMockDataMode || _probeState == ServerProbeState.connected,
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
        visibleFrom: _windowFrom,
        visibleTo: _windowTo,
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
    final l10n = AppLocalizations.of(context)!;
    final demoModeController = DemoModeScope.of(context);
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

    return DashboardStatePanel(
      isMockData: _isMockDataMode,
      settingsLoaded: _settingsLoaded,
      serverLabel: serverLabel,
      probeState: _probeState,
      displayProbe: displayProbe,
      demoModeController: demoModeController,
      allowlistCount: OpenSpentInfo.persistedMetadataAllowlist.length,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final selectedIndex = _resolveNavIndex(context);

            final shellScopeData = _buildShellScopeData();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DashboardSpacing.shellGutter,
                    DashboardSpacing.shellGutter,
                    DashboardSpacing.shellGutter,
                    0,
                  ),
                  child: DashboardShellHeader(
                    hasSettingsRoute: _hasSettingsRoute,
                    onHelpPressed: _openHelpDialog,
                    onSettingsPressed: _openSettingsDialog,
                  ),
                ),
                const SizedBox(height: DashboardSpacing.shellGutter),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: DashboardSpacing.shellGutter,
                  ),
                  child: DashboardShellHero(),
                ),
                const SizedBox(height: DashboardSpacing.shellGutter),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DashboardSpacing.shellGutter,
                  ),
                  child: DashboardShellNav(
                    selectedIndex: selectedIndex,
                    hasSessionsRoute: _hasSessionsRoute,
                    hasExchangeRatesRoute: _hasExchangeRatesRoute,
                    onMetricsNav: () =>
                        context.navigateTo(const DashboardMetricsRoute()),
                    onSessionsNav: () =>
                        context.navigateTo(const DashboardSessionsRoute()),
                    onExchangeRatesNav: () =>
                        context.navigateTo(const DashboardExchangeRatesRoute()),
                    onStateNav: () =>
                        context.navigateTo(const DashboardStateRoute()),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DashboardSpacing.shellGutter,
                    ),
                    child: SizedBox(
                      key: const Key('dashboard-shell-route-area'),
                      width: double.infinity,
                      child: _DashboardShellScope(
                        data: shellScopeData,
                        child: const AutoRouter(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: DashboardSpacing.shellGutter,
                  ),
                  child: DashboardShellFooter(),
                ),
                const SizedBox(height: DashboardSpacing.shellGutter),
              ],
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
