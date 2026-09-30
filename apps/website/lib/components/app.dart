import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_hooks/jaspr_hooks.dart';

import '../hooks/use_website_localization.dart';
import '../localization.dart';

@client
class App extends HookComponent {
  const App({super.key});

  @override
  Component build(BuildContext context) {
    final localization = useWebsiteLocalization();
    return _LandingPage(
      loc: localization.loc,
      onToggleLanguage: localization.toggleLanguage,
    );
  }
}

const _repository = 'https://github.com/Code-Growers/opencode_spent';

class _LandingPage extends StatelessComponent {
  const _LandingPage({required this.loc, required this.onToggleLanguage});
  final Loc loc;
  final void Function() onToggleLanguage;

  Component _text(String value) => Component.text(value);
  Component _link(String text, String href, {bool primary = false}) =>
      a(href: href, classes: primary ? 'site-action primary' : 'site-action', [
        _text(text),
        span(attributes: {'aria-hidden': 'true'}, [_text('↗')]),
      ]);

  @override
  Component build(BuildContext context) => div(
    classes: 'site-frame',
    attributes: {'lang': loc.languageCode},
    [
      a(href: '#main', classes: 'skip-link', [_text(loc.skipContent)]),
      header(classes: 'site-header', [
        a(href: '#main', classes: 'site-identity', [
          img(
            src: 'logo.svg',
            attributes: {'alt': 'Code Growers'},
            classes: 'site-logo',
          ),
          span([_text(loc.title)]),
        ]),
        nav(
          attributes: {'aria-label': loc.navigation},
          classes: 'site-nav',
          [
            a(href: '#product', [_text(loc.navProduct)]),
            a(href: '#start', [_text(loc.navStart)]),
            a(href: '#privacy', [_text(loc.navPrivacy)]),
          ],
        ),
        button(
          classes: 'language-toggle',
          attributes: {'aria-label': loc.languageSwitchLabel},
          onClick: onToggleLanguage,
          [_text(loc.langSwitch)],
        ),
        a(href: '/demo/', classes: 'header-demo', [
          _text(loc.openDemo),
          _text(' ↗'),
        ]),
      ]),
      main_(
        id: 'main',
        attributes: {'tabindex': '-1'},
        [_hero(), _product(), _start(), _privacy(), _company()],
      ),
      footer(classes: 'site-footer', [
        p([_text(loc.footer)]),
        a(href: _repository, [_text('GitHub ↗')]),
        a(href: '#main', [_text(loc.backToTop)]),
      ]),
    ],
  );

  Component _hero() => section(classes: 'site-hero registration-frame', [
    div(classes: 'hero-copy', [
      p(classes: 'eyebrow', [_text(loc.heroEyebrow)]),
      h1([
        _text('${loc.heroTitle} '),
        span(classes: 'accent', [_text(loc.heroAccent)]),
      ]),
      p(classes: 'hero-description', [_text(loc.heroSubtitle)]),
      ul(classes: 'local-proof', [
        li([_text(loc.localProcessing)]),
        li([_text(loc.noUploads)]),
        li([_text(loc.noAccount)]),
      ]),
      div(classes: 'action-group', [
        _link(loc.linkDemo, '/demo/', primary: true),
        _link(loc.setupAction, '#start'),
      ]),
      p(classes: 'small secondary', [_text(loc.heroNote)]),
    ]),
    div(classes: 'hero-visual', [
      img(
        src: 'brand-flower.webp',
        attributes: {'alt': '', 'aria-hidden': 'true'},
        classes: 'hero-flower',
      ),
      div(classes: 'hero-summary', [
        p(classes: 'eyebrow', [_text(loc.sampleData)]),
        p(classes: 'small secondary', [_text(loc.estimateLabel)]),
        p(classes: 'hero-total accent', [_text('\$42.80')]),
        p(classes: 'small secondary', [_text(loc.samplePeriod)]),
        _summaryRow('OpenCode', '\$18.60'),
        _summaryRow('Claude Code', '\$15.20'),
        _summaryRow('Codex', '\$9.00'),
        p(classes: 'small secondary', [_text(loc.estimateNote)]),
      ]),
    ]),
    div(classes: 'source-strip', [
      span(classes: 'eyebrow', [_text(loc.supportedSources)]),
      span([_text('OpenCode')]),
      span([_text('Claude Code')]),
      span([_text('Codex')]),
      span(classes: 'accent small', [_text(loc.badgeOpenSource)]),
    ]),
  ]);

  Component _summaryRow(String label, String value) =>
      div(classes: 'summary-row', [
        span([_text(label)]),
        span([_text(value)]),
      ]);

  Component _sectionHeading(
    String index,
    String label,
    String title,
    String body,
  ) => div(classes: 'section-heading', [
    p(classes: 'eyebrow accent', [_text('$index / $label')]),
    h2([_text(title)]),
    p(classes: 'secondary', [_text(body)]),
  ]);

