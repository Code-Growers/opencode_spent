import 'dart:io';

import 'package:jaspr_test/jaspr_test.dart';
import 'package:openspent_website/components/app.dart';

void main() {
  group('OpenSpent Website', () {
    testComponents('renders english fallback by default', (tester) async {
      tester.pumpComponent(const App());

      expect(find.text('OpenSpent'), findsOneComponent);
      expect(
        find.text('The control room for OpenCode spend.'),
        findsOneComponent,
      );
      expect(find.text('PRIVACY FIRST'), findsOneComponent);
      expect(find.text('100% Local'), findsOneComponent);
      expect(find.text('[EN] / CS'), findsOneComponent);
      expect(find.text('Metrics & Charts'), findsOneComponent);
      expect(find.text('Sessions Overview'), findsOneComponent);
      expect(find.text('Company Cockpit'), findsNComponents(2));
      expect(find.text('Company OpenCode cockpit'), findsOneComponent);
      expect(find.text('Try the Demo'), findsOneComponent);
      expect(find.text('GitHub Repository'), findsOneComponent);
      expect(find.text('Code Growers s.r.o.'), findsOneComponent);
    });

    testComponents('renders czech when toggled', (tester) async {
      tester.pumpComponent(const App());

      await tester.click(find.tag('button'));

      expect(find.text('Řídicí věž pro OpenCode spend.'), findsOneComponent);
      expect(find.text('Stoprocentně lokální'), findsOneComponent);
      expect(find.text('Metriky v reálném čase'), findsOneComponent);
      expect(find.text('EN / [CS]'), findsOneComponent);
      expect(find.text('Metriky a Grafy'), findsOneComponent);
      expect(find.text('Přehled Relací'), findsOneComponent);
      expect(find.text('Firemní Cockpit'), findsNComponents(2));
      expect(find.text('Vyzkoušet Demo'), findsOneComponent);
      expect(find.text('GitHub Repository'), findsOneComponent);
      expect(find.text('Code Growers s.r.o.'), findsOneComponent);
    });

    testComponents('renders preview and terminal content', (tester) async {
      tester.pumpComponent(const App());

      expect(find.text('Metrics & Charts'), findsOneComponent);
      expect(find.text('Sessions Overview'), findsOneComponent);
    });

    test('mock chart bars interpolate CSS heights', () {
      final source = File('lib/components/app.dart').readAsStringSync();

      expect(source, contains(r"'style': 'height: $height%'"));
      expect(source, isNot(contains(r"'style': 'height: \$height%'")));
    });
  });
}
