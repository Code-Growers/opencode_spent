import 'package:jaspr/dom.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:openspent_website/components/app.dart';

void main() {
  testComponents(
    'explains supported sources, pricing and three ways to start',
    (tester) async {
      tester.pumpComponent(const App());
      expect(find.text('OpenSpent'), findsOneComponent);
      expect(find.text('On your machine.'), findsOneComponent);
      expect(find.text('Processed on your device'), findsOneComponent);
      expect(find.text('No usage uploads'), findsOneComponent);
      expect(find.text('No account needed'), findsOneComponent);
      expect(find.text('On your desktop'), findsOneComponent);
      expect(find.text('In your browser'), findsOneComponent);
      expect(find.text('In your terminal'), findsNComponents(2));
      expect(find.text('Sample data'), findsNComponents(3));
      expect(
        find.text('Token-based estimate. Not a subscription bill.'),
        findsOneComponent,
      );
      expect(find.textContaining(r'$ openspent --days 30'), findsOneComponent);
      expect(
        find.text('Local by design. Private by default.'),
        findsOneComponent,
      );
      expect(find.text('Code Growers s.r.o.'), findsOneComponent);
      expect(find.tag('h1'), findsOneComponent);
    },
  );

  testComponents('navigation and setup actions resolve to real destinations', (
    tester,
  ) async {
    tester.pumpComponent(const App());
    expect(
      find.byComponentPredicate(
        (element) => element is a && element.href == '#product',
      ),
      findsOneComponent,
    );
    expect(
      find.byComponentPredicate(
        (element) => element is a && element.href == '#start',
      ),
      findsNComponents(2),
    );
    expect(
      find.byComponentPredicate(
        (element) => element is a && element.href == '#privacy',
      ),
      findsOneComponent,
    );
    expect(
      find.byComponentPredicate(
        (element) => element is a && element.href == '/demo/',
      ),
      findsNComponents(4),
    );
    expect(
      find.byComponentPredicate(
        (element) =>
            element is a && element.href.endsWith('#cli-spending-summary'),
      ),
      findsOneComponent,
    );
  });

  testComponents('switches the entire journey between Czech and English', (
    tester,
  ) async {
    tester.pumpComponent(const App());
    for (var cycle = 0; cycle < 3; cycle++) {
      await tester.click(find.tag('button'));
      expect(find.text('Na vašem počítači.'), findsOneComponent);
      expect(find.text('Bez odesílání dat o využití'), findsOneComponent);
      expect(find.text('Na vašem desktopu'), findsOneComponent);
      expect(find.text('V prohlížeči'), findsOneComponent);
      expect(find.text('V terminálu'), findsNComponents(2));
      expect(find.text('Ukázková data'), findsNComponents(3));
      expect(find.text('Přejít na obsah'), findsOneComponent);
      expect(find.textContaining(r'$ openspent --days 30'), findsOneComponent);
      await tester.click(find.tag('button'));
      expect(find.text('On your machine.'), findsOneComponent);
      expect(find.text('Sample data'), findsNComponents(3));
      expect(
        find.text('© 2026 Code Growers s.r.o. MIT Licensed.'),
        findsOneComponent,
      );
    }
  });
}
