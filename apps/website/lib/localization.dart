class Loc {
  final String languageCode;

  const Loc(this.languageCode);

  static const en = Loc('en');
  static const cs = Loc('cs');

  // Nav / Header
  String get title => 'OpenSpent';
  String get langSwitch => this == cs ? 'EN / [CS]' : '[EN] / CS';

  // Hero
  String get heroTitle =>
      this == cs ? 'Sledujte OpenCode. Lokálně.' : 'Monitor OpenCode. Locally.';
  String get heroSubtitle => this == cs
      ? 'Privacy-first, lokální open-source dashboard pro sledování vašich nákladů a využití OpenCode.'
      : 'A privacy-first, local-only open-source dashboard to track your OpenCode API usage and costs.';

  // Badges
  String get badgeAlpha => 'ALPHA';
  String get badgeFree => this == cs ? 'ZDARMA' : 'FREE';
  String get badgePrivacy => this == cs ? 'SOUKROMÍ' : 'PRIVACY FIRST';
  String get badgeOpenSource => 'OPEN SOURCE';

  // What it does
  String get sectionFeatures =>
      this == cs ? '// Co to dělá' : '// What it does';

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
      ? 'Minimalistický, monochromatický dashboard inspirovaný terminálem pro rychlý přehled.'
      : 'Minimalist, monochromatic, terminal-inspired dashboard for a quick overview.';

  // Previews
  String get sectionPreview =>
      this == cs ? '// Jak to vypadá' : '// What it looks like';
  String get previewMetrics =>
      this == cs ? 'Metriky a Grafy' : 'Metrics & Charts';
  String get previewSessions =>
      this == cs ? 'Přehled Relací' : 'Sessions Overview';
  String get previewRates => this == cs ? 'Měnové Kurzy' : 'Exchange Rates';
  String get previewSettings => this == cs ? 'Nastavení' : 'Settings';

  // Open Source / Company
  String get sectionCompany =>
      this == cs ? '// Kdo za tím stojí' : '// Built by';
  String get companyTitle => 'Code Growers s.r.o.';
  String get companyBody => this == cs
      ? 'Jsme vývojářské studio, které věří v lokální nástroje a ochranu soukromí. Vytvořili jsme OpenSpent jako open-source (MIT).'
      : 'We are a development studio that believes in local-first tools and privacy. We built OpenSpent as open-source (MIT).';
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
