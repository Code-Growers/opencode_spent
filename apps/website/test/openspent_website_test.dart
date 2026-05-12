import 'package:jaspr_test/jaspr_test.dart';
import 'package:openspent_website/components/app.dart';

void main() {
  group('OpenSpent Website', () {
    testComponents('renders english fallback by default', (tester) async {
      tester.pumpComponent(const App());

      expect(find.text('OpenSpent'), findsOneComponent);
      expect(find.text('Monitor OpenCode. Locally.'), findsOneComponent);
      expect(find.text('PRIVACY FIRST'), findsOneComponent);
      expect(find.text('100% Local'), findsOneComponent);
      expect(find.text('[EN] / CS'), findsOneComponent);
      expect(find.text('Metrics & Charts'), findsOneComponent);
      expect(find.text('Sessions Overview'), findsOneComponent);
      expect(find.text('Try the Demo'), findsOneComponent);
      expect(find.text('GitHub Repository'), findsOneComponent);
      expect(find.text('Code Growers s.r.o.'), findsOneComponent);
    });

    testComponents('renders czech when toggled', (tester) async {
      tester.pumpComponent(const App());

      await tester.click(find.tag('button'));

      expect(find.text('Sledujte OpenCode. Lokálně.'), findsOneComponent);
      expect(find.text('Stoprocentně lokální'), findsOneComponent);
      expect(find.text('Metriky v reálném čase'), findsOneComponent);
      expect(find.text('EN / [CS]'), findsOneComponent);
      expect(find.text('Metriky a Grafy'), findsOneComponent);
      expect(find.text('Přehled Relací'), findsOneComponent);
      expect(find.text('Vyzkoušet Demo'), findsOneComponent);
      expect(find.text('GitHub Repository'), findsOneComponent);
      expect(find.text('Code Growers s.r.o.'), findsOneComponent);
    });

    testComponents('renders preview and terminal content', (tester) async {
      tester.pumpComponent(const App());

      expect(find.text('Metrics & Charts'), findsOneComponent);
      expect(find.text('Sessions Overview'), findsOneComponent);
    });
  });
}
