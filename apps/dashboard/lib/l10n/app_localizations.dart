import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_cs.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('cs'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'OpenSpent'**
  String get appTitle;

  /// No description provided for @localLabel.
  ///
  /// In en, this message translates to:
  /// **'[ LOCAL ]'**
  String get localLabel;

  /// No description provided for @heroTitle.
  ///
  /// In en, this message translates to:
  /// **'Monitor coding usage. Locally.'**
  String get heroTitle;

  /// No description provided for @heroDescription.
  ///
  /// In en, this message translates to:
  /// **'A privacy-first local dashboard with cached metrics and terminal-style drilldowns.'**
  String get heroDescription;

  /// No description provided for @heroEyebrow.
  ///
  /// In en, this message translates to:
  /// **'// LOCAL-FIRST SPEND INTELLIGENCE'**
  String get heroEyebrow;

  /// No description provided for @heroMetricSyncLabel.
  ///
  /// In en, this message translates to:
  /// **'SYNC'**
  String get heroMetricSyncLabel;

  /// No description provided for @heroMetricSyncValue.
  ///
  /// In en, this message translates to:
  /// **'REALTIME'**
  String get heroMetricSyncValue;

  /// No description provided for @heroMetricDataLabel.
  ///
  /// In en, this message translates to:
  /// **'DATA'**
  String get heroMetricDataLabel;

  /// No description provided for @heroMetricDataValue.
  ///
  /// In en, this message translates to:
  /// **'LOCAL'**
  String get heroMetricDataValue;

  /// No description provided for @heroMetricFieldsLabel.
  ///
  /// In en, this message translates to:
  /// **'FIELDS'**
  String get heroMetricFieldsLabel;

  /// No description provided for @heroMetricFieldsValue.
  ///
  /// In en, this message translates to:
  /// **'ALLOWLISTED'**
  String get heroMetricFieldsValue;

  /// No description provided for @statusPaneTitle.
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get statusPaneTitle;

  /// No description provided for @statusLineReady.
  ///
  /// In en, this message translates to:
  /// **'> Dashboard .......... {state}'**
  String statusLineReady(String state);

  /// No description provided for @statusLineMode.
  ///
  /// In en, this message translates to:
  /// **'> Mode .............. {mode}'**
  String statusLineMode(String mode);

  /// No description provided for @statusLineServer.
  ///
  /// In en, this message translates to:
  /// **'> Server ............ {server}'**
  String statusLineServer(String server);

  /// No description provided for @statusLineProbe.
  ///
  /// In en, this message translates to:
  /// **'> Probe ............. {probe}'**
  String statusLineProbe(String probe);

  /// No description provided for @statusProbeConnected.
  ///
  /// In en, this message translates to:
  /// **'CONNECTED'**
  String get statusProbeConnected;

  /// No description provided for @statusProbeDisconnected.
  ///
  /// In en, this message translates to:
  /// **'DISCONNECTED'**
  String get statusProbeDisconnected;

  /// No description provided for @statusProbeError.
  ///
  /// In en, this message translates to:
  /// **'ERROR'**
  String get statusProbeError;

  /// No description provided for @statusProbeLoading.
  ///
  /// In en, this message translates to:
  /// **'LOADING'**
  String get statusProbeLoading;

  /// No description provided for @statusProbeUnknown.
  ///
  /// In en, this message translates to:
  /// **'UNKNOWN'**
  String get statusProbeUnknown;

  /// No description provided for @statusReady.
  ///
  /// In en, this message translates to:
  /// **'READY'**
  String get statusReady;

  /// No description provided for @statusLoading.
  ///
  /// In en, this message translates to:
  /// **'LOADING'**
  String get statusLoading;

  /// No description provided for @statusModeLocalCache.
  ///
  /// In en, this message translates to:
  /// **'LOCAL CACHE'**
  String get statusModeLocalCache;

  /// No description provided for @statusModeMockSuffix.
  ///
  /// In en, this message translates to:
  /// **' (MOCK)'**
  String get statusModeMockSuffix;

  /// No description provided for @dataModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Data Mode:'**
  String get dataModeLabel;

  /// No description provided for @dataModeReal.
  ///
  /// In en, this message translates to:
  /// **'REAL'**
  String get dataModeReal;

  /// No description provided for @dataModeMock.
  ///
  /// In en, this message translates to:
  /// **'MOCK'**
  String get dataModeMock;

  /// No description provided for @statusServerNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'NOT CONFIGURED'**
  String get statusServerNotConfigured;

  /// No description provided for @statusServerLoading.
  ///
  /// In en, this message translates to:
  /// **'LOADING'**
  String get statusServerLoading;

  /// No description provided for @privacyPaneTitle.
  ///
  /// In en, this message translates to:
  /// **'PRIVACY'**
  String get privacyPaneTitle;

  /// No description provided for @privacyLinePrompts.
  ///
  /// In en, this message translates to:
  /// **'> Prompts stored ..... NO'**
  String get privacyLinePrompts;

  /// No description provided for @privacyLineToolOutput.
  ///
  /// In en, this message translates to:
  /// **'> Tool output ........ NO'**
  String get privacyLineToolOutput;

  /// No description provided for @privacyLineErrors.
  ///
  /// In en, this message translates to:
  /// **'> Raw errors ......... NO'**
  String get privacyLineErrors;

  /// No description provided for @persistedAllowlist.
  ///
  /// In en, this message translates to:
  /// **'> Persisted metadata allowlist size: {count}'**
  String persistedAllowlist(int count);

  /// No description provided for @metricsTitle.
  ///
  /// In en, this message translates to:
  /// **'Time window'**
  String get metricsTitle;

  /// No description provided for @shellNavMetrics.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get shellNavMetrics;

  /// No description provided for @shellNavSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get shellNavSessions;

  /// No description provided for @shellNavExchangeRates.
  ///
  /// In en, this message translates to:
  /// **'Exchange rates'**
  String get shellNavExchangeRates;

  /// No description provided for @shellNavState.
  ///
  /// In en, this message translates to:
  /// **'Sources & status'**
  String get shellNavState;

  /// No description provided for @metricsLoad.
  ///
  /// In en, this message translates to:
  /// **'_ awaiting first metrics payload ...'**
  String get metricsLoad;

  /// No description provided for @metricsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'> metrics unavailable'**
  String get metricsUnavailable;

  /// No description provided for @metricsMissingExchangeRatesHelper.
  ///
  /// In en, this message translates to:
  /// **'> missing exchange rates for spend days. Sync rates in the exchange panel and retry.'**
  String get metricsMissingExchangeRatesHelper;

  /// No description provided for @textTab.
  ///
  /// In en, this message translates to:
  /// **'[ TEXT ]'**
  String get textTab;

  /// No description provided for @spendTab.
  ///
  /// In en, this message translates to:
  /// **'[ SPEND ]'**
  String get spendTab;

  /// No description provided for @tokensTab.
  ///
  /// In en, this message translates to:
  /// **'[ TOKENS ]'**
  String get tokensTab;

  /// No description provided for @modelsTab.
  ///
  /// In en, this message translates to:
  /// **'[ MODELS ]'**
  String get modelsTab;

  /// No description provided for @overallSection.
  ///
  /// In en, this message translates to:
  /// **'-- OVERALL --'**
  String get overallSection;

  /// No description provided for @selectedDaySection.
  ///
  /// In en, this message translates to:
  /// **'-- SELECTED DAY ({day}) --'**
  String selectedDaySection(String day);

  /// No description provided for @peakHourSection.
  ///
  /// In en, this message translates to:
  /// **'-- PEAK HOUR ({hour}:00 UTC) --'**
  String peakHourSection(String hour);

  /// No description provided for @peakHourEmptySection.
  ///
  /// In en, this message translates to:
  /// **'-- PEAK HOUR --'**
  String get peakHourEmptySection;

  /// No description provided for @lineTotalCost.
  ///
  /// In en, this message translates to:
  /// **'> Total cost ......... {currency} {value}'**
  String lineTotalCost(String currency, String value);

  /// No description provided for @lineSessions.
  ///
  /// In en, this message translates to:
  /// **'> Sessions ........... {value}'**
  String lineSessions(int value);

  /// No description provided for @lineTopMover.
  ///
  /// In en, this message translates to:
  /// **'> Top mover .......... {model} ({sign}{currency}{value})'**
  String lineTopMover(String model, String sign, String currency, String value);

  /// No description provided for @lineTopMoverEmpty.
  ///
  /// In en, this message translates to:
  /// **'> Top mover .......... NONE'**
  String get lineTopMoverEmpty;

  /// No description provided for @compareSummary.
  ///
  /// In en, this message translates to:
  /// **'> Vs prior ........... {sign}{currency} {value}'**
  String compareSummary(String sign, String currency, String value);

  /// No description provided for @compareSummaryDriver.
  ///
  /// In en, this message translates to:
  /// **'> Delta driver ....... {model} {sign}{currency} {value}'**
  String compareSummaryDriver(
    String model,
    String sign,
    String currency,
    String value,
  );

  /// No description provided for @compareSummaryNoDriver.
  ///
  /// In en, this message translates to:
  /// **'> Delta driver ....... NONE'**
  String get compareSummaryNoDriver;

  /// No description provided for @lineInputTokens.
  ///
  /// In en, this message translates to:
  /// **'> Input tokens ....... {value}'**
  String lineInputTokens(String value);

  /// No description provided for @lineOutputTokens.
  ///
  /// In en, this message translates to:
  /// **'> Output tokens ...... {value}'**
  String lineOutputTokens(String value);

  /// No description provided for @lineTotalTokens.
  ///
  /// In en, this message translates to:
  /// **'> Total tokens ....... {value}'**
  String lineTotalTokens(String value);

  /// No description provided for @lineAvgTokensPerSession.
  ///
  /// In en, this message translates to:
  /// **'> Avg/session ........ {value}'**
  String lineAvgTokensPerSession(String value);

  /// No description provided for @lineCostPerMillionTokens.
  ///
  /// In en, this message translates to:
  /// **'> Cost/1M tokens ..... {currency} {value}'**
  String lineCostPerMillionTokens(String currency, String value);

  /// No description provided for @linePeakCost.
  ///
  /// In en, this message translates to:
  /// **'> Cost ............... {currency} {value}'**
  String linePeakCost(String currency, String value);

  /// No description provided for @linePeakTokensInOut.
  ///
  /// In en, this message translates to:
  /// **'> Tokens (In/Out) .... {input} / {output}'**
  String linePeakTokensInOut(String input, String output);

  /// No description provided for @lineNoActivity.
  ///
  /// In en, this message translates to:
  /// **'> No activity recorded'**
  String get lineNoActivity;

  /// No description provided for @modelThreeDayTrend.
  ///
  /// In en, this message translates to:
  /// **'3D {first}/{second}/{third}'**
  String modelThreeDayTrend(String first, String second, String third);

  /// No description provided for @modelCostShareTrend.
  ///
  /// In en, this message translates to:
  /// **'{currency} {totalCost} [{share}%] • {trend}'**
  String modelCostShareTrend(
    String currency,
    String totalCost,
    int share,
    String trend,
  );

  /// No description provided for @modelTokensSessions.
  ///
  /// In en, this message translates to:
  /// **'TOK {tokens} | SES {sessions}'**
  String modelTokensSessions(String tokens, String sessions);

  /// No description provided for @modelCostPerMillionTokens.
  ///
  /// In en, this message translates to:
  /// **'{currency} {value}/1M TOK'**
  String modelCostPerMillionTokens(String currency, String value);

  /// No description provided for @modelCostPerMillionTokensUnavailable.
  ///
  /// In en, this message translates to:
  /// **'{currency} --/1M TOK'**
  String modelCostPerMillionTokensUnavailable(String currency);

  /// No description provided for @hourlySpendTitle.
  ///
  /// In en, this message translates to:
  /// **'HOURLY SPEND (UTC)'**
  String get hourlySpendTitle;

  /// No description provided for @hourlyTokensTitle.
  ///
  /// In en, this message translates to:
  /// **'HOURLY TOKENS IN/OUT (UTC)'**
  String get hourlyTokensTitle;

  /// No description provided for @tokenLegend.
  ///
  /// In en, this message translates to:
  /// **'IN dim | OUT bright'**
  String get tokenLegend;

  /// No description provided for @spendTrendUnavailable.
  ///
  /// In en, this message translates to:
  /// **'> spend trend unavailable'**
  String get spendTrendUnavailable;

  /// No description provided for @tokenTrendUnavailable.
  ///
  /// In en, this message translates to:
  /// **'> token trend unavailable'**
  String get tokenTrendUnavailable;

  /// No description provided for @modelSpendUnavailable.
  ///
  /// In en, this message translates to:
  /// **'> model spend unavailable'**
  String get modelSpendUnavailable;

  /// No description provided for @modelTrend.
  ///
  /// In en, this message translates to:
  /// **'{days}D {trend}'**
  String modelTrend(int days, String trend);

  /// No description provided for @metricsProvidersTab.
  ///
  /// In en, this message translates to:
  /// **'[ PROVIDERS ]'**
  String get metricsProvidersTab;

  /// No description provided for @metricsKpiTotalPrice.
  ///
  /// In en, this message translates to:
  /// **'Reported cost · {currency} {value}'**
  String metricsKpiTotalPrice(String currency, String value);

  /// No description provided for @metricsKpiTotalRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests · {value}'**
  String metricsKpiTotalRequests(String value);

  /// No description provided for @metricsKpiTotalToolCalls.
  ///
  /// In en, this message translates to:
  /// **'Tool calls · {value}'**
  String metricsKpiTotalToolCalls(String value);

  /// No description provided for @metricsKpiAvgResponseTime.
  ///
  /// In en, this message translates to:
  /// **'Avg. response time · {value}'**
  String metricsKpiAvgResponseTime(String value);

  /// No description provided for @metricsKpiTotalTokens.
  ///
  /// In en, this message translates to:
  /// **'Tokens · {value}'**
  String metricsKpiTotalTokens(String value);

  /// No description provided for @metricsKpiNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'--'**
  String get metricsKpiNotAvailable;

  /// No description provided for @metricsKpiPartial.
  ///
  /// In en, this message translates to:
  /// **'{value} (partial)'**
  String metricsKpiPartial(String value);

  /// No description provided for @providersUsageChartTitle.
  ///
  /// In en, this message translates to:
  /// **'-- USAGE PER PROVIDER --'**
  String get providersUsageChartTitle;

  /// No description provided for @providersPriceChartTitle.
  ///
  /// In en, this message translates to:
  /// **'-- PRICE PER PROVIDER --'**
  String get providersPriceChartTitle;

  /// No description provided for @providersPriceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'> {provider} price unavailable'**
  String providersPriceUnavailable(String provider);

  /// No description provided for @helpRemoteLineCors.
  ///
  /// In en, this message translates to:
  /// **'> When using the dashboard in a browser against a local server, start OpenCode with --cors=\"{origin}\" so it allows this browser origin. The value must be origin only — not /demo or any other path.'**
  String helpRemoteLineCors(String origin);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'[ SETTINGS ]'**
  String get settingsTitle;

  /// No description provided for @settingsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency:'**
  String get settingsCurrency;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language:'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageCzech.
  ///
  /// In en, this message translates to:
  /// **'Czech'**
  String get settingsLanguageCzech;

  /// No description provided for @settingsServerUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL:'**
  String get settingsServerUrl;

  /// No description provided for @settingsServerUsername.
  ///
  /// In en, this message translates to:
  /// **'Server username:'**
  String get settingsServerUsername;

  /// No description provided for @settingsServerPassword.
  ///
  /// In en, this message translates to:
  /// **'Server password:'**
  String get settingsServerPassword;

  /// No description provided for @settingsServerAuthHint.
  ///
  /// In en, this message translates to:
  /// **'Optional Basic Auth. If a password is set and the username is blank, OpenSpent uses `opencode`.'**
  String get settingsServerAuthHint;

  /// No description provided for @settingsServerUrlInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid http:// or https:// server URL.'**
  String get settingsServerUrlInvalid;

  /// No description provided for @settingsSave.
  ///
  /// In en, this message translates to:
  /// **'[ SAVE ]'**
  String get settingsSave;

  /// No description provided for @settingsClose.
  ///
  /// In en, this message translates to:
  /// **'[ CLOSE ]'**
  String get settingsClose;

  /// No description provided for @helpDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'[ INFO / HELP ]'**
  String get helpDialogTitle;

  /// No description provided for @helpTabLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get helpTabLocal;

  /// No description provided for @helpTabRemote.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get helpTabRemote;

  /// No description provided for @helpLocalLineImport.
  ///
  /// In en, this message translates to:
  /// **'> Import JSON or SQLite files directly into OpenSpent from the sessions panel.'**
  String get helpLocalLineImport;

  /// No description provided for @helpLocalLinePaths.
  ///
  /// In en, this message translates to:
  /// **'> OpenCode usually stores its main DB at ~/.local/share/opencode/opencode.db on macOS/Linux and under %USERPROFILE%\\.local\\share\\opencode\\opencode.db on Windows.'**
  String get helpLocalLinePaths;

  /// No description provided for @helpLocalLineCommandDbPath.
  ///
  /// In en, this message translates to:
  /// **'> Useful command: opencode db path'**
  String get helpLocalLineCommandDbPath;

  /// No description provided for @helpLocalLineCommandExport.
  ///
  /// In en, this message translates to:
  /// **'> Useful commands: opencode export, opencode import'**
  String get helpLocalLineCommandExport;

  /// No description provided for @helpLocalLineCommandSessionList.
  ///
  /// In en, this message translates to:
  /// **'> Useful command: opencode session list'**
  String get helpLocalLineCommandSessionList;

  /// No description provided for @helpLocalLineCommandStats.
  ///
  /// In en, this message translates to:
  /// **'> Useful command: opencode stats'**
  String get helpLocalLineCommandStats;

  /// No description provided for @helpLocalLineBackup.
  ///
  /// In en, this message translates to:
  /// **'> Back up exported files and local DB copies carefully. Keep the workflow privacy-first and local-first.'**
  String get helpLocalLineBackup;

  /// No description provided for @helpRemoteLineServe.
  ///
  /// In en, this message translates to:
  /// **'> Start the API server with: opencode serve'**
  String get helpRemoteLineServe;

  /// No description provided for @helpRemoteLineDefaultUrl.
  ///
  /// In en, this message translates to:
  /// **'> Default server URL: http://localhost:4096'**
  String get helpRemoteLineDefaultUrl;

  /// No description provided for @helpRemoteLineHostUse.
  ///
  /// In en, this message translates to:
  /// **'> Use localhost on the same machine. Use a remote host URL only when OpenCode is served from another machine.'**
  String get helpRemoteLineHostUse;

  /// No description provided for @helpRemoteLineAuthEnv.
  ///
  /// In en, this message translates to:
  /// **'> Basic Auth uses OPENCODE_SERVER_USERNAME and OPENCODE_SERVER_PASSWORD.'**
  String get helpRemoteLineAuthEnv;

  /// No description provided for @helpRemoteLineAuthDefaultUsername.
  ///
  /// In en, this message translates to:
  /// **'> When password protection is enabled and no username is set, the default username is `opencode`.'**
  String get helpRemoteLineAuthDefaultUsername;

  /// No description provided for @exchangeRatesTitle.
  ///
  /// In en, this message translates to:
  /// **'[ EXCHANGE RATES ]'**
  String get exchangeRatesTitle;

  /// No description provided for @exchangeRatesActionSync.
  ///
  /// In en, this message translates to:
  /// **'[ SYNC RATES ]'**
  String get exchangeRatesActionSync;

  /// No description provided for @exchangeRatesStatusLoading.
  ///
  /// In en, this message translates to:
  /// **'LOADING'**
  String get exchangeRatesStatusLoading;

  /// No description provided for @exchangeRatesStatusError.
  ///
  /// In en, this message translates to:
  /// **'ERROR'**
  String get exchangeRatesStatusError;

  /// No description provided for @exchangeRatesStatusReady.
  ///
  /// In en, this message translates to:
  /// **'READY'**
  String get exchangeRatesStatusReady;

  /// No description provided for @exchangeRatesStatusMissing.
  ///
  /// In en, this message translates to:
  /// **'MISSING {count}'**
  String exchangeRatesStatusMissing(int count);

  /// No description provided for @exchangeRatesMissingDaysNone.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get exchangeRatesMissingDaysNone;

  /// No description provided for @exchangeRatesCurrencyChanged.
  ///
  /// In en, this message translates to:
  /// **'> Display currency set to {currency}.'**
  String exchangeRatesCurrencyChanged(String currency);

  /// No description provided for @exchangeRatesCurrencyChangeError.
  ///
  /// In en, this message translates to:
  /// **'> Failed to update display currency.'**
  String get exchangeRatesCurrencyChangeError;

  /// No description provided for @exchangeRatesSyncSuccess.
  ///
  /// In en, this message translates to:
  /// **'> Synced missing rates for {count} spend day(s).'**
  String exchangeRatesSyncSuccess(int count);

  /// No description provided for @exchangeRatesSyncError.
  ///
  /// In en, this message translates to:
  /// **'> Exchange-rate sync failed.'**
  String get exchangeRatesSyncError;

  /// No description provided for @exchangeRatesError.
  ///
  /// In en, this message translates to:
  /// **'> Error ............. {message}'**
  String exchangeRatesError(String message);

  /// No description provided for @exchangeRatesLineStatus.
  ///
  /// In en, this message translates to:
  /// **'> Status ............ {value}'**
  String exchangeRatesLineStatus(String value);

  /// No description provided for @exchangeRatesLineDisplay.
  ///
  /// In en, this message translates to:
  /// **'> Display ........... {currency}'**
  String exchangeRatesLineDisplay(String currency);

  /// No description provided for @exchangeRatesLineSpendDays.
  ///
  /// In en, this message translates to:
  /// **'> Spend days ........ {count}'**
  String exchangeRatesLineSpendDays(int count);

  /// No description provided for @exchangeRatesLineCoverage.
  ///
  /// In en, this message translates to:
  /// **'> Coverage .......... {covered}/{total}'**
  String exchangeRatesLineCoverage(int covered, int total);

  /// No description provided for @exchangeRatesLineMissingDays.
  ///
  /// In en, this message translates to:
  /// **'> Missing days ...... {days}'**
  String exchangeRatesLineMissingDays(String days);

  /// No description provided for @sessionsSpotlightEmptyScope.
  ///
  /// In en, this message translates to:
  /// **'> No ranked evidence in current scope.'**
  String get sessionsSpotlightEmptyScope;

  /// No description provided for @sessionsSpotlightEmpty.
  ///
  /// In en, this message translates to:
  /// **'> Ranked evidence unavailable.'**
  String get sessionsSpotlightEmpty;

  /// No description provided for @sessionsExplorerTitle.
  ///
  /// In en, this message translates to:
  /// **'[ SESSIONS EXPLORER ]'**
  String get sessionsExplorerTitle;

  /// No description provided for @sessionsExplorerActionSync.
  ///
  /// In en, this message translates to:
  /// **'[ SYNC NOW ]'**
  String get sessionsExplorerActionSync;

  /// No description provided for @sessionsExplorerActionImport.
  ///
  /// In en, this message translates to:
  /// **'[ IMPORT DATA ]'**
  String get sessionsExplorerActionImport;

  /// No description provided for @sessionsExplorerLoading.
  ///
  /// In en, this message translates to:
  /// **'> Loading cached sessions...'**
  String get sessionsExplorerLoading;

  /// No description provided for @sessionsExplorerEmptyConnected.
  ///
  /// In en, this message translates to:
  /// **'> No cached sessions found. Sync or import to begin.'**
  String get sessionsExplorerEmptyConnected;

  /// No description provided for @sessionsExplorerEmptyDisconnected.
  ///
  /// In en, this message translates to:
  /// **'> No cached sessions found. Connect to the local server or import data to begin.'**
  String get sessionsExplorerEmptyDisconnected;

  /// No description provided for @activeModelFilter.
  ///
  /// In en, this message translates to:
  /// **'> Model filter ...... {model}'**
  String activeModelFilter(String model);

  /// No description provided for @activeDayFilter.
  ///
  /// In en, this message translates to:
  /// **'> Day filter ........ {day}'**
  String activeDayFilter(String day);

  /// No description provided for @activeHourFilter.
  ///
  /// In en, this message translates to:
  /// **'> Hour filter ....... {hour}:00 UTC'**
  String activeHourFilter(String hour);

  /// No description provided for @clearFilterAction.
  ///
  /// In en, this message translates to:
  /// **'[ CLEAR ]'**
  String get clearFilterAction;

  /// No description provided for @sessionsExplorerFilteredEmpty.
  ///
  /// In en, this message translates to:
  /// **'> No sessions match the active filters.'**
  String get sessionsExplorerFilteredEmpty;

  /// No description provided for @sessionsExplorerSyncSuccess.
  ///
  /// In en, this message translates to:
  /// **'> Sync completed successfully.'**
  String get sessionsExplorerSyncSuccess;

  /// No description provided for @sessionsExplorerSyncError.
  ///
  /// In en, this message translates to:
  /// **'> Sync failed.'**
  String get sessionsExplorerSyncError;

  /// No description provided for @sessionsExplorerImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'> Import completed successfully.'**
  String get sessionsExplorerImportSuccess;

  /// No description provided for @sessionsExplorerImportWalModeError.
  ///
  /// In en, this message translates to:
  /// **'> Browser import requires a standalone SQLite file. WAL-mode OpenCode databases are not supported for single-file uploads yet.'**
  String get sessionsExplorerImportWalModeError;

  /// No description provided for @sessionsExplorerImportError.
  ///
  /// In en, this message translates to:
  /// **'> Import failed: invalid format or error.'**
  String get sessionsExplorerImportError;

  /// No description provided for @sessionsExplorerImportNoFile.
  ///
  /// In en, this message translates to:
  /// **'> Import cancelled.'**
  String get sessionsExplorerImportNoFile;

  /// No description provided for @sessionsExplorerUnknownModel.
  ///
  /// In en, this message translates to:
  /// **'Unknown model'**
  String get sessionsExplorerUnknownModel;

  /// No description provided for @sessionsExplorerSubagent.
  ///
  /// In en, this message translates to:
  /// **'> Subagent .......... {category}'**
  String sessionsExplorerSubagent(String category);

  /// No description provided for @sessionsExplorerError.
  ///
  /// In en, this message translates to:
  /// **'> Error ............. operation failed. Check source data or server status.'**
  String get sessionsExplorerError;

  /// No description provided for @sessionRowData.
  ///
  /// In en, this message translates to:
  /// **'> {date} • {model} • {tokens} TOK • {currency} {cost} • ID: {id}'**
  String sessionRowData(
    String date,
    String model,
    String tokens,
    String currency,
    String cost,
    String id,
  );

  /// No description provided for @lineVisibleWindow.
  ///
  /// In en, this message translates to:
  /// **'> Window ............. {window}'**
  String lineVisibleWindow(String window);

  /// No description provided for @exchangeRatesLineWindow.
  ///
  /// In en, this message translates to:
  /// **'> Window ............ {window}'**
  String exchangeRatesLineWindow(String window);

  /// No description provided for @metricsTokensTopDrivers.
  ///
  /// In en, this message translates to:
  /// **'-- TOP DRIVERS --'**
  String get metricsTokensTopDrivers;

  /// No description provided for @modelDriverRow.
  ///
  /// In en, this message translates to:
  /// **'> {modelName} {padding} {currency} {cost} | {tokens} TOK | {sessions} SES'**
  String modelDriverRow(
    String modelName,
    String padding,
    String currency,
    String cost,
    String tokens,
    String sessions,
  );

  /// No description provided for @metricsModelHourlySpend.
  ///
  /// In en, this message translates to:
  /// **'-- HOURLY SPEND --'**
  String get metricsModelHourlySpend;

  /// No description provided for @metricsModelHourlyTokens.
  ///
  /// In en, this message translates to:
  /// **'-- HOURLY TOKENS --'**
  String get metricsModelHourlyTokens;

  /// No description provided for @modelSelectedDayMetrics.
  ///
  /// In en, this message translates to:
  /// **'> Day ............... {currency} {cost} | {tokens} TOK | {sessions} SES'**
  String modelSelectedDayMetrics(
    String currency,
    String cost,
    String tokens,
    String sessions,
  );

  /// No description provided for @windowAll.
  ///
  /// In en, this message translates to:
  /// **'ALL'**
  String get windowAll;

  /// No description provided for @window7d.
  ///
  /// In en, this message translates to:
  /// **'7D'**
  String get window7d;

  /// No description provided for @window30d.
  ///
  /// In en, this message translates to:
  /// **'30D'**
  String get window30d;

  /// No description provided for @window90d.
  ///
  /// In en, this message translates to:
  /// **'90D'**
  String get window90d;

  /// No description provided for @windowCustom.
  ///
  /// In en, this message translates to:
  /// **'CUSTOM'**
  String get windowCustom;

  /// No description provided for @windowActionAll.
  ///
  /// In en, this message translates to:
  /// **'[ ALL ]'**
  String get windowActionAll;

  /// No description provided for @windowAction7d.
  ///
  /// In en, this message translates to:
  /// **'[ 7D ]'**
  String get windowAction7d;

  /// No description provided for @windowAction30d.
  ///
  /// In en, this message translates to:
  /// **'[ 30D ]'**
  String get windowAction30d;

  /// No description provided for @windowAction90d.
  ///
  /// In en, this message translates to:
  /// **'[ 90D ]'**
  String get windowAction90d;

  /// No description provided for @windowActionCustom.
  ///
  /// In en, this message translates to:
  /// **'[ CUSTOM ]'**
  String get windowActionCustom;

  /// No description provided for @customRangeSelectStart.
  ///
  /// In en, this message translates to:
  /// **'Select Start'**
  String get customRangeSelectStart;

  /// No description provided for @customRangeSelectEnd.
  ///
  /// In en, this message translates to:
  /// **'Select End'**
  String get customRangeSelectEnd;

  /// No description provided for @sessionsExplorerCachedHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'-- CACHED HISTORY --'**
  String get sessionsExplorerCachedHistoryTitle;

  /// No description provided for @sessionsExplorerCachedCount.
  ///
  /// In en, this message translates to:
  /// **'> Sessions .......... {count}'**
  String sessionsExplorerCachedCount(int count);

  /// No description provided for @sessionsExplorerCachedNewest.
  ///
  /// In en, this message translates to:
  /// **'> Newest ............ {date}'**
  String sessionsExplorerCachedNewest(String date);

  /// No description provided for @sessionsExplorerCachedOldest.
  ///
  /// In en, this message translates to:
  /// **'> Oldest ............ {date}'**
  String sessionsExplorerCachedOldest(String date);

  /// No description provided for @sessionsExplorerCachedEmpty.
  ///
  /// In en, this message translates to:
  /// **'> Cache is empty'**
  String get sessionsExplorerCachedEmpty;

  /// No description provided for @sessionsExplorerLastOpTitle.
  ///
  /// In en, this message translates to:
  /// **'-- LAST OPERATION --'**
  String get sessionsExplorerLastOpTitle;

  /// No description provided for @sessionsExplorerLastOpType.
  ///
  /// In en, this message translates to:
  /// **'> Type .............. {type}'**
  String sessionsExplorerLastOpType(String type);

  /// No description provided for @sessionsExplorerLastOpStatus.
  ///
  /// In en, this message translates to:
  /// **'> Status ............ {status}'**
  String sessionsExplorerLastOpStatus(String status);

  /// No description provided for @sessionsExplorerLastOpSource.
  ///
  /// In en, this message translates to:
  /// **'> Source ............ {source}'**
  String sessionsExplorerLastOpSource(String source);

  /// No description provided for @sessionsExplorerLastOpCount.
  ///
  /// In en, this message translates to:
  /// **'> Cached ............ {count}'**
  String sessionsExplorerLastOpCount(int count);

  /// No description provided for @sessionsExplorerLastOpNone.
  ///
  /// In en, this message translates to:
  /// **'> No recent operations'**
  String get sessionsExplorerLastOpNone;

  /// No description provided for @opTypeLoad.
  ///
  /// In en, this message translates to:
  /// **'LOAD'**
  String get opTypeLoad;

  /// No description provided for @opTypeSync.
  ///
  /// In en, this message translates to:
  /// **'SYNC'**
  String get opTypeSync;

  /// No description provided for @opTypeImportJson.
  ///
  /// In en, this message translates to:
  /// **'IMPORT JSON'**
  String get opTypeImportJson;

  /// No description provided for @opTypeImportSqlite.
  ///
  /// In en, this message translates to:
  /// **'IMPORT SQLITE'**
  String get opTypeImportSqlite;

  /// No description provided for @opStatusSuccess.
  ///
  /// In en, this message translates to:
  /// **'SUCCESS'**
  String get opStatusSuccess;

  /// No description provided for @opStatusFailure.
  ///
  /// In en, this message translates to:
  /// **'FAILURE'**
  String get opStatusFailure;

  /// No description provided for @lineRollingAvgCost.
  ///
  /// In en, this message translates to:
  /// **'> Rolling avg cost ... {currency} {value}/day'**
  String lineRollingAvgCost(String currency, String value);

  /// No description provided for @lineRollingAvgTokens.
  ///
  /// In en, this message translates to:
  /// **'> Rolling avg tokens . {value}/day'**
  String lineRollingAvgTokens(String value);

  /// No description provided for @linePaceForecast.
  ///
  /// In en, this message translates to:
  /// **'> Pace (7d forecast) . {currency} {value}'**
  String linePaceForecast(String currency, String value);

  /// No description provided for @spendDailyAvgLabel.
  ///
  /// In en, this message translates to:
  /// **'AVG {currency} {amount}'**
  String spendDailyAvgLabel(String currency, String amount);

  /// No description provided for @spendDailyPeakLabel.
  ///
  /// In en, this message translates to:
  /// **'PEAK {currency} {amount}'**
  String spendDailyPeakLabel(String currency, String amount);

  /// No description provided for @spendHourlyAvgLabel.
  ///
  /// In en, this message translates to:
  /// **'AVG {currency} {amount}'**
  String spendHourlyAvgLabel(String currency, String amount);

  /// No description provided for @spendHourlyPeakLabel.
  ///
  /// In en, this message translates to:
  /// **'PEAK {currency} {amount}'**
  String spendHourlyPeakLabel(String currency, String amount);

  /// No description provided for @comparePriorWindow.
  ///
  /// In en, this message translates to:
  /// **'> Prior window ....... {window}'**
  String comparePriorWindow(String window);

  /// No description provided for @compareDeltaSessions.
  ///
  /// In en, this message translates to:
  /// **'> Delta sessions ..... {sign}{value}'**
  String compareDeltaSessions(String sign, int value);

  /// No description provided for @compareDeltaTokens.
  ///
  /// In en, this message translates to:
  /// **'> Delta tokens ....... {sign}{value}'**
  String compareDeltaTokens(String sign, int value);

  /// No description provided for @compareSplitSessions.
  ///
  /// In en, this message translates to:
  /// **'> Split sessions ..... {sign}{currency} {value}'**
  String compareSplitSessions(String sign, String currency, String value);

  /// No description provided for @compareSplitAvg.
  ///
  /// In en, this message translates to:
  /// **'> Split avg/session .. {sign}{currency} {value}'**
  String compareSplitAvg(String sign, String currency, String value);

  /// No description provided for @compareSplitCost.
  ///
  /// In en, this message translates to:
  /// **'> Split cost/1M ...... {sign}{currency} {value}'**
  String compareSplitCost(String sign, String currency, String value);

  /// No description provided for @compareSplitUnavailable.
  ///
  /// In en, this message translates to:
  /// **'> Split breakdown .... math undefined'**
  String get compareSplitUnavailable;

  /// No description provided for @compareUnavailableHelper.
  ///
  /// In en, this message translates to:
  /// **'> Prior-window compare unavailable due to missing exchange rates.'**
  String get compareUnavailableHelper;

  /// Title of the exchange rates history chart.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rate History ({currency} → CZK)'**
  String exchangeRatesHistoryTitle(String currency);

  /// No description provided for @sessionsSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search metadata...'**
  String get sessionsSearchPlaceholder;

  /// No description provided for @sessionsSearchClear.
  ///
  /// In en, this message translates to:
  /// **'[ CLEAR ]'**
  String get sessionsSearchClear;

  /// No description provided for @sessionsSearchResultsCount.
  ///
  /// In en, this message translates to:
  /// **'> Results ........... {count}'**
  String sessionsSearchResultsCount(int count);

  /// No description provided for @sessionsListHeader.
  ///
  /// In en, this message translates to:
  /// **'-- SESSION LOG --'**
  String get sessionsListHeader;

  /// No description provided for @pieLegendOverflow.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String pieLegendOverflow(int count);

  /// No description provided for @metricsOverviewSessionsPerDay.
  ///
  /// In en, this message translates to:
  /// **'-- SESSIONS / DAY --'**
  String get metricsOverviewSessionsPerDay;

  /// No description provided for @metricsOverviewAvgCostPerSession.
  ///
  /// In en, this message translates to:
  /// **'-- AVG COST / SESSION --'**
  String get metricsOverviewAvgCostPerSession;

  /// No description provided for @metricsOverviewAvgTokensPerSession.
  ///
  /// In en, this message translates to:
  /// **'-- AVG TOKENS / SESSION --'**
  String get metricsOverviewAvgTokensPerSession;

  /// No description provided for @shellFooterDevelopedBy.
  ///
  /// In en, this message translates to:
  /// **'Developed by {company}'**
  String shellFooterDevelopedBy(String company);

  /// No description provided for @shellFooterBuildVersion.
  ///
  /// In en, this message translates to:
  /// **'Build {version}'**
  String shellFooterBuildVersion(String version);

  /// No description provided for @axisLabelDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get axisLabelDate;

  /// No description provided for @axisLabelSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get axisLabelSessions;

  /// No description provided for @axisLabelAvgCost.
  ///
  /// In en, this message translates to:
  /// **'Avg Cost'**
  String get axisLabelAvgCost;

  /// No description provided for @axisLabelAvgTokens.
  ///
  /// In en, this message translates to:
  /// **'Avg Tokens'**
  String get axisLabelAvgTokens;

  /// No description provided for @metricsActivity.
  ///
  /// In en, this message translates to:
  /// **'ACTIVITY'**
  String get metricsActivity;

  /// No description provided for @metricsActiveDays.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE DAYS'**
  String get metricsActiveDays;

  /// No description provided for @metricsCurrentStreak.
  ///
  /// In en, this message translates to:
  /// **'CURRENT STREAK'**
  String get metricsCurrentStreak;

  /// No description provided for @metricsLongestStreak.
  ///
  /// In en, this message translates to:
  /// **'LONGEST STREAK'**
  String get metricsLongestStreak;

  /// No description provided for @metricsPeakDay.
  ///
  /// In en, this message translates to:
  /// **'PEAK DAY'**
  String get metricsPeakDay;

  /// No description provided for @metricsPeakDayDetail.
  ///
  /// In en, this message translates to:
  /// **'{count} sessions'**
  String metricsPeakDayDetail(int count);

  /// No description provided for @metricsDayCountCompact.
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String metricsDayCountCompact(int count);

  /// No description provided for @metricsHeatmapLegendLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get metricsHeatmapLegendLow;

  /// No description provided for @metricsHeatmapLegendHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get metricsHeatmapLegendHigh;

  /// No description provided for @metricsHeatmapCellLabel.
  ///
  /// In en, this message translates to:
  /// **'{day}: {sessions} sessions, {tokens} tokens'**
  String metricsHeatmapCellLabel(String day, int sessions, String tokens);

  /// No description provided for @metricsHeatmapCellTooltip.
  ///
  /// In en, this message translates to:
  /// **'{day}\n{sessions} sessions • {tokens} tokens'**
  String metricsHeatmapCellTooltip(String day, int sessions, String tokens);

  /// No description provided for @usageSourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Local usage sources'**
  String get usageSourcesTitle;

  /// No description provided for @usageConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get usageConnect;

  /// No description provided for @usageRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get usageRefresh;

  /// No description provided for @usageDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get usageDisconnect;

  /// No description provided for @usageConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get usageConnected;

  /// No description provided for @usageNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get usageNotConnected;

  /// No description provided for @usageChooseFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose folder'**
  String get usageChooseFolder;

  /// No description provided for @usageSourceError.
  ///
  /// In en, this message translates to:
  /// **'Could not read this source. Previously imported usage is retained.'**
  String get usageSourceError;

  /// No description provided for @usageSourceResult.
  ///
  /// In en, this message translates to:
  /// **'{sessions} sessions · {skipped} skipped records · {failed} unreadable files'**
  String usageSourceResult(int sessions, int skipped, int failed);

  /// No description provided for @usageLastRefresh.
  ///
  /// In en, this message translates to:
  /// **'Last refresh: {time}'**
  String usageLastRefresh(String time);

  /// No description provided for @usageNeverRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Not refreshed yet'**
  String get usageNeverRefreshed;

  /// No description provided for @usageSourcesBrowser.
  ///
  /// In en, this message translates to:
  /// **'Local source connections are available in the desktop app.'**
  String get usageSourcesBrowser;

  /// No description provided for @usagePricingTitle.
  ///
  /// In en, this message translates to:
  /// **'API estimate pricing'**
  String get usagePricingTitle;

  /// No description provided for @usagePricingHelp.
  ///
  /// In en, this message translates to:
  /// **'Standard API token rates, USD per million tokens. Subscription fees, taxes, tools and fast-mode premiums are excluded.'**
  String get usagePricingHelp;

  /// No description provided for @usagePricingSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Published rate snapshot: {version}'**
  String usagePricingSnapshot(String version);

  /// No description provided for @usagePricingModel.
  ///
  /// In en, this message translates to:
  /// **'Usage model'**
  String get usagePricingModel;

  /// No description provided for @usagePricingMapping.
  ///
  /// In en, this message translates to:
  /// **'Use published model rates'**
  String get usagePricingMapping;

  /// No description provided for @usagePricingCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom rates'**
  String get usagePricingCustom;

  /// No description provided for @usagePricingReset.
  ///
  /// In en, this message translates to:
  /// **'Reset to published rates'**
  String get usagePricingReset;

  /// No description provided for @usagePricingSave.
  ///
  /// In en, this message translates to:
  /// **'Save rates'**
  String get usagePricingSave;

  /// No description provided for @usagePricingInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter finite, nonnegative rates. Input and output rates are required.'**
  String get usagePricingInvalid;

  /// No description provided for @usageInput.
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get usageInput;

  /// No description provided for @usageOutput.
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get usageOutput;

  /// No description provided for @usageCacheRead.
  ///
  /// In en, this message translates to:
  /// **'Cache reads'**
  String get usageCacheRead;

  /// No description provided for @usageCacheWrite.
  ///
  /// In en, this message translates to:
  /// **'Cache writes'**
  String get usageCacheWrite;

  /// No description provided for @usageCacheWrite1h.
  ///
  /// In en, this message translates to:
  /// **'Cache writes (1 hour)'**
  String get usageCacheWrite1h;

  /// No description provided for @usageReasoning.
  ///
  /// In en, this message translates to:
  /// **'Reasoning (included in output)'**
  String get usageReasoning;

  /// No description provided for @usageHarnessAll.
  ///
  /// In en, this message translates to:
  /// **'All harnesses'**
  String get usageHarnessAll;

  /// No description provided for @usageComparisonTitle.
  ///
  /// In en, this message translates to:
  /// **'Usage by harness'**
  String get usageComparisonTitle;

  /// No description provided for @usageApiEstimate.
  ///
  /// In en, this message translates to:
  /// **'Estimated API cost'**
  String get usageApiEstimate;

  /// No description provided for @usageReportedCost.
  ///
  /// In en, this message translates to:
  /// **'Reported cost'**
  String get usageReportedCost;

  /// No description provided for @usageUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get usageUnknown;

  /// No description provided for @usagePricingCoverage.
  ///
  /// In en, this message translates to:
  /// **'{priced} of {total} usage records priced'**
  String usagePricingCoverage(int priced, int total);

  /// No description provided for @usageCustomPrice.
  ///
  /// In en, this message translates to:
  /// **'Custom pricing'**
  String get usageCustomPrice;

  /// No description provided for @usageApproximate.
  ///
  /// In en, this message translates to:
  /// **'Approximate: uses short-context or 5-minute cache-write rates where metadata is unavailable.'**
  String get usageApproximate;

  /// No description provided for @usageTokensHelp.
  ///
  /// In en, this message translates to:
  /// **'Input includes cache reads and writes across all requests, including repeated conversation context. Reasoning is included in output. Hover over token totals for exact counts.'**
  String get usageTokensHelp;

  /// No description provided for @usagePartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get usagePartial;

  /// No description provided for @usageNoMapping.
  ///
  /// In en, this message translates to:
  /// **'Keep original model'**
  String get usageNoMapping;

  /// No description provided for @usagePricingNoModels.
  ///
  /// In en, this message translates to:
  /// **'Import usage to configure model prices.'**
  String get usagePricingNoModels;

  /// No description provided for @usagePricingPublished.
  ///
  /// In en, this message translates to:
  /// **'Published rates'**
  String get usagePricingPublished;

  /// No description provided for @usageSourcesHelp.
  ///
  /// In en, this message translates to:
  /// **'Connect once to load local token metadata. Refresh on launch or on demand; disconnect keeps imported history.'**
  String get usageSourcesHelp;

  /// No description provided for @usagePricingRatesHelp.
  ///
  /// In en, this message translates to:
  /// **'Blank cache rates leave events using that category unpriced. A zero rate is an explicit free category.'**
  String get usagePricingRatesHelp;

  /// No description provided for @usageSourceBusy.
  ///
  /// In en, this message translates to:
  /// **'Refreshing local usage…'**
  String get usageSourceBusy;

  /// No description provided for @overviewPurpose.
  ///
  /// In en, this message translates to:
  /// **'Your spending, usage and models in one place.'**
  String get overviewPurpose;

  /// No description provided for @sessionsPurpose.
  ///
  /// In en, this message translates to:
  /// **'Find a session. Compare usage. Trace the cost.'**
  String get sessionsPurpose;

  /// No description provided for @exchangePurpose.
  ///
  /// In en, this message translates to:
  /// **'Manage the rates used to convert your spending.'**
  String get exchangePurpose;

  /// No description provided for @sourcesPurpose.
  ///
  /// In en, this message translates to:
  /// **'Check your local data, connection and privacy.'**
  String get sourcesPurpose;

  /// No description provided for @mockDataNotice.
  ///
  /// In en, this message translates to:
  /// **'Sample data · switch to Real to see your usage'**
  String get mockDataNotice;

  /// No description provided for @realDataNotice.
  ///
  /// In en, this message translates to:
  /// **'Local data'**
  String get realDataNotice;

  /// No description provided for @sessionsPage.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {pages}'**
  String sessionsPage(int page, int pages);

  /// No description provided for @previousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get previousPage;

  /// No description provided for @nextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get nextPage;

  /// No description provided for @mockDataLabel.
  ///
  /// In en, this message translates to:
  /// **'Sample data'**
  String get mockDataLabel;

  /// No description provided for @sessionsSortLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get sessionsSortLatest;

  /// No description provided for @sessionsSortCost.
  ///
  /// In en, this message translates to:
  /// **'Reported cost'**
  String get sessionsSortCost;

  /// No description provided for @sessionsSortTokens.
  ///
  /// In en, this message translates to:
  /// **'Tokens'**
  String get sessionsSortTokens;

  /// No description provided for @clearScopeFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearScopeFilters;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['cs', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'cs':
      return AppLocalizationsCs();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
