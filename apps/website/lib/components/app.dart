import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import '../localization.dart';

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
          'min-h-screen bg-[#05070b] text-white font-mono leading-relaxed selection:bg-[#1d4ed8] selection:text-white',
      [
        div(
          classes:
              'w-full max-w-[1240px] mx-auto min-h-screen border-x border-[#1f2937] bg-[radial-gradient(circle_at_top_left,_rgba(59,130,246,0.16),_transparent_34%),linear-gradient(180deg,#0d0e10_0%,#05070b_48%,#020305_100%)] flex flex-col shadow-[0_0_80px_rgba(0,0,0,0.5)]',
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
          'p-6 border-b border-[#1f2937] flex justify-between items-center sticky top-0 bg-[#05070b]/85 backdrop-blur-xl z-10',
      [
        div(classes: 'flex items-center gap-3', [
          div(
            classes:
                'p-2 rounded-xl border border-[#1d4ed8]/50 bg-[#3b82f6]/10 shadow-[0_0_24px_rgba(59,130,246,0.16)]',
            [img(src: 'favicon.svg', classes: 'w-4 h-4')],
          ),
          h1(classes: 'm-0 tracking-[0.15em] uppercase text-lg font-bold', [
            Component.text(loc.title),
          ]),
        ]),
        button(
          classes:
              'text-[#a1a1aa] hover:text-white transition-colors cursor-pointer bg-transparent border-none p-0 font-mono text-sm tracking-widest',
          onClick: _toggleLang,
          [Component.text(loc.langSwitch)],
        ),
      ],
    );
  }

  Component _buildHero() {
    return section(
      classes:
          'px-6 py-24 md:py-32 flex flex-col items-center justify-center text-center border-b border-[#1f2937] relative overflow-hidden',
      [
        // Subtle background glow
        div(
          classes:
              'absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[760px] h-[360px] bg-[#3b82f6]/[0.12] blur-[120px] pointer-events-none',
          [],
        ),

        div(
          classes:
              'mb-6 inline-flex items-center gap-3 rounded-full border border-[#2563eb]/50 bg-[#3b82f6]/10 px-4 py-2 text-xs uppercase tracking-[0.24em] text-[#93c5fd]',
          [
            span([Component.text('●')]),
            Component.text('Realtime local analytics'),
          ],
        ),
        h2(
          classes:
              'text-4xl md:text-7xl font-bold tracking-tight mb-6 max-w-[940px] leading-[0.95]',
          [Component.text(loc.heroTitle)],
        ),
        p(classes: 'text-lg md:text-xl text-[#cbd5e1] max-w-[760px] mb-10', [
          Component.text(loc.heroSubtitle),
        ]),
        div(
          classes:
              'flex flex-col sm:flex-row gap-4 items-center justify-center',
          [
            a(
              href: '/demo/',
              classes:
                  'inline-flex items-center justify-center gap-2 px-8 py-4 bg-white text-black font-bold uppercase tracking-widest hover:bg-[#ccc] transition-colors w-full sm:w-auto',
              [
                span([Component.text('→')]),
                Component.text(loc.linkDemo),
              ],
            ),
            a(
              href: 'https://github.com/Code-Growers/opencode_spent',
              target: Target.blank,
              classes:
                  'inline-flex items-center justify-center gap-2 px-8 py-4 border border-[#444] text-white font-bold uppercase tracking-widest hover:bg-[#111] hover:border-[#666] transition-colors w-full sm:w-auto',
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
          'flex flex-wrap justify-center border-b border-[#1f2937] bg-[#0d0e10]/70',
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
          'px-8 py-4 border-r border-[#1f2937] last:border-r-0 text-sm tracking-[0.2em] text-[#a1a1aa]',
      [Component.text(text)],
    );
  }

  Component _buildFeatures() {
    return section(
      classes:
          'p-6 md:p-12 border-b border-[#1f2937] flex flex-col lg:flex-row gap-12',
      [
        div(classes: 'lg:w-[280px] flex-shrink-0', [
          h3(
            classes:
                'm-0 text-sm tracking-[0.2em] uppercase text-[#60a5fa] mb-4',
            [Component.text(loc.sectionFeatures)],
          ),
          p(classes: 'text-[#94a3b8] m-0 text-sm leading-relaxed', [
            Component.text(loc.sectionFeaturesBody),
          ]),
        ]),
        div(classes: 'flex-[1.35] grid grid-cols-1 md:grid-cols-2 gap-8', [
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
        div(classes: 'w-full lg:w-[400px]', [
          div(
            classes:
                'bg-[#050505] border border-[#333] p-6 text-xs text-[#a1a1aa] leading-loose whitespace-pre overflow-x-auto h-full flex flex-col justify-center',
            [Component.text(_asciiChart())],
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
          'min-h-[220px] p-8 border border-[#1f2937] bg-[#111318]/80 hover:border-[#3b82f6]/60 hover:bg-[#151923] transition-colors flex flex-col rounded-3xl shadow-[0_24px_54px_rgba(0,0,0,0.28)]',
      [
        div(classes: 'text-[#60a5fa] mb-6 text-lg font-bold tracking-widest', [
          Component.text(icon),
        ]),
        strong(
          classes:
              'block mb-4 text-white font-semibold uppercase tracking-wider text-base',
          [Component.text(title)],
        ),
        p(classes: 'text-[#94a3b8] text-base leading-relaxed m-0', [
          Component.text(body),
        ]),
      ],
    );
  }

  Component _buildPreview() {
    return section(classes: 'p-6 md:p-12 border-b border-[#1f2937]', [
      div(classes: 'mb-8', [
        h3(classes: 'm-0 text-sm tracking-[0.2em] uppercase text-[#666] mb-2', [
          Component.text(loc.sectionPreview),
        ]),
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
          _mockSignalRow('HQ SERVER', 'CONNECTED', 'text-[#10b981]'),
          _mockSignalRow('MONTH SPEND', '\$24,860', 'text-white'),
          _mockSignalRow('ACTIVE MODELS', '12', 'text-white'),
          _mockSignalRow('PROMPTS', 'NEVER STORED', 'text-[#60a5fa]'),
        ]),
      ]),
    ]);
  }

  Component _mockWindow(String title, List<Component> children) {
    return div(
      classes:
          'border border-[#1f2937] bg-[#090b10] rounded-2xl overflow-hidden shadow-[0_24px_60px_rgba(0,0,0,0.28)]',
      [
        div(
          classes:
              'border-b border-[#333] p-3 flex items-center gap-3 bg-[#0a0a0a]',
          [
            div(classes: 'flex gap-1.5', [
              div(classes: 'w-2.5 h-2.5 rounded-full bg-[#333]', []),
              div(classes: 'w-2.5 h-2.5 rounded-full bg-[#333]', []),
              div(classes: 'w-2.5 h-2.5 rounded-full bg-[#333]', []),
            ]),
            span(classes: 'text-xs text-[#888] tracking-widest uppercase', [
              Component.text(title),
            ]),
          ],
        ),
        div(classes: 'p-6 flex flex-col', children),
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
        span(classes: 'text-[#a1a1aa]', [Component.text(model)]),
        span(classes: 'text-white', [Component.text(cost)]),
      ],
    );
  }

  Component _mockSignalRow(String label, String value, String valueClass) {
    return div(
      classes:
          'flex justify-between gap-6 py-3 border-b border-[#111827] last:border-0 text-xs',
      [
        span(classes: 'text-[#64748b]', [Component.text(label)]),
        span(classes: '$valueClass tracking-widest', [Component.text(value)]),
      ],
    );
  }

  Component _buildEnterprise() {
    return section(
      classes:
          'p-6 md:p-12 border-b border-[#1f2937] grid grid-cols-1 lg:grid-cols-[1.15fr_0.85fr] gap-8 items-stretch',
      [
        div(
          classes:
              'rounded-3xl border border-[#2563eb]/40 bg-[#0f172a]/50 p-8 shadow-[0_30px_80px_rgba(37,99,235,0.12)]',
          [
            h3(
              classes:
                  'm-0 text-sm tracking-[0.2em] uppercase text-[#60a5fa] mb-6',
              [Component.text(loc.sectionEnterprise)],
            ),
            h4(
              classes:
                  'text-3xl md:text-4xl font-bold leading-tight mb-5 max-w-3xl',
              [Component.text(loc.enterpriseTitle)],
            ),
            p(classes: 'text-[#cbd5e1] leading-relaxed max-w-3xl mb-8', [
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
          _mockSignalRow('finance view', 'LIVE', 'text-[#10b981]'),
          _mockSignalRow('engineering view', 'FILTERED', 'text-[#60a5fa]'),
          _mockSignalRow('sensitive fields', 'BLOCKED', 'text-[#fbbf24]'),
        ]),
      ],
    );
  }

  Component _enterprisePoint(String number, String text) {
    return div(
      classes: 'border border-[#1f2937] bg-[#05070b]/80 rounded-2xl p-4',
      [
        div(classes: 'text-[#60a5fa] text-xs tracking-[0.2em] mb-3', [
          Component.text(number),
        ]),
        p(classes: 'm-0 text-sm text-[#e5e7eb] leading-relaxed', [
          Component.text(text),
        ]),
      ],
    );
  }

  Component _miniMetric(String label, String value) {
    return div(classes: 'border border-[#1f2937] bg-[#05070b] rounded-xl p-3', [
      div(classes: 'text-[10px] text-[#64748b] tracking-[0.2em] mb-2', [
        Component.text(label),
      ]),
      div(classes: 'text-lg text-white font-bold', [Component.text(value)]),
    ]);
  }

  Component _buildCompany() {
    return section(
      classes:
          'p-6 md:p-12 grid grid-cols-1 md:grid-cols-2 gap-12 items-center',
      [
        div([
          h3(
            classes: 'm-0 text-sm tracking-[0.2em] uppercase text-[#666] mb-6',
            [Component.text(loc.sectionCompany)],
          ),
          h4(classes: 'text-2xl font-bold mb-4', [
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
                  'text-sm text-[#888] tracking-widest uppercase m-0 group-hover:text-white transition-colors',
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