  Component _product() => section(id: 'product', classes: 'site-section', [
    _sectionHeading('01', loc.navProduct, loc.productTitle, loc.productBody),
    div(
      classes: 'product-preview',
      attributes: {'aria-label': loc.previewLabel},
      [
        div(classes: 'preview-top', [
          span([_text(loc.previewMetrics)]),
          span(classes: 'small accent', [_text(loc.sampleData)]),
        ]),
        div(classes: 'preview-kpis', [
          _metric(loc.estimateLabel, '\$42.80'),
          _metric(loc.previewHeatmapRuns, '124'),
          _metric(loc.previewHeatmapActiveDays, '18'),
        ]),
        div(classes: 'preview-detail', [
          div(classes: 'preview-chart', [
            h3([_text(loc.spendTrend)]),
            div(
              classes: 'bar-chart',
              attributes: {'aria-label': loc.chartDescription},
              [
                for (final height in [
                  20,
                  42,
                  30,
                  68,
                  44,
                  85,
                  61,
                  48,
                  76,
                  55,
                  93,
                  72,
                ])
                  div(
                    classes: 'chart-bar',
                    attributes: {'style': 'height: $height%'},
                    [],
                  ),
              ],
            ),
            div(classes: 'summary-row small secondary', [
              span([_text(loc.periodStart)]),
              span([_text(loc.periodEnd)]),
            ]),
          ]),
          div(classes: 'preview-sessions', [
            h3([_text(loc.previewSessions)]),
            _summaryRow('OpenCode', '\$0.24'),
            _summaryRow('Claude Code', '\$0.18'),
            _summaryRow('Codex', '\$0.09'),
            p(classes: 'small secondary', [_text(loc.previewExplanation)]),
          ]),
        ]),
        div(classes: 'preview-bottom', [
          span(classes: 'small secondary', [_text(loc.previewLabel)]),
          a(href: '/demo/', [_text(loc.exploreDemo)]),
        ]),
      ],
    ),
    div(classes: 'feature-grid', [
      _feature('01', loc.featCostTitle, loc.featCostBody),
      _feature('02', loc.featMonitorTitle, loc.featMonitorBody),
      _feature('03', loc.featPrivacyTitle, loc.featPrivacyBody),
    ]),
  ]);

  Component _metric(String label, String value) =>
      div(classes: 'preview-metric', [
        p(classes: 'small secondary', [_text(label)]),
        p(classes: 'metric-value', [_text(value)]),
      ]);
  Component _feature(String index, String title, String body) =>
      article(classes: 'feature-card', [
        p(classes: 'eyebrow secondary', [_text(index)]),
        h3([_text(title)]),
        p(classes: 'secondary', [_text(body)]),
      ]);

  Component _start() => section(id: 'start', classes: 'site-section', [
    _sectionHeading('02', loc.navStart, loc.startTitle, loc.startBody),
    div(classes: 'start-grid', [
      _startCard(
        '01',
        loc.desktopTitle,
        loc.desktopBody,
        loc.desktopAction,
        '$_repository#development',
      ),
      _startCard(
        '02',
        loc.browserTitle,
        loc.browserBody,
        loc.openDemo,
        '/demo/',
      ),
      _startCard(
        '03',
        loc.cliTitle,
        loc.cliBody,
        loc.cliAction,
        '$_repository#cli-spending-summary',
      ),
    ]),
    div(classes: 'terminal-example', [
      div(classes: 'summary-row', [
        span([_text(loc.cliTitle)]),
        span(classes: 'small secondary', [_text(loc.sampleData)]),
      ]),
      pre([
        code([
          _text(
            r'$ openspent --days 30'
            '\n\n'
            'Harness       API estimate (USD)\n'
            'OpenCode                   18.60\n'
            'Claude Code                15.20\n'
            'Codex                       9.00\n'
            'TOTAL                      42.80',
          ),
        ]),
      ]),
      p(classes: 'small secondary', [_text(loc.cliNote)]),
    ]),
  ]);

  Component _startCard(
    String index,
    String title,
    String body,
    String action,
    String href,
  ) => article(classes: 'start-card', [
    p(classes: 'eyebrow accent', [_text(index)]),
    h3([_text(title)]),
    p(classes: 'secondary', [_text(body)]),
    _link(action, href),
  ]);

  Component _privacy() => section(
    id: 'privacy',
    classes: 'site-section privacy-grid',
    [
      _sectionHeading('03', loc.navPrivacy, loc.privacyTitle, loc.privacyBody),
      div(classes: 'privacy-facts', [
        _summaryRow(loc.privacyPrompts, loc.never),
        _summaryRow(loc.privacyPayloads, loc.never),
        _summaryRow(loc.privacyPaths, loc.never),
        _summaryRow(loc.privacyStorage, loc.onYourDevice),
        p(classes: 'small secondary', [_text(loc.dataLimits)]),
      ]),
      div(classes: 'team-note', [
        h3([_text(loc.enterpriseTitle)]),
        p(classes: 'secondary', [_text(loc.enterpriseBody)]),
        _link(
          loc.serverSetup,
          '$_repository#local-claude-code-and-codex-usage',
        ),
      ]),
    ],
  );

  Component _company() => section(classes: 'site-section company-section', [
    div([
      p(classes: 'eyebrow accent', [_text(loc.sectionCompany)]),
      h2([_text(loc.companyTitle)]),
      p(classes: 'secondary', [_text(loc.companyBody)]),
    ]),
    _link(loc.visitCodeGrowers, 'https://codegrowers.com/${loc.languageCode}/'),
  ]);
}
