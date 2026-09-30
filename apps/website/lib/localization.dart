class Loc {
  const Loc(this.languageCode);
  final String languageCode;
  static const en = Loc('en');
  static const cs = Loc('cs');
  String _t(String en, String cs) => languageCode == 'cs' ? cs : en;

  String get title => 'OpenSpent';
  String get langSwitch => _t('[EN] / CS', 'EN / [CS]');
  String get languageSwitchLabel =>
      _t('Switch to Czech', 'Přepnout do angličtiny');
  String get skipContent => _t('Skip to content', 'Přejít na obsah');
  String get navigation => _t('Sections', 'Sekce');
  String get navProduct => _t('Product', 'Produkt');
  String get navStart => _t('Get started', 'Jak začít');
  String get navPrivacy => _t('Privacy', 'Soukromí');
  String get heroEyebrow => _t(
    'LOCAL PROCESSING. ZERO USAGE UPLOADS.',
    'LOKÁLNÍ ZPRACOVÁNÍ. ŽÁDNÉ ODESÍLÁNÍ DAT.',
  );
  String get heroTitle => _t('Your AI coding costs.', 'Vaše náklady na AI.');
  String get heroAccent => _t('On your machine.', 'Na vašem počítači.');
  String get heroSubtitle => _t(
    'OpenSpent reads your OpenCode, Claude Code and Codex logs and calculates spending on your device. Explore costs, models and sessions while your usage data stays with you.',
    'OpenSpent čte lokální záznamy OpenCode, Claude Code a Codex a počítá náklady přímo na vašem zařízení. Prozkoumejte náklady, modely a relace. Data o využití zůstávají u vás.',
  );
  String get localProcessing =>
      _t('Processed on your device', 'Zpracování na vašem zařízení');
  String get noUploads => _t('No usage uploads', 'Bez odesílání dat o využití');
  String get noAccount => _t('No account needed', 'Bez registrace');
  String get heroNote => _t(
    'Free and open source. Cost estimates work offline, with no model API calls or API keys.',
    'Zdarma a open source. Odhady nákladů fungují offline, bez volání API modelů a bez API klíčů.',
  );
  String get linkDemo => _t('Try the demo', 'Vyzkoušet demo');
  String get openDemo => _t('Open demo', 'Otevřít demo');
  String get setupAction => _t('Use your own data', 'Použít vlastní data');
  String get supportedSources => _t('Supported sources', 'Podporované zdroje');
  String get badgeOpenSource => 'MIT / OPEN SOURCE';
  String get sampleData => _t('Sample data', 'Ukázková data');
  String get samplePeriod =>
      _t('Last 30 days · USD', 'Posledních 30 dní · USD');
  String get estimateLabel => _t('Estimated API cost', 'Odhad API nákladů');
  String get estimateNote => _t(
    'Token-based estimate. Not a subscription bill.',
    'Odhad podle tokenů. Nejde o účet za předplatné.',
  );
  String get productTitle =>
      _t('From a total to the details.', 'Od celku k detailům.');
  String get productBody => _t(
    'Start with your spending. Filter by harness and time, then explore models, activity and individual sessions.',
    'Začněte náklady. Vyberte nástroj a období, potom prozkoumejte modely, aktivitu a jednotlivé relace.',
  );
  String get previewLabel =>
      _t('Illustrative dashboard preview', 'Ilustrační náhled dashboardu');
  String get previewMetrics => _t('Spending overview', 'Přehled nákladů');
  String get previewSessions => _t('Recent sessions', 'Poslední relace');
  String get previewHeatmapRuns => _t('Sessions', 'Relace');
  String get previewHeatmapActiveDays => _t('Active days', 'Aktivní dny');
  String get spendTrend => _t('Spending over time', 'Náklady v čase');
  String get chartDescription => _t(
    'Illustrative spending bars over 30 days',
    'Ilustrační graf nákladů za 30 dní',
  );
  String get periodStart => _t('30 days ago', 'Před 30 dny');
  String get periodEnd => _t('Today', 'Dnes');
  String get previewExplanation => _t(
    'Find a session by model, date or identifier. Your prompts stay private.',
    'Vyhledejte relaci podle modelu, data nebo identifikátoru. Prompty zůstávají soukromé.',
  );
  String get exploreDemo =>
      _t('Explore the interactive demo ↗', 'Prozkoumat interaktivní demo ↗');
  String get featCostTitle =>
      _t('Know what the numbers mean', 'Rozumějte jednotlivým číslům');
  String get featCostBody => _t(
    'Reported spend and API estimates are shown separately, with pricing coverage. View dashboard totals in USD, CZK or EUR.',
    'Vykázané náklady a API odhady jsou oddělené, včetně pokrytí cenami. Dashboard podporuje USD, CZK a EUR.',
  );
  String get featMonitorTitle =>
      _t('Find the expensive patterns', 'Odhalte nákladné vzorce');
  String get featMonitorBody => _t(
    'Compare models and harnesses, inspect activity by day and hour, and search sessions without digging through logs.',
    'Porovnávejte modely a nástroje, prohlížejte denní a hodinovou aktivitu a hledejte relace bez procházení logů.',
  );
  String get featPrivacyTitle =>
      _t('Local analysis. Private data.', 'Lokální analýza. Soukromá data.');
  String get featPrivacyBody => _t(
    'Your device does the processing and stores only allowlisted usage metadata. No hosted analytics service receives your data. Prompts, tool payloads and project paths never enter the dashboard.',
    'Zpracování probíhá na vašem zařízení a ukládají se pouze povolená metadata o využití. Data neposíláme do hostované analytické služby. Prompty, obsah nástrojů a cesty k projektům se do dashboardu nedostanou.',
  );
  String get startTitle =>
      _t('Choose how you work.', 'Vyberte si svůj způsob práce.');
  String get startBody => _t(
    'A workspace for exploring. A browser for trying it out. A command for a quick answer.',
    'Desktop pro analýzu. Prohlížeč pro vyzkoušení. Příkaz pro rychlou odpověď.',
  );
  String get desktopTitle => _t('On your desktop', 'Na vašem desktopu');
  String get desktopBody => _t(
    'Run the Flutter app, connect local Claude Code and Codex folders in Settings, and sync or import OpenCode data.',
    'Spusťte Flutter aplikaci, připojte lokální složky Claude Code a Codex v nastavení a synchronizujte nebo importujte OpenCode.',
  );
  String get desktopAction => _t('Desktop setup', 'Návod pro desktop');
  String get browserTitle => _t('In your browser', 'V prohlížeči');
  String get browserBody => _t(
    'Explore sample data first. Switch to Real to import OpenCode JSON or SQLite, or connect an accessible OpenCode server. Local folder scans require desktop.',
    'Začněte ukázkovými daty. Přepněte na Real, importujte OpenCode JSON či SQLite nebo připojte dostupný OpenCode server. Skenování složek vyžaduje desktop.',
  );
  String get cliTitle => _t('In your terminal', 'V terminálu');
  String get cliBody => _t(
    'Run openspent on demand to read local OpenCode, Claude Code and Codex usage. Filter the period, inspect pricing coverage or export JSON.',
    'Příkaz openspent na požádání načte lokální využití OpenCode, Claude Code a Codex. Vyberte období, ověřte pokrytí cenami nebo exportujte JSON.',
  );
  String get cliAction => _t('CLI setup', 'Návod pro CLI');
  String get cliNote => _t(
    'Example after compiling the CLI. USD estimates use the same offline pricing rules as the app; unknown prices remain unknown.',
    'Ukázka po kompilaci CLI. Odhady v USD používají stejné offline ceny jako aplikace; neznámé ceny zůstávají neznámé.',
  );
  String get privacyTitle => _t(
    'Local by design. Private by default.',
    'Lokálně od základu. Soukromí samozřejmostí.',
  );
  String get privacyBody => _t(
    'The desktop app and CLI read local records, calculate costs offline and keep usage metadata on your device. There is no OpenSpent cloud backend, account or analytics upload. Optional network features fetch usage from your configured OpenCode server or currency exchange rates; they do not upload your local usage.',
    'Desktopová aplikace a CLI čtou lokální záznamy, počítají náklady offline a ukládají metadata o využití na vašem zařízení. OpenSpent nemá cloudový backend, účet ani odesílání analytiky. Volitelné síťové funkce načítají využití z vašeho OpenCode serveru nebo měnové kurzy; lokální data o využití neodesílají.',
  );
  String get privacyPrompts => _t('Prompts stored', 'Uložené prompty');
  String get privacyPayloads => _t('Raw tool payloads', 'Obsah nástrojů');
  String get privacyPaths =>
      _t('Project paths displayed', 'Zobrazené cesty projektů');
  String get privacyStorage => _t('Usage storage', 'Úložiště využití');
  String get never => _t('Never', 'Nikdy');
  String get onYourDevice => _t('On your device', 'Na vašem zařízení');
  String get dataLimits => _t(
    'Totals cover available local records. Missing logs and cloud-only work are outside the totals. API estimates exclude subscriptions, taxes and extra service charges.',
    'Součty pokrývají dostupné lokální záznamy. Chybějící logy a cloudová práce nejsou zahrnuté. API odhady nezahrnují předplatné, daně a poplatky za další služby.',
  );
  String get enterpriseTitle => _t(
    'An OpenCode server for the whole team.',
    'OpenCode server pro celý tým.',
  );
  String get enterpriseBody => _t(
    'Connect a team-owned OpenCode server and explore its usage from the same local dashboard. Your team keeps control of the server and its data.',
    'Připojte týmový OpenCode server a prohlížejte využití ze stejného lokálního dashboardu. Server a jeho data zůstávají pod kontrolou vašeho týmu.',
  );
  String get serverSetup =>
      _t('Read the data-source guide', 'Návod ke zdrojům dat');
  String get sectionCompany => _t('Built by', 'Vytvořili');
  String get companyTitle => 'Code Growers s.r.o.';
  String get companyBody => _t(
    'We build web, mobile and AI products. OpenSpent is our open-source tool for making AI usage easier to understand, with privacy built in.',
    'Vyvíjíme webové, mobilní a AI produkty. OpenSpent je náš open-source nástroj pro lepší přehled o využití AI s důrazem na soukromí.',
  );
  String get visitCodeGrowers =>
      _t('Meet Code Growers', 'Poznejte Code Growers');
  String get backToTop => _t('Back to top ↑', 'Zpět nahoru ↑');
  String get footer => _t(
    '© 2026 Code Growers s.r.o. MIT Licensed.',
    '© 2026 Code Growers s.r.o. Licence MIT.',
  );
}
