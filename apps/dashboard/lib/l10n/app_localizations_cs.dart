// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get appTitle => 'OpenSpent';

  @override
  String get localLabel => '[ LOKÁLNÍ ]';

  @override
  String get heroTitle => 'Monitorujte OpenCode. Lokálně.';

  @override
  String get heroDescription =>
      'Soukromý lokální dashboard s cachovanými metrikami a terminálovým zobrazením.';

  @override
  String get statusPaneTitle => 'STAV';

  @override
  String statusLineReady(String state) {
    return '> Dashboard .......... $state';
  }

  @override
  String statusLineMode(String mode) {
    return '> Režim ............. $mode';
  }

  @override
  String statusLineServer(String server) {
    return '> Server ............ $server';
  }

  @override
  String statusLineProbe(String probe) {
    return '> Sonda ............. $probe';
  }

  @override
  String get statusProbeConnected => 'PŘIPOJENO';

  @override
  String get statusProbeDisconnected => 'ODPOJENO';

  @override
  String get statusProbeError => 'CHYBA';

  @override
  String get statusProbeLoading => 'NAČÍTÁM';

  @override
  String get statusProbeUnknown => 'NEZNÁMO';

  @override
  String get statusReady => 'PŘIPRAVEN';

  @override
  String get statusLoading => 'NAČÍTÁM';

  @override
  String get statusModeLocalCache => 'LOKÁLNÍ CACHE';

  @override
  String get statusModeMockSuffix => ' (MOCK)';

  @override
  String get dataModeLabel => 'Režim dat:';

  @override
  String get dataModeReal => 'REÁL';

  @override
  String get dataModeMock => 'MOCK';

  @override
  String get statusServerNotConfigured => 'NENÍ NASTAVENO';

  @override
  String get statusServerLoading => 'NAČÍTÁM';

  @override
  String get privacyPaneTitle => 'SOUKROMÍ';

  @override
  String get privacyLinePrompts => '> Promptů uloženo ..... NE';

  @override
  String get privacyLineToolOutput => '> Výstup nástrojů ..... NE';

  @override
  String get privacyLineErrors => '> Syrové chyby ........ NE';

  @override
  String persistedAllowlist(int count) {
    return '> Velikost uloženého allowlistu metadat: $count';
  }

  @override
  String get metricsTitle => 'METRIKY';

  @override
  String get metricsLoad => '_ čekám na první data metrik ...';

  @override
  String get metricsUnavailable => '> metriky nedostupné';

  @override
  String get metricsMissingExchangeRatesHelper =>
      '> chybí kurzy pro dny s útratou. Synchronizujte kurzy v panelu měn a zkuste to znovu.';

  @override
  String get textTab => '[ TEXT ]';

  @override
  String get spendTab => '[ ÚTRATA ]';

  @override
  String get tokensTab => '[ TOKENY ]';

  @override
  String get modelsTab => '[ MODELY ]';

  @override
  String get overallSection => '-- CELKOVĚ --';

  @override
  String selectedDaySection(String day) {
    return '-- VYBRANÝ DEN ($day) --';
  }

  @override
  String peakHourSection(String hour) {
    return '-- NEJVYŠŠÍ HODINA ($hour:00 UTC) --';
  }

  @override
  String get peakHourEmptySection => '-- NEJVYŠŠÍ HODINA --';

  @override
  String lineTotalCost(String currency, String value) {
    return '> Celková cena ....... $currency $value';
  }

  @override
  String lineSessions(int value) {
    return '> Relace ............. $value';
  }

  @override
  String lineTopMover(
    String model,
    String sign,
    String currency,
    String value,
  ) {
    return '> Největší skokan .... $model ($sign$currency$value)';
  }

  @override
  String get lineTopMoverEmpty => '> Největší skokan .... ŽÁDNÝ';

  @override
  String compareSummary(String sign, String currency, String value) {
    return '> Oproti minulosti ... $sign$value $currency';
  }

  @override
  String compareSummaryDriver(
    String model,
    String sign,
    String currency,
    String value,
  ) {
    return '> Hlavní tahoun ...... $model $sign$value $currency';
  }

  @override
  String get compareSummaryNoDriver => '> Hlavní tahoun ...... ŽÁDNÝ';

  @override
  String lineInputTokens(String value) {
    return '> Vstupní tokeny ..... $value';
  }

  @override
  String lineOutputTokens(String value) {
    return '> Výstupní tokeny .... $value';
  }

  @override
  String lineTotalTokens(String value) {
    return '> Celkem tokenů ...... $value';
  }

  @override
  String lineAvgTokensPerSession(String value) {
    return '> Průměr/relaci ...... $value';
  }

  @override
  String lineCostPerMillionTokens(String currency, String value) {
    return '> Cena/1M tokenů ..... $currency $value';
  }

  @override
  String linePeakCost(String currency, String value) {
    return '> Cena ............... $currency $value';
  }

  @override
  String linePeakTokensInOut(String input, String output) {
    return '> Tokeny (Dovnitř/Ven) $input / $output';
  }

  @override
  String get lineNoActivity => '> Žádná zaznamenaná aktivita';

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
    return 'TOK $tokens | REL $sessions';
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
  String get hourlySpendTitle => 'HODINOVÁ ÚTRATA (UTC)';

  @override
  String get hourlyTokensTitle => 'HODINOVÉ TOKENY DOVNITŘ/VEN (UTC)';

  @override
  String get tokenLegend => 'IN tlum. | OUT jasně';

  @override
  String get spendTrendUnavailable => '> trend útraty nedostupný';

  @override
  String get tokenTrendUnavailable => '> trend tokenů nedostupný';

  @override
  String get modelSpendUnavailable => '> útrata modelů nedostupná';

  @override
  String modelTrend(int days, String trend) {
    return '${days}D $trend';
  }

  @override
  String get metricsProvidersTab => '[ POSKYTOVATELÉ ]';

  @override
  String metricsKpiTotalPrice(String currency, String value) {
    return '> CELKOVÁ CENA ...... $value $currency';
  }

  @override
  String metricsKpiTotalRequests(String value) {
    return '> CELKEM POŽADAVKŮ .. $value';
  }

  @override
  String metricsKpiTotalToolCalls(String value) {
    return '> CELKEM TOOL CALLŮ . $value';
  }

  @override
  String metricsKpiAvgResponseTime(String value) {
    return '> PRŮM. ODEZVA ...... $value';
  }

  @override
  String metricsKpiTotalTokens(String value) {
    return '> CELKEM TOKENŮ ..... $value';
  }

  @override
  String get metricsKpiNotAvailable => '--';

  @override
  String metricsKpiPartial(String value) {
    return '$value (částečně)';
  }

  @override
  String get providersUsageChartTitle => '-- VYUŽITÍ PODLE POSKYTOVATELE --';

  @override
  String get providersPriceChartTitle => '-- CENA PODLE POSKYTOVATELE --';

  @override
  String providersPriceUnavailable(String provider) {
    return '> cena za $provider nedostupná';
  }

  @override
  String helpRemoteLineCors(String origin) {
    return '> Při používání dashboardu v prohlížeči proti lokálnímu serveru spusťte OpenCode s --cors=\"$origin\", aby povolil tento browser origin. Hodnota musí být jen origin — ne /demo ani žádná jiná cesta.';
  }

  @override
  String get settingsTitle => '[ NASTAVENÍ ]';

  @override
  String get settingsCurrency => 'Měna:';

  @override
  String get settingsLanguage => 'Jazyk:';

  @override
  String get settingsLanguageSystem => 'Výchozí podle systému';

  @override
  String get settingsLanguageEnglish => 'Angličtina';

  @override
  String get settingsLanguageCzech => 'Čeština';

  @override
  String get settingsServerUrl => 'URL serveru:';

  @override
  String get settingsServerUsername => 'Uživatelské jméno serveru:';

  @override
  String get settingsServerPassword => 'Heslo serveru:';

  @override
  String get settingsServerAuthHint =>
      'Volitelné Basic Auth. Pokud je nastavené heslo a jméno zůstane prázdné, OpenSpent použije `opencode`.';

  @override
  String get settingsServerUrlInvalid =>
      'Zadejte platnou URL serveru s http:// nebo https://.';

  @override
  String get settingsSave => '[ ULOŽIT ]';

  @override
  String get settingsClose => '[ ZAVŘÍT ]';

  @override
  String get helpDialogTitle => '[ INFO / NÁPOVĚDA ]';

  @override
  String get helpTabLocal => 'Lokální';

  @override
  String get helpTabRemote => 'Remote';

  @override
  String get helpLocalLineImport =>
      '> Importujte JSON nebo SQLite soubory přímo do OpenSpent z panelu relací.';

  @override
  String get helpLocalLinePaths =>
      '> OpenCode obvykle ukládá hlavní DB do ~/.local/share/opencode/opencode.db na macOS/Linux a na Windows pod %USERPROFILE%\\.local\\share\\opencode\\opencode.db.';

  @override
  String get helpLocalLineCommandDbPath =>
      '> Užitečný příkaz: opencode db path';

  @override
  String get helpLocalLineCommandExport =>
      '> Užitečné příkazy: opencode export, opencode import';

  @override
  String get helpLocalLineCommandSessionList =>
      '> Užitečný příkaz: opencode session list';

  @override
  String get helpLocalLineCommandStats => '> Užitečný příkaz: opencode stats';

  @override
  String get helpLocalLineBackup =>
      '> Zálohujte exportované soubory a kopie lokální DB opatrně. Zachovejte privacy-first a local-first workflow.';

  @override
  String get helpRemoteLineServe =>
      '> API server spusťte příkazem: opencode serve';

  @override
  String get helpRemoteLineDefaultUrl =>
      '> Výchozí URL serveru: http://localhost:4096';

  @override
  String get helpRemoteLineHostUse =>
      '> Na stejném stroji používejte localhost. URL vzdáleného hosta používejte jen tehdy, když OpenCode běží na jiném stroji.';

  @override
  String get helpRemoteLineAuthEnv =>
      '> Basic Auth používá OPENCODE_SERVER_USERNAME a OPENCODE_SERVER_PASSWORD.';

  @override
  String get helpRemoteLineAuthDefaultUsername =>
      '> Pokud je zapnutá ochrana heslem a není nastaveno jméno, výchozí uživatelské jméno je `opencode`.';

  @override
  String get exchangeRatesTitle => '[ KURZY ]';

  @override
  String get exchangeRatesActionSync => '[ SYNCHRONIZOVAT KURZY ]';

  @override
  String get exchangeRatesStatusLoading => 'NAČÍTÁM';

  @override
  String get exchangeRatesStatusError => 'CHYBA';

  @override
  String get exchangeRatesStatusReady => 'PŘIPRAVENO';

  @override
  String exchangeRatesStatusMissing(int count) {
    return 'CHYBÍ $count';
  }

  @override
  String get exchangeRatesMissingDaysNone => 'žádné';

  @override
  String exchangeRatesCurrencyChanged(String currency) {
    return '> Zobrazovaná měna nastavena na $currency.';
  }

  @override
  String get exchangeRatesCurrencyChangeError =>
      '> Nepodařilo se změnit zobrazovanou měnu.';

  @override
  String exchangeRatesSyncSuccess(int count) {
    return '> Chybějící kurzy byly synchronizovány pro $count den(dny) útraty.';
  }

  @override
  String get exchangeRatesSyncError => '> Synchronizace kurzů selhala.';

  @override
  String exchangeRatesError(String message) {
    return '> Chyba ............. $message';
  }

  @override
  String exchangeRatesLineStatus(String value) {
    return '> Stav .............. $value';
  }

  @override
  String exchangeRatesLineDisplay(String currency) {
    return '> Zobrazení ......... $currency';
  }

  @override
  String exchangeRatesLineSpendDays(int count) {
    return '> Dny útraty ........ $count';
  }

  @override
  String exchangeRatesLineCoverage(int covered, int total) {
    return '> Pokrytí ........... $covered/$total';
  }

  @override
  String exchangeRatesLineMissingDays(String days) {
    return '> Chybějící dny ..... $days';
  }

  @override
  String get sessionsSpotlightEmptyScope =>
      '> V aktuálním rozsahu není žádné hodnocené evidence.';

  @override
  String get sessionsSpotlightEmpty =>
      '> Hodnocené evidence nejsou k dispozici.';

  @override
  String get sessionsExplorerTitle => '[ PRŮZKUMNÍK RELACÍ ]';

  @override
  String get sessionsExplorerActionSync => '[ SYNCHRONIZOVAT ]';

  @override
  String get sessionsExplorerActionImport => '[ IMPORTOVAT DATA ]';

  @override
  String get sessionsExplorerLoading => '> Načítám cachované relace...';

  @override
  String get sessionsExplorerEmptyConnected =>
      '> Žádné cachované relace nebyly nalezeny. Začněte synchronizací nebo importem.';

  @override
  String get sessionsExplorerEmptyDisconnected =>
      '> Žádné cachované relace nebyly nalezeny. Připojte lokální server nebo importujte data.';

  @override
  String activeModelFilter(String model) {
    return '> Filtr modelu ...... $model';
  }

  @override
  String activeDayFilter(String day) {
    return '> Filtr dne ......... $day';
  }

  @override
  String activeHourFilter(String hour) {
    return '> Filtr hodiny ...... $hour:00 UTC';
  }

  @override
  String get clearFilterAction => '[ ZRUŠIT ]';

  @override
  String get sessionsExplorerFilteredEmpty =>
      '> Žádné relace neodpovídají aktivním filtrům.';

  @override
  String get sessionsExplorerSyncSuccess =>
      '> Synchronizace byla úspěšně dokončena.';

  @override
  String get sessionsExplorerSyncError => '> Synchronizace selhala.';

  @override
  String get sessionsExplorerImportSuccess => '> Import byl úspěšně dokončen.';

  @override
  String get sessionsExplorerImportWalModeError =>
      '> Import v prohlížeči vyžaduje samostatný SQLite soubor. OpenCode databáze v režimu WAL zatím nejsou podporované pro nahrání jediného souboru.';

  @override
  String get sessionsExplorerImportError =>
      '> Import selhal: neplatný formát nebo chyba.';

  @override
  String get sessionsExplorerImportNoFile => '> Import byl zrušen.';

  @override
  String get sessionsExplorerUnknownModel => 'Neznámý model';

  @override
  String sessionsExplorerSubagent(String category) {
    return '> Subagent .......... $category';
  }

  @override
  String get sessionsExplorerError =>
      '> Chyba ............. operace selhala. Zkontrolujte zdroj dat nebo stav serveru.';

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
    return '> Okno ............... $window';
  }

  @override
  String exchangeRatesLineWindow(String window) {
    return '> Okno .............. $window';
  }

  @override
  String get metricsTokensTopDrivers => '-- NEJVYUŽÍVANĚJŠÍ --';

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
  String get metricsModelHourlySpend => '-- HODINOVÁ ÚTRATA --';

  @override
  String get metricsModelHourlyTokens => '-- HODINOVÉ TOKENY --';

  @override
  String modelSelectedDayMetrics(
    String currency,
    String cost,
    String tokens,
    String sessions,
  ) {
    return '> Den ............... $currency $cost | $tokens TOK | $sessions SES';
  }

  @override
  String get windowAll => 'VŠE';

  @override
  String get window7d => '7D';

  @override
  String get window30d => '30D';

  @override
  String get window90d => '90D';

  @override
  String get windowCustom => 'VLASTNÍ';

  @override
  String get windowActionAll => '[ VŠE ]';

  @override
  String get windowAction7d => '[ 7D ]';

  @override
  String get windowAction30d => '[ 30D ]';

  @override
  String get windowAction90d => '[ 90D ]';

  @override
  String get windowActionCustom => '[ VLASTNÍ ]';

  @override
  String get sessionsExplorerCachedHistoryTitle => '-- CACHOVANÁ HISTORIE --';

  @override
  String sessionsExplorerCachedCount(int count) {
    return '> Relací ............ $count';
  }

  @override
  String sessionsExplorerCachedNewest(String date) {
    return '> Nejnovější ........ $date';
  }

  @override
  String sessionsExplorerCachedOldest(String date) {
    return '> Nejstarší ......... $date';
  }

  @override
  String get sessionsExplorerCachedEmpty => '> Cache je prázdná';

  @override
  String get sessionsExplorerLastOpTitle => '-- POSLEDNÍ OPERACE --';

  @override
  String sessionsExplorerLastOpType(String type) {
    return '> Typ ............... $type';
  }

  @override
  String sessionsExplorerLastOpStatus(String status) {
    return '> Stav .............. $status';
  }

  @override
  String sessionsExplorerLastOpSource(String source) {
    return '> Zdroj ............. $source';
  }

  @override
  String sessionsExplorerLastOpCount(int count) {
    return '> Cachováno ......... $count';
  }

  @override
  String get sessionsExplorerLastOpNone => '> Žádné nedávné operace';

  @override
  String get opTypeLoad => 'NAČTENÍ';

  @override
  String get opTypeSync => 'SYNCHRONIZACE';

  @override
  String get opTypeImportJson => 'IMPORT JSON';

  @override
  String get opTypeImportSqlite => 'IMPORT SQLITE';

  @override
  String get opStatusSuccess => 'ÚSPĚCH';

  @override
  String get opStatusFailure => 'SELHÁNÍ';

  @override
  String lineRollingAvgCost(String currency, String value) {
    return '> Průměrný denní náklad . $currency $value/den';
  }

  @override
  String lineRollingAvgTokens(String value) {
    return '> Průměrné denní tokeny . $value/den';
  }

  @override
  String linePaceForecast(String currency, String value) {
    return '> Odhad (na 7 dní) ...... $currency $value';
  }

  @override
  String spendDailyAvgLabel(String currency, String amount) {
    return 'PRŮMĚR $currency $amount';
  }

  @override
  String spendDailyPeakLabel(String currency, String amount) {
    return 'MAX $currency $amount';
  }

  @override
  String spendHourlyAvgLabel(String currency, String amount) {
    return 'PRŮMĚR $currency $amount';
  }

  @override
  String spendHourlyPeakLabel(String currency, String amount) {
    return 'MAX $currency $amount';
  }

  @override
  String comparePriorWindow(String window) {
    return '> Minulé období ...... $window';
  }

  @override
  String compareDeltaSessions(String sign, int value) {
    return '> Rozdíl relací ...... $sign$value';
  }

  @override
  String compareDeltaTokens(String sign, int value) {
    return '> Rozdíl tokenů ...... $sign$value';
  }

  @override
  String compareSplitSessions(String sign, String currency, String value) {
    return '> Vliv relací ........ $sign$value $currency';
  }

  @override
  String compareSplitAvg(String sign, String currency, String value) {
    return '> Vliv prům./relaci .. $sign$value $currency';
  }

  @override
  String compareSplitCost(String sign, String currency, String value) {
    return '> Vliv ceny/1M ....... $sign$value $currency';
  }

  @override
  String get compareSplitUnavailable => '> Rozklad delty ...... nelze spočítat';

  @override
  String get compareUnavailableHelper =>
      '> Porovnání s minulým obdobím není dostupné kvůli chybějícím kurzům.';

  @override
  String exchangeRatesHistoryTitle(String currency) {
    return 'Historie směnných kurzů ($currency → CZK)';
  }

  @override
  String get sessionsSearchPlaceholder => 'Hledat v metadatech...';

  @override
  String get sessionsSearchClear => '[ ZRUŠIT ]';

  @override
  String sessionsSearchResultsCount(int count) {
    return '> Výsledky .......... $count';
  }

  @override
  String get sessionsListHeader => '-- ZÁZNAM RELACÍ --';

  @override
  String pieLegendOverflow(int count) {
    return '+$count dalších';
  }

  @override
  String get metricsOverviewSessionsPerDay => '-- RELACE / DEN --';

  @override
  String get metricsOverviewAvgCostPerSession => '-- PRŮM. CENA / RELACI --';

  @override
  String get metricsOverviewAvgTokensPerSession =>
      '-- PRŮM. TOKENY / RELACI --';
}
