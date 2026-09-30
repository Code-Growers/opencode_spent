import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import '../localization.dart';

@client
class App extends StatefulComponent {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  Loc loc = Loc.en;

  void _toggleLang() {
    setState(() {
      loc = loc == Loc.en ? Loc.cs : Loc.en;
    });
  }

  @override
  Component build(BuildContext context) {
    return div(
      classes:
          'min-h-screen bg-[#080808] text-white font-brand leading-relaxed selection:bg-[#39ff82] selection:text-[#080808]',
      [
        div(
          classes:
              'brand-frame w-[calc(100%-40px)] lg:w-[calc(100%-70px)] max-w-[1600px] mx-auto min-h-screen border-x border-[#303030] bg-[#080808] flex flex-col overflow-clip',
          [
            _buildHeader(),
            main_(classes: 'flex-grow flex flex-col', [
              _buildHero(),
              _buildBadges(),
              _buildFeatures(),
              _buildPreview(),
              _buildEnterprise(),
              _buildCompany(),
            ]),
            _buildFooter(),
          ],
        ),
      ],
    );
  }

  Component _buildHeader() {
    return header(
      classes:
          'p-6 border-b border-[#303030] flex justify-between items-center sticky top-0 bg-[#080808] z-10',
      [
        div(classes: 'flex items-center gap-3', [
          div(classes: 'pr-4', [
            img(src: 'logo.svg', classes: 'w-[90px] h-auto'),
          ]),
          h1(classes: 'm-0 tracking-tight text-lg font-normal', [
            Component.text(loc.title),
          ]),
        ]),
        button(
          classes:
              'text-[#aaaaaa] hover:text-white transition-colors cursor-pointer bg-transparent border-none p-0 font-brand text-sm tracking-wide',
          onClick: _toggleLang,
          [Component.text(loc.langSwitch)],
        ),
      ],
    );
  }

