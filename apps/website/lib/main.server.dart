import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';

import 'components/app.dart';
import 'main.server.options.dart';

void main() {
  Jaspr.initializeApp(options: defaultServerOptions);

  runApp(
    Document(
      title: 'OpenSpent',
      head: [link(href: 'styles.css', rel: 'stylesheet')],
      body: const App(),
    ),
  );
}
