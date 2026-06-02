class Loc {
  final String languageCode;

  const Loc(this.languageCode);

  static const en = Loc('en');
  static const cs = Loc('cs');

  // Nav / Header
  String get title => 'OpenSpent';
  String get langSwitch => this == cs ? 'EN / [CS]' : '[EN] / CS';

  // Hero
  String get heroTitle => this == cs
      ? 'Řídicí věž pro OpenCode spend.'
      : 'The control room for OpenCode spend.';
  String get heroSubtitle => this == cs
      ? 'Moderní lokální dashboard pro týmy, které chtějí vidět náklady, modely a relace z jednoho místa bez úniku promptů nebo raw payloadů.'
      : 'A modern local dashboard for teams that need usage, models, sessions, and spend in one place without exposing prompts or raw payloads.';

  // Badges
  String get badgeAlpha => 'ALPHA';
  String get badgeFree => this == cs ? 'ZDARMA' : 'FREE';
  String get badgePrivacy => this == cs ? 'SOUKROMÍ' : 'PRIVACY FIRST';
  String get badgeOpenSource => 'OPEN SOURCE';
  String get badgeRealtime => this == cs ? 'REALTIME' : 'REALTIME';

  // What it does
  String get sectionFeatures =>
      this == cs ? '// Co to dělá' : '// What it does';
  String get sectionFeaturesBody => this == cs
      ? 'Pro týmy, které potřebují ostrý dashboard místo dalšího log souboru.'
      : 'Built for operators who need a crisp dashboard, not another log file.';

  String get featPrivacyTitle =>
      this == cs ? 'Stoprocentně lokální' : '100% Local';
  String get featPrivacyBody => this == cs
      ? 'Všechna data zůstávají u vás. Žádné prompty, žádné kódy, žádné cloud servery.'
      : 'All data stays on your machine. No prompts, no code, no cloud servers.';

  String get featCostTitle =>
      this == cs ? 'Chytré sledování nákladů' : 'Smart Cost Tracking';
  String get featCostBody => this == cs
      ? 'Zjistěte přesně, kolik stojí jednotlivé běhy a modely. Podpora USD i CZK.'
      : 'Know exactly how much individual runs and models cost. USD & CZK support.';

  String get featMonitorTitle =>
      this == cs ? 'Metriky v reálném čase' : 'Real-time Metrics';
  String get featMonitorBody => this == cs
      ? 'Dashboard inspirovaný terminálem s živým stavem serveru, drilldowny a přehledy pro rychlé rozhodování.'
      : 'A terminal-inspired dashboard with live server state, drilldowns, and executive-ready summaries.';
  String get featCompanyTitle =>
      this == cs ? 'Firemní OpenCode cockpit' : 'Company OpenCode cockpit';
  String get featCompanyBody => this == cs
      ? 'Připojte dashboard k firemnímu OpenCode serveru a sledujte týmovou útratu z jednoho lokálního místa v reálném čase.'
      : 'Point the dashboard at a company-owned OpenCode server and watch team spend from one local place in realtime.';

  // Previews
  String get sectionPreview =>
      this == cs ? '// Jak to vypadá' : '// What it looks like';
  String get previewMetrics =>
      this == cs ? 'Metriky a Grafy' : 'Metrics & Charts';
  String get previewSessions =>
      this == cs ? 'Přehled Relací' : 'Sessions Overview';
  String get previewRates => this == cs ? 'Měnové Kurzy' : 'Exchange Rates';
  String get previewSettings => this == cs ? 'Nastavení' : 'Settings';
  String get previewCompany =>
      this == cs ? 'Firemní Cockpit' : 'Company Cockpit';

  // Enterprise use case
  String get sectionEnterprise =>
      this == cs ? '// Firemní použití' : '// Company use case';
  String get enterpriseTitle => this == cs
      ? 'Jeden lokální dashboard pro celý týmový OpenCode server.'
      : 'One local dashboard for your team-owned OpenCode server.';
  String get enterpriseBody => this == cs
      ? 'OpenSpent může běžet vedle interního OpenCode serveru a dávat engineering leadům realtime přehled o nákladech, modelech, relacích a trendech. Data zůstávají u vás: UI zobrazuje jen allowlistovaná metadata, ne prompty, vstupy nástrojů ani raw výstupy.'
      : 'OpenSpent can sit next to an internal OpenCode server and give engineering leads a realtime view of spend, models, sessions, and trends. Data stays with you: the UI renders allowlisted metadata only, not prompts, tool inputs, or raw outputs.';
  String get enterprisePointRealtime => this == cs
      ? 'Realtime pohled na týmové náklady'
      : 'Realtime team spend visibility';
  String get enterprisePointLocal => this == cs
      ? 'Lokální cache a soukromá metadata'
      : 'Local cache and private metadata';
  String get enterprisePointOps => this == cs
      ? 'Jedno místo pro finance i engineering'
      : 'One place for finance and engineering';

  // Open Source / Company
  String get sectionCompany =>
      this == cs ? '// Kdo za tím stojí' : '// Built by';
  String get companyTitle => 'Code Growers s.r.o.';
  String get companyBody => this == cs
      ? 'Jsme vývojářské studio, které věří v lokální nástroje a ochranu soukromí. Vytvořili jsme OpenSpent jako open-source (MIT).'
      : 'We are a development studio that believes in local-first tools and privacy. We built OpenSpent as open-source (MIT).';
  String get linkDemo => this == cs ? 'Vyzkoušet Demo' : 'Try the Demo';
  String get linkGithub => 'GitHub Repository';
  String get linkLinkedin => 'LinkedIn';

  // Terminal ASCII
  String get terminalCommand =>
      this == cs ? '\$ openspent stav' : '\$ openspent status';
  String get terminalUsage =>
      this == cs ? 'VYUŽITÍ (30 DNÍ)' : 'USAGE (30 DAYS)';
  String get terminalCost => this == cs ? 'NÁKLADY' : 'COST';
  String get terminalTotal => this == cs ? 'CELKEM' : 'TOTAL';
  String get terminalTrend => 'TREND';

  // Footer
  String get footer => this == cs
      ? '© 2026 Code Growers s.r.o. Licence MIT.'
      : '© 2026 Code Growers s.r.o. MIT Licensed.';
}
