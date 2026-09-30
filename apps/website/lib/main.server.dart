import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';

import 'components/app.dart';
import 'main.server.options.dart';

void main() {
  Jaspr.initializeApp(options: defaultServerOptions);

  runApp(
    Document(
      title: 'OpenSpent',
      head: [
        link(href: 'styles.css', rel: 'stylesheet'),
        link(href: 'favicon.svg', rel: 'icon', type: 'image/svg+xml'),
        meta(
          name: 'description',
          content:
              'Track OpenCode, Claude Code and Codex costs on your machine. Local processing, offline estimates, no account and no usage uploads.',
        ),
        meta(attributes: {'property': 'og:title', 'content': 'OpenSpent'}),
        meta(
          attributes: {
            'property': 'og:description',
            'content':
                'Track OpenCode, Claude Code and Codex costs on your machine. Local processing, offline estimates, no account and no usage uploads.',
          },
        ),
        meta(attributes: {'property': 'og:image', 'content': 'cover.jpg'}),
        meta(attributes: {'property': 'og:type', 'content': 'website'}),
      ],
      body: const App(),
    ),
  );
}