  Component _buildHero() {
    return section(
      classes:
          'px-6 py-24 md:py-32 flex flex-col items-start justify-center text-left border-b border-[#303030] relative overflow-hidden',
      [
        img(
          src: 'brand-flower.webp',
          attributes: {'alt': '', 'aria-hidden': 'true'},
          classes:
              'absolute right-0 top-0 h-full w-2/3 object-contain opacity-20 pointer-events-none',
        ),
        div(
          classes:
              'mb-6 relative inline-flex items-center gap-3 rounded-none border border-[#39ff82]/50 bg-[#39ff82]/10 px-4 py-2 text-xs uppercase tracking-[0.06em] text-[#39ff82]',
          [
            span([Component.text('●')]),
            Component.text('Realtime local analytics'),
          ],
        ),
        h2(
          classes:
              'relative text-4xl md:text-6xl font-normal tracking-tight mb-6 max-w-[940px] max-w-full leading-[1.3]',
          [Component.text(loc.heroTitle)],
        ),
        p(
          classes:
              'relative text-lg md:text-xl text-[#c5c5c5] max-w-[760px] mb-10',
          [Component.text(loc.heroSubtitle)],
        ),
        div(
          classes:
              'relative flex flex-col sm:flex-row gap-4 items-center justify-center',
          [
            a(
              href: '/demo/',
              classes:
                  'inline-flex items-center justify-center gap-2 px-8 py-4 bg-[#39ff82] text-[#080808] font-normal uppercase tracking-wide hover:bg-white transition-colors w-full sm:w-auto',
              [
                span([Component.text('→')]),
                Component.text(loc.linkDemo),
              ],
            ),
            a(
              href: 'https://github.com/Code-Growers/opencode_spent',
              target: Target.blank,
              classes:
                  'inline-flex items-center justify-center gap-2 px-8 py-4 border border-[#444] text-white font-normal uppercase tracking-wide hover:bg-[#111] hover:border-[#666] transition-colors w-full sm:w-auto',
              [
                span([Component.text('↗')]),
                Component.text(loc.linkGithub),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Component _buildBadges() {
    return div(
      classes:
          'flex flex-wrap justify-center border-b border-[#303030] bg-[#080808]/70',
      [
        _badge(loc.badgeAlpha),
        _badge(loc.badgeFree),
        _badge(loc.badgePrivacy),
        _badge(loc.badgeOpenSource),
        _badge(loc.badgeRealtime),
      ],
    );
  }

  Component _badge(String text) {
    return div(
      classes:
          'px-8 py-4 border-r border-[#303030] last:border-r-0 text-sm tracking-[0.06em] text-[#aaaaaa]',
      [Component.text(text)],
    );
  }

  Component _buildFeatures() {
    return section(
      classes:
          'p-6 md:p-12 border-b border-[#303030] flex flex-col lg:flex-row gap-12',
      [
        div(classes: 'w-full lg:w-[280px] flex-shrink-0', [
          h3(
            classes:
                'm-0 text-sm tracking-[0.06em] uppercase text-[#39ff82] mb-4',
            [Component.text(loc.sectionFeatures)],
          ),
          p(classes: 'text-[#aaaaaa] m-0 text-sm leading-relaxed', [
            Component.text(loc.sectionFeaturesBody),
          ]),
        ]),
        div(classes: 'flex-1 grid grid-cols-1 md:grid-cols-2 gap-8', [
          _featureCard(
            title: loc.featPrivacyTitle,
            body: loc.featPrivacyBody,
            icon: '[!]',
          ),
          _featureCard(
            title: loc.featCostTitle,
            body: loc.featCostBody,
            icon: '[\$]',
          ),
          _featureCard(
            title: loc.featMonitorTitle,
            body: loc.featMonitorBody,
            icon: '[~]',
          ),
          _featureCard(
            title: loc.featCompanyTitle,
            body: loc.featCompanyBody,
            icon: '[HQ]',
          ),
        ]),
      ],
    );
  }

  Component _featureCard({
    required String title,
    required String body,
    required String icon,
  }) {
    return div(
      classes:
          'min-h-[220px] p-8 border border-[#303030] bg-[#0c0c0c]/80 hover:border-[#39ff82]/60 hover:bg-[#101811] transition-colors flex flex-col rounded-none ',
      [
        div(classes: 'text-[#39ff82] mb-6 text-lg font-normal tracking-wide', [
          Component.text(icon),
        ]),
        strong(
          classes:
              'block mb-4 text-white font-normal uppercase tracking-wider text-base',
          [Component.text(title)],
        ),
        p(classes: 'text-[#aaaaaa] text-base leading-relaxed m-0', [
          Component.text(body),
        ]),
      ],
    );
  }

  Component _buildPreview() {
    return section(classes: 'p-6 md:p-12 border-b border-[#303030]', [
      div(classes: 'mb-8', [
        h3(
          classes: 'm-0 text-sm tracking-[0.06em] uppercase text-[#666] mb-2',
          [Component.text(loc.sectionPreview)],
        ),
      ]),
      div(classes: 'mb-8 min-w-0', [
        div(
          classes:
              'bg-[#050505] border border-[#333] p-6 text-xs text-[#aaaaaa] leading-loose whitespace-pre overflow-x-auto rounded-none flex flex-col justify-center',
          [Component.text(_asciiChart())],
        ),
      ]),
      div(classes: 'grid grid-cols-1 md:grid-cols-2 gap-6', [
        _mockWindow(loc.previewMetrics, [
          div(classes: 'flex gap-2 mb-4', [
            _mockBar(40),
            _mockBar(70),
            _mockBar(30),
            _mockBar(90),
            _mockBar(50),
          ]),
          div(classes: 'flex justify-between text-[#666]', [
            span([Component.text('1w')]),
            span([Component.text('Now')]),
          ]),
        ]),
        _mockWindow(loc.previewSessions, [
          _mockTableRow('10:45:21', 'GPT-4o', '\$0.12'),
          _mockTableRow('09:12:04', 'Claude-3.5', '\$0.08'),
          _mockTableRow('YESTERDAY', 'Local', '\$0.00'),
        ]),
        _mockWindow(loc.previewCompany, [
          _mockSignalRow('HQ SERVER', 'CONNECTED', 'text-[#39ff82]'),
          _mockSignalRow('MONTH SPEND', '\$24,860', 'text-white'),
          _mockSignalRow('ACTIVE MODELS', '12', 'text-white'),
          _mockSignalRow('PROMPTS', 'NEVER STORED', 'text-[#39ff82]'),
        ]),
        _mockWindow(loc.previewHeatmap, [
          div(classes: 'flex flex-col gap-5', [
            div(
              classes:
                  'flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between',
              [
                div(classes: 'flex flex-col gap-3', [
                  div(classes: 'flex flex-col gap-1', [
                    span(
                      classes: 'text-2xl font-normal text-white leading-none',
                      [Component.text('142')],
                    ),
                    span(
                      classes:
                          'text-[10px] text-[#aaaaaa] tracking-[0.06em] uppercase',
                      [Component.text(loc.previewHeatmapRuns)],
                    ),
                  ]),
                  div(classes: 'grid grid-cols-2 gap-2 sm:grid-cols-3', [
                    _mockHeatmapStat(loc.previewHeatmapActiveDays, '24'),
                    _mockHeatmapStat(loc.previewHeatmapCurrentStreak, '4D'),
                    _mockHeatmapStat(loc.previewHeatmapPeak, '1 PM'),
                  ]),
                ]),
                div(
                  classes:
                      'flex gap-1.5 items-center text-[10px] text-[#aaaaaa] tracking-wider uppercase',
                  [
                    span([Component.text(loc.previewHeatmapLegendLess)]),
                    _mockHeatmapCell(0),
                    _mockHeatmapCell(1),
                    _mockHeatmapCell(2),
                    _mockHeatmapCell(3),
                    _mockHeatmapCell(4),
                    span([Component.text(loc.previewHeatmapLegendMore)]),
                  ],
                ),
              ],
            ),
            _mockHeatmapGrid(),
          ]),
        ]),
      ]),
    ]);
  }

  Component _mockWindow(String title, List<Component> children) {
    return div(
      classes:
          'border border-[#303030] bg-[#0c0c0c] rounded-none overflow-hidden  flex flex-col',
      [
        div(
          classes:
              'border-b border-[#333] p-3 flex items-center gap-3 bg-[#0a0a0a]',
          [
            div(classes: 'flex gap-1.5', [
              div(classes: 'w-2.5 h-2.5 rounded-none bg-[#333]', []),
              div(classes: 'w-2.5 h-2.5 rounded-none bg-[#333]', []),
              div(classes: 'w-2.5 h-2.5 rounded-none bg-[#333]', []),
            ]),
            span(classes: 'text-xs text-[#888] tracking-wide uppercase', [
              Component.text(title),
            ]),
          ],
        ),
        div(classes: 'p-6 flex flex-col flex-grow justify-center', children),
      ],
    );
  }

  Component _mockHeatmapGrid() {
    final List<List<int>> columns = [
      [0, 0, 1, 0, 0, 0, 0],
      [0, 1, 2, 1, 0, 0, 1],
      [0, 2, 4, 3, 1, 0, 0],
      [1, 3, 4, 4, 2, 1, 0],
      [0, 1, 3, 2, 1, 0, 0],
      [0, 0, 2, 1, 0, 0, 0],
      [0, 1, 1, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 1, 2],
      [1, 0, 0, 1, 2, 3, 1],
      [2, 1, 0, 2, 4, 3, 0],
      [3, 2, 1, 1, 2, 1, 0],
      [1, 0, 0, 0, 1, 0, 0],
    ];

    return div(classes: 'overflow-x-auto', [
      div(
        classes: 'inline-flex min-w-max gap-1.5',
        columns
            .map(
              (levels) => div(
                classes: 'flex flex-col gap-1.5',
                levels.map((level) => _mockHeatmapCell(level)).toList(),
              ),
            )
            .toList(),
      ),
    ]);
  }

  Component _mockHeatmapCell(int level) {
    final bgClasses = [
      'bg-[#121212]',
      'bg-[#163d25]',
      'bg-[#227c42]',
      'bg-[#2cbd60]',
      'bg-[#39ff82]',
    ];
    return div(
      classes:
          'w-2.5 h-2.5 rounded-[2px] border border-white/6 ${bgClasses[level]}',
      [],
    );
  }

  Component _mockHeatmapStat(String label, String value) {
    return div(
      classes: 'rounded-none border border-[#303030] bg-[#080808] px-3 py-2',
      [
        div(classes: 'text-[9px] text-[#aaaaaa] tracking-[0.18em] uppercase', [
          Component.text(label),
        ]),
        div(classes: 'mt-1 text-sm font-normal text-white', [
          Component.text(value),
        ]),
      ],
    );
  }

  Component _mockBar(int height) {
    return div(classes: 'flex-1 bg-[#222] relative h-16', [
      div(
        classes: 'absolute bottom-0 left-0 right-0 bg-[#444]',
        attributes: {'style': 'height: $height%'},
        [],
      ),
    ]);
  }

  Component _mockTableRow(String time, String model, String cost) {
    return div(
      classes:
          'flex justify-between py-2 border-b border-[#111] last:border-0 text-xs',
      [
        span(classes: 'text-[#666]', [Component.text(time)]),
        span(classes: 'text-[#aaaaaa]', [Component.text(model)]),
        span(classes: 'text-white', [Component.text(cost)]),
      ],
    );
  }

  Component _mockSignalRow(String label, String value, String valueClass) {
    return div(
      classes:
          'flex justify-between gap-6 py-3 border-b border-[#121212] last:border-0 text-xs',
      [
        span(classes: 'text-[#aaaaaa]', [Component.text(label)]),
        span(classes: '$valueClass tracking-wide', [Component.text(value)]),
      ],
    );
  }

  Component _buildEnterprise() {
    return section(
      classes:
          'p-6 md:p-12 border-b border-[#303030] grid grid-cols-1 lg:grid-cols-[1.15fr_0.85fr] gap-8 items-stretch',
      [
        div(
          classes:
              'rounded-none border border-[#39ff82]/40 bg-[#101811]/50 p-8 ',
          [
            h3(
              classes:
                  'm-0 text-sm tracking-[0.06em] uppercase text-[#39ff82] mb-6',
              [Component.text(loc.sectionEnterprise)],
            ),
            h4(
              classes:
                  'text-3xl md:text-4xl font-normal leading-tight mb-5 max-w-3xl',
              [Component.text(loc.enterpriseTitle)],
            ),
            p(classes: 'text-[#c5c5c5] leading-relaxed max-w-3xl mb-8', [
              Component.text(loc.enterpriseBody),
            ]),
            div(classes: 'grid grid-cols-1 md:grid-cols-3 gap-4', [
              _enterprisePoint('01', loc.enterprisePointRealtime),
              _enterprisePoint('02', loc.enterprisePointLocal),
              _enterprisePoint('03', loc.enterprisePointOps),
            ]),
          ],
        ),
        _mockWindow(loc.previewCompany, [
          div(classes: 'grid grid-cols-2 gap-3 mb-4', [
            _miniMetric('SPEND', '\$24.8K'),
            _miniMetric('SESSIONS', '1,284'),
            _miniMetric('TEAM', '42 DEV'),
            _miniMetric('LATENCY', '812MS'),
          ]),
          _mockSignalRow('finance view', 'LIVE', 'text-[#39ff82]'),
          _mockSignalRow('engineering view', 'FILTERED', 'text-[#39ff82]'),
          _mockSignalRow('sensitive fields', 'BLOCKED', 'text-[#fbbf24]'),
        ]),
      ],
    );
  }

  Component _enterprisePoint(String number, String text) {
    return div(
      classes: 'border border-[#303030] bg-[#080808]/80 rounded-none p-4',
      [
        div(classes: 'text-[#39ff82] text-xs tracking-[0.06em] mb-3', [
          Component.text(number),
        ]),
        p(classes: 'm-0 text-sm text-[#ffffff] leading-relaxed', [
          Component.text(text),
        ]),
      ],
    );
  }

  Component _miniMetric(String label, String value) {
    return div(
      classes: 'border border-[#303030] bg-[#080808] rounded-none p-3',
      [
        div(classes: 'text-[10px] text-[#aaaaaa] tracking-[0.06em] mb-2', [
          Component.text(label),
        ]),
        div(classes: 'text-lg text-white font-normal', [Component.text(value)]),
      ],
    );
  }

  Component _buildCompany() {
    return section(
      classes:
          'p-6 md:p-12 grid grid-cols-1 md:grid-cols-2 gap-12 items-center',
      [
        div([
          h3(
            classes: 'm-0 text-sm tracking-[0.06em] uppercase text-[#666] mb-6',
            [Component.text(loc.sectionCompany)],
          ),
          h4(classes: 'text-2xl font-normal mb-4', [
            Component.text(loc.companyTitle),
          ]),
          p(classes: 'text-[#888] mb-8 leading-relaxed max-w-md', [
            Component.text(loc.companyBody),
          ]),
          a(
            href: 'https://www.linkedin.com/company/code-growers-s-r-o/',
            target: Target.blank,
            classes:
                'inline-flex items-center gap-2 text-white border-b border-[#444] pb-1 hover:border-white transition-colors',
            [
              span([Component.text('↗')]),
              Component.text(loc.linkLinkedin),
            ],
          ),
        ]),
        a(
          href: 'https://codegrowers.com/',
          target: Target.blank,
          classes:
              'border border-[#222] p-8 flex flex-col items-center justify-center text-center bg-[#050505] relative overflow-hidden group no-underline',
          [
            div(
              classes:
                  'absolute inset-0 bg-white/5 opacity-0 group-hover:opacity-100 transition-opacity duration-500',
              [],
            ),
            img(
              src: 'logo.svg',
              classes:
                  'h-12 w-auto mb-6 group-hover:scale-110 transition-transform duration-700 opacity-80 group-hover:opacity-100',
            ),
            p(
              classes:
                  'text-sm text-[#888] tracking-wide uppercase m-0 group-hover:text-white transition-colors',
              [Component.text('Code Growers')],
            ),
          ],
        ),
      ],
    );
  }

  Component _buildFooter() {
    return footer(
      classes:
          'p-6 border-t border-[#222] text-[#666] text-xs flex flex-col sm:flex-row justify-between items-center gap-4 bg-black',
      [
        p(classes: 'm-0 tracking-wider', [Component.text(loc.footer)]),
        div(classes: 'flex gap-6', [
          a(
            href: 'https://github.com/Code-Growers/opencode_spent',
            target: Target.blank,
            classes: 'hover:text-white transition-colors',
            [Component.text('GitHub')],
          ),
          a(
            href: 'https://www.linkedin.com/company/code-growers-s-r-o/',
            target: Target.blank,
            classes: 'hover:text-white transition-colors',
            [Component.text('LinkedIn')],
          ),
        ]),
      ],
    );
  }

  String _asciiChart() {
    return '''
${loc.terminalCommand}
[====================] 100%

${loc.terminalUsage}
  API        ${loc.terminalCost}
  gpt-4o     \$ 12.40
  claude     \$  4.20
  local      \$  0.00
  -------------------
  ${loc.terminalTotal}      \$ 16.60

${loc.terminalTrend}
    ^
  5 |   *
  4 |  ***  *
  3 | **** ***
  2 |**********
  0 +----------->
''';
  }
}
