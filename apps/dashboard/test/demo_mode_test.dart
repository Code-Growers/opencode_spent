import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:openspent_dashboard/src/demo/dashboard_demo.dart';

void main() {
  testWidgets('DemoModeController toggles state correctly', (tester) async {
    final controller = DemoModeController();
    expect(controller.value, DashboardDataMode.real);

    controller.toggle();
    expect(controller.value, DashboardDataMode.mock);

    controller.toggle();
    expect(controller.value, DashboardDataMode.real);
  });

  testWidgets('DemoModeScope is visible to UI and updates mode correctly', (
    tester,
  ) async {
    final controller = DemoModeController(DashboardDataMode.mock);

    await tester.pumpWidget(
      MaterialApp(
        home: DemoModeScope(
          controller: controller,
          child: Builder(
            builder: (context) {
              final scope = DemoModeScope.of(context);
              final isMock = scope?.value == DashboardDataMode.mock;
              return Scaffold(
                body: Column(
                  children: [
                    Text(isMock ? 'Mode: MOCK' : 'Mode: REAL'),
                    ElevatedButton(
                      onPressed: scope?.toggle,
                      child: const Text('Toggle'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Mode: MOCK'), findsOneWidget);

    await tester.tap(find.text('Toggle'));
    await tester.pumpAndSettle();

    expect(find.text('Mode: REAL'), findsOneWidget);
  });
}
