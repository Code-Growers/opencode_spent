// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'OpenSpent';

  @override
  String get localLabel => '[ LOCAL ]';

  @override
  String get heroTitle => 'Monitor coding usage. Locally.';

  @override
  String get heroDescription =>
      'A privacy-first local dashboard with cached metrics and terminal-style drilldowns.';

  @override
  String get heroEyebrow => '// LOCAL-FIRST SPEND INTELLIGENCE';

  @override
  String get heroMetricSyncLabel => 'SYNC';

  @override
  String get heroMetricSyncValue => 'REALTIME';

  @override
  String get heroMetricDataLabel => 'DATA';

  @override
  String get heroMetricDataValue => 'LOCAL';

  @override
  String get heroMetricFieldsLabel => 'FIELDS';

  @override
  String get heroMetricFieldsValue => 'ALLOWLISTED';

  @override
  String get statusPaneTitle => 'STATUS';

  @override
  String statusLineReady(String state) {
    return '> Dashboard .......... $state';
  }

  @override
  String statusLineMode(String mode) {
    return '> Mode .............. $mode';
  }

  @override
  String statusLineServer(String server) {
    return '> Server ............ $server';
  }

  @override
  String statusLineProbe(String probe) {
    return '> Probe ............. $probe';
  }

  @override
  String get statusProbeConnected => 'CONNECTED';

  @override
  String get statusProbeDisconnected => 'DISCONNECTED';

  @override
  String get statusProbeError => 'ERROR';

  @override
  String get statusProbeLoading => 'LOADING';

  @override
  String get statusProbeUnknown => 'UNKNOWN';

  @override
  String get statusReady => 'READY';

  @override
  String get statusLoading => 'LOADING';

  @override
  String get statusModeLocalCache => 'LOCAL CACHE';

  @override
  String get statusModeMockSuffix => ' (MOCK)';

  @override
  String get dataModeLabel => 'Data Mode:';

  @override
  String get dataModeReal => 'REAL';

  @override
  String get dataModeMock => 'MOCK';

  @override
  String get statusServerNotConfigured => 'NOT CONFIGURED';

  @override
  String get statusServerLoading => 'LOADING';

  @override
  String get privacyPaneTitle => 'PRIVACY';

  @override
  String get privacyLinePrompts => '> Prompts stored ..... NO';

  @override
  String get privacyLineToolOutput => '> Tool output ........ NO';

  @override
  String get privacyLineErrors => '> Raw errors ......... NO';

  @override
  String persistedAllowlist(int count) {
    return '> Persisted metadata allowlist size: $count';
  }

  @override
  String get metricsTitle => 'Time window';

  @override
  String get shellNavMetrics => 'Overview';

  @override
  String get shellNavSessions => 'Sessions';

  @override
  String get shellNavExchangeRates => 'Exchange rates';

  @override
  String get shellNavState => 'Sources & status';

  @override
  String get metricsLoad => '_ awaiting first metrics payload ...';

  @override
  String get metricsUnavailable => '> metrics unavailable';

  @override
  String get metricsMissingExchangeRatesHelper =>
      '> missing exchange rates for spend days. Sync rates in the exchange panel and retry.';

  @override
  String get textTab => '[ TEXT ]';

  @override
  String get spendTab => '[ SPEND ]';

  @override
  String get tokensTab => '[ TOKENS ]';

  @override
  String get modelsTab => '[ MODELS ]';

  @override
  String get overallSection => '-- OVERALL --';

  @override
  String selectedDaySection(String day) {
    return '-- SELECTED DAY ($day) --';
  }

  @override
  String peakHourSection(String hour) {
    return '-- PEAK HOUR ($hour:00 UTC) --';
  }

  @override
  String get peakHourEmptySection => '-- PEAK HOUR --';

  @override
  String lineTotalCost(String currency, String value) {
    return '> Total cost ......... $currency $value';
  }

  @override
  String lineSessions(int value) {
    return '> Sessions ........... $value';
  }

  @override
  String lineTopMover(
    String model,
    String sign,
    String currency,
    String value,
  ) {
    return '> Top mover .......... $model ($sign$currency$value)';
  }

  @override
  String get lineTopMoverEmpty => '> Top mover .......... NONE';

  @override
  String compareSummary(String sign, String currency, String value) {
    return '> Vs prior ........... $sign$currency $value';
  }

  @override
  String compareSummaryDriver(
    String model,
    String sign,
    String currency,
    String value,
  ) {
    return '> Delta driver ....... $model $sign$currency $value';
  }

  @override
  String get compareSummaryNoDriver => '> Delta driver ....... NONE';

  @override
  String lineInputTokens(String value) {
    return '> Input tokens ....... $value';
  }

  @override
  String lineOutputTokens(String value) {
    return '> Output tokens ...... $value';
  }

  @override
  String lineTotalTokens(String value) {
    return '> Total tokens ....... $value';
  }

  @override
  String lineAvgTokensPerSession(String value) {
    return '> Avg/session ........ $value';
  }

  @override
  String lineCostPerMillionTokens(String currency, String value) {
    return '> Cost/1M tokens ..... $currency $value';
  }

  @override
  String linePeakCost(String currency, String value) {
    return '> Cost ............... $currency $value';
  }

  @override
  String linePeakTokensInOut(String input, String output) {
    return '> Tokens (In/Out) .... $input / $output';
  }

  @override
  String get lineNoActivity => '> No activity recorded';

  @override
  String modelThreeDayTrend(String first, String second, String third) {
    return '3D $first/$second/$third';
  }

  @override
  String modelCostShareTrend(
    String currency,
    String totalCost,
    int share,
    String trend,
  ) {
    return '$currency $totalCost [$share%] • $trend';
  }

  @override
  String modelTokensSessions(String tokens, String sessions) {
    return 'TOK $tokens | SES $sessions';
  }

  @override
  String modelCostPerMillionTokens(String currency, String value) {
    return '$currency $value/1M TOK';
  }

  @override
  String modelCostPerMillionTokensUnavailable(String currency) {
    return '$currency --/1M TOK';
  }

  @override
  String get hourlySpendTitle => 'HOURLY SPEND (UTC)';

  @override
  String get hourlyTokensTitle => 'HOURLY TOKENS IN/OUT (UTC)';

  @override
  String get tokenLegend => 'IN dim | OUT bright';

  @override
  String get spendTrendUnavailable => '> spend trend unavailable';

  @override
  String get tokenTrendUnavailable => '> token trend unavailable';

  @override
  String get modelSpendUnavailable => '> model spend unavailable';

  @override
  String modelTrend(int days, String trend) {
    return '${days}D $trend';
  }

  @override
  String get metricsProvidersTab => '[ PROVIDERS ]';

  @override
  String metricsKpiTotalPrice(String currency, String value) {
    return 'Reported cost · $currency $value';
  }

  @override
  String metricsKpiTotalRequests(String value) {
    return 'Requests · $value';
  }

  @override
  String metricsKpiTotalToolCalls(String value) {
    return 'Tool calls · $value';
  }

  @override
  String metricsKpiAvgResponseTime(String value) {
    return 'Avg. response time · $value';
  }

  @override
  String metricsKpiTotalTokens(String value) {
    return 'Tokens · $value';
  }

  @override
  String get metricsKpiNotAvailable => '--';

  @override
  String metricsKpiPartial(String value) {
    return '$value (partial)';
  }

  @override
  String get providersUsageChartTitle => '-- USAGE PER PROVIDER --';

  @override
  String get providersPriceChartTitle => '-- PRICE PER PROVIDER --';

  @override
  String providersPriceUnavailable(String provider) {
    return '> $provider price unavailable';
  }

  @override
  String helpRemoteLineCors(String origin) {
    return '> When using the dashboard in a browser against a local server, start OpenCode with --cors=\"$origin\" so it allows this browser origin. The value must be origin only — not /demo or any other path.';
  }

  @override
  String get settingsTitle => '[ SETTINGS ]';

  @override
  String get settingsCurrency => 'Currency:';

  @override
  String get settingsLanguage => 'Language:';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageCzech => 'Czech';

  @override
  String get settingsServerUrl => 'Server URL:';

  @override
  String get settingsServerUsername => 'Server username:';

  @override
  String get settingsServerPassword => 'Server password:';

  @override
  String get settingsServerAuthHint =>
      'Optional Basic Auth. If a password is set and the username is blank, OpenSpent uses `opencode`.';

  @override
  String get settingsServerUrlInvalid =>
      'Enter a valid http:// or https:// server URL.';

  @override
  String get settingsSave => '[ SAVE ]';

  @override
  String get settingsClose => '[ CLOSE ]';

  @override
  String get helpDialogTitle => '[ INFO / HELP ]';

  @override
  String get helpTabLocal => 'Local';

  @override
  String get helpTabRemote => 'Remote';

  @override
  String get helpLocalLineImport =>
      '> Import JSON or SQLite files directly into OpenSpent from the sessions panel.';

  @override
  String get helpLocalLinePaths =>
      '> OpenCode usually stores its main DB at ~/.local/share/opencode/opencode.db on macOS/Linux and under %USERPROFILE%\\.local\\share\\opencode\\opencode.db on Windows.';

  @override
  String get helpLocalLineCommandDbPath => '> Useful command: opencode db path';

  @override
  String get helpLocalLineCommandExport =>
      '> Useful commands: opencode export, opencode import';

  @override
  String get helpLocalLineCommandSessionList =>
      '> Useful command: opencode session list';

  @override
  String get helpLocalLineCommandStats => '> Useful command: opencode stats';

  @override
  String get helpLocalLineBackup =>
      '> Back up exported files and local DB copies carefully. Keep the workflow privacy-first and local-first.';

  @override
  String get helpRemoteLineServe =>
      '> Start the API server with: opencode serve';

  @override
  String get helpRemoteLineDefaultUrl =>
      '> Default server URL: http://localhost:4096';

  @override
  String get helpRemoteLineHostUse =>
      '> Use localhost on the same machine. Use a remote host URL only when OpenCode is served from another machine.';

  @override
  String get helpRemoteLineAuthEnv =>
      '> Basic Auth uses OPENCODE_SERVER_USERNAME and OPENCODE_SERVER_PASSWORD.';

  @override
  String get helpRemoteLineAuthDefaultUsername =>
      '> When password protection is enabled and no username is set, the default username is `opencode`.';

  @override
  String get exchangeRatesTitle => '[ EXCHANGE RATES ]';

  @override
  String get exchangeRatesActionSync => '[ SYNC RATES ]';

  @override
  String get exchangeRatesStatusLoading => 'LOADING';

  @override
  String get exchangeRatesStatusError => 'ERROR';

  @override
  String get exchangeRatesStatusReady => 'READY';

  @override
  String exchangeRatesStatusMissing(int count) {
    return 'MISSING $count';
  }

  @override
  String get exchangeRatesMissingDaysNone => 'none';

  @override
  String exchangeRatesCurrencyChanged(String currency) {
    return '> Display currency set to $currency.';
  }

  @override
  String get exchangeRatesCurrencyChangeError =>
      '> Failed to update display currency.';

  @override
  String exchangeRatesSyncSuccess(int count) {
    return '> Synced missing rates for $count spend day(s).';
  }

  @override
  String get exchangeRatesSyncError => '> Exchange-rate sync failed.';

  @override
  String exchangeRatesError(String message) {
    return '> Error ............. $message';
  }

  @override
  String exchangeRatesLineStatus(String value) {
    return '> Status ............ $value';
  }

  @override
  String exchangeRatesLineDisplay(String currency) {
    return '> Display ........... $currency';
  }

  @override
  String exchangeRatesLineSpendDays(int count) {
    return '> Spend days ........ $count';
  }

  @override
  String exchangeRatesLineCoverage(int covered, int total) {
    return '> Coverage .......... $covered/$total';
  }

  @override
  String exchangeRatesLineMissingDays(String days) {
    return '> Missing days ...... $days';
  }

  @override
  String get sessionsSpotlightEmptyScope =>
      '> No ranked evidence in current scope.';

  @override
  String get sessionsSpotlightEmpty => '> Ranked evidence unavailable.';

  @override
  String get sessionsExplorerTitle => '[ SESSIONS EXPLORER ]';

  @override
  String get sessionsExplorerActionSync => '[ SYNC NOW ]';

  @override
  String get sessionsExplorerActionImport => '[ IMPORT DATA ]';

  @override
  String get sessionsExplorerLoading => '> Loading cached sessions...';

  @override
  String get sessionsExplorerEmptyConnected =>
      '> No cached sessions found. Sync or import to begin.';

  @override
  String get sessionsExplorerEmptyDisconnected =>
      '> No cached sessions found. Connect to the local server or import data to begin.';

  @override
  String activeModelFilter(String model) {
    return '> Model filter ...... $model';
  }

  @override
  String activeDayFilter(String day) {
    return '> Day filter ........ $day';
  }

  @override
  String activeHourFilter(String hour) {
    return '> Hour filter ....... $hour:00 UTC';
  }

  @override
  String get clearFilterAction => '[ CLEAR ]';

  @override
  String get sessionsExplorerFilteredEmpty =>
      '> No sessions match the active filters.';

  @override
  String get sessionsExplorerSyncSuccess => '> Sync completed successfully.';

  @override
  String get sessionsExplorerSyncError => '> Sync failed.';

  @override
  String get sessionsExplorerImportSuccess =>
      '> Import completed successfully.';

  @override
  String get sessionsExplorerImportWalModeError =>
      '> Browser import requires a standalone SQLite file. WAL-mode OpenCode databases are not supported for single-file uploads yet.';

  @override
  String get sessionsExplorerImportError =>
      '> Import failed: invalid format or error.';

  @override
  String get sessionsExplorerImportNoFile => '> Import cancelled.';

  @override
  String get sessionsExplorerUnknownModel => 'Unknown model';

  @override
  String sessionsExplorerSubagent(String category) {
    return '> Subagent .......... $category';
  }

  @override
  String get sessionsExplorerError =>
      '> Error ............. operation failed. Check source data or server status.';

  @override
  String sessionRowData(
    String date,
    String model,
    String tokens,
    String currency,
    String cost,
    String id,
  ) {
    return '> $date • $model • $tokens TOK • $currency $cost • ID: $id';
  }

  @override
  String lineVisibleWindow(String window) {
    return '> Window ............. $window';
  }

  @override
  String exchangeRatesLineWindow(String window) {
    return '> Window ............ $window';
  }

  @override
  String get metricsTokensTopDrivers => '-- TOP DRIVERS --';

  @override
  String modelDriverRow(
    String modelName,
    String padding,
    String currency,
    String cost,
    String tokens,
    String sessions,
  ) {
    return '> $modelName $padding $currency $cost | $tokens TOK | $sessions SES';
  }

  @override
  String get metricsModelHourlySpend => '-- HOURLY SPEND --';

  @override
  String get metricsModelHourlyTokens => '-- HOURLY TOKENS --';

  @override
  String modelSelectedDayMetrics(
    String currency,
    String cost,
    String tokens,
    String sessions,
  ) {
    return '> Day ............... $currency $cost | $tokens TOK | $sessions SES';
  }

  @override
  String get windowAll => 'ALL';

  @override
  String get window7d => '7D';

  @override
  String get window30d => '30D';

  @override
  String get window90d => '90D';

  @override
  String get windowCustom => 'CUSTOM';

  @override
  String get windowActionAll => '[ ALL ]';

  @override
  String get windowAction7d => '[ 7D ]';

  @override
  String get windowAction30d => '[ 30D ]';

  @override
  String get windowAction90d => '[ 90D ]';

  @override
  String get windowActionCustom => '[ CUSTOM ]';

  @override
  String get customRangeSelectStart => 'Select Start';

  @override
  String get customRangeSelectEnd => 'Select End';

  @override
  String get sessionsExplorerCachedHistoryTitle => '-- CACHED HISTORY --';

  @override
  String sessionsExplorerCachedCount(int count) {
    return '> Sessions .......... $count';
  }

  @override
  String sessionsExplorerCachedNewest(String date) {
    return '> Newest ............ $date';
  }

  @override
  String sessionsExplorerCachedOldest(String date) {
    return '> Oldest ............ $date';
  }

  @override
  String get sessionsExplorerCachedEmpty => '> Cache is empty';

  @override
  String get sessionsExplorerLastOpTitle => '-- LAST OPERATION --';

  @override
  String sessionsExplorerLastOpType(String type) {
    return '> Type .............. $type';
  }

  @override
  String sessionsExplorerLastOpStatus(String status) {
    return '> Status ............ $status';
  }

  @override
  String sessionsExplorerLastOpSource(String source) {
    return '> Source ............ $source';
  }

  @override
  String sessionsExplorerLastOpCount(int count) {
    return '> Cached ............ $count';
  }

  @override
  String get sessionsExplorerLastOpNone => '> No recent operations';

  @override
  String get opTypeLoad => 'LOAD';

  @override
  String get opTypeSync => 'SYNC';

  @override
  String get opTypeImportJson => 'IMPORT JSON';

  @override
  String get opTypeImportSqlite => 'IMPORT SQLITE';

  @override
  String get opStatusSuccess => 'SUCCESS';

  @override
  String get opStatusFailure => 'FAILURE';

  @override
  String lineRollingAvgCost(String currency, String value) {
    return '> Rolling avg cost ... $currency $value/day';
  }

  @override
  String lineRollingAvgTokens(String value) {
    return '> Rolling avg tokens . $value/day';
  }

  @override
  String linePaceForecast(String currency, String value) {
    return '> Pace (7d forecast) . $currency $value';
  }

  @override
  String spendDailyAvgLabel(String currency, String amount) {
    return 'AVG $currency $amount';
  }

  @override
  String spendDailyPeakLabel(String currency, String amount) {
    return 'PEAK $currency $amount';
  }

  @override
  String spendHourlyAvgLabel(String currency, String amount) {
    return 'AVG $currency $amount';
  }

  @override
  String spendHourlyPeakLabel(String currency, String amount) {
    return 'PEAK $currency $amount';
  }

  @override
  String comparePriorWindow(String window) {
    return '> Prior window ....... $window';
  }

  @override
  String compareDeltaSessions(String sign, int value) {
    return '> Delta sessions ..... $sign$value';
  }

  @override
  String compareDeltaTokens(String sign, int value) {
    return '> Delta tokens ....... $sign$value';
  }

  @override
  String compareSplitSessions(String sign, String currency, String value) {
    return '> Split sessions ..... $sign$currency $value';
  }

  @override
  String compareSplitAvg(String sign, String currency, String value) {
    return '> Split avg/session .. $sign$currency $value';
  }

  @override
  String compareSplitCost(String sign, String currency, String value) {
    return '> Split cost/1M ...... $sign$currency $value';
  }

  @override
  String get compareSplitUnavailable => '> Split breakdown .... math undefined';

  @override
  String get compareUnavailableHelper =>
      '> Prior-window compare unavailable due to missing exchange rates.';

  @override
  String exchangeRatesHistoryTitle(String currency) {
    return 'Exchange Rate History ($currency → CZK)';
  }

  @override
  String get sessionsSearchPlaceholder => 'Search metadata...';

  @override
  String get sessionsSearchClear => '[ CLEAR ]';

  @override
  String sessionsSearchResultsCount(int count) {
    return '> Results ........... $count';
  }

  @override
  String get sessionsListHeader => '-- SESSION LOG --';

  @override
  String pieLegendOverflow(int count) {
    return '+$count more';
  }

  @override
  String get metricsOverviewSessionsPerDay => '-- SESSIONS / DAY --';

  @override
  String get metricsOverviewAvgCostPerSession => '-- AVG COST / SESSION --';

  @override
  String get metricsOverviewAvgTokensPerSession => '-- AVG TOKENS / SESSION --';

  @override
  String shellFooterDevelopedBy(String company) {
    return 'Developed by $company';
  }

  @override
  String shellFooterBuildVersion(String version) {
    return 'Build $version';
  }

  @override
  String get axisLabelDate => 'Date';

  @override
  String get axisLabelSessions => 'Sessions';

  @override
  String get axisLabelAvgCost => 'Avg Cost';

  @override
  String get axisLabelAvgTokens => 'Avg Tokens';

  @override
  String get metricsActivity => 'ACTIVITY';

  @override
  String get metricsActiveDays => 'ACTIVE DAYS';

  @override
  String get metricsCurrentStreak => 'CURRENT STREAK';

  @override
  String get metricsLongestStreak => 'LONGEST STREAK';

  @override
  String get metricsPeakDay => 'PEAK DAY';

  @override
  String metricsPeakDayDetail(int count) {
    return '$count sessions';
  }

  @override
  String metricsDayCountCompact(int count) {
    return '${count}d';
  }

  @override
  String get metricsHeatmapLegendLow => 'Low';

  @override
  String get metricsHeatmapLegendHigh => 'High';

  @override
  String metricsHeatmapCellLabel(String day, int sessions, String tokens) {
    return '$day: $sessions sessions, $tokens tokens';
  }

  @override
  String metricsHeatmapCellTooltip(String day, int sessions, String tokens) {
    return '$day\n$sessions sessions • $tokens tokens';
  }

  @override
  String get usageSourcesTitle => 'Local usage sources';

  @override
  String get usageConnect => 'Connect';

  @override
  String get usageRefresh => 'Refresh';

  @override
  String get usageDisconnect => 'Disconnect';

  @override
  String get usageConnected => 'Connected';

  @override
  String get usageNotConnected => 'Not connected';

  @override
  String get usageChooseFolder => 'Choose folder';

  @override
  String get usageSourceError =>
      'Could not read this source. Previously imported usage is retained.';

  @override
  String usageSourceResult(int sessions, int skipped, int failed) {
    return '$sessions sessions · $skipped skipped records · $failed unreadable files';
  }

  @override
  String usageLastRefresh(String time) {
    return 'Last refresh: $time';
  }

  @override
  String get usageNeverRefreshed => 'Not refreshed yet';

  @override
  String get usageSourcesBrowser =>
      'Local source connections are available in the desktop app.';

  @override
  String get usagePricingTitle => 'API estimate pricing';

  @override
  String get usagePricingHelp =>
      'Standard API token rates, USD per million tokens. Subscription fees, taxes, tools and fast-mode premiums are excluded.';

  @override
  String usagePricingSnapshot(String version) {
    return 'Published rate snapshot: $version';
  }

  @override
  String get usagePricingModel => 'Usage model';

  @override
  String get usagePricingMapping => 'Use published model rates';

  @override
  String get usagePricingCustom => 'Custom rates';

  @override
  String get usagePricingReset => 'Reset to published rates';

  @override
  String get usagePricingSave => 'Save rates';

  @override
  String get usagePricingInvalid =>
      'Enter finite, nonnegative rates. Input and output rates are required.';

  @override
  String get usageInput => 'Input';

  @override
  String get usageOutput => 'Output';

  @override
  String get usageCacheRead => 'Cache reads';

  @override
  String get usageCacheWrite => 'Cache writes';

  @override
  String get usageCacheWrite1h => 'Cache writes (1 hour)';

  @override
  String get usageReasoning => 'Reasoning (included in output)';

  @override
  String get usageHarnessAll => 'All harnesses';

  @override
  String get usageComparisonTitle => 'Usage by harness';

  @override
  String get usageApiEstimate => 'Estimated API cost';

  @override
  String get usageReportedCost => 'Reported cost';

  @override
  String get usageUnknown => 'Unavailable';

  @override
  String usagePricingCoverage(int priced, int total) {
    return '$priced of $total usage records priced';
  }

  @override
  String get usageCustomPrice => 'Custom pricing';

  @override
  String get usageApproximate =>
      'Approximate: uses short-context or 5-minute cache-write rates where metadata is unavailable.';

  @override
  String get usageTokensHelp =>
      'Input includes cache reads and writes across all requests, including repeated conversation context. Reasoning is included in output. Hover over token totals for exact counts.';

  @override
  String get usagePartial => 'Partial';

  @override
  String get usageNoMapping => 'Keep original model';

  @override
  String get usagePricingNoModels => 'Import usage to configure model prices.';

  @override
  String get usagePricingPublished => 'Published rates';

  @override
  String get usageSourcesHelp =>
      'Connect once to load local token metadata. Refresh on launch or on demand; disconnect keeps imported history.';

  @override
  String get usagePricingRatesHelp =>
      'Blank cache rates leave events using that category unpriced. A zero rate is an explicit free category.';

  @override
  String get usageSourceBusy => 'Refreshing local usage…';

  @override
  String get overviewPurpose => 'Your spending, usage and models in one place.';

  @override
  String get sessionsPurpose =>
      'Find a session. Compare usage. Trace the cost.';

  @override
  String get exchangePurpose =>
      'Manage the rates used to convert your spending.';

  @override
  String get sourcesPurpose => 'Check your local data, connection and privacy.';

  @override
  String get mockDataNotice => 'Sample data · switch to Real to see your usage';

  @override
  String get realDataNotice => 'Local data';

  @override
  String sessionsPage(int page, int pages) {
    return 'Page $page of $pages';
  }

  @override
  String get previousPage => 'Previous page';

  @override
  String get nextPage => 'Next page';

  @override
  String get mockDataLabel => 'Sample data';

  @override
  String get sessionsSortLatest => 'Latest';

  @override
  String get sessionsSortCost => 'Reported cost';

  @override
  String get sessionsSortTokens => 'Tokens';

  @override
  String get clearScopeFilters => 'Clear filters';
}
