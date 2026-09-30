import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openspent_dashboard/src/screens/dashboard/widgets/dashboard_chip_button.dart';
import 'package:openspent_dashboard/src/theme/dashboard_colors.dart';

void main() {
  testWidgets('DashboardChipButton responds to keyboard Enter and Space', (
    WidgetTester tester,
  ) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: DashboardChipButton(
              label: 'Test Button',
              autofocus: true,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Space key activates it
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    // Wait for the tap to be processed since InkWell might have a delay
    await tester.pump(const Duration(milliseconds: 300));
    expect(tapped, isTrue);

    tapped = false;

    // Verify Enter key activates it
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tapped, isTrue);
  });

  testWidgets('DashboardChipButton uses labelLarge text style', (
    WidgetTester tester,
  ) async {
    const customStyle = TextStyle(fontSize: 42.0, color: Colors.amber);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(textTheme: const TextTheme(labelLarge: customStyle)),
        home: Scaffold(
          body: Center(
            child: DashboardChipButton(label: 'Test Button', onTap: () {}),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final textWidget = tester.widget<Text>(find.text('Test Button'));
    expect(textWidget.style?.fontSize, customStyle.fontSize);
  });

  testWidgets('DashboardChipButton isSelected and isEmphasized semantics', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              children: [
                DashboardChipButton(
                  label: 'Normal',
                  onTap: () {},
                  autofocus: true, // will be focused
                ),
                DashboardChipButton(
                  label: 'Selected',
                  isSelected: true,
                  activeColor: Colors.red,
                  onTap: () {},
                ),
                DashboardChipButton(
                  label: 'Emphasized',
                  isEmphasized: true,
                  activeColor: Colors.green,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final normalContainer = tester.widget<Container>(
      find
          .descendant(
            of: find.widgetWithText(DashboardChipButton, 'Normal'),
            matching: find.byType(Container),
          )
          .first,
    );
    final normalDecoration = normalContainer.decoration as BoxDecoration;
    expect(normalDecoration.boxShadow, isNull);
    expect((normalDecoration.border as Border).top.width, 2);

    final selectedContainer = tester.widget<Container>(
      find
          .descendant(
            of: find.widgetWithText(DashboardChipButton, 'Selected'),
            matching: find.byType(Container),
          )
          .first,
    );
    final selectedDecoration = selectedContainer.decoration as BoxDecoration;
    expect(selectedDecoration.color, dashboardSurfaceHighlightColor);
    final selectedBorder = selectedDecoration.border as Border;
    expect(selectedBorder.top.color, Colors.red);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    final focusedSelectedContainer = tester.widget<Container>(
      find
          .descendant(
            of: find.widgetWithText(DashboardChipButton, 'Selected'),
            matching: find.byType(Container),
          )
          .first,
    );
    final focusedSelectedDecoration =
        focusedSelectedContainer.decoration as BoxDecoration;
    expect(focusedSelectedDecoration.boxShadow, isNull);
    expect((focusedSelectedDecoration.border as Border).top.width, 2);

    // Normal chip (focused) semantics should not have 'selected' state.
    final normalSemantics = tester.getSemantics(find.text('Normal'));
    final normalData = normalSemantics.getSemanticsData();
    expect(normalData.flagsCollection.isSelected, ui.Tristate.none);

    // Selected chip semantics should have 'selected' state.
    final selectedSemantics = tester.getSemantics(find.text('Selected'));
    final selectedData = selectedSemantics.getSemanticsData();
    expect(selectedData.flagsCollection.isSelected, ui.Tristate.isTrue);

    // Emphasized chip semantics should NOT have 'selected' state.
    final emphasizedSemantics = tester.getSemantics(find.text('Emphasized'));
    final emphasizedData = emphasizedSemantics.getSemanticsData();
    expect(emphasizedData.flagsCollection.isSelected, ui.Tristate.none);

    // Check assertion for both true
    expect(
      () => DashboardChipButton(
        label: 'Both',
        isSelected: true,
        isEmphasized: true,
      ),
      throwsAssertionError,
    );
  });
}
