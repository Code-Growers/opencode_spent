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
          'min-h-screen bg-black text-white font-mono leading-relaxed selection:bg-[#333] selection:text-white',
      [
        div(
          classes:
              'w-full max-w-[1200px] mx-auto min-h-screen border-x border-[#222] bg-gradient-to-b from-[#050505] to-black flex flex-col',
          [
            _buildHeader(),
            main_(classes: 'flex-grow flex flex-col', [
              _buildHero(),
              _buildBadges(),
              _buildFeatures(),
              _buildPreview(),
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
          'p-6 border-b border-[#222] flex justify-between items-center sticky top-0 bg-black/80 backdrop-blur-md z-10',
      [
        div(classes: 'flex items-center gap-3', [
          img(src: 'favicon.svg', classes: 'w-4 h-4'), // Simple logo
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
          'px-6 py-24 flex flex-col items-center justify-center text-center border-b border-[#222] relative overflow-hidden',
      [
        // Subtle background glow
        div(
          classes:
              'absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[300px] bg-white/[0.02] blur-[100px] pointer-events-none',
          [],
        ),

        h2(
          classes:
              'text-4xl md:text-6xl font-bold tracking-tight mb-6 max-w-[800px] leading-tight',
          [Component.text(loc.heroTitle)],
        ),
        p(classes: 'text-lg md:text-xl text-[#a1a1aa] max-w-[600px] mb-10', [
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
      classes: 'flex flex-wrap justify-center border-b border-[#222]',
      [
        _badge(loc.badgeAlpha),
        _badge(loc.badgeFree),
        _badge(loc.badgePrivacy),
        _badge(loc.badgeOpenSource),
      ],
    );
  }

  Component _badge(String text) {
    return div(
      classes:
          'px-8 py-4 border-r border-[#222] last:border-r-0 text-sm tracking-[0.2em] text-[#a1a1aa]',
      [Component.text(text)],
    );
  }

  Component _buildFeatures() {
    return section(
      classes:
          'p-6 md:p-12 border-b border-[#222] flex flex-col lg:flex-row gap-12',
      [
        div(classes: 'flex-1 grid grid-cols-1 md:grid-cols-2 gap-6', [
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
          'p-6 border border-[#222] bg-[#0a0a0a] hover:border-[#444] transition-colors flex flex-col',
      [
        div(classes: 'text-[#666] mb-4 font-bold tracking-widest', [
          Component.text(icon),
        ]),
        strong(
          classes:
              'block mb-3 text-white font-normal uppercase tracking-wider text-sm',
          [Component.text(title)],
        ),
        p(classes: 'text-[#888] text-sm leading-relaxed m-0', [
          Component.text(body),
        ]),
      ],
    );
  }

  Component _buildPreview() {
    return section(classes: 'p-6 md:p-12 border-b border-[#222]', [
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
      ]),
    ]);
  }

  Component _mockWindow(String title, List<Component> children) {
    return div(
      classes: 'border border-[#333] bg-[#050505] rounded-sm overflow-hidden',
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
        attributes: {'style': 'height: \$height%'},
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
                  'w-16 h-16 mb-6 group-hover:scale-110 transition-transform duration-700 opacity-80 group-hover:opacity-100',
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
