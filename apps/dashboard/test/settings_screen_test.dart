import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:openspent_dashboard/src/screens/settings/settings_screen.dart';
import 'package:openspent_dashboard/l10n/app_localizations.dart';
import 'package:openspent_core/openspent_core.dart';

class MockSettingsRepository implements SettingsRepository {
  @override
  Future<OpenCodeSettings?> readSettings() async => null;

  @override
  Future<void> writeSettings(OpenCodeSettings settings) async {}
}

void main() {
  testWidgets('SettingsScreen inputs have correct semantics', (
    WidgetTester tester,
  ) async {
    final mockRepo = MockSettingsRepository();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SettingsScreen(settingsRepository: mockRepo),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(SettingsScreen)),
    )!;

    final urlSemantics = tester.getSemantics(
      find.byKey(const Key('settings-server-url-field')),
    );
    expect(urlSemantics.label, l10n.settingsServerUrl);
    expect(urlSemantics.flagsCollection.isTextField, isTrue);

    final usernameSemantics = tester.getSemantics(
      find.byKey(const Key('settings-server-username-field')),
    );
    expect(usernameSemantics.label, l10n.settingsServerUsername);
    expect(usernameSemantics.flagsCollection.isTextField, isTrue);

    final passwordSemantics = tester.getSemantics(
      find.byKey(const Key('settings-server-password-field')),
    );
    expect(passwordSemantics.label, l10n.settingsServerPassword);
    expect(passwordSemantics.flagsCollection.isTextField, isTrue);

    final currencySemantics = tester.getSemantics(
      find.byKey(const Key('settings-currency-semantics')),
    );
    final currencyData = currencySemantics.getSemanticsData();
    expect(currencySemantics.label, contains(l10n.settingsCurrency));
    expect(currencySemantics.label, contains('USD'));
    expect(currencyData.flagsCollection.isButton, isTrue);
    expect(currencyData.flagsCollection.isFocused, isNot(ui.Tristate.none));
    expect(currencyData.flagsCollection.isExpanded, ui.Tristate.isFalse);
    expect(currencyData.hasAction(ui.SemanticsAction.tap), isTrue);
    expect(currencyData.hasAction(ui.SemanticsAction.focus), isTrue);

    final languageSemantics = tester.getSemantics(
      find.byKey(const Key('settings-language-semantics')),
    );
    final languageData = languageSemantics.getSemanticsData();
    expect(languageSemantics.label, contains(l10n.settingsLanguage));
    expect(languageSemantics.label, contains(l10n.settingsLanguageSystem));
    expect(languageData.flagsCollection.isButton, isTrue);
    expect(languageData.flagsCollection.isFocused, isNot(ui.Tristate.none));
    expect(languageData.flagsCollection.isExpanded, ui.Tristate.isFalse);
    expect(languageData.hasAction(ui.SemanticsAction.tap), isTrue);
    expect(languageData.hasAction(ui.SemanticsAction.focus), isTrue);
  });
}
